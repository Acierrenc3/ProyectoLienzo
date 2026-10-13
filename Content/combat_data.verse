# combat_data.verse — Datos del juego: héroes, habilidades y enemigos.
# Para añadir contenido basta con tocar este archivo. Fuente de los números: docs/DISENO.md

# Habilidad de un héroe.
skill := class:
    Name:string
    Cost:int                        # Puntos de acción
    Multiplier:float = 0.0          # Daño respecto al ataque normal (0 = no hace daño)
    HitsAll:logic = false           # Golpea a todos los enemigos
    TargetsAlly:logic = false       # Se usa sobre un aliado (curar, dar PA)
    HealAmount:int = 0              # Vida que cura al aliado
    GiveAP:int = 0                  # PA que da al aliado
    BurnTurns:int = 0               # Quemadura al enemigo
    StunTurns:int = 0               # Aturdimiento al enemigo
    WeakTurns:int = 0               # Debilidad al enemigo
    HarmonyTurns:int = 0            # Armonía: el grupo hace +25 % de daño durante N rondas
    SelfCostPercent:float = 0.0     # Coste en vida propia (Kesh), fracción de la vida máxima

hero_kind := enum:
    Oria
    Joel
    Kesh

# Orden del grupo (y de las ranuras de guardado).
PartyOrder()<computes>:[]hero_kind =
    array{hero_kind.Oria, hero_kind.Joel, hero_kind.Kesh}

# Experiencia necesaria para pasar del nivel indicado al siguiente.
XPToNext(Level:int)<computes>:int =
    40 + Level * 30

MaxLevel()<computes>:int = 20

# --- Equipo ---
# Partituras: efectos pasivos equipables (una por héroe).
partitura := enum:
    Ninguna
    Eco         # Empieza cada combate con 2 PA
    Serena      # +15 % de vida máxima
    Rapida      # +4 de velocidad
    Firme       # +4 de defensa
    Ardiente    # Los ataques normales queman 2 turnos

AllPartituras()<computes>:[]partitura =
    array{partitura.Eco, partitura.Serena, partitura.Rapida, partitura.Firme, partitura.Ardiente}

PartituraName(P:partitura)<computes>:string =
    if (P = partitura.Eco) then "Partitura del Eco"
    else if (P = partitura.Serena) then "Partitura Serena"
    else if (P = partitura.Rapida) then "Partitura Presto"
    else if (P = partitura.Firme) then "Partitura Firme"
    else if (P = partitura.Ardiente) then "Partitura Ardiente"
    else "Ninguna"

PartituraDesc(P:partitura)<computes>:string =
    if (P = partitura.Eco) then "(empieza el combate con 2 PA)"
    else if (P = partitura.Serena) then "(+15 % de vida máxima)"
    else if (P = partitura.Rapida) then "(+4 de velocidad)"
    else if (P = partitura.Firme) then "(+4 de defensa)"
    else if (P = partitura.Ardiente) then "(los ataques normales queman)"
    else ""

# Conversión para el guardado (las partituras se guardan como números).
PartituraToInt(P:partitura)<computes>:int =
    if (P = partitura.Eco) then 1
    else if (P = partitura.Serena) then 2
    else if (P = partitura.Rapida) then 3
    else if (P = partitura.Firme) then 4
    else if (P = partitura.Ardiente) then 5
    else 0

PartituraFromInt(I:int)<computes>:partitura =
    if (I = 1) then partitura.Eco
    else if (I = 2) then partitura.Serena
    else if (I = 3) then partitura.Rapida
    else if (I = 4) then partitura.Firme
    else if (I = 5) then partitura.Ardiente
    else partitura.Ninguna

MaxInstrumentTier()<computes>:int = 3

# Instrumento de cada héroe (su arma). Cada mejora da +3 de ataque.
InstrumentName(HeroKind:hero_kind, HeroTier:int)<computes>:string =
    Base := if (HeroKind = hero_kind.Joel) then "Diapasón" else if (HeroKind = hero_kind.Kesh) then "Campanillas rotas" else "Martillo-tambor"
    if (HeroTier > 0) then "{Base} +{HeroTier}" else Base

# --- Héroes (estadísticas según nivel, instrumento y partitura) ---
MakeHero(HeroKind:hero_kind, HeroLevel:int, HeroTier:int, HeroPart:partitura):combatant =
    L := Max(HeroLevel, 1) - 1
    var NameV:string = "Oria"
    var HPV:int = 120 + 12 * L
    var AtkV:int = 18 + 2 * L
    var DefV:int = 6 + L
    var SpdV:int = 10
    var SkillsV:[]skill = OriaSkills()
    var RhythmV:logic = true
    if (HeroKind = hero_kind.Joel):
        set NameV = "Joel"
        set HPV = 95 + 9 * L
        set AtkV = 12 + L
        set DefV = 5 + L
        set SpdV = 12
        set SkillsV = JoelSkills()
        set RhythmV = false
    else if (HeroKind = hero_kind.Kesh):
        set NameV = "Kesh"
        set HPV = 85 + 8 * L
        set AtkV = 20 + 2 * L
        set DefV = 3 + L
        set SpdV = 14
        set SkillsV = KeshSkills()
        set RhythmV = false
    TierV := Min(Max(HeroTier, 0), MaxInstrumentTier())
    set AtkV = AtkV + 3 * TierV
    if (HeroPart = partitura.Serena, Bonus := Floor[HPV * 0.15]):
        set HPV = HPV + Bonus
    if (HeroPart = partitura.Rapida):
        set SpdV = SpdV + 4
    if (HeroPart = partitura.Firme):
        set DefV = DefV + 4
    StartAPV := if (HeroPart = partitura.Eco) then 2 else 0
    combatant:
        Name := NameV
        Kind := HeroKind
        Level := L + 1
        MaxHP := HPV
        Attack := AtkV
        Defense := DefV
        Speed := SpdV
        Skills := SkillsV
        UsesRhythm := RhythmV
        Tier := TierV
        Equipped := HeroPart
        StartAP := StartAPV
        BurnOnAttack := logic{HeroPart = partitura.Ardiente}

# Oria, la Percusionista: daño.
OriaSkills():[]skill =
    array{
        skill{Name := "Redoble", Cost := 3, Multiplier := 2.5},
        skill{Name := "Golpe Sordo", Cost := 2, Multiplier := 1.2, StunTurns := 1},
        skill{Name := "Tambor Ígneo", Cost := 4, Multiplier := 0.9, HitsAll := true, BurnTurns := 3}
    }

# Joel, el Afinador: apoyo.
JoelSkills():[]skill =
    array{
        skill{Name := "Afinar", Cost := 2, TargetsAlly := true, HealAmount := 35},
        skill{Name := "Diapasón", Cost := 1, TargetsAlly := true, GiveAP := 2},
        skill{Name := "Armonía", Cost := 3, HarmonyTurns := 2}
    }

# Kesh, la Callada: control (sus habilidades le cuestan vida).
KeshSkills():[]skill =
    array{
        skill{Name := "Campanillas", Cost := 2, Multiplier := 1.3, WeakTurns := 2},
        skill{Name := "Eco del Silencio", Cost := 2, Multiplier := 0.5, StunTurns := 1, SelfCostPercent := 0.10},
        skill{Name := "Réquiem", Cost := 5, Multiplier := 1.8, HitsAll := true, SelfCostPercent := 0.20}
    }

# --- Enemigos (los Mudos) ---
# Badajo: golpes lentos y pesados.
MakeBadajo():combatant =
    combatant:
        Name := "Badajo"
        MaxHP := 150
        Attack := 22
        Defense := 4
        Speed := 7
        XPReward := 30
        Pattern := attack_pattern{Name := "Campanazo", MinWindup := 1.2, MaxWindup := 2.0}

# Coro Hueco: combo de tres golpes rápidos (en canon).
MakeCoroHueco():combatant =
    combatant:
        Name := "Coro Hueco"
        MaxHP := 90
        Attack := 12
        Defense := 2
        Speed := 9
        XPReward := 25
        Pattern := attack_pattern{Name := "Canon", MinWindup := 1.0, MaxWindup := 1.6, FollowUpGaps := array{0.7, 0.5}, HitMultiplier := 0.7}

# Sordina: si su golpe entra, deja al héroe Débil.
MakeSordina():combatant =
    combatant:
        Name := "Sordina"
        MaxHP := 70
        Attack := 10
        Defense := 3
        Speed := 8
        XPReward := 20
        Pattern := attack_pattern{Name := "Apagón", MinWindup := 0.9, MaxWindup := 1.5, WeakTurns := 2}

# --- Mudos de la Fundición (zona 2) ---
# Yunque: muy lento, pero tras el primer golpe repite casi sin aviso.
MakeYunque():combatant =
    combatant:
        Name := "Yunque"
        MaxHP := 220
        Attack := 28
        Defense := 7
        Speed := 5
        XPReward := 45
        Pattern := attack_pattern{Name := "Martillazo", MinWindup := 1.6, MaxWindup := 2.6, FollowUpGaps := array{0.4}, HitMultiplier := 0.8}

# Fuelle: rápido e impredecible; su aviso puede ser muy corto o muy largo.
MakeFuelle():combatant =
    combatant:
        Name := "Fuelle"
        MaxHP := 80
        Attack := 14
        Defense := 2
        Speed := 12
        XPReward := 30
        Pattern := attack_pattern{Name := "Soplido", MinWindup := 0.5, MaxWindup := 2.4}

# Diapasón: su vibración alcanza a todo el grupo.
MakeDiapason():combatant =
    combatant:
        Name := "Diapasón"
        MaxHP := 110
        Attack := 13
        Defense := 4
        Speed := 10
        XPReward := 40
        Pattern := attack_pattern{Name := "Vibración", MinWindup := 1.1, MaxWindup := 1.7, HitsAllHeroes := true, HitMultiplier := 0.7}

# --- Mudos de la Torre (zona 3) ---
# Eco Errante: cuatro golpes seguidos con el mismo ritmo; si entran, debilitan.
MakeEcoErrante():combatant =
    combatant:
        Name := "Eco Errante"
        MaxHP := 100
        Attack := 11
        Defense := 3
        Speed := 13
        XPReward := 45
        Pattern := attack_pattern{Name := "Reverberación", MinWindup := 1.0, MaxWindup := 1.4, FollowUpGaps := array{0.45, 0.45, 0.45}, HitMultiplier := 0.55, WeakTurns := 1}

# Gárgola Coral: muy resistente; grita dos veces a todo el grupo.
MakeGargola():combatant =
    combatant:
        Name := "Gárgola Coral"
        MaxHP := 260
        Attack := 20
        Defense := 9
        Speed := 6
        XPReward := 60
        Pattern := attack_pattern{Name := "Grito de piedra", MinWindup := 1.3, MaxWindup := 2.0, FollowUpGaps := array{0.9}, HitsAllHeroes := true, HitMultiplier := 0.65}

# --- Jefes del Acto 1 ---
# El Metrónomo Roto: máquina gigante. En la segunda fase acelera el tempo (avisos más cortos y combos).
MakeMetronomo():combatant =
    combatant:
        Name := "Metrónomo Roto"
        MaxHP := 600
        Attack := 26
        Defense := 6
        Speed := 8
        XPReward := 150
        Pattern := attack_pattern{Name := "Péndulo", MinWindup := 1.4, MaxWindup := 2.2, FollowUpGaps := array{1.0}}
        HasPhase2 := true
        Phase2Pattern := attack_pattern{Name := "Allegro", MinWindup := 0.8, MaxWindup := 1.2, FollowUpGaps := array{0.6, 0.6, 0.45}, HitMultiplier := 0.75}
        Phase2Message := "¡El Metrónomo Roto acelera el tempo!"

# La Soprano Hueca: sus gritos alcanzan a todo el grupo. En la segunda fase grita en oleadas.
MakeSoprano():combatant =
    combatant:
        Name := "Soprano Hueca"
        MaxHP := 750
        Attack := 24
        Defense := 5
        Speed := 11
        XPReward := 220
        Pattern := attack_pattern{Name := "Aria", MinWindup := 1.2, MaxWindup := 1.8, HitsAllHeroes := true, HitMultiplier := 0.8}
        HasPhase2 := true
        Phase2Pattern := attack_pattern{Name := "Coloratura", MinWindup := 1.0, MaxWindup := 1.5, FollowUpGaps := array{0.8, 0.55, 0.55}, HitsAllHeroes := true, HitMultiplier := 0.6, WeakTurns := 1}
        Phase2Message := "¡La Soprano Hueca alcanza notas imposibles!"

# Tipos de enemigo que se pueden elegir en el editor para cada encuentro.
enemy_kind := enum:
    Badajo
    CoroHueco
    Sordina
    MetronomoRoto
    SopranoHueca
    Yunque
    Fuelle
    Diapason
    EcoErrante
    GargolaCoral

MakeEnemy(EnemyKind:enemy_kind):combatant =
    if (EnemyKind = enemy_kind.CoroHueco):
        MakeCoroHueco()
    else if (EnemyKind = enemy_kind.Sordina):
        MakeSordina()
    else if (EnemyKind = enemy_kind.MetronomoRoto):
        MakeMetronomo()
    else if (EnemyKind = enemy_kind.SopranoHueca):
        MakeSoprano()
    else if (EnemyKind = enemy_kind.Yunque):
        MakeYunque()
    else if (EnemyKind = enemy_kind.Fuelle):
        MakeFuelle()
    else if (EnemyKind = enemy_kind.Diapason):
        MakeDiapason()
    else if (EnemyKind = enemy_kind.EcoErrante):
        MakeEcoErrante()
    else if (EnemyKind = enemy_kind.GargolaCoral):
        MakeGargola()
    else:
        MakeBadajo()

# Encuentro de prueba (Activador y AutoStartDelay): los tres Mudos.
TestEncounter():[]enemy_kind =
    array{enemy_kind.Badajo, enemy_kind.CoroHueco, enemy_kind.Sordina}
