"""Resident grouped incremental baseline: CPython 1/4 processes and NumPy."""
import array
import json
import mmap
import multiprocessing as mp
import os
from pathlib import Path
import sys
import time


def finish(s, k, v):
    if k == 1:
        return (s * (10000 - min(v, 10000)) + 5000) // 10000
    return max(0, s - v) if k == 2 else s


def mapped(path):
    with open(path, 'rb') as f:
        data = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    # Touch every page before timing; canonical commands stay read-only.
    _ = sum(data[i] for i in range(0, len(data), 4096))
    return data


def work(r, lo, hi, out):
    cmd = COMMANDS[r * WORDS:(r + 1) * WORDS]
    updates = (WORDS - N) // 4
    rows, sums, totals, n, cap, w = ROWS, SUMS, TOTALS, N, CAP, W
    for i in range(lo, hi):
        cart = cmd[i]
        off = cart * w
        subtotal = sums[cart]
        for k in range(i, updates, n):
            p = n + k * 4
            slot = cmd[p + 1]
            a, b = off + 1 + slot, off + 1 + cap + slot
            subtotal -= rows[a] * rows[b]
            subtotal += cmd[p + 2] * cmd[p + 3]
            rows[a], rows[b] = cmd[p + 2], cmd[p + 3]
        if i < updates:
            sums[cart] = subtotal
            totals[cart] = finish(subtotal, rows[off + w - 2], rows[off + w - 1])
        out[i] = totals[cart]


def worker_job(job):
    r, lo, hi = job
    work(r, lo, hi, SHARED_OUT)


def main():
    global ROWS, SUMS, TOTALS, COMMANDS, SHARED_OUT, N, CAP, W, WORDS
    if sys.byteorder != 'little':
        raise ValueError('Fixtures are little-endian u64')
    root, name, rep = Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
    meta = json.loads((root / 'manifest.json').read_text())
    N, CAP, WORDS = meta['carts'], meta['lines'], meta['command_words']
    W = 2 * CAP + 3
    COMMANDS = memoryview(mapped(root / 'commands.bin')).cast('Q')
    expected = memoryview(mapped(root / 'expected.bin')).cast('Q')
    base = mapped(root / 'base.bin')
    if len(base) != N * W * 8 or len(COMMANDS) != WORDS * meta['rounds'] or len(expected) != N * meta['rounds']:
        raise ValueError('Invalid fixture size')
    # Vectorized input validation is untimed for all Python modes. The timed
    # python-1/python-4 implementation below uses ordinary CPython loops only.
    import numpy as np
    command_grid = np.frombuffer(COMMANDS, dtype='<u8').reshape(meta['rounds'], WORDS)
    for cmd in command_grid:
        ids = cmd[:N]
        if len(np.unique(ids)) != N or np.max(ids) >= N:
            raise ValueError('Invalid query IDs')
        patches = cmd[N:].reshape(-1, N, 4)
        if len(patches) and (np.any(patches[:,:,0] != ids[None,:]) or
                np.any(patches[:,:,1] >= CAP) or np.any(patches[:,:,2] > 99999999) or
                np.any(patches[:,:,3] < 1) or np.any(patches[:,:,3] > 1000)):
            raise ValueError('Invalid patch')
    start = time.perf_counter_ns()
    # Exported caches are independently checked against the full-rescan oracle
    # on every round. Initial retained placement is outside batch timing.
    row_map = mmap.mmap(-1, len(base)); row_map[:] = base
    ROWS = memoryview(row_map).cast('Q')
    caches = []
    for file in ['sums.bin', 'totals.bin']:
        data = (root / file).read_bytes()
        if len(data) != N * 8:
            raise ValueError('Invalid cache size')
        buf = mmap.mmap(-1, len(data)); buf[:] = data
        caches.append(memoryview(buf).cast('Q'))
    SUMS, TOTALS = caches
    for cart in range(N):
        off = cart * W
        if meta['rounds'] == 1:
            SUMS[cart] = sum(ROWS[off+1+j] * ROWS[off+1+CAP+j] for j in range(ROWS[off]))
        TOTALS[cart] = finish(SUMS[cart], ROWS[off+W-2], ROWS[off+W-1])
    out_map = mmap.mmap(-1, N * 8); SHARED_OUT = memoryview(out_map).cast('Q')
    pool = mp.get_context('fork').Pool(4) if name == 'python-4' else None
    if name == 'python-numpy':
        import numpy as np
        rows = np.frombuffer(row_map, dtype='<u8').reshape(N, W)
        sums = np.frombuffer(SUMS, dtype='<u8'); totals = np.frombuffer(TOTALS, dtype='<u8')
        commands = np.frombuffer(COMMANDS, dtype='<u8').reshape(meta['rounds'], WORDS)
        def price_numpy(ids):
            s, kind, value = sums[ids], rows[ids, W-2], rows[ids, W-1]
            percent = (s * (10000 - np.minimum(value, 10000)) + 5000) // 10000
            fixed = s - np.minimum(s, value)
            return np.where(kind == 1, percent, np.where(kind == 2, fixed, s))
        # Exercise the native discount arithmetic at the upstream gates too.
        totals[:] = price_numpy(np.arange(N))
        def run_numpy(r):
            cmd = commands[r]; ids = cmd[:N]; patches = cmd[N:].reshape(-1, N, 4)
            if len(patches):
                slots = patches[:, :, 1]
                p, q = patches[:, :, 2], patches[:, :, 3]
                old = rows[ids[None, :], 1 + slots] * rows[ids[None, :], 1 + CAP + slots]
                sums[ids] = sums[ids] - old.sum(axis=0) + (p * q).sum(axis=0)
                rows[ids[None, :], 1 + slots] = p
                rows[ids[None, :], 1 + CAP + slots] = q
                totals[ids] = price_numpy(ids)
            return totals[ids]
    init_ms = (time.perf_counter_ns() - start) / 1e6
    try:
        for r in range(meta['rounds']):
            start = time.perf_counter_ns()
            if pool:
                pool.map(worker_job, [(r, t*N//4, (t+1)*N//4) for t in range(4)], chunksize=1)
                out = array.array('Q')
                out.frombytes(SHARED_OUT.cast("B"))
            elif name == 'python-numpy':
                out = run_numpy(r)
            else:
                out = array.array('Q', [0]) * N
                work(r, 0, N, out)
            us = (time.perf_counter_ns() - start) / 1000
            if name == 'python-numpy':
                target = np.frombuffer(expected, dtype='<u8', count=N, offset=r*N*8)
                if not np.array_equal(out, target):
                    raise ValueError(f'Wrong NumPy result round={r}')
                checksum = sum(map(int, out)) % (1 << 64)
            else:
                checksum = 0
                for i, value in enumerate(out):
                    if value != expected[r*N+i]:
                        raise ValueError(f'Wrong result round={r} query={i}')
                    checksum += value
                checksum %= 1 << 64
            print(f'{name},{rep},{r},{us:.6f},{init_ms:.6f},{N},{checksum}', flush=True)
    finally:
        if pool:
            pool.close(); pool.join()


if __name__ == '__main__':
    main()
