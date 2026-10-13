# Contratiempo — Documento de diseño

> Nombre del juego: **Contratiempo**. Nombre del repositorio y del proyecto UEFN: `ProyectoLienzo`.
> RPG por turnos para **un jugador** en Fortnite (UEFN + Verse). Juego original.

## Concepto
Un RPG por turnos en el que esquivar y bloquear **al ritmo** de los ataques enemigos lo es todo. En música, un *contratiempo* es una nota que cae fuera del pulso.

## Mundo
Un archipiélago de islas costeras que vive al compás de **la Campana Mayor**, un faro-campana gigante que marca el ritmo del mundo: mareas, estaciones, latidos. La campana se ha agrietado y **el Silencio** se extiende: lo que toca se vuelve gris y queda inmóvil como piedra.

- **Tono:** melancólico pero esperanzador; apto para el público de Fortnite.
- **Estilo visual:** contraste entre zonas vivas y coloridas y zonas tomadas por el Silencio (desaturadas, con niebla), conseguido con volúmenes de postprocesado de UEFN.
- **Sonido:** protagonista. Cada enemigo y cada ataque tiene una firma rítmica reconocible.

## El jugador: el Director / la Directora
La última persona capaz de oír la melodía. Explora con su propia skin de Fortnite; en combate **dirige** al trío de héroes: elige sus acciones y marca los tiempos de esquiva y bloqueo.

## Héroes
| Héroe | Rol | Arma | Mecánica única |
|---|---|---|---|
| **Oria**, la Percusionista | Daño / aguante | Martillo-tambor | **Ritmo**: contador que sube con cada acción bien sincronizada y aumenta su daño; se reinicia al fallar. |
| **Joel**, el Afinador | Apoyo | Diapasón | **Armonía**: cura y da PA; si el grupo actúa en el orden que él marca, todos reciben una bonificación. |
| **Kesh**, la Callada | Control | Campanillas rotas | **Eco del Silencio**: silencia a un enemigo (pierde su turno) a cambio de vida propia. Antigua criatura del Silencio: misterio central de la historia. |

## Combate
| Elemento | Descripción | Valor inicial |
|---|---|---|
| Estadísticas | Vida, Ataque, Defensa, Velocidad (orden de turnos) | — |
| Puntos de acción (PA) | Atacar da PA; las habilidades los gastan | +1 por ataque, máx. 9 |
| **Compás** | Cada ataque enemigo tiene aviso sonoro y visual con su ritmo propio | — |
| **Esquiva** | Pulsar en la ventana: evita el daño | ~400 ms (ajustar) |
| **Contratiempo** (bloqueo perfecto) | Ventana más corta: anula el daño, devuelve PA y lanza un contraataque | ~200 ms (ajustar) |
| **Crescendo** | Barra común que se llena con contratiempos; permite un ataque combinado del trío (Fase 4) | — |

**Equipo:** cada héroe usa un **instrumento** (arma) y puede equipar **partituras** con efectos pasivos.

## Habilidades de Oria (Fase 2)
| Habilidad | Coste | Efecto |
|---|---|---|
| Redoble | 3 PA | 2,5× daño a un objetivo |
| Golpe Sordo | 2 PA | 1,2× daño + Aturdimiento 1 turno |
| Tambor Ígneo | 4 PA | 0,9× daño a todos + Quemadura 3 turnos |

## Grupo (Fase 4)
| Héroe | PV (nv. 1) | Ataque | Defensa | Velocidad | Por nivel |
|---|---|---|---|---|---|
| Oria | 120 | 18 | 6 | 10 | +12 PV, +2 Ataque, +1 Defensa |
| Joel | 95 | 12 | 5 | 12 | +9 PV, +1 Ataque, +1 Defensa |
| Kesh | 85 | 20 | 3 | 14 | +8 PV, +2 Ataque, +1 Defensa |

- Experiencia para subir: 40 + 30 × nivel actual. Nivel máximo 20.
- Experiencia por enemigo: Badajo 30, Coro Hueco 25, Sordina 20 (la reciben todos los héroes).
- Cada héroe tiene sus propios PA (máx. 9). Los enemigos atacan a un héroe al azar; la esquiva protege a ese héroe.
- Si un héroe cae, vuelve con 1 PV en el siguiente combate; si caen los tres, derrota (reaparición en el último faro).

### Habilidades de Joel
| Habilidad | Coste | Efecto |
|---|---|---|
| Afinar | 2 PA | Cura 35 PV a un aliado |
| Diapasón | 1 PA | Da 2 PA a un aliado |
| Armonía | 3 PA | El grupo hace +25 % de daño durante 2 rondas |

### Habilidades de Kesh (cuestan vida propia; nunca la dejan a 0)
| Habilidad | Coste | Efecto |
|---|---|---|
| Campanillas | 2 PA | 1,3× daño + Debilidad 2 turnos |
| Eco del Silencio | 2 PA + 10 % PV | 0,5× daño + Aturdimiento 1 turno |
| Réquiem | 5 PA + 20 % PV | 1,8× daño a todos |

## Equipo (Fase 4)
**Instrumentos** (arma de cada héroe): Martillo-tambor (Oria), Diapasón (Joel), Campanillas rotas (Kesh). Cada mejora (+1 a +3) da +3 de ataque. Se mejoran con la **Resina de la Campana** (cofres; mejora a todo el grupo).

**Partituras** (una por héroe, se encuentran en cofres y se equipan en el menú del grupo, tecla E):
| Partitura | Efecto |
|---|---|
| del Eco | Empieza cada combate con 2 PA |
| Serena | +15 % de vida máxima |
| Presto | +4 de velocidad |
| Firme | +4 de defensa |
| Ardiente | Los ataques normales queman 2 turnos |

## Estados alterados
- **Quemadura:** pierde un 6 % de la vida máxima al empezar su turno.
- **Aturdimiento:** pierde el turno.
- **Debilidad:** hace un 25 % menos de daño.
- **Ritmo (Oria):** +1 por esquiva, +2 por Contratiempo (máx. 10); +10 % de daño por punto; vuelve a 0 al recibir un golpe.

## Enemigos: los Mudos
Criaturas de piedra nacidas del Silencio.

| Enemigo | Patrón | Notas |
|---|---|---|
| **Badajo** | "Campanazo": 1 golpe lento (preparación 1,2–2,0 s) | 150 PV · Ataque 22 · Enemigo de tutorial |
| **Coro Hueco** | "Canon": 3 golpes (preparación 1,0–1,6 s, luego 0,7 s y 0,5 s) al 70 % | 90 PV · Ataque 12 · Enseña a esquivar en cadena |
| **Sordina** | "Apagón": 1 golpe rápido (0,9–1,5 s); si entra, Débil 2 turnos | 70 PV · Ataque 10 · Prioridad de objetivo |
| **Yunque** (Fundición) | "Martillazo": preparación muy larga (1,6–2,6 s) y repetición a los 0,4 s, al 80 % | 220 PV · Ataque 28 · Defensa 7 · Muy lento |
| **Fuelle** (Fundición) | "Soplido": 1 golpe con aviso impredecible (0,5–2,4 s) | 80 PV · Ataque 14 · El más rápido de la zona |
| **Diapasón** (Fundición) | "Vibración": golpea a todo el grupo al 70 % (1,1–1,7 s) | 110 PV · Ataque 13 |
| **Eco Errante** (Torre) | "Reverberación": 4 golpes a ritmo fijo (0,45 s) al 55 %; si entran, Débil 1 turno | 100 PV · Ataque 11 · Velocidad 13 |
| **Gárgola Coral** (Torre) | "Grito de piedra": 2 golpes a todo el grupo al 65 % | 260 PV · Ataque 20 · Defensa 9 |
| **Metrónomo Roto** (jefe 1) | "Péndulo" 2 golpes; en fase 2 "Allegro", 4 golpes rápidos | 600 PV · Ataque 26 |
| **Soprano Hueca** (jefe 2) | "Aria" a todo el grupo; en fase 2 "Coloratura", 4 golpes a todos y Débil | 750 PV · Ataque 24 |

## Acto 1 — "La Grieta"
| Zona | Contenido | Se une |
|---|---|---|
| **Puerto Calma** | Pueblo inicial y tutorial (Badajo, Coro Hueco, Sordina) | Oria |
| **Fundición de la Campana** | Taller del Metrónomo Roto (Yunque, Fuelle, Diapasón) | Joel |
| **Torre de la Soprano** | Kesh, la antigua Muda; la Soprano Hueca (Eco Errante, Gárgola Coral) | Kesh |

**Jefes:**
- **El Metrónomo Roto**: máquina gigante que cambia de tempo a mitad del combate.
- **La Soprano Hueca**: gritos en oleadas que hay que esquivar en cadena.

**Puntos de descanso:** pequeños faros donde se recupera vida y PA, se guarda la partida y reaparecen los enemigos.

## Propiedad intelectual
Solo tomamos la *estructura de combate* (turnos con reacciones en tiempo real), que es una mecánica de juego. Nada de nombres, personajes, historia, arte ni música de otros juegos.
