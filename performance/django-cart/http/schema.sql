CREATE TABLE cart_bench_cart (
 id bigint PRIMARY KEY, discount_kind integer NOT NULL CHECK(discount_kind BETWEEN 0 AND 2),
 discount_value bigint NOT NULL CHECK(discount_value BETWEEN 0 AND 99999999)
);
CREATE TABLE cart_bench_item (
 cart_id bigint NOT NULL REFERENCES cart_bench_cart(id),
 slot integer NOT NULL CHECK(slot BETWEEN 0 AND 31), price bigint NOT NULL CHECK(price BETWEEN 0 AND 99999999),
 quantity integer NOT NULL CHECK(quantity BETWEEN 1 AND 1000), PRIMARY KEY(cart_id,slot)
);
