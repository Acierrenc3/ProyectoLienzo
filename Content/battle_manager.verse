# battle_manager.verse — Gestor del combate por turnos (Fase 2: Oria contra hasta 3 Mudos).
#
# Dispositivos que hay que colocar en UEFN y enlazar en el panel Detalles:
#   StartTrigger     (trigger_device)                      -> al pisarlo empieza el combate
#   ArenaSpot        (teleporter_device)                   -> posición del jugador en la arena
#   ReturnSpot       (teleporter_device)                   -> adonde vuelve el jugador al terminar
#   BattleCamera     (gameplay_camera_fixed_point_device)  -> cámara fija de la arena
#   DodgeInput       (input_trigger_device)                -> tecla de esquiva / bloqueo
#   EnemyProp        (creative_prop)                       -> modelo del primer enemigo (Badajo)
#   ExtraEnemyProps  ([]creative_prop, opcional)           -> modelos del 2.º y 3.er enemigo
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Resultado de la reacción del jugador a un golpe enemigo.
dodge_result := enum:
    Miss    # No pulsó: recibe el golpe
    Early   # Pulsó demasiado pronto: recibe el golpe
    Dodge   # Esquiva: evita el daño, +1 Ritmo
    Parry   # Contratiempo: bloqueo perfecto, +1 PA, +2 Ritmo y contraataque

battle_outcome := enum:
    Victory
    Defeat
    Fled

# Un enemigo en la arena: sus datos, su modelo y su posición inicial.
enemy_slot := class:
    Fighter:combatant
    Prop:creative_prop
    Home:transform

battle_manager := class(creative_device):

    @editable StartTrigger:trigger_device = trigger_device{}
    @editable ArenaSpot:teleporter_device = teleporter_device{}
    @editable ReturnSpot:teleporter_device = teleporter_device{}
    @editable BattleCamera:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable DodgeInput:input_trigger_device = input_trigger_device{}
    @editable EnemyProp:creative_prop = creative_prop{}
    @editable ExtraEnemyProps:[]creative_prop = array{}

    # Ventanas de reacción en segundos antes del impacto (ver docs/DISENO.md).
    @editable DodgeWindow:float = 0.40
    @editable ParryWindow:float = 0.20
    # Margen tras el impacto que aún cuenta (compensa la latencia).
    @editable LateGrace:float = 0.08
    # PRUEBAS: si es mayor que 0, el combate empieza solo tras estos segundos. Poner -1 antes de publicar.
    @editable AutoStartDelay:float = 4.0

    CounterMultiplier:float = 0.5
    MaxAP:int = 9
    MaxRhythm:int = 10
    StartingItems:int = 2
    TonicHeal:int = 40
    LungeTime:float = 0.25

    var InBattle:logic = false
    var AP:int = 0
    var Items:int = 0

    OnBegin<override>()<suspends>:void =
        StartTrigger.TriggeredEvent.Subscribe(OnStartTriggered)
        if (AutoStartDelay > 0.0):
            Sleep(AutoStartDelay)
            loop:
                if (Player := GetPlayspace().GetPlayers()[0]):
                    if (not InBattle?):
                        set InBattle = true
                        spawn{ RunBattle(Player) }
                    break
                Sleep(1.0)

    OnStartTriggered(MaybeAgent:?agent):void =
        if (not InBattle?, Agent := MaybeAgent?, Player := player[Agent]):
            set InBattle = true
            spawn{ RunBattle(Player) }

    # Crea los enemigos del encuentro: uno por cada prop colocado (máximo 3).
    BuildEnemies():[]enemy_slot =
        Props:[]creative_prop = array{EnemyProp} + ExtraEnemyProps
        Fighters := EncounterEnemies()
        for (Index -> Prop : Props, Fighter := Fighters[Index]):
            Fighter.ResetForBattle()
            enemy_slot{Fighter := Fighter, Prop := Prop, Home := Prop.GetTransform()}

    # Combate completo: entrar en la arena, jugar los turnos y volver.
    RunBattle(Player:player)<suspends>:void =
        if (UI := GetPlayerUI[Player]):
            Hero := MakeOria()
            Hero.ResetForBattle()
            Enemies := BuildEnemies()
            set AP = 0
            set Items = StartingItems

            Screen := battle_ui{PlayerUI := UI}
            Screen.Init()
            EnterArena(Player, Enemies)
            Screen.Show()
            Refresh(Screen, Hero, Enemies)
            if (Enemies.Length > 1):
                Screen.SetMessage("¡Los Mudos te rodean!")
            else:
                Screen.SetMessage("¡Un Mudo bloquea el camino!")
            Sleep(1.5)

            Outcome := BattleLoop(Hero, Enemies, Screen)
            Screen.HideMenu()
            if (Outcome = battle_outcome.Victory):
                Screen.SetMessage("¡Victoria! Los Mudos vuelven a ser piedra.")
            else if (Outcome = battle_outcome.Defeat):
                Screen.SetMessage("Derrota... El Silencio te alcanza.")
            else:
                Screen.SetMessage("Huyes del combate.")
            Sleep(3.0)

            Screen.Hide()
            ExitArena(Player, Enemies)
        set InBattle = false

    EnterArena(Player:player, Enemies:[]enemy_slot):void =
        for (Slot : Enemies):
            Slot.Prop.Show()
            if (Slot.Prop.TeleportTo[Slot.Home]) {}
        ArenaSpot.Teleport(Player)
        BattleCamera.AddTo(Player)
        if (Character := Player.GetFortCharacter[]):
            Character.PutInStasis(stasis_args{AllowTurning := false, AllowFalling := true, AllowEmotes := false})

    ExitArena(Player:player, Enemies:[]enemy_slot):void =
        if (Character := Player.GetFortCharacter[]):
            Character.ReleaseFromStasis()
        BattleCamera.RemoveFrom(Player)
        ReturnSpot.Teleport(Player)
        for (Slot : Enemies):
            Slot.Prop.Show()
            if (Slot.Prop.TeleportTo[Slot.Home]) {}

    # Bucle de turnos: el jugador y luego cada enemigo, hasta que un bando cae o el jugador huye.
    BattleLoop(Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:battle_outcome =
        var Outcome:battle_outcome = battle_outcome.Fled
        loop:
            # --- Turno del jugador ---
            Burn := Hero.StartTurn()
            Refresh(Screen, Hero, Enemies)
            if (Burn > 0):
                Screen.SetMessage("La quemadura te hace {Burn} de daño.")
                Sleep(1.0)
            if (Hero.IsDefeated[]):
                set Outcome = battle_outcome.Defeat
                break

            Fled := PlayerTurn(Hero, Enemies, Screen)
            if (Fled?):
                set Outcome = battle_outcome.Fled
                break
            Refresh(Screen, Hero, Enemies)
            Sleep(1.2)
            if (AliveCount(Enemies) = 0):
                set Outcome = battle_outcome.Victory
                break

            # --- Turno de los enemigos ---
            var EnemyIndex:int = 0
            loop:
                if (EnemyIndex >= Enemies.Length):
                    break
                if (Slot := Enemies[EnemyIndex], not Slot.Fighter.IsDefeated[], not Hero.IsDefeated[]):
                    EnemyTurn(Slot, Hero, Enemies, Screen)
                set EnemyIndex = EnemyIndex + 1
            Refresh(Screen, Hero, Enemies)
            if (Hero.IsDefeated[]):
                set Outcome = battle_outcome.Defeat
                break
            if (AliveCount(Enemies) = 0):
                set Outcome = battle_outcome.Victory
                break
        Outcome

    # Turno del jugador. Devuelve true si huye.
    PlayerTurn(Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:logic =
        Skills := OriaSkills()
        var Fled:logic = false
        loop:
            Screen.SetMessage("Tu turno: elige una acción.")
            CanUseSkill := logic{AnySkillAffordable[Skills]}
            Main := Screen.Ask(
                array{"Atacar", "Habilidades", "Tónico (x{Items})", "Huir"},
                array{true, CanUseSkill, logic{Items > 0}, true},
                false)

            if (Main = 0):
                MaybeTarget := ChooseTarget(Enemies, Screen)
                if (Target := MaybeTarget?):
                    Screen.HideMenu()
                    Damage := CalculateDamage(Hero, Target.Fighter, 1.0)
                    Target.Fighter.TakeDamage(Damage)
                    set AP = Min(AP + 1, MaxAP)
                    Screen.SetMessage("{Hero.Name} golpea a {Target.Fighter.Name}: {Damage} de daño.")
                    CheckDefeated(Target)
                    break
            else if (Main = 1):
                MaybeSkill := ChooseSkill(Skills, Screen)
                if (ChosenSkill := MaybeSkill?):
                    Used := UseSkill(ChosenSkill, Hero, Enemies, Screen)
                    if (Used?):
                        break
            else if (Main = 2):
                if (Items > 0):
                    Screen.HideMenu()
                    set Items = Items - 1
                    Hero.Heal(TonicHeal)
                    Screen.SetMessage("{Hero.Name} bebe un tónico y recupera {TonicHeal} PV.")
                    break
            else if (Main = 3):
                Screen.HideMenu()
                set Fled = true
                break
        Fled

    # Submenú de habilidades. Devuelve la habilidad elegida o nada si pulsa Volver.
    ChooseSkill(Skills:[]skill, Screen:battle_ui)<suspends>:?skill =
        Labels := for (S : Skills) { "{S.Name} ({S.Cost} PA)" }
        Enabled := for (S : Skills) { logic{AP >= S.Cost} }
        Screen.SetMessage("Elige una habilidad.")
        Pick := Screen.Ask(Labels, Enabled, true)
        if (Chosen := Skills[Pick], AP >= Chosen.Cost):
            option{Chosen}
        else:
            false

    # Aplica una habilidad. Devuelve false si el jugador se echa atrás al elegir objetivo.
    UseSkill(Chosen:skill, Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:logic =
        if (Chosen.HitsAll?):
            Screen.HideMenu()
            set AP = AP - Chosen.Cost
            for (Slot : Enemies, not Slot.Fighter.IsDefeated[]):
                ApplySkillTo(Chosen, Hero, Slot)
            Screen.SetMessage("¡{Chosen.Name}! {Hero.Name} golpea a todos los enemigos.")
            true
        else:
            MaybeTarget := ChooseTarget(Enemies, Screen)
            if (Target := MaybeTarget?):
                Screen.HideMenu()
                set AP = AP - Chosen.Cost
                Damage := ApplySkillTo(Chosen, Hero, Target)
                Screen.SetMessage("¡{Chosen.Name}! {Target.Fighter.Name} recibe {Damage} de daño.")
                true
            else:
                false

    # Daño y estados de una habilidad sobre un enemigo. Devuelve el daño hecho.
    ApplySkillTo(Chosen:skill, Hero:combatant, Slot:enemy_slot):int =
        Damage := CalculateDamage(Hero, Slot.Fighter, Chosen.Multiplier)
        Slot.Fighter.TakeDamage(Damage)
        if (Chosen.BurnTurns > 0):
            set Slot.Fighter.BurnTurns = Max(Slot.Fighter.BurnTurns, Chosen.BurnTurns)
        if (Chosen.StunTurns > 0):
            set Slot.Fighter.StunTurns = Max(Slot.Fighter.StunTurns, Chosen.StunTurns)
        CheckDefeated(Slot)
        Damage

    # Elige objetivo. Con un solo enemigo vivo no pregunta.
    ChooseTarget(Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:?enemy_slot =
        Alive := for (Slot : Enemies, not Slot.Fighter.IsDefeated[]) { Slot }
        if (Alive.Length = 1, Only := Alive[0]):
            option{Only}
        else:
            Labels := for (Slot : Alive) { "{Slot.Fighter.Name} (PV {Slot.Fighter.HP})" }
            Screen.SetMessage("Elige un objetivo.")
            Pick := Screen.Ask(Labels, array{}, true)
            if (Target := Alive[Pick]):
                option{Target}
            else:
                false

    # Turno de un enemigo: Quemadura, Aturdimiento o ataque (con combo si lo tiene).
    EnemyTurn(Slot:enemy_slot, Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:void =
        Enemy := Slot.Fighter
        Burn := Enemy.StartTurn()
        if (Burn > 0):
            Screen.SetMessage("{Enemy.Name} arde: {Burn} de daño.")
            CheckDefeated(Slot)
            Refresh(Screen, Hero, Enemies)
            Sleep(1.0)
        if (Enemy.IsDefeated[]):
            return
        if (Enemy.StunTurns > 0):
            set Enemy.StunTurns = Enemy.StunTurns - 1
            Screen.SetMessage("{Enemy.Name} está aturdido y pierde su turno.")
            Sleep(1.2)
            return

        Pattern := Enemy.Pattern
        Hits := Pattern.FollowUpGaps.Length + 1
        if (Hits > 1):
            Screen.SetMessage("¡{Enemy.Name} prepara {Pattern.Name}! ({Hits} golpes) Pulsa justo antes de cada impacto.")
        else:
            Screen.SetMessage("¡{Enemy.Name} prepara {Pattern.Name}! Pulsa justo antes del impacto.")
        ResolveHit(Slot, Hero, Screen, GetRandomFloat(Pattern.MinWindup, Pattern.MaxWindup))
        Refresh(Screen, Hero, Enemies)
        var HitIndex:int = 0
        loop:
            if (HitIndex >= Pattern.FollowUpGaps.Length):
                break
            if (Gap := Pattern.FollowUpGaps[HitIndex], not Hero.IsDefeated[], not Enemy.IsDefeated[]):
                ResolveHit(Slot, Hero, Screen, Gap)
                Refresh(Screen, Hero, Enemies)
            set HitIndex = HitIndex + 1
        Sleep(1.2)

    # Un golpe enemigo con su ventana de reacción.
    ResolveHit(Slot:enemy_slot, Hero:combatant, Screen:battle_ui, Windup:float)<suspends>:void =
        Enemy := Slot.Fighter
        ImpactTime := GetSimulationElapsedTime() + Windup
        spawn{ AnimateAttack(Slot, Windup) }

        Result := WaitForReaction(ImpactTime)
        # Si el jugador reaccionó antes, esperamos al impacto para mostrar el resultado a tiempo.
        Remaining := ImpactTime - GetSimulationElapsedTime()
        if (Remaining > 0.0):
            Sleep(Remaining)

        if (Result = dodge_result.Parry):
            set AP = Min(AP + 1, MaxAP)
            set Hero.Rhythm = Min(Hero.Rhythm + 2, MaxRhythm)
            Counter := CalculateDamage(Hero, Enemy, CounterMultiplier)
            Enemy.TakeDamage(Counter)
            CheckDefeated(Slot)
            Screen.SetMessage("¡CONTRATIEMPO! Bloqueo perfecto y contraataque: {Counter} de daño.")
        else if (Result = dodge_result.Dodge):
            set Hero.Rhythm = Min(Hero.Rhythm + 1, MaxRhythm)
            Screen.SetMessage("¡Esquiva! Ritmo {Hero.Rhythm}.")
        else:
            Damage := CalculateDamage(Enemy, Hero, Enemy.Pattern.HitMultiplier)
            Hero.TakeDamage(Damage)
            set Hero.Rhythm = 0
            if (Enemy.Pattern.WeakTurns > 0):
                set Hero.WeakTurns = Max(Hero.WeakTurns, Enemy.Pattern.WeakTurns)
            if (Result = dodge_result.Early):
                Screen.SetMessage("¡Demasiado pronto! {Enemy.Name} te golpea: {Damage} de daño.")
            else:
                Screen.SetMessage("{Enemy.Name} te golpea: {Damage} de daño.")

    # Espera la primera pulsación. Solo cuenta la primera: pulsar antes de tiempo es fallo.
    WaitForReaction(ImpactTime:float)<suspends>:dodge_result =
        race:
            block:
                Sleep(Max(ImpactTime - GetSimulationElapsedTime(), 0.0) + LateGrace)
                dodge_result.Miss
            block:
                DodgeInput.PressedEvent.Await()
                EvaluatePress(ImpactTime)

    # Clasifica la pulsación según su distancia al impacto (positivo = antes del impacto).
    EvaluatePress(ImpactTime:float)<transacts>:dodge_result =
        Offset := ImpactTime - GetSimulationElapsedTime()
        if (Offset >= -LateGrace, Offset <= ParryWindow):
            dodge_result.Parry
        else if (Offset >= -LateGrace, Offset <= DodgeWindow):
            dodge_result.Dodge
        else:
            dodge_result.Early

    # Animación provisional: el enemigo retrocede, embiste y vuelve a su sitio.
    AnimateAttack(Slot:enemy_slot, Windup:float)<suspends>:void =
        Start := Slot.Home.Translation
        Target := ArenaSpot.GetTransform().Translation
        Direction := Target - Start
        Back := Start - Direction * 0.15
        Strike := Start + Direction * 0.6
        Lunge := Min(LungeTime, Windup * 0.5)
        Slot.Prop.MoveTo(Back, Slot.Home.Rotation, Max(Windup - Lunge, 0.05))
        Slot.Prop.MoveTo(Strike, Slot.Home.Rotation, Lunge)
        Slot.Prop.MoveTo(Start, Slot.Home.Rotation, 0.35)

    # Oculta el modelo de un enemigo derrotado.
    CheckDefeated(Slot:enemy_slot):void =
        if (Slot.Fighter.IsDefeated[]):
            Slot.Prop.Hide()

    AliveCount(Enemies:[]enemy_slot)<transacts>:int =
        Alive := for (Slot : Enemies, not Slot.Fighter.IsDefeated[]) { Slot }
        Alive.Length

    AnySkillAffordable(Skills:[]skill)<transacts><decides>:void =
        Affordable := for (S : Skills, AP >= S.Cost) { S }
        Affordable.Length > 0

    # Actualiza la interfaz con la vida, PA, Ritmo y estados.
    Refresh(Screen:battle_ui, Hero:combatant, Enemies:[]enemy_slot):void =
        Screen.SetHeroLine("{Hero.Name}   PV {Hero.HP}/{Hero.MaxHP}   PA {AP}   Ritmo {Hero.Rhythm}   Tónicos {Items}{Hero.StatusText()}")
        Lines := for (Slot : Enemies):
            if (Slot.Fighter.IsDefeated[]):
                "{Slot.Fighter.Name}: derrotado"
            else:
                "{Slot.Fighter.Name}   PV {Slot.Fighter.HP}/{Slot.Fighter.MaxHP}{Slot.Fighter.StatusText()}"
        Screen.SetEnemyLines(Lines)
