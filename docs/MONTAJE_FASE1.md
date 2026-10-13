# Montaje de la arena — Fase 1

Dispositivos colocados en `ProyectoLienzo.umap` y enlazados al `battle_manager`.

> **Ojo con los ejes (UEFN 6.0):** en el panel Detalles, los campos de **Ubicación** van en orden
> **Izquierda (antes -Y), Arriba (antes Z), Adelante (antes X)**. En **Rotación**: Izquierda (inclinación),
> Arriba (giro), Adelante (alabeo). En la cámara, una inclinación **positiva mira hacia abajo**.

| Campo `@editable` | Dispositivo | Posición (Izq, Arriba, Adelante) | Ajustes |
|---|---|---|---|
| `StartTrigger` | Activador | (-84, 0, -412) | Por defecto |
| `ArenaSpot` | Teletransportador | (-800, 0, -300) | Grupo A, **grupo objetivo V** (sin enlazar) |
| `ReturnSpot` | Teletransportador2 | (500, 0, -900) | Grupo A, **grupo objetivo V** (sin enlazar) |
| `BattleCamera` | Cámara de punto fijo | (-800, 380, -950), rotación (15, 0, 0) | **"Añadir a jugadores al inicio" desactivado** |
| `DodgeInput` | Gatillo de entrada | — | Entrada: **Personalizado 4 (Saltar)** = barra espaciadora |
| `EnemyProp` | Graybox Wall Small C (`Fortnite/GrayBox/Props`) | (-800, 0, 350), escala 2 | Modelo provisional del Badajo |

| `ExtraEnemyProps[0]` | Graybox Wall Small C2 (Coro Hueco) | (-1150, 0, 250), escala 1,4 | |
| `ExtraEnemyProps[1]` | Graybox Wall Small C3 (Sordina) | (-450, 0, 250), escala 1,1 | |

`AutoStartDelay` = 4 (PRUEBAS: el combate empieza solo; poner -1 antes de publicar).

El `battle_manager` tiene **"Visible en partida" desactivado**.

## Cómo probar
1. **Abrir sesión** en UEFN y entrar en la isla.
2. Pisar el **Activador** → teletransporte a la arena con cámara fija.
3. Menú: Atacar / Redoble (3 PA) / Tónico / Huir.
4. Turno del Badajo: el bloque retrocede y embiste. Pulsar **espacio** justo antes del impacto:
   - ≤ 0,20 s antes → **Contratiempo** (sin daño, +1 PA, contraataque)
   - ≤ 0,40 s antes → **Esquiva** (sin daño)
   - antes de eso, o sin pulsar → recibes el golpe.

## Zona de exploración (Fase 3)

Marcadores: duplicados de *Graybox Wall Small* enlazados en los arrays del `battle_manager`.

| Campo | Marcador | Posición (Izq, Arriba, Adelante) | Contenido |
|---|---|---|---|
| `Encounters[0]` | C4 | (600, 0, 600) | Badajo |
| `Encounters[1]` | C5 | (1000, 0, 1200) | Coro Hueco |
| `Encounters[2]` | C6 | (400, 0, 1700) | Badajo + Sordina |
| `Encounters[3]` | C7 (escala 1,7) | (1300, 0, 400) | Badajo + Coro Hueco + Sordina |
| `RestSpots[0]` | C8 (alto: 0,6 / 3,5 / 0,6) | (300, 0, -300) | Faro |
| `Chests[0]` | C9 (bajo: 0,8 / 0,4 / 0,8) | (1400, 0, 1500) | 1 tónico |

`TriggerRadius` = 250 cm · `TonicDropChance` = 0,35 · `AutoStartDelay` = -1 (desactivado).

## Grupo en la arena (Fase 4)

| Campo | Marcador | Posición (Izq, Arriba, Adelante) | Escala |
|---|---|---|---|
| `HeroProps[0]` | C10 (Joel) | (-1050, 0, -380) | 0,5 / 1,3 / 0,5 |
| `HeroProps[1]` | C11 (Kesh) | (-550, 0, -380) | 0,5 / 1,3 / 0,5 |

`StartingPartySize` = 3. `ResetSaveOnStart` = **true solo para pruebas** (borra el guardado al empezar; ponerlo a false antes de publicar).

## Equipo y menú (Fase 4, parte 2)

| Campo | Elemento | Ajustes |
|---|---|---|
| `MenuInput` | Gatillo de entrada2 | Entrada: **Personalizado 6 (Interactuar)** = tecla E · Descripción HUD "Menú del grupo" |
| `MenuKeyHint` | — | "E (Interactuar)" |
| `Chests[0]` | C9 (1400, 0, 1500) | 1 tónico + Partitura Serena |
| `Chests[1]` | C12 (-200, 0, 1300) | Partitura del Eco + Resina (UpgradesInstruments) |
| `Chests[2]` | C13 (1700, 0, 800) | 1 tónico + Partitura Ardiente |

Las partituras Presto y Firme quedan para el contenido del Acto 1.

## Historia y jefes (Fase 5)

Guion completo en `docs/HISTORIA_ACTO1.md`. `StartingPartySize` = 1 (solo Oria; Joel y Kesh se unen por historia). `IntroLines` = 4 líneas de la intro.

| Campo | Marcador | Posición (Izq, Arriba, Adelante) | Escala | Ajustes |
|---|---|---|---|---|
| `StoryEvents[0]` El Afinador | C14 | (-700, 0, 300) | 0,3 / 2 / 0,3 | Requiere 1 · Activa 2 · Se une Joel |
| `Encounters[4]` Metrónomo Roto | C15 | (-900, 0, 1200) | 2,5 | Jefe · Requiere 2 · Activa 3 |
| `StoryEvents[1]` La Callada | C16 | (0, 0, 1900) | 0,3 / 2 / 0,3 | Requiere 3 · Activa 4 · Se une Kesh |
| `Encounters[5]` Soprano Hueca | C17 | (800, 0, 2000) | 2 / 3 / 2 | Jefe · Requiere 4 · Activa 5 |
| `StoryEvents[2]` La Campana herida | C18 | (-500, 0, 1700) | 0,3 / 2 / 0,3 | Requiere 5 · Activa 6 |

Nota: un guardado antiguo con `PartySize` 3 no se reduce al cambiar `StartingPartySize`; para probar la historia desde cero, activar `ResetSaveOnStart` temporalmente.

## Zonas y encuentros nuevos (Fase 5)

| Zona | Lado del mapa | Contenido |
|---|---|---|
| Puerto Calma | Centro y derecha (C4–C9, faro C8) | Encounters 0–3, cofres |
| Fundición | Izquierda (Izq negativo) | Joel (C14), Metrónomo (C15), Encounters 6–7 |
| Torre | Al fondo (Adelante ≥ 1700) | Kesh (C16), Soprano (C17), final (C18), Encounters 8–9 |

| Campo | Marcador (escala 1,7) | Posición (Izq, Arriba, Adelante) | Enemigos | Requiere |
|---|---|---|---|---|
| `Encounters[6]` | C19 | (-1300, 0, 700) | Yunque + Fuelle | 2 |
| `Encounters[7]` | C20 | (-1400, 0, 1600) | Diapasón + Fuelle + Badajo | 2 |
| `Encounters[8]` | C21 | (400, 0, 2500) | Eco Errante + Diapasón | 4 |
| `Encounters[9]` | C22 | (1400, 0, 2400) | Gárgola Coral + Eco Errante | 4 |

## Mapa reorganizado (Fase 5, segunda pasada)

Las posiciones de las tablas anteriores quedan **sustituidas** por estas. Los marcadores se separaron 3 veces más para que quepan los edificios, y la arena de combate se apartó 80 m del pueblo.

### Arena de combate (apartada, sobre suelo de tierra)

| Elemento | Posición (Izq, Arriba, Adelante) |
|---|---|
| Teletransportador (`ArenaSpot`) | (-800, 0, -8300) |
| Cámara de punto fijo | (-800, 380, -8950), rotación (15, 0, 0) |
| C (Badajo) / C2 / C3 | (-800, 0, -7650) / (-1150, 0, -7750) / (-450, 0, -7750) |
| C10 (Joel) / C11 (Kesh) | (-1050, 0, -8380) / (-550, 0, -8380) |
| Teletransportador2 (`ReturnSpot`) | (0, 0, -1200) |

### Marcadores del mundo

| Marcador | Uso | Posición (Izq, Adelante) |
|---|---|---|
| C4, C5, C6, C7 | Encuentros 0–3 (Puerto Calma) | (1800, 1800), (3000, 3600), (1200, 5100), (3900, 1200) |
| C8 | Faro de descanso | (900, -900) |
| C9, C12, C13 | Cofres | (4200, 4500), (-600, 3900), (5100, 2400) |
| C14, C15 | Joel / Metrónomo Roto | (-2100, 900), (-2700, 3600) |
| C16, C17, C18 | Kesh / Soprano Hueca / final | (0, 5700), (2400, 6000), (-1500, 5100) |
| C19, C20 | Encuentros Fundición | (-3900, 2100), (-4200, 4800) |
| C21, C22 | Encuentros Torre | (1200, 7500), (4200, 7200) |

### Ambientación (prefabricados y galerías de Fortnite)

Cada prefabricado tiene un actor raíz ("Raíz de set de juego"); moviendo la raíz se mueve todo. Al borrar la raíz se borra el conjunto.

| Elemento | Origen | Raíz en (Izq, Adelante) |
|---|---|---|
| Suelo: 9 baldosas *Grass Temp Solid1* (escala 10/1/10) | Galerías › Terreno › Forest & Grass Floor | X ∈ {-4500, 1000, 6500} × Z ∈ {-1000, 4500, 10000} (salvo Fundición) + (7500, -4000) |
| Suelo Fundición y arena: *Dirt Temp Solid* (escala 10/1/10) | Galerías › Terreno › Dirt & Mud Floor | (-4500, 4500) y (1100, -8460) |
| Caminos: *Dirt Temp Solid* (Arriba 3) | igual | N-S (1000, 2800) escala 0,8/1/20 · E-O (6000, 2400) escala 24/1/0,8 |
| 15 robles *Hera Oak Tree Medium Grasslands CS* | Galerías › Naturaleza › Bahía Buenaventura | repartidos por las 3 zonas y detrás de la arena |
| Plaza-parque *Gazebo*, *Blue House*, *Brick House* | Prefabricados › Parque Placentero | (7400, -1800), (7000, 500), (7000, 4200) |
| *Slant*, *Garage*, *Two Stacks* (Fundición) | Prefabricados › Fábrica | (-6500, 3000), (-7200, 800), (-6800, 6400) |
| *Lockie's Lighthouse* (torre de la Soprano), *Lighthouse Keeper's Home*, *Dock House*, *Other House* (Torre) | Prefabricados › Faro y Parque Placentero | (3000, 9800), (6000, 10000), (-1200, 11000), (-3500, 9200) |

Ojo: el pivote de las baldosas no está en el centro (cada baldosa a escala 10 cubre de X-4640 a X+600 y de Z-2040 a Z+3040).

## Música (Fase 5)

Tres dispositivos **Radio** junto a la consola; `battle_manager` los enciende y apaga desde Verse.

| Campo | Dispositivo | Pista | Ajustes |
|---|---|---|---|
| `ExploreMusic` | Radio | Music_StW_Ambient_Login01 | Sin límite de distancia · fundidos de 1 s |
| `BattleMusic` | Radio2 | Music_StW_Low_Combat01 | Igual |
| `BossMusic` | Radio3 | Music_StW_High_Combat01 | Igual |

## Indicador de objetivos (Fase 5)

`GuideBeacon` = **Baliza** (Dispositivos › IU, rayo de luz) y `GuideMap` = **Dispositivo indicador del mapa** (Dispositivos › IU). No hace falta colocarlos en un sitio concreto: `battle_manager` los teletransporta al siguiente objetivo y activa el pulso de dirección.

Orden de los objetivos: primero los combates normales disponibles que aún no se han vencido nunca (en el orden de `Encounters`), después el evento de historia disponible y, por último, el jefe disponible. Los encuentros vencidos se guardan en `save_data.ClearedEncounters`, así que reaparecer en un faro no hace que el indicador vuelva atrás. En el HUD se muestra "Objetivo: … · N m".

## Modelos 3D propios (Fase 6)

Modelos originales hechos por código (`tools/generar_modelos.py`), sin recursos de terceros. Los OBJ y sus vistas previas están en `Assets/Modelos/`; en UEFN están importados en `Content/Modelos/` (malla + materiales por color).

- Regenerar: `python3 tools/generar_modelos.py Assets/Modelos` y `python3 tools/previsualizar.py Assets/Modelos` (vistas `_vista.png`). Después, en UEFN: filtrar *Malla estática*, seleccionar las 18 mallas › clic derecho › **Reimportar**.
- Ejes: el importador OBJ de UEFN no convierte Y-arriba; el generador ya escribe los vértices como (adelante, lado, alto) para que el modelo quede de pie y mirando a +X (Adelante).
- Cada malla tiene un Blueprint `PB_<Nombre>` (clase padre **Malla estática de construcción**, `BuildingSMActor`) con la malla puesta en *Valores predeterminados de clase › Malla estática*. Colocados en el nivel, Verse los acepta como `creative_prop`.

| Actor en el nivel | Uso | Posición (Izq, Arriba, Adelante) |
|---|---|---|
| PB Badajo, PB CoroHueco, PB Diapason, PB EcoErrante, PB Fuelle, PB GargolaCoral | Almacén de modelos de enemigo (ocultos al empezar) | Izq −2000, −1600, −1200, −800, −400, 0 · Arriba 0 · Adelante −10500 |
| PB MetronomoRoto, PB SopranoHueca, PB Sordina, PB Yunque | Ídem | Izq 600, 1200, 1700, 2100 · Adelante −10500 |
| PB Joel / PB Kesh | `HeroProps[0]` / `HeroProps[1]` en la arena | (−1050, 0, −8380) / (−550, 0, −8380) |
| Graybox Wall Small C10 / C11 | Antiguos modelos provisionales de Joel y Kesh, retirados | Arriba −3000 |

`battle manager` › **EnemyModels** (10 elementos, `Kind` + `Prop` + `YawDegrees` = 180): Badajo, Coro Hueco, Sordina, Metrónomo Roto, Soprano Hueca, Yunque, Fuelle, Diapasón, Eco Errante, Gárgola Coral, cada uno con su `PB`. Al empezar un combate, `BuildEnemies` lleva el modelo de cada tipo al hueco de la arena (`EnemyProp`, `ExtraEnemyProps`), oculta el prop provisional de ese hueco y lo gira hacia la cámara. Si un tipo no tiene modelo, se usa el prop provisional como antes. Al empezar la partida y antes de cada combate, los modelos vuelven al almacén ocultos.

Las 5 espadas (`PB_Espada_*`) están creadas pero aún no colocadas: pensadas para el equipo de los héroes o como decoración.
