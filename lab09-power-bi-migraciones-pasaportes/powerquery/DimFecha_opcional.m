// Alternativa a la tabla DAX, no ejecutar las dos opciones.
// Consulta en blanco llamada DimFecha; depende de Tramites ya limpiada.
let
    Inicio = List.Min(Tramites[FechaSolicitud]),
    Fin = List.Max(Tramites[FechaSolicitud]),
    Lista = List.Dates(Inicio, Duration.Days(Fin-Inicio)+1, #duration(1,0,0,0)),
    Tabla = Table.FromList(Lista, Splitter.SplitByNothing(), {"Fecha"}),
    Tipo = Table.TransformColumnTypes(Tabla, {{"Fecha", type date}}),
    Anio = Table.AddColumn(Tipo, "Anio", each Date.Year([Fecha]), Int64.Type),
    Numero = Table.AddColumn(Anio, "MesNumero", each Date.Month([Fecha]), Int64.Type),
    Mes = Table.AddColumn(Numero, "Mes", each Date.ToText([Fecha], "MMM", "es-PE"), type text),
    AnioMes = Table.AddColumn(Mes, "AnioMes", each Date.ToText([Fecha], "yyyy-MM", "es-PE"), type text),
    Orden = Table.AddColumn(AnioMes, "AnioMesOrden", each [Anio]*100+[MesNumero], Int64.Type)
in
    Orden
