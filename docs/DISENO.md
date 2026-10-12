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

## Acto 1 — "La Grieta"
| Zona | Contenido | Se une |
|---|---|---|
| **Puerto Calma** | Pueblo inicial y tutorial | Oria |
| **Bosque de Juncos** | El viento hace sonar los juncos; la música avisa de los peligros | Joel |
| **Fundición de la Campana** | Kesh aparece como enemiga y acaba uniéndose | Kesh |

**Jefes:**
- **El Metrónomo Roto**: máquina gigante que cambia de tempo a mitad del combate.
- **La Soprano Hueca**: gritos en oleadas que hay que esquivar en cadena.

**Puntos de descanso:** pequeños faros donde se recupera vida y PA, se guarda la partida y reaparecen los enemigos.

## Propiedad intelectual
Solo tomamos la *estructura de combate* (turnos con reacciones en tiempo real), que es una mecánica de juego. Nada de nombres, personajes, historia, arte ni música de otros juegos.
