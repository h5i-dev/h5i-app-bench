"""Read-only pricing adapter; one PostgreSQL aggregate per request."""
from contextlib import asynccontextmanager
import os

import asyncpg
from fastapi import FastAPI, HTTPException

SQL = """SELECT c.discount_kind,c.discount_value,
 COALESCE(SUM(i.price*i.quantity),0)::bigint AS subtotal
 FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id
 WHERE c.id=$1 GROUP BY c.id"""


@asynccontextmanager
async def lifespan(app):
    app.state.pool = await asyncpg.create_pool(os.environ['DATABASE_URL'], min_size=1, max_size=8)
    yield
    await app.state.pool.close()


app = FastAPI(lifespan=lifespan)


@app.get('/health')
async def health():
    return {'ok': True}


@app.get('/metrics')
async def metrics():
    return {}


@app.get('/carts/{cart_id}/total')
async def total(cart_id: str):
    if not cart_id.isascii() or not cart_id.isdecimal() or not 0 < int(cart_id) < 2**63:
        raise HTTPException(400)
    cart_id = int(cart_id)
    row = await app.state.pool.fetchrow(SQL, cart_id)
    if row is None:
        raise HTTPException(404)
    subtotal, kind, value = row['subtotal'], row['discount_kind'], row['discount_value']
    discount = subtotal * min(value, 10000) if kind == 1 else min(subtotal * 10000, value * 10000) if kind == 2 else 0
    return {'id': cart_id, 'total_cents': (subtotal * 10000 - discount + 5000) // 10000}
