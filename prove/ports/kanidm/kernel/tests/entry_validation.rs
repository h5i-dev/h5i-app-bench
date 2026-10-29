// Exercise the canonical kernel against the verbatim pinned upstream method.
use kanidm_kernel::entry_validation as candidate;
#[path="../../difftest/entry_validation/reference.rs"] mod reference;
use candidate::*;
fn next(seed:&mut u64)->u64{*seed=seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);*seed}
fn ids(seed:&mut u64,max:u16)->Vec<u16>{let mut v=Vec::new();for k in 0..max{if next(seed)>>60<4{v.push(k)}}v}
#[test]
fn pinned_entry_validation(){
 let mut seed=0x4b616e69646d_cafe;let mut comparisons=0;
 for _ in 0..100000 {
  let names=ids(&mut seed,9);let class_present=next(&mut seed)%10!=0;
  let mut e=Entry {class_present,classes:if next(&mut seed)%10==0{None}else{Some(names)},attrs:Vec::new()};
  for key in 0..9 {if key==0 && class_present || key>0 && next(&mut seed)>>60<6 {
   e.attrs.push(Attribute {key,count:(next(&mut seed)%4) as usize,syntax:(next(&mut seed)%3) as u16,valid:next(&mut seed)%8!=0});
  }}
  let mut classes=Vec::new();let mut attrs=Vec::new();
  for key in 0..9 {if next(&mut seed)%10!=0 {classes.push(ClassSchema {key,systemmust:ids(&mut seed,9),must:ids(&mut seed,9),systemmay:ids(&mut seed,9),may:ids(&mut seed,9),systemsupplements:ids(&mut seed,9),supplements:ids(&mut seed,9),systemexcludes:ids(&mut seed,9),excludes:ids(&mut seed,9)})}
   if next(&mut seed)%10!=0 {attrs.push(AttributeSchema {key,name:key,phantom:next(&mut seed)%10==0,multi:next(&mut seed)%2==0,syntax:(next(&mut seed)%3) as u16})}
  }
  let actual=candidate::validate(&e,&classes,&attrs);let expected=reference::validate(&e,&classes,&attrs);
  assert_eq!(actual,expected,"entry={e:?} classes={classes:?} attrs={attrs:?}");comparisons+=1;
 }
 println!("{comparisons} complete entry-validation results including exact ordered error payloads");
}

fn class(key:u16)->ClassSchema{ClassSchema {key,systemmust:vec![],must:vec![],systemmay:vec![],may:vec![],systemsupplements:vec![],supplements:vec![],systemexcludes:vec![],excludes:vec![]}}
fn base()->(Entry,Vec<ClassSchema>,Vec<AttributeSchema>){
 let e=Entry {class_present:true,classes:Some(vec![3]),attrs:vec![Attribute {key:0,count:1,syntax:0,valid:true},Attribute {key:4,count:1,syntax:0,valid:true}]};
 let mut c=class(3);c.must=vec![0];c.may=vec![4];
 let attrs=vec![AttributeSchema {key:0,name:0,phantom:false,multi:true,syntax:0},AttributeSchema {key:4,name:4,phantom:false,multi:true,syntax:0}];
 (e,vec![c],attrs)
}
fn compare(e:&Entry,c:&[ClassSchema],a:&[AttributeSchema],want:Result<(),Error>){
 let actual=candidate::validate(e,c,a);assert_eq!(actual,reference::validate(e,c,a),"entry={e:?} classes={c:?} attrs={a:?}");assert_eq!(actual,want);
}
#[test]
fn pinned_entry_deep_decisions(){
 let(e,c,a)=base();compare(&e,&c,&a,Ok(()));
 let mut x=e.clone();x.class_present=false;compare(&x,&c,&a,Err(Error::NoClassFound));
 x=e.clone();x.classes=None;compare(&x,&c,&a,Err(Error::NoClassFound));
 x=e.clone();x.classes=Some(vec![0,7]);compare(&x,&[],&[],Ok(()));
 x=e.clone();x.classes=Some(vec![3,6,7]);compare(&x,&c,&a,Err(Error::InvalidClass(vec![6,7])));
 let mut cc=c.clone();cc[0].systemsupplements=vec![6];cc[0].supplements=vec![7];compare(&e,&cc,&a,Err(Error::SupplementsNotSatisfied(vec![6,7])));
 cc[0].supplements=vec![3,7];compare(&e,&cc,&a,Ok(())); // one match satisfies union
 cc=c.clone();cc[0].systemexcludes=vec![3];cc[0].excludes=vec![3,6];compare(&e,&cc,&a,Err(Error::ExcludesNotSatisfied(vec![3,3])));
 cc=c.clone();cc[0].must=vec![6];compare(&e,&cc,&a,Err(Error::Corrupted));
 let mut aa=a.clone();aa[1].name=5;cc=c.clone();cc[0].must=vec![0,4];compare(&e,&cc,&aa,Err(Error::MissingMustAttribute(vec![5])));
 // Recycled relaxes missing values, but cannot conceal a broken schema.
 x=e.clone();x.classes=Some(vec![2,3]);cc.insert(0,class(2));compare(&x,&cc,&aa,Ok(()));
 cc[1].must=vec![7];compare(&x,&cc,&aa,Err(Error::Corrupted));
 // Extensible accepts schema attributes outside may, but denies phantom attributes.
 x=e.clone();x.classes=Some(vec![1,3]);cc=c.clone();cc[0].may.clear();cc.insert(0,class(1));compare(&x,&cc,&a,Ok(()));
 aa=a.clone();aa[1].phantom=true;compare(&x,&cc,&aa,Err(Error::PhantomAttribute(4)));
 compare(&x,&cc,&a[..1],Err(Error::InvalidAttribute(4)));
 x=e.clone();cc=c.clone();cc[0].may.clear();compare(&x,&cc,&a,Err(Error::AttributeNotValidForClass(4)));
 cc=c.clone();cc[0].may.push(7);compare(&e,&cc,&a,Err(Error::Corrupted));
 for extensible in [false,true] {for count in [0,1,2,usize::MAX] {for multi in [false,true] {for valid in [false,true] {for actual in [0,1] {
  x=e.clone();cc=c.clone();aa=a.clone();if extensible{x.classes=Some(vec![1,3]);cc.insert(0,class(1));}
  x.attrs[1].count=count;x.attrs[1].valid=valid;x.attrs[1].syntax=actual;aa[1].multi=multi;
  let want=if (!multi && count>1)||!valid||actual!=0{Err(Error::InvalidAttributeSyntax(4))}else{Ok(())};compare(&x,&cc,&aa,want);
 }}}}}
 println!("Targeted deep decisions: every error category, precedence, recycled/extensible and full AVA boundaries");
}
