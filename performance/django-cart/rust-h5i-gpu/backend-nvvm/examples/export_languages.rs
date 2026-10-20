use django_cart_pricing::{pricing::finish,wide::{at,width}};
use std::{fs::{self,File},io::{Write,BufWriter},path::Path};
const WARMUP:usize=8;const ITERATIONS:usize=50;
fn initial(cap:usize,population:usize)->Vec<u64> {
    let w=width(cap); let mut rows=vec![0;population*w];
    for i in 0..population {
        let off=i*w; rows[off]=cap as u64;
        for j in 0..cap {
            rows[off+1+j]=((i*7919+j*104729)%100000) as u64;
            rows[off+1+cap+j]=((i+j)%9+1) as u64;
        }
        rows[off+w-2]=(i%3) as u64;
        rows[off+w-1]=if i%3==1 {[0,1,1250,3333,9999,10000,15000][i%7]} else {(i%100000) as u64};
    }
    rows
}
fn subtotals(rows:&[u64],cap:usize)->Vec<u64> {
    rows.chunks_exact(width(cap)).map(|r|(0..r[0] as usize).map(|j|r[1+j]*r[1+cap+j]).sum()).collect()
}
fn totals(rows:&[u64],sums:&[u64],cap:usize)->Vec<u64> {
    rows.chunks_exact(width(cap)).zip(sums).map(|(r,&s)|finish(s,r[width(cap)-2],r[width(cap)-1])).collect()
}
fn apply(rows:&mut [u64],cmd:&[u64],queries:usize,cap:usize) {
    for p in cmd[queries..].chunks_exact(4) {
        let off=p[0] as usize*width(cap);let slot=p[1] as usize;
        rows[off+1+slot]=p[2];rows[off+1+cap+slot]=p[3];
    }
}
struct Step {commands:Vec<u64>,expected:Vec<u64>}
fn trace(base:&[u64],cap:usize,n:usize,updates:usize,population:usize)->Vec<Step> {
    assert!(cap.is_power_of_two() && updates.div_ceil(n)<=cap);
    let mut rows=base.to_vec();
    (0..WARMUP+ITERATIONS).map(|round| {
        let mut commands:Vec<u64>=(0..n).map(|j|(((round*n+j)*7919)%population) as u64).collect();
        let mut seen=vec![false;population];
        for &id in &commands {assert!(!seen[id as usize]);seen[id as usize]=true;}
        for k in 0..updates {
            let cart=commands[k%n];let slot=(round*17+k/n*13)%cap;
            // Periodic bound values exercise updates, rounding and stale caches.
            let price=if (round+k)%31==0 {99_999_999} else {((round*997+k*7919+7)%100000) as u64};
            let qty=if (round+k)%37==0 {1000} else {((round+k)%9+1) as u64};
            commands.extend([cart,slot as u64,price,qty]);
        }
        apply(&mut rows,&commands,n,cap);
        let expected=commands[..n].iter().map(|&i|at(&rows[i as usize*width(cap)..(i as usize+1)*width(cap)],cap)).collect();
        Step{commands,expected}
    }).collect()
}

fn write(path:&Path,data:&[u64]) {assert!(cfg!(target_endian="little"));let mut f=BufWriter::new(File::create(path).unwrap()); f.write_all(unsafe{std::slice::from_raw_parts(data.as_ptr() as *const u8,data.len()*8)}).unwrap();}
fn save(root:&Path,n:usize,cap:usize,f:usize,base:&[u64],steps:&[Step]) {
 fs::create_dir_all(root).unwrap();write(&root.join("base.bin"),base);let sums=subtotals(base,cap);let totals=totals(base,&sums,cap);write(&root.join("sums.bin"),&sums);write(&root.join("totals.bin"),&totals);
 let mut commands=BufWriter::new(File::create(root.join("commands.bin")).unwrap());let mut expected=BufWriter::new(File::create(root.join("expected.bin")).unwrap());
 for step in steps {for (file,values) in [(&mut commands,&step.commands),(&mut expected,&step.expected)] {file.write_all(unsafe{std::slice::from_raw_parts(values.as_ptr() as *const u8,values.len()*8)}).unwrap();}}
 fs::write(root.join("manifest.json"),serde_json::to_string_pretty(&serde_json::json!({"carts":n,"lines":cap,"factor":f,"rounds":steps.len(),"warmup":if steps.len()>1 {8}else{0},"command_words":n+n*f*4})).unwrap()).unwrap();
}
fn main(){let args:Vec<String>=std::env::args().collect();let root=Path::new(&args[1]);fs::create_dir_all(root).unwrap();
 let oracle:serde_json::Value=serde_json::from_str(&fs::read_to_string(&args[2]).unwrap()).unwrap();
 for cap in [32,128,512,2048] {let cases=oracle[cap.to_string()]["cases"].as_array().unwrap();let n=cases.len();let mut base=vec![0;n*width(cap)];let mut expected=Vec::new();
 for (i,c) in cases.iter().enumerate(){let p=c["prices"].as_array().unwrap();let q=c["quantities"].as_array().unwrap();let off=i*width(cap);base[off]=p.len() as u64;for j in 0..p.len(){base[off+1+j]=p[j].as_u64().unwrap();base[off+1+cap+j]=q[j].as_u64().unwrap();}base[off+width(cap)-2]=c["kind"].as_u64().unwrap();base[off+width(cap)-1]=c["value"].as_u64().unwrap();expected.push(c["total_cents"].as_u64().unwrap());}
 save(&root.join(format!("gate-{cap}")),n,cap,0,&base,&[Step{commands:(0..n as u64).collect(),expected}]);}
 let smoke=args.iter().any(|a|a=="--smoke");for (n,cap,f) in if smoke{vec![(64,32,0),(64,32,1),(64,32,16)]}else{vec![(4096,512,16),(65536,2048,1),(65536,2048,16),(65536,2048,64)]}{
 let dir=root.join(format!("{n}-{cap}-{f}"));if dir.join("manifest.json").exists(){continue;}eprintln!("export {n}x{cap} updates={f}");let base=initial(cap,n);let steps=trace(&base,cap,n,n*f,n);save(&dir,n,cap,f,&base,&steps);}}
