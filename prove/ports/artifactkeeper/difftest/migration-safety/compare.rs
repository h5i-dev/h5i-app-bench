#[allow(dead_code)] mod upstream { include!("UPSTREAM"); pub fn mask(x:&str)->String {mask_sql(x)} pub fn classes(h:&str)->Vec<(&'static str,String,usize)>{classify(h)} pub fn ident(h:&str,f:usize)->Option<String>{identifier_after(h,f)} pub fn find(h:&str,n:&str,f:usize)->Option<(usize,usize)>{find_phrase(h,n,f)} }
#[allow(dead_code)] mod port { include!("PORT"); }
fn next(s:&mut u64)->u64{*s=s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);*s}
fn kind(k:port::Kind)->&'static str {use port::Kind::*;match k {BlockingIndex=>"blocking_index",ValidatingConstraint=>"validating_constraint",ColumnRewrite=>"column_rewrite",SetNotNull=>"set_not_null",VolatileDefault=>"volatile_default",UnboundedBackfill=>"unbounded_backfill",TableRewrite=>"table_rewrite_maintenance"}}
fn classes(s:&str){let p:Vec<_>=port::classify(s.as_bytes()).into_iter().map(|f|(kind(f.kind),String::from_utf8(f.table).unwrap(),f.at)).collect();assert_eq!(p,upstream::classes(s),"classify {s:?}");}
fn main(){
 let mut state=0xa7517788u64;let alphabet=b"aAZ_09-/ *'\n\t\r\x0b\x0c;.$()";let mut checks=0;
 for _ in 0..100000 {
  let len=(next(&mut state)%160)as usize;let mut b=Vec::new();for _ in 0..len{b.push(alphabet[(next(&mut state)as usize)%alphabet.len()]);}
  let s=std::str::from_utf8(&b).unwrap();let actual=port::mask_sql(&b);assert_eq!(actual,upstream::mask(s).into_bytes(),"mask {s:?}");assert_eq!(actual.len(),b.len());for (i,c) in b.iter().enumerate(){assert_eq!(*c==b'\n',actual[i]==b'\n');}checks+=1;
  let from=(next(&mut state)%180)as usize;assert_eq!(port::identifier_after(&b,from),upstream::ident(s,from).map(String::into_bytes),"ident {s:?} {from}");checks+=1;
  for needle in ["", " ","A","A Z","a\tZ", "-", "_", "CREATE INDEX", "09"] {
   let from=(next(&mut state)%180)as usize;assert_eq!(port::find_phrase(&b,needle.as_bytes(),from),upstream::find(s,needle,from),"find {s:?} {needle:?} {from}");checks+=1;
  }
 }
 let phrases=["CREATE INDEX i ON t(x)","CREATE UNIQUE INDEX CONCURRENTLY i ON s.t(x)","ALTER TABLE a ADD CONSTRAINT x CHECK(y) NOT VALID","ALTER TABLE b ALTER COLUMN x TYPE z","ALTER TABLE a SET NOT NULL","ALTER TABLE a ADD COLUMN x DEFAULT gen_random_uuid()","UPDATE a SET x=1","DELETE FROM b LIMIT 2","REINDEX INDEX CONCURRENTLY x","VACUUM FULL x","ALTER TABLE a ALTER TABLE b ADD CONSTRAINT x CHECK(y)","DO $$ UPDATE a SET x=1; LOOP END $$"];
 for _ in 0..30000 {let mut s=String::new();let len=next(&mut state)%6;for _ in 0..len {s.push_str(phrases[(next(&mut state)as usize)%phrases.len()]);s.push_str("; ");}classes(&s);checks+=1;}
 for s in ["/* nested /* inside */ end */ SELECT 'a''b'; -- tail\n", "DO $$ BEGIN ALTER TABLE x SET NOT NULL; END $$", "/* é € 😀 */ SELECT 'é € 😀'", "'unterminated\n", "/* unclosed\n"]{assert_eq!(port::mask_sql(s.as_bytes()),upstream::mask(s).into_bytes());checks+=1;}
 for s in ["IF NOT EXISTS ONLY public.table", "IF EXISTS x.y.z", "\"Schema\".\"Table\"", "x.", "a..b", "ONLY IF EXISTS t"]{for from in 0..s.len()+2{assert_eq!(port::identifier_after(s.as_bytes(),from),upstream::ident(s,from).map(String::into_bytes));checks+=1;}}
 let corpus=std::fs::read(std::env::args().nth(1).unwrap()).unwrap();for doc in corpus.split(|c|*c==0){let s=std::str::from_utf8(doc).unwrap();let masked=upstream::mask(s);assert_eq!(port::mask_sql(doc),masked.as_bytes());classes(&masked);checks+=2;}
 println!("PASS {checks} SQL mask/search comparisons; exact byte positions, nested comments, quote escapes, Unicode comments/literals");
}
