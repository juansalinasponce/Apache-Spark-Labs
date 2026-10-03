// Consulta de solución. Sustituir la ruta por la ubicación local del Excel.
let
    Origen = Excel.Workbook(File.Contents("C:\Lab09\datos\01_tramites_pasaportes.xlsx"), null, true),
    Hoja = Origen{[Item="Tramites", Kind="Sheet"]}[Data],
    Encabezados = Table.PromoteHeaders(Hoja, [PromoteAllScalars=true]),
    Texto = Table.TransformColumnTypes(Encabezados, {{"TramiteID", type text}, {"SedeID", type text}, {"TipoTramite", type text}, {"Canal", type text}, {"Estado", type text}}),
    Limpieza = Table.TransformColumns(Texto, {{"Canal", each Text.Upper(Text.Trim(Text.Clean(_))), type text}, {"Estado", each Text.Upper(Text.Trim(Text.Clean(_))), type text}}),
    Fechas = Table.TransformColumns(Limpieza, {{"FechaSolicitud", each Date.FromText(_, [Format="yyyy-MM-dd", Culture="es-PE"]), type date}, {"FechaEntrega", each if _ = null or _ = "" then null else Date.FromText(_, [Format="yyyy-MM-dd", Culture="es-PE"]), type nullable date}}),
    Tipos = Table.TransformColumnTypes(Fechas, {{"EdadSolicitante", Int64.Type}, {"ImporteReferencial", Currency.Type}}, "es-PE"),
    SinDuplicados = Table.Distinct(Tipos, {"TramiteID"})
in
    SinDuplicados
