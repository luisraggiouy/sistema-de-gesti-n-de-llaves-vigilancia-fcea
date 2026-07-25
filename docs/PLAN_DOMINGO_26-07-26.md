# Plan Domingo 26-07-2026 — FCEA Sistema de Llaves

Escrito el sábado 25-07-2026 al finalizar la jornada de piloto.

## Estado con el que cerramos el sábado

**El piloto está funcionando bien.** Confirmado por el usuario:

- Terminal A puede pedir llaves → Monitor las recibe en tiempo real.
- Monitor entrega y devuelve llaves normalmente.
- Modal "Agregar vigilante" **funciona** (el bug de PocketBase readonly quedó resuelto por reboot / helper `kill_pocketbase_zombis`).
- 6 vigilantes cargados, turno matutino activo.
- Objetos olvidados: 5 en custodia.

Nos vamos con **3 pendientes concretos** para mañana, sin urgencia.

---

## Pendiente 1 — Instalar el sistema en Terminal B

**Contexto**: Terminal A ya quedó operando el sábado. Terminal B está sin instalar. Es la última PC del piloto.

**Pasos** (usá el pendrive del sábado, que ya tiene los launchers blindados con el helper `kill_pocketbase_zombis.ps1`):

1. Encender Terminal B con el pendrive conectado.
2. Doble clic en `INSTALAR SISTEMA.bat` del pendrive.
3. UAC → SI.
4. En el menú elegir opción **[2] PRODUCCION EN 3 PCs (autodeteccion)**.
5. Cuando pregunte la IP del Monitor, verificar que autodetecte la del Monitor de la LAN. Si autodetecta bien y responde HTTP en :8090 → aceptar. Si no, escribirla a mano (la misma que usa Terminal A hoy).
6. Al final del script, la PC se reinicia sola. Al arrancar Chrome se abre solo en modo kiosk apuntando al Monitor.

**Verificación**:
- Desde Terminal B pedir una llave de prueba con un usuario cualquiera.
- Confirmar en el Monitor que la solicitud aparece con "Terminal-B" identificado.
- Devolverla y confirmar cierre.

**Contingencia**: si algo falla en la copia o en el autodetectar rol, el log queda en `C:\fcea_recuperador.log` (o `%TEMP%\fcea_desinstalar.log` si venís del desinstalador). Mandame la foto y lo resolvemos.

**Tiempo estimado**: 15-25 minutos, con Chrome-kiosk arrancando al final.

---

## Pendiente 2 — Corregir "Hace 300 min" cuando la solicitud es nueva

**Síntoma observado**: al llegar una solicitud recién creada desde Terminal A, la tarjeta en el Monitor la muestra como "Hace 300 min" cuando debería decir "Ahora" o "Hace 0 min". Foto adjunta del sábado, hora 12:37:23 vs solicitud que se acababa de generar.

**Diagnóstico** (mío, sin haberlo tocado todavía):

El commit `f018aaf` de ayer arregló el **formateo** (`formatTiempoEspera.ts`: ahora convierte 300 → "Hace 5h 00m", 65 → "Hace 1h 05m", etc.) pero el problema real es el **valor de entrada**. Alguien le está pasando 300 al formateador para una solicitud que se creó hace 5 segundos.

Hipótesis A (probable): la fecha `hora_solicitud` en PocketBase se está guardando en zona horaria distinta a la que usa `Date.now()` en el browser. UY es UTC-3. Si PocketBase guarda `created` en UTC y el hook lo lee como si fuera hora local, la diferencia siempre sería exactamente **-3 horas = -180 min**, no 300. Pero si la Terminal A tiene mal el reloj (o la Monitor lo tiene mal), la brecha real puede dar 300 min.

Hipótesis B: el campo `hora_solicitud` no se está poblando desde Terminal A y queda con un valor default de PocketBase (posible epoch 0, aunque en ese caso serían millones de minutos, no 300).

Hipótesis C: hay un cálculo raro en `minutosDesde` cuando la fecha viene como string ISO con offset.

**Plan de trabajo mañana**:

1. Abrir en el Monitor `http://127.0.0.1:8090/_/` → colección `solicitudes` → ver el registro real de la solicitud que se ve como "Hace 300 min". Anotar el valor exacto de `hora_solicitud` y de `created`.
2. Comparar con `new Date().toISOString()` en la consola del browser en ese mismo instante.
3. Si la diferencia es exactamente 300 min = 5h → es problema de reloj entre PC del Monitor y PC de Terminal A. Sincronizar ambos relojes con hora oficial de UY y listo.
4. Si la diferencia NO es 300 min → hay un bug de parseo. Revisar en `src/hooks/useSolicitudes.ts` (o donde viva el hook) cómo se lee `hora_solicitud` y compararlo con `PendingRequestCard.tsx` (que usa `formatTiempoEspera(minutosDesde(solicitud.horaSolicitud))`).
5. Fix: en cualquiera de los dos casos, asegurar que **siempre** `hora_solicitud` en PocketBase se escriba como ISO 8601 UTC (`toISOString()`) y que al leer se parsee con `new Date(str)`. Eso vuelve el cálculo inmune a la zona horaria de la PC.

**Verificación**:
- Pedir una llave desde Terminal A.
- La tarjeta en Monitor debe mostrar "Ahora" inmediatamente y pasar a "Hace 1 min" tras 60 segundos.
- Dejar la solicitud sin atender 90 minutos y verificar que muestre "Hace 1h 30m".

**Archivos involucrados**:
- `src/utils/formatTiempoEspera.ts` (ya OK)
- `src/components/monitor/PendingRequestCard.tsx` (usa `minutosDesde`)
- `src/components/monitor/SolicitudCard.tsx`
- `src/hooks/useSolicitudes.ts` o `src/contexts/SolicitudesContext.tsx` (donde se hace el fetch de PocketBase)
- Posiblemente `src/pages/TerminalUsuario.tsx` donde se hace el `pb.collection('solicitudes').create(...)` para ver qué le está pasando en `hora_solicitud`.

**Tiempo estimado**: 30-45 minutos si es reloj (arreglo instantáneo), 1-1.5 horas si hay que tocar código + rebuild + regrabar pendrive + ACTUALIZAR_DATOS en ambas terminales.

---

## Pendiente 3 — Pestaña "Dashboard" desaparecida del Monitor

**Síntoma observado**: en la foto del sábado a las 12:37, la barra superior del Monitor tiene:
`Objetos | Agenda/Autorizaciones | Historial | Configuración | Vigilantes | Llaves | [icono de diagnóstico]`

**Falta la pestaña Dashboard** que existía antes del piloto. Probablemente se removió sin querer en alguna refactorización de `MonitorVigilancia.tsx` reciente.

**Diagnóstico rápido** (para verificar mañana antes de tocar nada):

1. Abrir `src/pages/MonitorVigilancia.tsx` y buscar la palabra `Dashboard` o `BarChart` en el JSX del header. Si no está, se cayó al hacer merge/refactor.
2. Confirmar que `src/pages/Dashboard.tsx` sigue existiendo y compilable.
3. Confirmar que la ruta al Dashboard está registrada en `src/App.tsx` (busca `<Route path="/dashboard"`).

**Plan de fix**:

1. En `MonitorVigilancia.tsx` volver a agregar el botón "Dashboard" al lado de los demás (después de "Vigilantes" o de "Llaves"). Usar el mismo estilo `<Button variant="outline" ...>` que los demás.
2. El onClick puede ser `() => window.open('/dashboard', '_blank')` para que abra el Dashboard en una pestaña nueva y no rompa el kiosk del Monitor, o navegación interna con router si preferimos.
3. Ícono sugerido: `BarChart3` de `lucide-react`.

**Archivos involucrados**:
- `src/pages/MonitorVigilancia.tsx` (agregar el botón en el header)
- `src/App.tsx` (verificar ruta)
- `src/pages/Dashboard.tsx` (no debería tocarse)

**Verificación**:
- Al hacer clic en "Dashboard" desde el Monitor, se abre la vista de estadísticas / reportes.
- La vista tiene los gráficos de `TurnStatsPieCharts` y `AdvancedChartVisualizations`.
- Se puede volver al Monitor sin recargar todo.

**Riesgo**: bajo. Es sumar un botón. No toca lógica de negocio ni PocketBase.

**Tiempo estimado**: 15-20 minutos incluido rebuild + regrabar pendrive + ACTUALIZAR_DATOS en Monitor.

---

## Orden sugerido para mañana

1. **Primero**: pendiente 3 (Dashboard) — es rápido, aislado, ganamos confianza.
2. **Segundo**: pendiente 2 (300 min) — sale rápido si es reloj, si no toca código.
3. **Tercero**: pendiente 1 (Terminal B) — cierra el hardware del piloto.

Los tres son **independientes**, se pueden reordenar sin problema.

## Flujo de despliegue después de cada fix de código

Para no volver a romper nada:

1. Guardar cambios en el repo (`git add -A && git commit -m "..."`).
2. `npm run build` — verificar que el `index-*.js` cambió de hash.
3. `git push origin main`.
4. Doble clic en `GRABAR_PENDRIVES.bat` de la raíz del repo → esto copia el `dist/` nuevo y el `scripts/` nuevo al pendrive.
5. Con el pendrive en el Monitor, doble clic en `INSTALAR SISTEMA.bat` → opción **[1] ACTUALIZAR SOLO DATOS + CÓDIGO** (¡OJO! si el modal preinstalado ofrece "solo datos" y también "reinstalar código", tenés que elegir el que actualiza código, porque los fixes de UI están en el JS compilado).
   - Nota: releer el bloque `MENU_PRINCIPAL` de `INSTALAR_SISTEMA_launcher.bat` antes: la opción [1] actual es "solo datos". Para actualizar código hay que ir por reinstalación completa opción [2], o modificar el launcher para agregar "opción [1.5] solo código" si ves que va a ser recurrente.
6. Ctrl+F5 en el Chrome del Monitor para forzar refresh del cache.
7. Repetir 5+6 en Terminal A (y Terminal B cuando exista).

## Cosas que YA quedaron listas para el futuro (no hay que hacer nada, están commiteadas y pusheadas)

- Commit `dee6f9b`: helper `scripts/lib/kill_pocketbase_zombis.ps1` + los 3 launchers del pendrive (INSTALAR / RECUPERAR / DESINSTALAR) inmunes al bug del PocketBase zombi elevado. Si en el futuro vuelve a haber un problema de "attempt to write a readonly database (8)", ya no hay que armar scripts a mano.
- `E:\7_ARREGLAR_ADMIN_DEFINITIVO.bat`: fix aislado en el pendrive por si algún día vuelve el mismo síntoma en algún admin. Está guardado y no se ejecuta salvo doble clic manual.
- Commit `f018aaf`: `formatTiempoEspera` con formato humano ("Hace 1h 05m" en vez de "Hace 65 min"). El formateo está bien; lo que falla es el **valor de entrada**, que es lo que veremos en el pendiente 2.

## Notas del sábado que no quiero perder

- **El bug del modal "Agregar vigilante" NO era del frontend** — era el zombi PocketBase elevado bloqueando `data.db`. Se destrabó solo con el reboot del Monitor. Confirmado por el usuario que ahora funciona.
- **`superuser upsert` no existe en PocketBase 0.22.4** — descartar de futuros scripts de admin CLI. Es de 0.23+.
- **La tarea programada `FCEA-Sistema-Llaves-AutoStart` lanza PocketBase elevado** — cualquier script que quiera parar el servicio a mano necesita usar el helper `kill_pocketbase_zombis.ps1` porque `taskkill /F /IM pocketbase.exe` desde contexto usuario no lo mata.
- **El script CLI de PocketBase devuelve exit code 0 aunque el texto diga "Failed"** — nunca confiar en `$LASTEXITCODE`. Siempre parsear el stdout buscando "success/created/updated" **y** ausencia de "error/failed/readonly/unknown".

Buen domingo!
