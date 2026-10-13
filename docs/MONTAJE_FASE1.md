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
