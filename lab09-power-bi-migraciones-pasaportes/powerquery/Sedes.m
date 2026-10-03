// Consulta de solución. Sustituir la ruta por la ubicación local del Excel.
let
    Origen = Excel.Workbook(File.Contents("C:\Lab09\datos\02_sedes.xlsx"), null, true),
    Hoja = Origen{[Item="Sedes", Kind="Sheet"]}[Data],
    Encabezados = Table.PromoteHeaders(Hoja, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {{"SedeID", type text}, {"Sede", type text}, {"Departamento", type text}, {"Provincia", type text}, {"Distrito", type text}, {"RegionNatural", type text}, {"Latitud", type number}, {"Longitud", type number}}, "es-PE")
in
    Tipos
