"""Produce wide-cart expectations with the pinned, unmodified Django library."""
import argparse
from decimal import Decimal
import json
from pathlib import Path
import random
import subprocess
import sys
from types import SimpleNamespace

APP=Path(__file__).resolve().parents[2]

def make_cases():
    source=Path('/var/tmp/h5i-bench-django-cart-src')
    assert subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()==(APP/'upstream/COMMIT').read_text().strip()
    subprocess.run(['git','-C',str(source),'diff','--exit-code','HEAD','--','cart'],check=True)
    sys.path.insert(0,str(source))
    from django.conf import settings
    settings.configure(SECRET_KEY='benchmark-only',INSTALLED_APPS=['django.contrib.auth','django.contrib.contenttypes','cart'],DATABASES={'default':{'ENGINE':'django.db.backends.sqlite3','NAME':':memory:'}},USE_TZ=True)
    import django
    django.setup()
    from cart.cart import Cart
    from cart.models import Cart as CartModel,Discount,Item
    from django.contrib.contenttypes.models import ContentType
    from django.core.management import call_command
    call_command('migrate',verbosity=0)
    ct=ContentType.objects.get_for_model(CartModel)
    rng=random.Random(20261019)
    output={}
    for cap in [32,128,512,2048]:
        cases=[]
        lengths=sorted({0,1,cap,*[n for n in [31,32,33,127,128,129,511,512,513,2047] if n<=cap]})
        for n in lengths:
            for kind,value in [(0,0),(1,1),(1,3333),(1,5000),(1,9999),(1,10000),(1,15000),(2,99999999)]:
                cases.append(([99999999]*n,[1000]*n,kind,value))
        cases.extend([([1],[1],1,5000),([3],[1],1,5000)])
        for _ in range(128):
            n=rng.randrange(cap+1)
            cases.append(([rng.randrange(100000000) for _ in range(n)],[rng.randrange(1,1001) for _ in range(n)],rng.randrange(3),rng.choice([0,1,3333,5000,9999,10000,15000,99999999])))
        rows=[]
        for prices,qty,kind,value in cases:
            discount=None if kind==0 else Discount(discount_type='percent' if kind==1 else 'fixed',value=Decimal(value)/100)
            facade=Cart.__new__(Cart);facade.cart=SimpleNamespace(discount=discount)
            facade._cache={'summary':sum((Decimal(p)/100*q for p,q in zip(prices,qty)),Decimal(0))}
            rows.append(dict(prices=prices,quantities=qty,kind=kind,value=value,total_cents=int(facade.total()*100)))
        # Exercise actual ORM aggregation at every new full-cart size, exactly
        # representable SQLite amounts so floating-point SQL is not the oracle.
        for kind,value in [(0,0),(1,3333),(1,15000),(2,123)]:
            model=CartModel.objects.create()
            Item.objects.bulk_create([Item(cart=model,content_type=ct,object_id=i+1,unit_price=Decimal('1.00'),quantity=1) for i in range(cap)])
            model.discount=None if kind==0 else Discount(discount_type='percent' if kind==1 else 'fixed',value=Decimal(value)/100)
            facade=Cart.__new__(Cart);facade.cart=model;facade._cache={}
            assert facade.summary()==Decimal(cap)
            v=int(facade.total()*100)
            rows.append(dict(prices=[100]*cap,quantities=[1]*cap,kind=kind,value=value,total_cents=v))
        output[str(cap)]=dict(decimal_cases=len(rows),orm_cases=4,cases=rows)
    return output

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--out',default='/var/tmp/cart-lines-oracle.json');args=p.parse_args()
    result=make_cases();Path(args.out).write_text(json.dumps(result))
    print({k:{n:v[n] for n in ('decimal_cases','orm_cases')} for k,v in result.items()})
