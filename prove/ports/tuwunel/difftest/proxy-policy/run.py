"""Compare pure outbound domain policy with verbatim pinned upstream methods."""
from pathlib import Path
import sys,subprocess,tempfile,json,hashlib
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'ports/rustfs/difftest'))
from count_loc import item
REV='7801b8ec6f7773d90b1bbfeeb352012d6e004e96'
FILE='src/core/config/proxy.rs'
s=subprocess.check_output(['git','-C',ROOT/'results/upstream/tuwunel.git','show',REV+':'+FILE],text=True)
methods=[item(s,r'pub fn for_url\('),item(s,r'fn matches\('),item(s,r'fn more_specific_than\('),item(s,r'fn from_str\('),item(s,r'fn parse\('),item(s,r'fn proxy_for\(')]
up='''#[derive(Clone,Debug)] enum WildCardedDomain {WildCard,WildCarded(String),Exact(String)}
#[derive(Clone)] struct Url {host:Option<String>,scheme:String,id:usize}
impl Url {fn domain(&self)->Option<&str>{self.host.as_deref()} fn scheme(&self)->&str{&self.scheme}}
struct PartialProxyConfig {url:Url,include:Vec<WildCardedDomain>,exclude:Vec<WildCardedDomain>}
impl PartialProxyConfig {'''+methods[0]+'''}
impl WildCardedDomain {'''+methods[1]+methods[2]+'''}
impl std::str::FromStr for WildCardedDomain {type Err=std::convert::Infallible;'''+methods[3]+'''}
#[derive(Clone,Copy)] enum ProxyScheme {Http,Https,Socks4,Socks4a,Socks5,Socks5h}
impl ProxyScheme {'''+methods[4]+'''}
enum ProxyConfig {None,Global{url:Url},ByDomain(Vec<PartialProxyConfig>)}
impl ProxyConfig {'''+methods[5]+'''}'''
print(json.dumps({'revision':REV,'path':FILE,'source_sha256':hashlib.sha256(s.encode()).hexdigest(),'selected_sha256':hashlib.sha256('\n'.join(methods).encode()).hexdigest()}),flush=True)
with tempfile.TemporaryDirectory() as td:
 t=Path(td);(t/'upstream.rs').write_text(up)
 h=Path(__file__).with_name('compare.rs').read_text().replace('"UPSTREAM"',json.dumps(str(t/'upstream.rs'))).replace('"PORT"',json.dumps(str(ROOT/'ports/tuwunel/kernel/src/proxy_policy.rs')))
 (t/'main.rs').write_text(h)
 subprocess.run(['rustc','--edition=2024','-O',t/'main.rs','-o',t/'check'],check=True)
 subprocess.run([t/'check'],check=True)
