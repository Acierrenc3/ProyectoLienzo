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

### Ambientación de las zonas (prefabricados de Fortnite)

Cada prefabricado tiene un actor raíz ("Raíz de set de juego"); moviendo la raíz se mueve todo el conjunto.

| Zona | Prefabricado (carpeta Prefabricados) | Raíz en (Izq, Arriba, Adelante) |
|---|---|---|
| Puerto Calma | Faro › Lockie's Lighthouse | (1536, 0, -512) |
| Fundición | Fábrica › Slant (taller de ladrillo) | (-2560, 0, 1024) |
| Torre | Fortaleza Feudal › Castillo de Fortaleza Feudal | (700, 0, 3600) |

Descartados: la fábrica grande (703 piezas, tapaba los encuentros) y la plaza de la Fortaleza (demasiado pesada).

## Música (Fase 5)

Tres dispositivos **Radio** junto a la consola; `battle_manager` los enciende y apaga desde Verse.

| Campo | Dispositivo | Pista | Ajustes |
|---|---|---|---|
| `ExploreMusic` | Radio | Music_StW_Ambient_Login01 | Sin límite de distancia · fundidos de 1 s |
| `BattleMusic` | Radio2 | Music_StW_Low_Combat01 | Igual |
| `BossMusic` | Radio3 | Music_StW_High_Combat01 | Igual |
