# battle_manager.verse — Gestor del combate por turnos (Fase 1: Oria contra un Badajo).
#
# Dispositivos que hay que colocar en UEFN y enlazar en el panel Detalles:
#   StartTrigger  (trigger_device)                      -> al pisarlo empieza el combate
#   ArenaSpot     (teleporter_device)                   -> posición del jugador en la arena
#   ReturnSpot    (teleporter_device)                   -> adonde vuelve el jugador al terminar
#   BattleCamera  (gameplay_camera_fixed_point_device)  -> cámara fija de la arena
#   DodgeInput    (input_trigger_device)                -> tecla de esquiva / bloqueo
#   EnemyProp     (creative_prop)                       -> modelo provisional del Badajo
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Resultado de la reacción del jugador a un ataque enemigo.
dodge_result := enum:
    Miss    # Recibe el golpe
    Dodge   # Esquiva: evita el daño
    Parry   # Contratiempo: bloqueo perfecto, +PA y contraataque

battle_outcome := enum:
    Victory
    Defeat
    Fled

battle_manager := class(creative_device):

    @editable StartTrigger:trigger_device = trigger_device{}
    @editable ArenaSpot:teleporter_device = teleporter_device{}
    @editable ReturnSpot:teleporter_device = teleporter_device{}
    @editable BattleCamera:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable DodgeInput:input_trigger_device = input_trigger_device{}
    @editable EnemyProp:creative_prop = creative_prop{}

    # Ventanas de reacción en segundos antes del impacto (ver docs/DISENO.md).
    @editable DodgeWindow:float = 0.40
    @editable ParryWindow:float = 0.20
    # Margen tras el impacto que aún cuenta (compensa la latencia).
    @editable LateGrace:float = 0.08
    # Duración aleatoria de la preparación del ataque enemigo.
    @editable MinWindup:float = 1.0
    @editable MaxWindup:float = 2.0

    SkillCost:int = 3
    SkillMultiplier:float = 2.5
    CounterMultiplier:float = 0.5
    MaxAP:int = 9
    StartingItems:int = 2
    TonicHeal:int = 40
    LungeTime:float = 0.25

    var InBattle:logic = false
    var AP:int = 0
    var Items:int = 0

    OnBegin<override>()<suspends>:void =
        StartTrigger.TriggeredEvent.Subscribe(OnStartTriggered)

    OnStartTriggered(MaybeAgent:?agent):void =
        if (not InBattle?, Agent := MaybeAgent?, Player := player[Agent]):
            set InBattle = true
            spawn{ RunBattle(Player) }

    # Combate completo: entrar en la arena, jugar los turnos y volver.
    RunBattle(Player:player)<suspends>:void =
        Home := EnemyProp.GetTransform()
        if (UI := GetPlayerUI[Player]):
            Hero := MakeOria()
            Enemy := MakeBadajo()
            Hero.ResetHP()
            Enemy.ResetHP()
            set AP = 0
            set Items = StartingItems

            Screen := battle_ui{PlayerUI := UI}
            Screen.Init()
            EnterArena(Player, Home)
            Screen.Show()
            Screen.SetMessage("¡Un Badajo bloquea el camino!")
            Sleep(1.5)

            Outcome := BattleLoop(Hero, Enemy, Screen, Home)
            Screen.HideMenu()
            if (Outcome = battle_outcome.Victory):
                EnemyProp.Hide()
                Screen.SetMessage("¡Victoria! El Badajo vuelve a ser piedra.")
            else if (Outcome = battle_outcome.Defeat):
                Screen.SetMessage("Derrota... El Silencio te alcanza.")
            else:
                Screen.SetMessage("Huyes del combate.")
            Sleep(3.0)

            Screen.Hide()
            ExitArena(Player, Home)
        set InBattle = false

    EnterArena(Player:player, Home:transform):void =
        EnemyProp.Show()
        if (EnemyProp.TeleportTo[Home]) {}
        ArenaSpot.Teleport(Player)
        BattleCamera.AddTo(Player)
        if (Character := Player.GetFortCharacter[]):
            Character.PutInStasis(stasis_args{AllowTurning := false, AllowFalling := true, AllowEmotes := false})

    ExitArena(Player:player, Home:transform):void =
        if (Character := Player.GetFortCharacter[]):
            Character.ReleaseFromStasis()
        BattleCamera.RemoveFrom(Player)
        ReturnSpot.Teleport(Player)
        EnemyProp.Show()
        if (EnemyProp.TeleportTo[Home]) {}

    # Bucle de turnos: jugador y enemigo se alternan hasta que uno cae o el jugador huye.
    BattleLoop(Hero:combatant, Enemy:combatant, Screen:battle_ui, Home:transform)<suspends>:battle_outcome =
        var Outcome:battle_outcome = battle_outcome.Fled
        loop:
            # --- Turno del jugador ---
            Screen.Refresh(Hero, Enemy, AP, Items, SkillCost)
            Screen.SetMessage("Tu turno: elige una acción.")
            Screen.ShowMenu(logic{AP >= SkillCost}, logic{Items > 0})
            Action := Screen.WaitForAction()
            Screen.HideMenu()

            if (Action = battle_action.Flee):
                set Outcome = battle_outcome.Fled
                break
            DoPlayerAction(Action, Hero, Enemy, Screen)
            Screen.Refresh(Hero, Enemy, AP, Items, SkillCost)
            Sleep(1.2)
            if (Enemy.IsDefeated[]):
                set Outcome = battle_outcome.Victory
                break

            # --- Turno del enemigo ---
            EnemyTurn(Hero, Enemy, Screen, Home)
            Screen.Refresh(Hero, Enemy, AP, Items, SkillCost)
            Sleep(1.2)
            if (Enemy.IsDefeated[]):
                set Outcome = battle_outcome.Victory
                break
            if (Hero.IsDefeated[]):
                set Outcome = battle_outcome.Defeat
                break
        Outcome

    DoPlayerAction(Action:battle_action, Hero:combatant, Enemy:combatant, Screen:battle_ui):void =
        if (Action = battle_action.Attack):
            Damage := CalculateDamage(Hero, Enemy, 1.0)
            Enemy.TakeDamage(Damage)
            set AP = Min(AP + 1, MaxAP)
            Screen.SetMessage("{Hero.Name} golpea con su martillo-tambor: {Damage} de daño.")
        else if (Action = battle_action.Skill):
            if (AP >= SkillCost):
                set AP -= SkillCost
                Damage := CalculateDamage(Hero, Enemy, SkillMultiplier)
                Enemy.TakeDamage(Damage)
                Screen.SetMessage("¡Redoble! {Hero.Name} descarga una ráfaga: {Damage} de daño.")
        else if (Action = battle_action.Item):
            if (Items > 0):
                set Items -= 1
                Hero.Heal(TonicHeal)
                Screen.SetMessage("{Hero.Name} bebe un tónico y recupera {TonicHeal} PV.")

    # Ataque enemigo con aviso y ventana de reacción.
    EnemyTurn(Hero:combatant, Enemy:combatant, Screen:battle_ui, Home:transform)<suspends>:void =
        Screen.SetMessage("¡El {Enemy.Name} se prepara! Pulsa la tecla justo antes del impacto.")
        Windup := GetRandomFloat(MinWindup, MaxWindup)
        ImpactTime := GetSimulationElapsedTime() + Windup
        spawn{ AnimateAttack(Home, Windup) }

        Result := WaitForReaction(ImpactTime)
        # Si el jugador reaccionó antes, esperamos al impacto para mostrar el resultado a tiempo.
        Remaining := ImpactTime - GetSimulationElapsedTime()
        if (Remaining > 0.0):
            Sleep(Remaining)

        if (Result = dodge_result.Parry):
            set AP = Min(AP + 1, MaxAP)
            Counter := CalculateDamage(Hero, Enemy, CounterMultiplier)
            Enemy.TakeDamage(Counter)
            Screen.SetMessage("¡CONTRATIEMPO! Bloqueo perfecto y contraataque: {Counter} de daño.")
        else if (Result = dodge_result.Dodge):
            Screen.SetMessage("¡Esquiva! El golpe no te alcanza.")
        else:
            Damage := CalculateDamage(Enemy, Hero, 1.0)
            Hero.TakeDamage(Damage)
            Screen.SetMessage("El {Enemy.Name} te golpea: {Damage} de daño.")

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
            dodge_result.Miss

    # Animación provisional: el enemigo retrocede, embiste y vuelve a su sitio.
    AnimateAttack(Home:transform, Windup:float)<suspends>:void =
        Start := Home.Translation
        Target := ArenaSpot.GetTransform().Translation
        Direction := Target - Start
        Back := Start - Direction * 0.15
        Strike := Start + Direction * 0.6
        EnemyProp.MoveTo(Back, Home.Rotation, Max(Windup - LungeTime, 0.1))
        EnemyProp.MoveTo(Strike, Home.Rotation, LungeTime)
        EnemyProp.MoveTo(Start, Home.Rotation, 0.4)
