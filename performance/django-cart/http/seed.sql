-- psql -v carts=65536 -v lines=32; price/discount generator matches fixture().
TRUNCATE cart_bench_item,cart_bench_cart;
INSERT INTO cart_bench_cart
SELECT i+1,(i%3)::integer,CASE WHEN i%3=1 THEN (ARRAY[0,1,1250,3333,9999,10000,15000])[i%7+1] ELSE i%100000 END
FROM generate_series(0,:carts-1) AS s(i);
INSERT INTO cart_bench_item
SELECT i+1,j,((i::bigint*7919+j*104729)%100000),((i+j)%9+1)
FROM generate_series(0,:carts-1) AS s(i) CROSS JOIN generate_series(0,:lines-1) AS t(j);
ANALYZE cart_bench_cart;
ANALYZE cart_bench_item;
