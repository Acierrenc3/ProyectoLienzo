# combat_data.verse — Datos del juego: héroes, habilidades y enemigos.
# Para añadir contenido basta con tocar este archivo. Fuente de los números: docs/DISENO.md

# Habilidad de un héroe.
skill := class:
    Name:string
    Cost:int                  # Puntos de acción
    Multiplier:float          # Daño respecto al ataque normal
    HitsAll:logic = false     # true = golpea a todos los enemigos
    BurnTurns:int = 0         # Turnos de Quemadura que aplica
    StunTurns:int = 0         # Turnos de Aturdimiento que aplica

# --- Héroes ---
MakeOria():combatant =
    combatant{Name := "Oria", MaxHP := 120, Attack := 18, Defense := 6, Speed := 10}

OriaSkills():[]skill =
    array{
        skill{Name := "Redoble", Cost := 3, Multiplier := 2.5},
        skill{Name := "Golpe Sordo", Cost := 2, Multiplier := 1.2, StunTurns := 1},
        skill{Name := "Tambor Ígneo", Cost := 4, Multiplier := 0.9, HitsAll := true, BurnTurns := 3}
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
        Pattern := attack_pattern{Name := "Campanazo", MinWindup := 1.2, MaxWindup := 2.0}

# Coro Hueco: combo de tres golpes rápidos (en canon).
MakeCoroHueco():combatant =
    combatant:
        Name := "Coro Hueco"
        MaxHP := 90
        Attack := 12
        Defense := 2
        Speed := 9
        Pattern := attack_pattern{Name := "Canon", MinWindup := 1.0, MaxWindup := 1.6, FollowUpGaps := array{0.7, 0.5}, HitMultiplier := 0.7}

# Sordina: si su golpe entra, deja al héroe Débil.
MakeSordina():combatant =
    combatant:
        Name := "Sordina"
        MaxHP := 70
        Attack := 10
        Defense := 3
        Speed := 8
        Pattern := attack_pattern{Name := "Apagón", MinWindup := 0.9, MaxWindup := 1.5, WeakTurns := 2}

# Orden en que aparecen los enemigos según los props colocados en la arena.
EncounterEnemies():[]combatant =
    array{MakeBadajo(), MakeCoroHueco(), MakeSordina()}
