# world.verse — Elementos del mapa de exploración (Fase 3).
# Todos usan un prop como marcador: el juego detecta la cercanía del jugador, sin dispositivos extra.
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Un encuentro: al acercarse al marcador empieza un combate contra los enemigos indicados.
encounter_spot := class<concrete>:
    @editable Marker:creative_prop = creative_prop{}
    # Enemigos del combate (1 a 3), en el orden de los props de la arena.
    @editable Enemies:[]enemy_kind = array{enemy_kind.Badajo}
    var Defeated:logic = false
    # Se desarma tras huir: hay que alejarse para que vuelva a activarse.
    var Armed:logic = true

# Un punto de descanso (faro): cura del todo, guarda el punto de reaparición y reaparecen los enemigos.
rest_spot := class<concrete>:
    @editable Marker:creative_prop = creative_prop{}
    var Armed:logic = true

# Un cofre: da tónicos, una partitura y/o Resina la primera vez que te acercas.
chest_spot := class<concrete>:
    @editable Marker:creative_prop = creative_prop{}
    @editable Tonics:int = 1
    # Partitura que contiene (Ninguna = no contiene).
    @editable Partitura:partitura = partitura.Ninguna
    # Resina de la Campana: mejora un nivel el instrumento de todo el grupo.
    @editable UpgradesInstruments:logic = false
    var Opened:logic = false
