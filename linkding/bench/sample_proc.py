#!/usr/bin/env python3
"""Sample a process session until SIGTERM. Print one JSON object on exit.

Fields: rss_peak_kb (sum of VmRSS), cpu_peak_pct and cpu_avg_pct
(100 = one core, summed across the session).
"""
import json
import os
import signal
import sys
import time

SID = int(sys.argv[1])
CLK = os.sysconf("SC_CLK_TCK")
STOP = False


def handle(_signum, _frame):
    global STOP
    STOP = True


signal.signal(signal.SIGTERM, handle)
signal.signal(signal.SIGINT, handle)


def parse_stat(text):
    end = text.rfind(")")
    fields = text[end + 2 :].split()
    # fields[0] is state (orig field 3). utime=14, stime=15.
    utime = int(fields[11])
    stime = int(fields[12])
    sid = int(fields[3])
    return sid, utime + stime


def snapshot():
    rss = 0
    cpu = 0
    pids = 0
    for name in os.listdir("/proc"):
        if not name.isdigit():
            continue
        pid = int(name)
        try:
            with open(f"/proc/{pid}/stat") as fh:
                text = fh.read()
            sid, ticks = parse_stat(text)
            if sid != SID and pid != SID:
                continue
            with open(f"/proc/{pid}/status") as fh:
                for line in fh:
                    if line.startswith("VmRSS:"):
                        rss += int(line.split()[1])
                        break
            cpu += ticks
            pids += 1
        except (OSError, IndexError, ValueError):
            continue
    return rss, cpu, pids


def main():
    peak_rss = 0
    peak_cpu = 0.0
    cpu_sum = 0.0
    samples = 0
    _, prev_cpu, _ = snapshot()
    prev_t = time.monotonic()
    while not STOP:
        time.sleep(0.25)
        rss, cpu, _pids = snapshot()
        now = time.monotonic()
        if rss > peak_rss:
            peak_rss = rss
        dt = now - prev_t
        dc = cpu - prev_cpu
        if dt > 0 and dc >= 0:
            pct = (dc / CLK) / dt * 100.0
            cpu_sum += pct
            samples += 1
            if pct > peak_cpu:
                peak_cpu = pct
        prev_cpu = cpu
        prev_t = now
    avg = (cpu_sum / samples) if samples else 0.0
    json.dump(
        {
            "rss_peak_kb": peak_rss,
            "cpu_peak_pct": round(peak_cpu, 2),
            "cpu_avg_pct": round(avg, 2),
            "samples": samples,
        },
        sys.stdout,
    )
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
