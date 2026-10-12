# battle_manager.verse — Gestor del juego: exploración (Fase 3) y combate por turnos (Fases 1-2).
#
# Dispositivos que hay que colocar en UEFN y enlazar en el panel Detalles:
#   StartTrigger     (trigger_device)                      -> combate de prueba contra los 3 Mudos
#   ArenaSpot        (teleporter_device)                   -> posición del jugador en la arena
#   ReturnSpot       (teleporter_device)                   -> salida de la arena si no hay posición guardada
#   BattleCamera     (gameplay_camera_fixed_point_device)  -> cámara fija de la arena
#   DodgeInput       (input_trigger_device)                -> tecla de esquiva / bloqueo
#   EnemyProp        (creative_prop)                       -> modelo del 1.er enemigo en la arena
#   ExtraEnemyProps  ([]creative_prop)                     -> modelos del 2.º y 3.er enemigo en la arena
#   Encounters       ([]encounter_spot)                    -> enemigos del mapa (marcador + tipos de enemigo)
#   RestSpots        ([]rest_spot)                         -> faros de descanso
#   Chests           ([]chest_spot)                        -> cofres con tónicos
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

    # --- Exploración (Fase 3) ---
    @editable Encounters:[]encounter_spot = array{}
    @editable RestSpots:[]rest_spot = array{}
    @editable Chests:[]chest_spot = array{}
    # Distancia (cm) a la que un marcador se activa.
    @editable TriggerRadius:float = 250.0
    # Probabilidad de encontrar un tónico al ganar un combate (0 a 1).
    @editable TonicDropChance:float = 0.35

    # Ventanas de reacción en segundos antes del impacto (ver docs/DISENO.md).
    @editable DodgeWindow:float = 0.40
    @editable ParryWindow:float = 0.20
    # Margen tras el impacto que aún cuenta (compensa la latencia).
    @editable LateGrace:float = 0.08
    # PRUEBAS: si es mayor que 0, un combate de prueba empieza solo tras estos segundos.
    @editable AutoStartDelay:float = -1.0

    CounterMultiplier:float = 0.5
    MaxAP:int = 9
    MaxRhythm:int = 10
    StartingItems:int = 2
    TonicHeal:int = 40
    LungeTime:float = 0.25

    var InBattle:logic = false
    var AP:int = 0
    var Items:int = 0
    # El héroe y su vida persisten entre combates.
    var PartyHero:combatant = combatant{Name := "Oria", MaxHP := 120, Attack := 18, Defense := 6, Speed := 10}
    var MaybeExplore:?explore_ui = false
    # Punto de reaparición tras una derrota (último faro visitado).
    var MaybeRespawn:?transform = false

    OnBegin<override>()<suspends>:void =
        set PartyHero = MakeOria()
        PartyHero.ResetForBattle()
        set Items = StartingItems
        StartTrigger.TriggeredEvent.Subscribe(OnStartTriggered)

        # Esperamos al jugador (juego para un solo jugador).
        var MaybePlayer:?player = false
        loop:
            if (First := GetPlayspace().GetPlayers()[0]):
                set MaybePlayer = option{First}
                break
            Sleep(0.5)
        if (Player := MaybePlayer?):
            if (UI := GetPlayerUI[Player]):
                Explore := explore_ui{PlayerUI := UI}
                Explore.Init()
                set MaybeExplore = option{Explore}
                Explore.Show()
                UpdateExploreHud()
                Explore.Notify("El Silencio se extiende por Puerto Calma...")
            if (AutoStartDelay > 0.0):
                Sleep(AutoStartDelay)
                StartBattle(Player, TestEncounter(), false)
            ExploreLoop(Player)

    OnStartTriggered(MaybeAgent:?agent):void =
        if (not InBattle?, Agent := MaybeAgent?, Player := player[Agent]):
            spawn{ StartBattle(Player, TestEncounter(), false) }

    # --- Exploración ---

    # Comprueba varias veces por segundo si el jugador está cerca de un marcador.
    ExploreLoop(Player:player)<suspends>:void =
        loop:
            Sleep(0.2)
            if (not InBattle?, Character := Player.GetFortCharacter[]):
                Position := Character.GetTransform().Translation
                CheckChests(Position)
                CheckRestSpots(Position)
                MaybeEncounter := FindEncounter(Position)
                if (Encounter := MaybeEncounter?):
                    Outcome := StartBattle(Player, Encounter.Enemies, true)
                    AfterEncounter(Player, Encounter, Outcome)

    # Devuelve el encuentro activo más cercano dentro del radio (o nada). Rearma los lejanos.
    FindEncounter(Position:vector3):?encounter_spot =
        var Found:?encounter_spot = false
        for (Encounter : Encounters, not Encounter.Defeated?):
            Dist := Distance(Position, Encounter.Marker.GetTransform().Translation)
            if (Dist > TriggerRadius * 1.6):
                set Encounter.Armed = true
            else if (Dist <= TriggerRadius, Encounter.Armed?, not Found?):
                set Found = option{Encounter}
        Found

    AfterEncounter(Player:player, Encounter:encounter_spot, Outcome:battle_outcome):void =
        if (Outcome = battle_outcome.Victory):
            set Encounter.Defeated = true
            Encounter.Marker.Hide()
            if (GetRandomFloat(0.0, 1.0) < TonicDropChance):
                set Items = Items + 1
                Notify("¡Victoria! Encuentras un tónico.")
            else:
                Notify("¡Victoria!")
        else if (Outcome = battle_outcome.Fled):
            # Hay que alejarse para que el encuentro vuelva a activarse.
            set Encounter.Armed = false
            Notify("Has huido. Aléjate para recuperar el aliento.")
        else:
            PartyHero.ResetForBattle()
            set Encounter.Armed = false
            if (Respawn := MaybeRespawn?, Character := Player.GetFortCharacter[]):
                if (Character.TeleportTo[Respawn.Translation, Respawn.Rotation]) {}
            Notify("Despiertas junto al último faro.")
        UpdateExploreHud()

    CheckRestSpots(Position:vector3):void =
        for (Rest : RestSpots):
            Dist := Distance(Position, Rest.Marker.GetTransform().Translation)
            if (Dist > TriggerRadius * 1.6):
                set Rest.Armed = true
            else if (Dist <= TriggerRadius, Rest.Armed?):
                set Rest.Armed = false
                PartyHero.ResetForBattle()
                # Reaparecemos un poco delante del faro.
                RestTransform := Rest.Marker.GetTransform()
                Respawn := transform{
                    Translation := RestTransform.Translation + vector3{X := 250.0, Y := 0.0, Z := 50.0},
                    Rotation := RestTransform.Rotation,
                    Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}}
                set MaybeRespawn = option{Respawn}
                for (Encounter : Encounters):
                    set Encounter.Defeated = false
                    Encounter.Marker.Show()
                Notify("Descansas junto al faro. Vida recuperada. Los Mudos regresan...")
                UpdateExploreHud()

    CheckChests(Position:vector3):void =
        for (Chest : Chests, not Chest.Opened?):
            if (Distance(Position, Chest.Marker.GetTransform().Translation) <= TriggerRadius):
                set Chest.Opened = true
                Chest.Marker.Hide()
                set Items = Items + Chest.Tonics
                Notify("Cofre: +{Chest.Tonics} tónico(s).")
                UpdateExploreHud()

    Notify(Text:string):void =
        if (Explore := MaybeExplore?):
            Explore.Notify(Text)

    UpdateExploreHud():void =
        if (Explore := MaybeExplore?):
            Explore.SetHeroLine("{PartyHero.Name}   PV {PartyHero.HP}/{PartyHero.MaxHP}   Tónicos {Items}")

    # --- Combate ---

    # Crea los enemigos del combate con los props de la arena (máximo 3) y oculta los que sobran.
    BuildEnemies(Kinds:[]enemy_kind):[]enemy_slot =
        Props:[]creative_prop = array{EnemyProp} + ExtraEnemyProps
        for (Index -> Prop : Props, Index >= Kinds.Length):
            Prop.Hide()
        for (Index -> Kind : Kinds, Prop := Props[Index]):
            Fighter := MakeEnemy(Kind)
            Fighter.ResetForBattle()
            enemy_slot{Fighter := Fighter, Prop := Prop, Home := Prop.GetTransform()}

    # Combate completo: entrar en la arena, jugar los turnos y volver.
    # ReturnToSpot = true: el jugador vuelve exactamente a donde estaba.
    StartBattle(Player:player, Kinds:[]enemy_kind, ReturnToSpot:logic)<suspends>:battle_outcome =
        var Outcome:battle_outcome = battle_outcome.Fled
        if (not InBattle?, UI := GetPlayerUI[Player]):
            set InBattle = true
            var MaybeSaved:?transform = false
            if (ReturnToSpot?, Character := Player.GetFortCharacter[]):
                set MaybeSaved = option{Character.GetTransform()}
            if (Explore := MaybeExplore?):
                Explore.Hide()

            PartyHero.ClearStatus()
            Enemies := BuildEnemies(Kinds)
            set AP = 0

            Screen := battle_ui{PlayerUI := UI}
            Screen.Init()
            EnterArena(Player, Enemies)
            Screen.Show()
            Refresh(Screen, PartyHero, Enemies)
            if (Enemies.Length > 1):
                Screen.SetMessage("¡Los Mudos te rodean!")
            else:
                Screen.SetMessage("¡Un Mudo bloquea el camino!")
            Sleep(1.5)

            set Outcome = BattleLoop(PartyHero, Enemies, Screen)
            Screen.HideMenu()
            if (Outcome = battle_outcome.Victory):
                Screen.SetMessage("¡Victoria! Los Mudos vuelven a ser piedra.")
            else if (Outcome = battle_outcome.Defeat):
                Screen.SetMessage("Derrota... El Silencio te alcanza.")
            else:
                Screen.SetMessage("Huyes del combate.")
            Sleep(2.5)

            Screen.Hide()
            ExitArena(Player, Enemies, MaybeSaved)
            if (Explore := MaybeExplore?):
                Explore.Show()
            UpdateExploreHud()
            set InBattle = false
        Outcome

    EnterArena(Player:player, Enemies:[]enemy_slot):void =
        for (Slot : Enemies):
            Slot.Prop.Show()
            if (Slot.Prop.TeleportTo[Slot.Home]) {}
        ArenaSpot.Teleport(Player)
        BattleCamera.AddTo(Player)
        if (Character := Player.GetFortCharacter[]):
            Character.PutInStasis(stasis_args{AllowTurning := false, AllowFalling := true, AllowEmotes := false})

    ExitArena(Player:player, Enemies:[]enemy_slot, MaybeSaved:?transform):void =
        if (Character := Player.GetFortCharacter[]):
            Character.ReleaseFromStasis()
        BattleCamera.RemoveFrom(Player)
        # Vuelta exacta al punto del encuentro; si no hay posición guardada, al ReturnSpot.
        var Returned:logic = false
        if (Saved := MaybeSaved?, Character := Player.GetFortCharacter[], Character.TeleportTo[Saved.Translation, Saved.Rotation]):
            set Returned = true
        if (not Returned?):
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
