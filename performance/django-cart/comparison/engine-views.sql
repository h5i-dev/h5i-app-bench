-- The complete state of cart N is tenant N. Both adapters read the same
-- committed public tables, including correctness-test updates. Views contain
-- no cached totals. Engine.install_schema must run before this setup.
DROP TABLE cart_engine.cart, cart_engine.item;
CREATE VIEW cart_engine.cart AS
 SELECT id AS tenant_id, discount_kind::bigint AS kind, discount_value AS value
 FROM public.cart_bench_cart;
CREATE VIEW cart_engine.item AS
 SELECT cart_id AS tenant_id, slot::bigint, price, quantity::bigint
 FROM public.cart_bench_item;
