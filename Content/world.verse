# world.verse — Elementos del mapa de exploración (Fase 3).
# Todos usan un prop como marcador: el juego detecta la cercanía del jugador, sin dispositivos extra.
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Un encuentro: al acercarse al marcador empieza un combate contra los enemigos indicados.
encounter_spot := class<concrete>:
    @editable Marker:creative_prop = creative_prop{}
    # Enemigos del combate (1 a 3), en el orden de los props de la arena.
    @editable Enemies:[]enemy_kind = array{enemy_kind.Badajo}
    # Jefe: no reaparece en los faros y al vencerlo activa SetFlagOnWin.
    @editable IsBoss:logic = false
    # Solo aparece si la historia ha llegado a esta marca (0 = siempre).
    @editable RequiredFlag:int = 0
    @editable SetFlagOnWin:int = 0
    # Diálogo antes del combate (formato "Nombre: texto").
    @editable IntroLines:[]string = array{}
    var Defeated:logic = false
    # Se desarma tras huir: hay que alejarse para que vuelva a activarse.
    var Armed:logic = true

# Quién se une al grupo en un evento de historia.
party_join := enum:
    Nadie
    Joel
    Kesh

# Un evento de historia: al acercarse se muestra un diálogo (una sola vez).
story_event := class<concrete>:
    @editable Marker:creative_prop = creative_prop{}
    # Líneas del diálogo, formato "Nombre: texto".
    @editable Lines:[]string = array{}
    # Solo se activa si la historia ha llegado a esta marca (0 = siempre).
    @editable RequiredFlag:int = 0
    # Marca que se activa al terminar el diálogo (0 = ninguna).
    @editable SetFlag:int = 0
    @editable Joins:party_join = party_join.Nadie

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
