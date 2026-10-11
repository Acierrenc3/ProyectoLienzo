# Roadmap — Contratiempo (proyecto `ProyectoLienzo`)

Un RPG por turnos **para un solo jugador** en Fortnite (UEFN + Verse), inspirado en las *mecánicas* de los JRPG modernos con reacciones en tiempo real: combate por turnos, esquivar y bloquear en el momento justo, puntos de acción y un grupo de héroes.

> **Regla de oro (propiedad intelectual):** el juego es 100 % original. No usamos nombres, personajes, historia, música ni arte de *Clair Obscur: Expedition 33* ni de ningún otro juego. Epic rechaza las islas que lo hacen.

---

## Cómo trabajamos (Claude Code + UEFN + GitHub)

UEFN solo funciona en Windows y es el único que puede **compilar** Verse y colocar dispositivos en el mapa. Claude Code trabaja sobre los archivos del repositorio. Por eso cada tarea lleva una etiqueta:

| Etiqueta | Quién la hace | Ejemplos |
|---|---|---|
| `verse` | Claude Code | Escribir y corregir archivos `.verse` |
| `editor` | Tú, en UEFN | Colocar dispositivos, enlazar referencias `@editable`, montar la arena, probar |
| `diseño` | Juntos | Números, habilidades, enemigos, historia (en `docs/`) |
| `arte` | Tú (Fab o recursos propios) | Modelos, materiales, efectos, música |

**Ciclo de cada tarea:**

1. Crear un *issue* en GitHub con su criterio de "hecho".
2. Crear una rama: `feat/<nº-issue>-descripcion-corta`.
3. Pedir a Claude Code que implemente el issue (lee `CLAUDE.md` automáticamente).
4. En UEFN: **Verse → Build Verse Code**. Si hay errores, pegarlos tal cual a Claude Code.
5. Hacer la parte `editor` y probar con **Launch Session**.
6. Commit, *pull request* y merge a `main`.

Cada issue debe caber en **una sesión de Claude Code**: un sistema o archivo concreto, no "haz el combate".

**Organización en GitHub:** un *Milestone* por fase, etiquetas `verse` / `editor` / `diseño` / `arte` / `bug`, y un tablero de GitHub Projects (Pendiente → En curso → Probando → Hecho).

---

## Fase 0 — Preparación

**Objetivo:** repositorio y proyecto UEFN funcionando, y un primer `.verse` compilado por Claude Code.

- [x] `editor` Crear el proyecto UEFN en blanco `ProyectoLienzo` en `D:\Mods`.
- [x] `editor` Instalar Git y **Git LFS**; crear el repo en GitHub (privado) y subir este contenido.
- [x] `editor` Copiar los `*.digest.verse` de UEFN a `docs/api/` (están en `%LOCALAPPDATA%\UnrealEditorFortnite\Saved\VerseProject\ProyectoLienzo\Digests\BuiltIn`).
- [x] `editor` Anotar en `CLAUDE.md` la ruta donde van los `.verse` (`Content/`).
- [x] `verse` Dispositivo de prueba `hello_device.verse` que imprime un mensaje al empezar la partida (compila correctamente).
- [x] `diseño` Rellenar `docs/DISENO.md`: tono, mundo, nombre definitivo (**Contratiempo**) y los 3 héroes.

**Hecho cuando:** el ciclo completo (issue → Claude Code → compilar → probar → PR) ha funcionado una vez.

---

## Fase 1 — Núcleo de combate (lo más importante)

**Objetivo:** puedo ganar o perder un combate **1 contra 1** con menú de turnos y esquiva.

- [x] `verse` `battle_manager`: máquina de estados del combate (Inicio → Turno jugador → Turno enemigo → Victoria/Derrota).
- [x] `verse` `combatant`: clase con vida, ataque, defensa y velocidad; se usa igual para héroes y enemigos.
- [x] `verse` Interfaz del menú de turno (Atacar, Habilidad, Objeto, Huir) con vida en texto (barras gráficas: pendiente).
- [x] `verse` Ataque del enemigo con **aviso** y **ventana de esquiva** (+ Contratiempo adelantado de la Fase 2).
- [x] `verse` Pantalla de victoria y derrota.
- [x] `editor` Arena de combate, cámara fija, teletransporte de entrada y salida, y dispositivo de entrada para la tecla de esquiva (ver `docs/MONTAJE_FASE1.md`).
- [x] `editor` Enemigo provisional (bloque Graybox animado con `MoveTo`).
- [ ] `diseño` Primeros números: vida, daño y duración de la ventana de esquiva.

**Riesgo clave:** aunque sea para un jugador, Fortnite funciona con servidor y hay **latencia de entrada**. Empezar con ventanas generosas (unos 400 ms) y ajustar probando.

- [ ] Probar en sesión y ajustar ventanas de esquiva/bloqueo.

**Hecho cuando:** un amigo que no conoce el juego entiende el combate sin explicaciones.

---

## Fase 2 — Profundidad de combate

**Objetivo:** el combate tiene decisiones interesantes y recompensa la habilidad.

- [ ] `verse` **Puntos de acción (PA):** atacar da PA, las habilidades los gastan.
- [ ] `verse` **Bloqueo perfecto** (ventana más corta que la esquiva): devuelve PA y permite un contraataque.
- [ ] `verse` Habilidades definidas como **datos** (nombre, coste, daño, efecto), para añadir más sin tocar la lógica.
- [ ] `verse` Combos enemigos de varios golpes con ritmos distintos.
- [ ] `verse` Estados alterados: quemadura, aturdimiento, debilidad.
- [ ] `verse` Combates contra **varios enemigos** y selección de objetivo.
- [ ] `verse` Números de daño flotantes y mensajes de "¡Esquiva!" / "¡Bloqueo perfecto!".
- [ ] `diseño` 6–8 habilidades y 3 tipos de enemigo con patrones distintos.
- [ ] `arte` Efectos de Niagara para golpes y bloqueos.

**Hecho cuando:** jugar bien (bloqueos perfectos, buen uso de PA) se nota claramente en el resultado.

---

## Fase 3 — Exploración y encuentros

**Objetivo:** recorrer una zona, encontrar enemigos y volver al mismo sitio tras combatir.

- [ ] `verse` `encounter_manager`: al tocar un enemigo en el mapa empieza su combate; al ganar, desaparece.
- [ ] `verse` Guardar y restaurar la posición del jugador al entrar y salir de la arena.
- [ ] `verse` **Puntos de descanso:** recuperan vida y PA, guardan el progreso y reaparecen los enemigos.
- [ ] `verse` Cofres con objetos y recompensas tras el combate.
- [ ] `editor` Primera zona jugable (pequeña): camino, 4–5 encuentros y un punto de descanso.
- [ ] `editor` Transición visual al entrar en combate (fundido a negro o efecto de pantalla).

**Hecho cuando:** se juegan 10–15 minutos seguidos sin tocar el editor.

---

## Fase 4 — Grupo y progresión

**Objetivo:** el jugador controla un grupo de 3 héroes y lo mejora con el tiempo.

- [ ] `verse` Grupo de **3 héroes** controlados por el jugador; el orden de turnos depende de la velocidad.
- [ ] `verse` Habilidades únicas por héroe (estilos distintos, por ejemplo: daño, apoyo y control).
- [ ] `verse` Experiencia, niveles y subida de estadísticas.
- [ ] `verse` Equipo: armas y un sistema original de **mejoras equipables** con efectos pasivos.
- [ ] `verse` **Guardado persistente** entre sesiones (datos `persistable` de Verse).
- [ ] `verse` Menú fuera de combate: grupo, equipo y habilidades.
- [ ] `diseño` Curva de progresión y tabla de equipo.

**Nota:** los héroes en combate serán NPCs o modelos propios; el jugador sigue apareciendo con su skin de Fortnite al explorar.

**Hecho cuando:** volver a una zona anterior con el grupo mejorado se siente distinto.

---

## Fase 5 — Contenido del Acto 1

**Objetivo:** un primer acto completo y publicable (unos 45–60 minutos de juego).

- [ ] `diseño` Historia del Acto 1, diálogos y personajes secundarios.
- [ ] `verse` Sistema de diálogos y misiones sencillas.
- [ ] `verse` **2 jefes** con fases y mecánicas propias.
- [ ] `editor` 3 zonas conectadas con estilo visual propio.
- [ ] `editor` ~8 tipos de enemigo repartidos por las zonas.
- [ ] `arte` Música y ambientación (original o con licencia).

**Hecho cuando:** se puede jugar el Acto 1 de principio a fin.

---

## Fase 6 — Pulido y publicación

- [ ] `editor` Revisar el **presupuesto de memoria** de UEFN y el rendimiento.
- [ ] Pruebas con jugadores mediante códigos privados; apuntar los fallos como issues `bug`.
- [ ] Ajuste final de dificultad y de las ventanas de esquiva y bloqueo.
- [ ] Inscripción en el **Fortnite Creator Program**, clasificación por edades, miniatura, descripción y tráiler.
- [ ] Publicar la isla y crear la *release* `v1.0` en GitHub.

---

## Después del lanzamiento

- Actos 2 y 3 como actualizaciones.
- Modo difícil o "partida nueva+".
- Valorar cooperativo más adelante, solo si la base para un jugador está sólida.

---

## Riesgos principales

| Riesgo | Mitigación |
|---|---|
| Claude Code no puede compilar Verse ni ver el editor | Ciclo de compilar en UEFN y pegar los errores; tener los digest en `docs/api/` |
| Latencia en esquivas y bloqueos | Ventanas generosas al principio y ajustes probando |
| Animaciones limitadas | Level Sequences y efectos de Niagara; cámara que oculte las limitaciones |
| Presupuesto de memoria de la isla | Revisarlo en cada fase, no solo al final |
| Cambios en la API de Verse | Actualizar los digest tras cada actualización de UEFN |
| Proyecto demasiado grande | No pasar de fase hasta cumplir su criterio de "hecho" |
