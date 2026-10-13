# save_data.verse — Guardado persistente entre partidas (Fase 4).
# Los datos se guardan por jugador en un weak_map de ámbito de módulo.
using { /Verse.org/Simulation }

# Lo que se guarda. Las clases persistentes no admiten campos `var`: para cambiar algo, se crea una copia nueva.
save_data := class<final><persistable>:
    Version:int = 1
    # Nivel y experiencia de cada héroe, en el orden de PartyOrder().
    Levels:[]int = array{1, 1, 1}
    XPs:[]int = array{0, 0, 0}
    Items:int = 2
    # Equipo (por héroe, en el orden de PartyOrder()). Partituras guardadas como números.
    Tiers:[]int = array{0, 0, 0}
    Equipped:[]int = array{0, 0, 0}
    Owned:[]int = array{}
    # Índices de los cofres ya abiertos.
    OpenedChests:[]int = array{}
    # Índices de los encuentros vencidos al menos una vez (para el indicador de objetivos).
    ClearedEncounters:[]int = array{}
    # Historia: héroes en el grupo y marcas alcanzadas.
    PartySize:int = 1
    Flags:[]int = array{}
    # Último faro visitado (punto de reaparición).
    HasRespawn:logic = false
    RespawnX:float = 0.0
    RespawnY:float = 0.0
    RespawnZ:float = 0.0

var SaveTable:weak_map(player, save_data) = map{}
