"""Generación reproducible: solo biblioteca estándar de Python 3. No datos personales."""
from pathlib import Path
from datetime import date, timedelta
from collections import Counter
from xml.sax.saxutils import escape
import random, zipfile, json, calendar
ROOT = Path(__file__).resolve().parents[1]
R = random.Random(20261002)
CORTE = date(2026,9,30)

def excel(path, sheet, headers, rows):
    def col(n):
        s=''
        while n:
            n,a=divmod(n-1,26); s=chr(65+a)+s
        return s
    def cell(value, pos):
        if value is None: return f'<c r="{pos}"/>'
        if isinstance(value,(int,float)): return f'<c r="{pos}"><v>{value}</v></c>'
        return f'<c r="{pos}" t="inlineStr"><is><t xml:space="preserve">{escape(str(value))}</t></is></c>'
    allrows=[headers]+rows
    body=''.join(f'<row r="{i}">'+''.join(cell(v,f'{col(j)}{i}') for j,v in enumerate(row,1))+'</row>' for i,row in enumerate(allrows,1))
    dim=f'A1:{col(len(headers))}{len(allrows)}'
    files={
    '[Content_Types].xml':'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
    '_rels/.rels':'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml':f'<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="{sheet}" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
    'xl/worksheets/sheet1.xml':f'<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="{dim}"/><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight="15"/><sheetData>{body}</sheetData><autoFilter ref="{dim}"/></worksheet>'}
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for k,v in files.items(): z.writestr(k,v)

sedes=[
['S01','Sede Lima Centro (simulada)','Lima','Lima','Lima','Costa',-12.0464,-77.0428],
['S02','Sede Lima Norte (simulada)','Lima','Lima','Los Olivos','Costa',-11.9917,-77.0708],
['S03','Sede Callao (simulada)','Callao','Callao','Callao','Costa',-12.0566,-77.1181],
['S04','Sede Arequipa (simulada)','Arequipa','Arequipa','Arequipa','Sierra',-16.3989,-71.5350],
['S05','Sede Trujillo (simulada)','La Libertad','Trujillo','Trujillo','Costa',-8.1116,-79.0287],
['S06','Sede Chiclayo (simulada)','Lambayeque','Chiclayo','Chiclayo','Costa',-6.7714,-79.8409],
['S07','Sede Piura (simulada)','Piura','Piura','Piura','Costa',-5.1945,-80.6328],
['S08','Sede Cusco (simulada)','Cusco','Cusco','Cusco','Sierra',-13.5319,-71.9675],
['S09','Sede Huancayo (simulada)','Junín','Huancayo','Huancayo','Sierra',-12.0651,-75.2049],
['S10','Sede Iquitos (simulada)','Loreto','Maynas','Iquitos','Selva',-3.7437,-73.2516],
['S11','Sede Pucallpa (simulada)','Ucayali','Coronel Portillo','Callería','Selva',-8.3791,-74.5539],
['S12','Sede Tacna (simulada)','Tacna','Tacna','Tacna','Costa',-18.0066,-70.2463]]
rows=[]
for m in range(12):
    y=2025 if m<3 else 2026; month=((9+m)%12)+1
    n=[680,710,860,890,720,850,780,810,790,920,900,690][m]
    for j in range(n):
        f=date(y,month,R.randint(1,calendar.monthrange(y,month)[1]))
        sede=R.choices(sedes,weights=[23,16,9,9,8,6,6,6,5,4,4,4])[0]
        status=R.choices(['ENTREGADO','EN PROCESO','OBSERVADO','CANCELADO'],[82,9,6,3])[0]
        entrega=f+timedelta(days=R.randint(2,18)) if status=='ENTREGADO' else None
        if entrega and entrega>CORTE: status='EN PROCESO'; entrega=None
        canal=R.choice(['WEB','PRESENCIAL'])
        if len(rows)%17==0: canal=' '+canal.lower()+' '
        dirty_status=' '+status.lower()+' ' if len(rows)%19==0 else status
        rows.append([f'T{len(rows)+1:06d}',f.isoformat(),entrega.isoformat() if entrega else None,sede[0],R.choice(['PRIMERA EMISIÓN','RENOVACIÓN']),canal,dirty_status,R.randint(18,79),120.0])
raw=rows+[r[:] for r in rows[:24]]
excel(ROOT/'datos/01_tramites_pasaportes.xlsx','Tramites',['TramiteID','FechaSolicitud','FechaEntrega','SedeID','TipoTramite','Canal','Estado','EdadSolicitante','ImporteReferencial'],raw)
excel(ROOT/'datos/02_sedes.xlsx','Sedes',['SedeID','Sede','Departamento','Provincia','Distrito','RegionNatural','Latitud','Longitud'],sedes)
clean=[dict(zip(['TramiteID','FechaSolicitud','FechaEntrega','SedeID','TipoTramite','Canal','Estado','EdadSolicitante','ImporteReferencial'],r)) for r in rows]
for r in clean:
    r['Estado']=r['Estado'].strip().upper();r['Canal']=r['Canal'].strip().upper()
delivered=[r for r in clean if r['Estado']=='ENTREGADO']
days=[(date.fromisoformat(r['FechaEntrega'])-date.fromisoformat(r['FechaSolicitud'])).days for r in delivered]
metrics={'periodo':'2025-10-01 a 2026-09-30','corte':'2026-09-30','filas_excel':len(raw),'tramites':len(clean),'duplicados':24,'sedes':12,'entregados':len(delivered),'porcentaje_entrega':round(100*len(delivered)/len(clean),2),'dias_promedio':round(sum(days)/len(days),2),'estados':dict(Counter(r['Estado'] for r in clean)),'por_mes':dict(sorted(Counter(r['FechaSolicitud'][:7] for r in clean).items())),'entregados_por_mes_solicitud':dict(sorted(Counter(r['FechaSolicitud'][:7] for r in delivered).items())),'entregados_por_sede':{s[1]:sum(r['SedeID']==s[0] for r in delivered) for s in sedes}}
(ROOT/'datos/RESULTADOS_ESPERADOS.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n')
# Invariantes del dataset antes de empaquetar.
assert len({r['TramiteID'] for r in clean})==len(clean)
assert all(r['SedeID'] in {s[0] for s in sedes} for r in clean)
assert len(metrics['por_mes'])==12
assert all((r['Estado']=='ENTREGADO') == bool(r['FechaEntrega']) for r in clean)
assert all(date(2025,10,1)<=date.fromisoformat(r['FechaSolicitud'])<=CORTE for r in clean)
assert all(date.fromisoformat(r['FechaSolicitud'])<=date.fromisoformat(r['FechaEntrega'])<=CORTE for r in delivered)
for path in (ROOT/'datos').glob('*.xlsx'):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        import xml.etree.ElementTree as ET
        for name in z.namelist(): ET.fromstring(z.read(name))
print(json.dumps(metrics,ensure_ascii=False,indent=2))
