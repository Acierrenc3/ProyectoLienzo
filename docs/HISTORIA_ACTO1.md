# Contratiempo — Acto 1: «La Grieta» (guion jugable)

Los diálogos se escriben en el editor (campos `IntroLines`, `StoryEvents[].Lines` y `Encounters[].IntroLines` del `battle_manager`), una línea por elemento, con el formato `Nombre: texto`.

## Marcas de historia (flags)
| Marca | Significado | La activa |
|---|---|---|
| 1 | Intro vista | `IntroLines` al empezar |
| 2 | Joel se une | Evento «El Afinador» |
| 3 | Metrónomo Roto derrotado | Jefe 1 |
| 4 | Kesh se une | Evento «La Callada» |
| 5 | Soprano Hueca derrotada | Jefe 2 |
| 6 | Fin del Acto 1 | Evento «La Campana herida» |

Para el modo historia, `StartingPartySize` = 1 (solo Oria al empezar).

## Intro (al empezar la partida)
1. Narrador: Durante siglos, la Campana Mayor marcó el ritmo de las islas: las mareas, las estaciones, los latidos.
2. Narrador: Una noche, la campana se agrietó. Desde entonces, el Silencio avanza y todo lo que toca se vuelve piedra.
3. Oria: ¿Lo oyes, Director? Aún queda música en ti. Guíame y haré sonar mi tambor hasta que el Silencio retroceda.
4. Oria: Los Mudos rondan Puerto Calma. Busquemos el faro: allí podremos descansar.

## Evento «El Afinador» (requiere 1, activa 2, se une Joel)
1. Joel: ¡Esperad! Ese tambor... desafina medio tono, ¿sabéis?
2. Oria: ¿Y tú quién eres para decírmelo?
3. Joel: Joel, afinador de la Campana Mayor. O lo era, hasta que se rompió.
4. Joel: Algo golpea la Fundición con un tempo imposible. Si queréis detener el Silencio, necesitaréis a alguien que sepa escuchar.
5. Oria: Entonces ven con nosotros. Director, ya somos dos.

## Jefe 1: El Metrónomo Roto (requiere 2, activa 3)
Intro:
1. Joel: Ahí está. El metrónomo que marcaba el compás de la campana... se ha vuelto loco.
2. Oria: Si acelera, acelero yo. ¡Director, atento a su péndulo!

## Evento «La Callada» (requiere 3, activa 4, se une Kesh)
1. Kesh: ...
2. Joel: Esa chica lleva campanillas rotas. Y no hace ningún ruido al caminar.
3. Kesh: Yo era uno de ellos. Un Mudo. El Silencio me dejó ir... pero se quedó con mi voz.
4. Kesh: La Soprano Hueca canta en la torre. Su canto convierte a la gente en piedra. Puedo ayudaros a callarla.
5. Oria: Bienvenida, Kesh. Aquí nadie te pedirá que hables.

## Jefe 2: La Soprano Hueca (requiere 4, activa 5)
Intro:
1. Kesh: Cuando grite, protegeos todos a la vez. Su voz alcanza a cualquiera.
2. Joel: Afinaré lo que pueda. ¡Director, marca el compás!

## Evento «La Campana herida» (requiere 5, activa 6)
1. Narrador: El canto de la Soprano se apaga. Por primera vez en meses, se oye el mar.
2. Joel: La grieta de la campana sigue ahí... pero ya no crece.
3. Kesh: Esto no ha terminado. El Silencio tiene un director propio.
4. Oria: Pues que se prepare. Tenemos el nuestro.
5. Narrador: FIN DEL ACTO 1. Gracias por jugar a Contratiempo.
