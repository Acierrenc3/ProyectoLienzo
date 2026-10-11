# combatant.verse — Participantes del combate (héroes y enemigos).
# Valores iniciales: docs/DISENO.md
using { /Verse.org/Random }

# Un participante del combate. Se usa igual para héroes y enemigos.
combatant := class:
    Name:string
    MaxHP:int
    Attack:int
    Defense:int
    Speed:int
    var HP:int = 0

    # Restaura la vida al máximo (al empezar cada combate).
    ResetHP():void =
        set HP = MaxHP

    # Tiene éxito si el combatiente está fuera de combate.
    IsDefeated()<transacts><decides>:void =
        HP <= 0

    # Resta vida sin bajar de 0.
    TakeDamage(Amount:int):void =
        set HP = Max(HP - Amount, 0)

    # Suma vida sin pasar del máximo.
    Heal(Amount:int):void =
        set HP = Min(HP + Amount, MaxHP)

# Daño = Ataque x Multiplicador x (variación ±10 %) - Defensa. Mínimo 1.
CalculateDamage(Attacker:combatant, Defender:combatant, Multiplier:float)<transacts>:int =
    Raw := Attacker.Attack * 1.0 * Multiplier * GetRandomFloat(0.9, 1.1) - Defender.Defense * 1.0
    if (Rounded := Round[Raw]):
        Max(Rounded, 1)
    else:
        1

# --- Héroes ---
MakeOria():combatant =
    combatant{Name := "Oria", MaxHP := 120, Attack := 18, Defense := 6, Speed := 10}

# --- Enemigos (los Mudos) ---
MakeBadajo():combatant =
    combatant{Name := "Badajo", MaxHP := 150, Attack := 22, Defense := 4, Speed := 7}
