"""Reviewed integer-day editorial choices; does not round or install a time codec."""
import ast
import json
import re
import runpy
import sys
from pathlib import Path

BASE=Path(__file__).resolve().parent
sys.path.insert(0,str(BASE))
# These require handling, inspection, travel, an experiment, or actual waiting.
# Remaining reviewed half-day entries only discuss/read/display/hand over at the
# same site: 0 discrete days. Neither category grants a repeatable reward.
WORK = {
 'npc_002':{0,1}, 'npc_005':{1}, 'npc_009':{1,2}, 'npc_011':{0},
 'npc_012':{0}, 'npc_013':{0,1}, 'npc_028':{1}, 'npc_029':{0},
 'npc_030':{2}, 'npc_037':{0,1}, 'npc_043':{0}, 'npc_051':{2},
 'npc_052':{1}, 'npc_054':{1}, 'npc_065':{0}, 'npc_067':{0},
 'npc_070':{0}, 'npc_073':{0},
 'anomaly_001':{0}, 'anomaly_002':{0}, 'anomaly_004':{0,1},
 'anomaly_005':{0}, 'anomaly_007':{1}, 'anomaly_008':{0,1},
 'anomaly_009':{1}, 'anomaly_010':{0,1}, 'anomaly_011':{0},
 'anomaly_012':{0}, 'anomaly_013':{0,1,2}, 'anomaly_015':{1},
 'anomaly_017':{1}, 'anomaly_018':{0,1}, 'anomaly_019':{0},
 'anomaly_020':{0}, 'anomaly_021':{0,1,2,3}, 'anomaly_022':{0,1},
 'anomaly_024':{0}, 'anomaly_025':{0,1}, 'anomaly_027':{0},
 'anomaly_028':{0}, 'anomaly_029':{0}, 'anomaly_031':{0},
 'anomaly_033':{0,1}, 'anomaly_037':{1,2,3}, 'anomaly_040':{0}
}

def day_cost(text,days):
    if days:
        return text.replace('半天','1天')
    text=re.sub(r'(?:先)?花半天[，,；;]?','',text)
    text=text.replace('半天','本次現場互動')
    return '0天，不推進世界日期；'+text.lstrip('，,；;')

if __name__=='__main__':
    audit=[]
    for filename in ['write_npc_events.py','write_anomalies.py']:
        path=BASE/filename
        source=path.read_text(encoding='utf-8')
        namespace=runpy.run_path(str(path),run_name='__editorial_check__')
        replacements={}
        for row in namespace['ROWS']:
            for i,c in enumerate(row['choices']):
                if '半天' not in c['cost_zh']:
                    continue
                days=int(i in WORK.get(row['encounter_id'],set()))
                new=day_cost(c['cost_zh'],days)
                key=(c['label_zh'],c['cost_zh'])
                assert key not in replacements or replacements[key]==new,key
                replacements[key]=new
                audit.append({'encounter_id':row['encounter_id'],'choice_index':i,
                              'label_zh':c['label_zh'],'proposed_days':days,
                              'classification':'work_or_wait' if days else 'onsite_read_talk_or_handover'})
        raw=source.encode('utf-8')
        lines=raw.splitlines(keepends=True)
        offsets=[0]
        for line in lines: offsets.append(offsets[-1]+len(line))
        edits=[]
        for node in ast.walk(ast.parse(source)):
            if not isinstance(node,ast.Call) or not isinstance(node.func,ast.Name) or node.func.id!='C' or len(node.args)<3:
                continue
            label,cost=node.args[:2]
            if not isinstance(label,ast.Constant) or not isinstance(cost,ast.Constant): continue
            key=(label.value,cost.value)
            if key not in replacements: continue
            start=offsets[cost.lineno-1]+cost.col_offset
            end=offsets[cost.end_lineno-1]+cost.end_col_offset
            edits.append((start,end,json.dumps(replacements[key],ensure_ascii=False).encode('utf-8')))
        assert len(edits)==len(replacements),(filename,len(edits),len(replacements))
        for start,end,text in sorted(edits,reverse=True): raw=raw[:start]+text+raw[end:]
        revised=raw.decode('utf-8')
        # One negotiated observation-duration phrase is descriptive, not a new
        # fractional world-clock interval. Remove the undeclared interval there.
        revised=revised.replace('只涵蓋半天觀察的條款','只涵蓋本次觀察的條款')
        assert '半天' not in revised, filename
        path.write_text(revised,encoding='utf-8')
        runpy.run_path(str(path),run_name='__main__')
    report={'status':'DESIGN_ONLY_EDITORIAL_FIX','changed_choices':len(audit),
            'zero_day_choices':sum(x['proposed_days']==0 for x in audit),
            'one_day_choices':sum(x['proposed_days']==1 for x in audit),
            'rule':'No rounding of 0.5; reviewed work/wait versus onsite interaction. No world time code changed.',
            'repeatability_boundary':'Every grant and handover still needs actual finite stock, custody and one operation receipt before implementation.',
            'choices':audit}
    if audit:
        (BASE/'encounter-day-cost-review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='choices'},ensure_ascii=False,indent=2))
