# Guion del instructor — viernes 2 de octubre de 2026

Objetivo: que cada participante construya y guarde un informe local de pasaportes por sede. Nivel básico; sin publicación, modelado avanzado ni requisitos de Fabric.

## Antes de comenzar

- Distribuir ZIP y comprobar que todos lo extraigan antes de abrir Desktop.
- Tener Power BI Desktop en Windows y verificar importación de ambos Excel. El paquete fue validado a nivel de datos/estructura; las consultas y visuales requieren revisión final en Desktop.
- Preparar su propio PBIX siguiendo la guía antes de la sesión para tener una solución de respaldo.
- Proyectar `imagenes/dashboard_referencia.png` para mostrar el resultado objetivo.
- Probar el mapa; si está restringido, usar barras por departamento desde el inicio.

| Minutos | Actividad | Mensaje y control |
|---|---|---|
| 0–5 | Presentar el caso | Una fila = una solicitud; datos ficticios; obtenido = ENTREGADO |
| 5–15 | Importar los dos Excel | Mostrar Navegador y diferencia entre Cargar y Transformar |
| 15–35 | Power Query | Recortar, mayúsculas, tipos y duplicados; observar 9.624 → 9.600 |
| 35–50 | Relaciones y calendario | Sedes 1 → muchos Tramites; DimFecha desde FechaSolicitud |
| 50–65 | DAX básico | Dos columnas por fila y cuatro medidas que responden a filtros |
| 65–85 | Informe | Tarjetas, barras, línea y tabla; segmentadores. Dona y mapa si queda tiempo |
| 85–90 | Comprobar y guardar | Validar Lima y septiembre; guardar PBIX |

## Ejercicios breves para conducir la clase

1. Antes de limpiar: «¿WEB y web con espacios deberían ser canales diferentes?».
2. Antes de relacionar: colocar Sede y Total Tramites; observar el efecto de la relación.
3. Antes de DAX: «¿una solicitud sin entregar tiene cero días de atención o todavía no tiene ese resultado?».
4. Al filtrar Lima: explicar cómo la dimensión filtra las solicitudes de sus dos sedes.
5. Al ver septiembre: recordar el corte; no confundir solicitudes entregadas con entregas ocurridas en ese mes.

## Si el grupo se retrasa

Usar los `.m` de solución para recuperar Power Query y copiar los bloques DAX de uno en uno. Omitir GrupoEdad, la medida opcional de pendientes, dona y mapa. Conservar los dos archivos, la relación, el calendario, cuatro tarjetas, barras, línea y filtro por departamento.

## Cierre

Pedir que respondan con su informe: «¿Qué sede tiene más entregados?», «¿cuántos pasaportes obtuvo Lima?» y «¿qué significa la caída de septiembre?». Comprobar 1.692, 2.895 y la diferencia entre cohorte de solicitudes y mes de entrega. Entregar el PBIX guardado por cada participante.
