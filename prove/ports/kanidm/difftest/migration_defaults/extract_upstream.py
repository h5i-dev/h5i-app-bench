from pathlib import Path
import subprocess,json,hashlib,re
root=Path(__file__).resolve().parents[5]
folder=Path(__file__).resolve().parent
revision="f608c4fe14dfd8d5df8edeed470bf1fb92060abd"
records={}
for name in ["dl11","dl12","dl13","dl14","dl15","dl_1_12"]:
 file=f"server/lib/src/migration_data/{name}/system_config.rs"
 raw=subprocess.check_output(["git","-C",str(root/"prove/results/upstream/kanidm.git"),"show",revision+":"+file],text=True)
 body=raw[raw.index("pub fn e_system_config_v1()"):]
 # The function is the final item in these pinned files.
 assert body.rstrip().endswith("}")
 (folder/(name+".rs")).write_text("use super::*;\n"+body)
 records[file]={"file_sha256":hashlib.sha256(raw.encode()).hexdigest(),"reference_sha256":hashlib.sha256(("use super::*;\n"+body).encode()).hexdigest()}
(folder/"identity.json").write_text(json.dumps({"revision":revision,"files":records,"boundary":"Original initializer bodies verbatim, minimal typed attribute-to-set carrier; original Value::new_iutf8 Unicode lowercase semantics. No schema validation, transactional migration, or storage claim."},indent=2)+"\n")
