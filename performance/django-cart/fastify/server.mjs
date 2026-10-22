import cluster from 'node:cluster';
import Fastify from 'fastify';
import postgres from 'postgres';
import {finish} from '../javascript/main.mjs';

// Match the other applications: four workers, eight DB connections each.
if (cluster.isPrimary) {
  for (let i = 0; i < Number(process.env.WEB_CONCURRENCY || 4); i++) cluster.fork();
  cluster.on('exit', () => process.exit(1));
} else {
  const app = Fastify();
  const sql = postgres(process.env.DATABASE_URL, {max: 8, prepare: true});
  app.get('/health', async () => ({ok: true}));
  app.get('/metrics', async () => ({}));
  app.get('/carts/:id/total', async (req, reply) => {
    const id = Number(req.params.id);
    if (!/^[0-9]+$/.test(req.params.id) || !Number.isSafeInteger(id) || id < 1) return reply.code(400).send({});
    const rows = await sql`SELECT c.discount_kind,c.discount_value,COALESCE(SUM(i.price*i.quantity),0)::bigint AS subtotal FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=${id} GROUP BY c.id`;
    if (!rows.length) return reply.code(404).send({});
    const r = rows[0];
    return {id, total_cents: finish(Number(r.subtotal), r.discount_kind, Number(r.discount_value))};
  });
  await app.listen({host: '127.0.0.1', port: Number(process.env.PORT || 8780)});
}
