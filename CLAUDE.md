# CLAUDE.md — Instrucciones para Claude Code

## Proyecto
**Contratiempo**: RPG por turnos para **un solo jugador** en Fortnite, hecho con UEFN y Verse. Combate por turnos con reacciones en tiempo real (esquiva y bloqueo), puntos de acción y un grupo de 3 héroes. Consulta `ROADMAP.md` para la fase actual y `docs/DISENO.md` para el diseño (mundo, héroes Oria/Joel/Kesh, enemigos y valores de combate). Los valores de `DISENO.md` son la fuente de verdad para los números.

**El juego es original.** No uses nombres, personajes, textos ni referencias de *Clair Obscur: Expedition 33* ni de otros juegos.

## Limitaciones importantes
- **No puedes compilar Verse.** Solo se compila dentro de UEFN (Windows). Escribe el código con cuidado y espera a que el usuario te pegue los errores del compilador.
- **No puedes ver ni editar el mapa.** Los dispositivos se colocan en UEFN. Cuando el código necesite uno, decláralo con `@editable` y explica al usuario, en una lista breve, qué dispositivo colocar y cómo enlazarlo.
- Antes de usar una API, búscala en `docs/api/*.digest.verse`. Si no está ahí, no la inventes: dilo.

## Estructura
- Código Verse: `Content/` (raíz del proyecto UEFN; UEFN compila todos los `.verse` que hay ahí. Cada subcarpeta crea un submódulo de Verse, así que de momento todo va en `Content/` directamente).
- `.lore/` es el control de versiones propio de UEFN (Unreal Revision Control): **no lo toques**. Git y Lore conviven; Git está ignorado por Lore y Lore por Git.
- `docs/` — diseño y referencia de la API (`docs/api/`).
- Los archivos `.uasset` y `.umap` son binarios de UEFN: **no los edites**.

## Lecciones aprendidas (UEFN 6.0 / Verse)
- Los campos de posición del editor van en orden **Izquierda, Arriba, Adelante** (ver `docs/MONTAJE_FASE1.md`).
- Una comparación no es `logic`: usa `logic{A >= B}`.
- Los `data members` no pueden inicializarse con funciones `<localizes>` (error 3582): asigna textos en un método (`SetText`).
- Las funciones `<decides>` se llaman con corchetes: `logic{MiFuncion[X]}`, nunca con paréntesis.
- No llames funciones `<suspends>` dentro de la condición de un `if`: guarda el resultado antes (`R := F()` y luego `if (X := R?)`). Para bucles con llamadas `<suspends>`, usa `loop` con índice en vez de `for`.
- No uses el mismo nombre para un campo de la clase y una variable o parámetro de un método (p. ej. `Hero`, `Items`, `Kind`): Verse da error de identificador ambiguo.
- Las funciones de módulo usadas dentro de `for`/`if` deben marcarse `<computes>` (si no, error de efecto `no_rollback`).
- `option{...}` también es un contexto de fallo: calcula antes en una constante cualquier llamada sin `<computes>` y luego haz `option{Valor}`.
- Los dispositivos (balizas, indicadores de mapa…) se pueden mover en partida con `Dispositivo.TeleportTo[Posición, IdentityRotation()]`.
- Guardado: `var SaveTable:weak_map(player, save_data)` de ámbito de módulo con una clase `<persistable>` sin campos `var`.
- Los errores completos del compilador están en `%LOCALAPPDATA%\UnrealEditorFortnite\Saved\Logs\UnrealEditorFortnite.log` (buscar `Script error`).

## Convenciones de Verse
- Un sistema por archivo: `battle_manager.verse`, `combatant.verse`, `battle_ui.verse`…
- Nombres de tipos y funciones en inglés (`snake_case` para tipos, `PascalCase` para funciones y campos, como en la API de Epic). Comentarios en español.
- Valores ajustables (daño, vida, duración de las ventanas) como constantes o `@editable`, nunca escritos a mano en mitad de la lógica.
- Datos de juego (habilidades, enemigos) separados de la lógica.
- Usa correctamente los efectos: `<suspends>` para código asíncrono, `<decides>` y `[]` para expresiones que pueden fallar, `spawn`, `race` y `sync` para concurrencia.
- Ventanas de esquiva y bloqueo generosas por defecto (latencia del servidor).

## Flujo de trabajo
- Trabaja siempre en una rama `feat/<nº-issue>-descripcion`, nunca directamente en `main`.
- Al terminar una tarea: resume los cambios, lista los pasos `editor` que debe hacer el usuario y marca la casilla correspondiente en `ROADMAP.md`.
- Mensajes de commit en español, cortos y en imperativo: `Añade ventana de esquiva al ataque enemigo`.
