-- RAW: one database statement serves multiple independent HTTP requests.
SELECT c.id, c.discount_kind, c.discount_value, i.slot, i.price, i.quantity
FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id
WHERE c.id=ANY($1::bigint[]) ORDER BY c.id,i.slot
;
-- AGGREGATE: normal per-request database aggregate, matching Cart.summary().
SELECT c.id,c.discount_kind,c.discount_value,COALESCE(SUM(i.price*i.quantity),0)::bigint
FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id
WHERE c.id=$1 GROUP BY c.id
