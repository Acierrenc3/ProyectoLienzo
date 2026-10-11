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

El `battle_manager` tiene **"Visible en partida" desactivado**.

## Cómo probar
1. **Abrir sesión** en UEFN y entrar en la isla.
2. Pisar el **Activador** → teletransporte a la arena con cámara fija.
3. Menú: Atacar / Redoble (3 PA) / Tónico / Huir.
4. Turno del Badajo: el bloque retrocede y embiste. Pulsar **espacio** justo antes del impacto:
   - ≤ 0,20 s antes → **Contratiempo** (sin daño, +1 PA, contraataque)
   - ≤ 0,40 s antes → **Esquiva** (sin daño)
   - antes de eso, o sin pulsar → recibes el golpe.
