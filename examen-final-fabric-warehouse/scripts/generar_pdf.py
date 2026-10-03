"""Generar el PDF de distribución. Dependencia: pip install reportlab."""
from pathlib import Path
from html import escape
import re
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Preformatted, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'EXAMEN_FINAL_PASO_A_PASO.pdf'
styles = getSampleStyleSheet()
styles.add(ParagraphStyle('Cover', fontName='Helvetica-Bold', fontSize=26, leading=32, textColor=colors.HexColor('#16324f'), alignment=TA_CENTER, spaceAfter=22))
styles.add(ParagraphStyle('TextExam', fontName='Helvetica', fontSize=10, leading=15, spaceAfter=8))
styles.add(ParagraphStyle('CodeExam', fontName='Courier', fontSize=7, leading=9, spaceAfter=8))
styles['Heading1'].textColor = colors.HexColor('#16324f')
styles['Heading2'].textColor = colors.HexColor('#147d92')
flow = []
def para(text):
    text = escape(text)
    text = re.sub(r'`([^`]+)`', r'<font name="Courier">\1</font>', text)
    return Paragraph(text, styles['TextExam'])
def md(path):
    lines = path.read_text(encoding='utf-8').splitlines()
    buf = []
    def flush():
        if buf:
            flow.append(para(' '.join(buf)))
            buf.clear()
    for line in lines:
        if line.startswith('#'):
            flush()
            level = len(line)-len(line.lstrip('#'))
            flow.append(Paragraph(escape(line[level:].strip()), styles['Heading1' if level == 1 else 'Heading2']))
        elif not line.strip():
            flush()
        elif line.startswith('- ') or re.match(r'^\d+\. ', line):
            flush()
            flow.append(para(line))
        else:
            buf.append(line)
    flush()
def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor('#147d92'))
    canvas.line(42, 39, A4[0]-42, 39)
    canvas.setFont('Helvetica', 8)
    canvas.drawString(42, 26, 'Examen final | Microsoft Fabric Warehouse | Material del curso')
    canvas.drawRightString(A4[0]-42, 26, str(doc.page))
    canvas.restoreState()

flow += [Spacer(1,85), Paragraph('EXAMEN FINAL<br/>Analítica bancaria',styles['Cover']),
         Paragraph('Cuentas · Canales · Transacciones',styles['Title']), Spacer(1,24),
         para('Microsoft Fabric Warehouse · T-SQL · Pipeline automatizado · Power BI'),
         para('Guía de construcción paso a paso con scripts completos. Patrón del Lab07: Bronze, Silver y Gold en un único Warehouse.'),
         para('Duración sugerida: 5 horas. Evaluación: 100 puntos. Material preparado el 03 de octubre de 2026.'),
         Spacer(1,20), para('Nombre del estudiante: __________________________________'),
         para('Workspace / Warehouse: __________________________________'), PageBreak()]
flow.append(Paragraph('Contenido y orden de trabajo',styles['Heading1']))
for item in ['1. Enunciado y rúbrica','2. Guía paso a paso (11 pasos)','3. Configuración del pipeline automatizado','4. Modelo semántico, medidas, reporte y dashboard','5. Anexo A: validación del origen MySQL','6. Anexo B: scripts T-SQL de Fabric (01–09)','7. Anexo C: medidas DAX']:
    flow.append(para(item))
flow.append(para('Todos los scripts también están en archivos separados dentro de la misma carpeta. Ejecutar cada archivo en el motor indicado. Los anexos no sustituyen la explicación de los pasos.'))
for name in ['ENUNCIADO.md','GUIA_PASO_A_PASO.md','pipeline/CONFIGURACION_PIPELINE.md','powerbi/MODELO_Y_DASHBOARD.md']:
    flow.append(PageBreak())
    md(ROOT/name)
for group,files in [('Anexo A — MySQL',sorted((ROOT/'sql/mysql').glob('*.sql'))),('Anexo B — Fabric T-SQL',sorted((ROOT/'sql/fabric').glob('*.sql'))),('Anexo C — Medidas DAX',[ROOT/'powerbi/medidas.dax'])]:
    flow.append(PageBreak())
    flow.append(Paragraph(group,styles['Heading1']))
    for ix,path in enumerate(files):
        if ix: flow.append(PageBreak())
        flow.append(Paragraph(escape(str(path.relative_to(ROOT))),styles['Heading2']))
        # Wrap long code lines without losing characters; DAX measures can be pasted from source files.
        lines=[]
        for line in path.read_text(encoding='utf-8').splitlines():
            if len(line)<=100: lines.append(line)
            else:
                while len(line)>100:
                    split=line.rfind(' ',0,100)
                    if split<10: split=100
                    lines.append(line[:split])
                    line='    '+line[split:].lstrip()
                lines.append(line)
        flow.append(Preformatted('\n'.join(lines),styles['CodeExam']))
SimpleDocTemplate(str(OUTPUT),pagesize=A4,rightMargin=42,leftMargin=42,topMargin=45,bottomMargin=52,title='Examen final — Fabric Warehouse',author='Apache Spark Labs').build(flow,onFirstPage=footer,onLaterPages=footer)
print(OUTPUT)
