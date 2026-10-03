"""Validar contenido real de los Excel generados sin dependencias externas."""
from pathlib import Path
from collections import Counter
from datetime import date
import json, zipfile, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
def leer(path):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        sheet=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows=[]
    for row in sheet.findall('s:sheetData/s:row',ns):
        vals=[]
        for c in row.findall('s:c',ns):
            t=c.find('s:is/s:t',ns) if c.get('t')=='inlineStr' else c.find('s:v',ns)
            vals.append(t.text if t is not None else None)
        rows.append(vals)
    return [dict(zip(rows[0],row)) for row in rows[1:]]
t=leer(root/'datos/01_tramites_pasaportes.xlsx');s=leer(root/'datos/02_sedes.xlsx')
e=json.loads((root/'datos/RESULTADOS_ESPERADOS.json').read_text())
u={r['TramiteID']:r for r in t};ent=[r for r in u.values() if r['Estado'].strip().upper()=='ENTREGADO']
assert len(t)==e['filas_excel']==9624
assert len(u)==e['tramites']==9600
assert len(s)==len({r['SedeID'] for r in s})==12
assert all(r['SedeID'] in {x['SedeID'] for x in s} for r in t)
assert len(ent)==e['entregados']==7657
assert round(100*len(ent)/len(u),2)==e['porcentaje_entrega']
assert dict(sorted(Counter(r['FechaSolicitud'][:7] for r in u.values()).items()))==e['por_mes']
assert round(sum((date.fromisoformat(r['FechaEntrega'])-date.fromisoformat(r['FechaSolicitud'])).days for r in ent)/len(ent),2)==e['dias_promedio']
assert len({r['FechaSolicitud'][:7] for r in u.values()})==12
assert min(r['FechaSolicitud'] for r in u.values())=='2025-10-01'
assert max(r['FechaSolicitud'] for r in u.values())=='2026-09-30'
assert all((r['Estado'].strip().upper()=='ENTREGADO')==bool(r['FechaEntrega']) for r in u.values())
print('OK: ambos Excel, claves, 12 meses, duplicados, entregas y KPI coinciden con los resultados esperados.')
