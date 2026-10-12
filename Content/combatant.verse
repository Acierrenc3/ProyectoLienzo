# combatant.verse — Participantes del combate (héroes y enemigos) y sus estados.
# Valores iniciales: docs/DISENO.md
using { /Verse.org/Random }

# Patrón de ataque enemigo: uno o varios golpes seguidos (combo).
attack_pattern := class:
    Name:string = "Golpe"
    # Duración aleatoria de la preparación del primer golpe (segundos).
    MinWindup:float = 1.0
    MaxWindup:float = 2.0
    # Tiempo entre los golpes siguientes del combo. Vacío = un solo golpe.
    FollowUpGaps:[]float = array{}
    # Daño de cada golpe respecto al ataque normal.
    HitMultiplier:float = 1.0
    # Turnos de Debilidad que aplica al héroe si el golpe entra.
    WeakTurns:int = 0

# Un participante del combate. Se usa igual para héroes y enemigos.
combatant := class:
    Name:string
    MaxHP:int
    Attack:int
    Defense:int
    Speed:int
    Pattern:attack_pattern = attack_pattern{}

    var HP:int = 0
    # Estados alterados (turnos restantes).
    var BurnTurns:int = 0     # Quemadura: pierde un 6 % de la vida máxima al empezar su turno
    var StunTurns:int = 0     # Aturdimiento: pierde su turno
    var WeakTurns:int = 0     # Debilidad: hace un 25 % menos de daño
    # Ritmo (mecánica de Oria): sube con esquivas y Contratiempos, se reinicia al recibir un golpe.
    var Rhythm:int = 0

    # Deja el combatiente listo para un combate nuevo.
    ResetForBattle():void =
        set HP = MaxHP
        set BurnTurns = 0
        set StunTurns = 0
        set WeakTurns = 0
        set Rhythm = 0

    # Tiene éxito si el combatiente está fuera de combate.
    IsDefeated()<transacts><decides>:void =
        HP <= 0

    # Resta vida sin bajar de 0.
    TakeDamage(Amount:int):void =
        set HP = Max(HP - Amount, 0)

    # Suma vida sin pasar del máximo.
    Heal(Amount:int):void =
        set HP = Min(HP + Amount, MaxHP)

    # Multiplicador de daño propio: +10 % por punto de Ritmo, -25 % si está Débil.
    DamageModifier()<transacts>:float =
        var Modifier:float = 1.0 + Rhythm * 0.1
        if (WeakTurns > 0):
            set Modifier = Modifier * 0.75
        Modifier

    # Inicio del turno: aplica la Quemadura y reduce Debilidad. Devuelve el daño por Quemadura.
    StartTurn():int =
        var BurnDamage:int = 0
        if (BurnTurns > 0):
            if (Amount := Floor[MaxHP * 0.06]):
                set BurnDamage = Max(Amount, 1)
            else:
                set BurnDamage = 1
            TakeDamage(BurnDamage)
            set BurnTurns = BurnTurns - 1
        if (WeakTurns > 0):
            set WeakTurns = WeakTurns - 1
        BurnDamage

    # Texto corto con los estados activos, p. ej. " [Quemadura 2] [Débil 1]".
    StatusText():string =
        var Text:string = ""
        if (BurnTurns > 0):
            set Text = Text + " [Quemadura {BurnTurns}]"
        if (StunTurns > 0):
            set Text = Text + " [Aturdido]"
        if (WeakTurns > 0):
            set Text = Text + " [Débil {WeakTurns}]"
        Text

# Daño = Ataque x Multiplicador x Modificador propio x (variación ±10 %) - Defensa. Mínimo 1.
CalculateDamage(Attacker:combatant, Defender:combatant, Multiplier:float)<transacts>:int =
    Raw := Attacker.Attack * 1.0 * Multiplier * Attacker.DamageModifier() * GetRandomFloat(0.9, 1.1) - Defender.Defense * 1.0
    if (Rounded := Round[Raw]):
        Max(Rounded, 1)
    else:
        1
