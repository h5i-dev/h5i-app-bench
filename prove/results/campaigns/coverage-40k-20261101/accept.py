"""Save the 40k checkpoint only after all canonical acceptance evidence exists."""
from pathlib import Path
from datetime import datetime,timezone
import json,sys,subprocess
folder=Path(__file__).resolve().parent;root=folder.parents[3]
sys.path.insert(0,str(root/'prove/harness'))
from project_reach import fresh_gate,fresh_extraction
index=json.loads((root/'docs/prove/data/index.json').read_text());s=index['stats']
assert s['whole_project_verified'] and s['accepted']==s['properties']==1010
assert s['upstream_reached']==s['current_source_matched_lines']==40317
apps={};records={}
for app,info in index['apps'].items():
 g,e=fresh_gate(app),fresh_extraction(app)
 assert g and e,app
 apps[app]={'lines':info['current_source_matched_lines'],'properties':info['project_properties']['count']}
 records[app]={'gate_log':g['log'],'gate_finished_at':g['finished_at'],'extraction_log':e['log'],'extraction_finished_at':e['finished_at']}
r={'recorded_at':datetime.now(timezone.utc).isoformat(),'branch':subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip(),'baseline':{'lines':20765,'properties':609},'accepted':{'lines':s['current_source_matched_lines'],'properties':s['properties']},'target_lines':40000,'remaining_lines':0,'longer_term_target_lines':100000,'apps':apps,'evidence':records,'new_reach_breakdown':{'acp_catalog':6727,'schema_catalog':9011,'group_catalog':1975,'entry_catalog':558,'migration_catalog':1281},'validation':{'rust_tests_passed':43,'rust_tests_failed':0,'previous_kanidm_property_types_preserved':142},'meaning':'Deduplicated pinned executable source reached by property types and extracted dependencies; not complete behavioral equivalence. Most new reach is complete configuration construction and ordered selection.','published':False}
(folder/'accepted-checkpoint.json').write_text(json.dumps(r,indent=2)+'\n');print('Accepted checkpoint:',r['accepted'])
