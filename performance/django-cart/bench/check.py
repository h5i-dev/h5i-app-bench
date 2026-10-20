"""Check integer CPU output against pinned, unmodified django-cart methods.

The large corpus supplies an exact, already-loaded Decimal subtotal to the
facade cache. Small database cases also exercise the real ORM summary().
No timing from this correctness runner is a performance result.
"""
import argparse
from decimal import Decimal
from pathlib import Path
import random
import struct
import subprocess
import sys
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
WIDTH, MAX_LINES, MAX_PRICE, ERROR = 67, 32, 99_999_999, 2**64-1


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--source", type=Path, default=Path("/var/tmp/h5i-bench-django-cart-src"))
    parser.add_argument("--checker", nargs="+", required=True)
    parser.add_argument("--fixtures", type=Path, default=Path("/var/tmp/django-cart-fixtures.bin"))
    args = parser.parse_args()
    pin = (HERE.parent / "upstream/COMMIT").read_text().strip()
    actual = subprocess.check_output(["git", "-C", str(args.source), "rev-parse", "HEAD"], text=True).strip()
    if actual != pin:
        raise ValueError(f"upstream commit mismatch: {actual} != {pin}")
    subprocess.run(["git", "-C", str(args.source), "diff", "--exit-code", "HEAD", "--", "cart"], check=True)
    sys.path.insert(0, str(args.source.resolve()))
    from django.conf import settings
    settings.configure(
        SECRET_KEY="benchmark-only",
        INSTALLED_APPS=["django.contrib.auth", "django.contrib.contenttypes", "cart"],
        DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}},
        USE_TZ=True,
    )
    import django
    django.setup()
    from cart.cart import Cart
    from cart.models import Cart as CartModel, Discount, Item
    from django.contrib.contenttypes.models import ContentType
    from django.core.management import call_command
    from django.db import connection
    from django.test.utils import CaptureQueriesContext

    def make_facade(kind, value):
        facade = Cart.__new__(Cart)
        discount = None if kind == 0 else Discount(
            discount_type="percent" if kind == 1 else "fixed", value=Decimal(value)/100)
        facade.cart = SimpleNamespace(discount=discount)
        facade._cache = {}
        return facade

    rng = random.Random(20261019)
    cases = [([], [], 0, 0)]
    for price in [0, 1, 3, 99, 100, MAX_PRICE]:
        for kind, value in [(0,0), (1,1), (1,5000), (1,9999), (1,10000), (1,15000), (2,0), (2,MAX_PRICE)]:
            cases.append(([price], [1], kind, value))
    cases.append(([MAX_PRICE]*32, [1000]*32, 0, 0))
    for _ in range(4096):
        n = rng.randrange(33)
        cases.append(([rng.randrange(MAX_PRICE+1) for _ in range(n)],
                      [rng.randrange(1,1001) for _ in range(n)],
                      rng.randrange(3), rng.choice([0,1,3333,5000,9999,10000,15000,MAX_PRICE])))

    rows, expected = [], []
    for prices, quantities, kind, value in cases:
        row = [len(prices)] + prices + [0]*(32-len(prices)) + quantities + [0]*(32-len(prices)) + [kind,value]
        facade = make_facade(kind, value)
        subtotal = sum((Decimal(p)/100*q for p,q in zip(prices,quantities)), Decimal(0))
        facade._cache["summary"] = subtotal
        # Actual upstream discount_amount(), tax(), shipping(), total(), including
        # Decimal HALF_UP rounding. No locally restated total formula is the oracle.
        expected.append(int(facade.total()*100))
        rows.append(row)

    # Real database smoke checks: the exact subtotal supplied above agrees with
    # Cart.summary() and total() on small, exactly representable SQLite fixtures.
    call_command("migrate", verbosity=0)
    ct = ContentType.objects.get_for_model(CartModel)
    for case_id, (prices, quantities, kind, value) in enumerate(cases[:49]):
        facade = make_facade(kind, value)
        model = CartModel.objects.create()
        Item.objects.bulk_create([Item(cart=model, content_type=ct, object_id=i+1,
            unit_price=Decimal(p)/100, quantity=q) for i,(p,q) in enumerate(zip(prices,quantities))])
        discount = facade.cart.discount
        model.discount = discount
        facade.cart = model
        subtotal = sum((Decimal(p)/100*q for p,q in zip(prices,quantities)),Decimal(0))
        assert facade.summary() == subtotal
        facade._cache = {}
        with CaptureQueriesContext(connection) as queries:
            assert int(facade.total()*100) == expected[case_id]
        assert len(queries) == 1, "total must aggregate once, not once per calculator"

    # Unsupported snapshots must return an error, never wrap money or price an
    # invalid cart. These are benchmark bounds, not upstream validation claims.
    for offset, value in [(0,33), (1,MAX_PRICE+1), (33,0), (33,1001), (65,3), (66,MAX_PRICE+1)]:
        row = [0]*WIDTH
        row[0],row[1],row[33] = 1,100,1
        row[offset] = value
        rows.append(row)
        expected.append(ERROR)
    payload = b"".join(struct.pack("<67Q",*r) for r in rows)
    result = subprocess.run(args.checker, input=payload, capture_output=True, check=True).stdout
    assert len(result) == len(rows)*8
    got = list(struct.unpack(f"<{len(rows)}Q",result))
    for i,(a,b) in enumerate(zip(got,expected)):
        assert a == b, f"case {i}: CPU={a}, upstream={b}, row={rows[i]}"
    args.fixtures.write_bytes(payload)
    print(f"{len(cases)} upstream Decimal cases, 49 ORM cases, 6 rejection cases passed; {args.fixtures}")


if __name__ == "__main__":
    main()
