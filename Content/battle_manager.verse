# battle_manager.verse — Gestor del juego: exploración (Fase 3), grupo y progresión (Fase 4)
# y combate por turnos (Fases 1-2).
#
# Dispositivos que hay que colocar en UEFN y enlazar en el panel Detalles:
#   StartTrigger     (trigger_device)                      -> combate de prueba contra los 3 Mudos
#   ArenaSpot        (teleporter_device)                   -> posición del jugador (Oria) en la arena
#   ReturnSpot       (teleporter_device)                   -> salida de la arena si no hay posición guardada
#   BattleCamera     (gameplay_camera_fixed_point_device)  -> cámara fija de la arena
#   DodgeInput       (input_trigger_device)                -> tecla de esquiva / bloqueo
#   EnemyProp        (creative_prop)                       -> modelo del 1.er enemigo en la arena
#   ExtraEnemyProps  ([]creative_prop)                     -> modelos del 2.º y 3.er enemigo en la arena
#   HeroProps        ([]creative_prop, opcional)           -> modelos de Joel y Kesh en la arena
#   Encounters       ([]encounter_spot)                    -> enemigos del mapa (marcador + tipos de enemigo)
#   RestSpots        ([]rest_spot)                         -> faros de descanso
#   Chests           ([]chest_spot)                        -> cofres con tónicos, partituras o Resina
#   MenuInput        (input_trigger_device)                -> tecla para abrir el menú del grupo
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
    Dodge   # Esquiva: evita el daño
    Parry   # Contratiempo: bloqueo perfecto, +1 PA y contraataque

battle_outcome := enum:
    Victory
    Defeat
    Fled

# Un enemigo en la arena: sus datos, su modelo y su posición inicial.
enemy_slot := class:
    Fighter:combatant
    Prop:creative_prop
    Home:transform

# Un turno de la ronda: un héroe o un enemigo.
turn_actor := class:
    Fighter:combatant
    MaybeEnemy:?enemy_slot = false

battle_manager := class(creative_device):

    @editable StartTrigger:trigger_device = trigger_device{}
    @editable ArenaSpot:teleporter_device = teleporter_device{}
    @editable ReturnSpot:teleporter_device = teleporter_device{}
    @editable BattleCamera:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable DodgeInput:input_trigger_device = input_trigger_device{}
    @editable EnemyProp:creative_prop = creative_prop{}
    @editable ExtraEnemyProps:[]creative_prop = array{}
    @editable HeroProps:[]creative_prop = array{}

    # --- Exploración (Fase 3) ---
    @editable Encounters:[]encounter_spot = array{}
    @editable RestSpots:[]rest_spot = array{}
    @editable Chests:[]chest_spot = array{}
    # Distancia (cm) a la que un marcador se activa.
    @editable TriggerRadius:float = 250.0
    # Probabilidad de encontrar un tónico al ganar un combate (0 a 1).
    @editable TonicDropChance:float = 0.35

    # --- Grupo (Fase 4) ---
    # Héroes en el grupo al empezar (1 = Oria, 2 = +Joel, 3 = +Kesh). Más adelante se unirán con la historia.
    @editable StartingPartySize:int = 3
    # PRUEBAS: true borra el guardado al empezar la partida.
    @editable ResetSaveOnStart:logic = false
    @editable MenuInput:input_trigger_device = input_trigger_device{}
    # Texto que se muestra para indicar la tecla del menú.
    @editable MenuKeyHint:string = "la tecla del menú"

    # Ventanas de reacción en segundos antes del impacto (ver docs/DISENO.md).
    @editable DodgeWindow:float = 0.40
    @editable ParryWindow:float = 0.20
    # Margen tras el impacto que aún cuenta (compensa la latencia).
    @editable LateGrace:float = 0.08
    # PRUEBAS: si es mayor que 0, un combate de prueba empieza solo tras estos segundos.
    @editable AutoStartDelay:float = -1.0

    CounterMultiplier:float = 0.5
    HarmonyBonus:float = 1.25
    MaxAP:int = 9
    MaxRhythm:int = 10
    StartingItems:int = 2
    TonicHeal:int = 40
    LungeTime:float = 0.25

    var InBattle:logic = false
    var InMenu:logic = false
    var OwnedPartituras:[]partitura = array{}
    var Items:int = 0
    # Rondas restantes de Armonía (Joel): +25 % de daño del grupo.
    var HarmonyTurns:int = 0
    # El grupo y su vida persisten entre combates.
    var Party:[]combatant = array{}
    var MaybeExplore:?explore_ui = false
    # Punto de reaparición tras una derrota (último faro visitado).
    var MaybeRespawn:?vector3 = false

    OnBegin<override>()<suspends>:void =
        StartTrigger.TriggeredEvent.Subscribe(OnStartTriggered)

        # Esperamos al jugador (juego para un solo jugador).
        var MaybePlayer:?player = false
        loop:
            if (First := GetPlayspace().GetPlayers()[0]):
                set MaybePlayer = option{First}
                break
            Sleep(0.5)
        if (Player := MaybePlayer?):
            LoadGame(Player)
            if (UI := GetPlayerUI[Player]):
                Explore := explore_ui{PlayerUI := UI}
                Explore.Init()
                set MaybeExplore = option{Explore}
                Explore.Show()
                UpdateExploreHud()
                Explore.Notify("El Silencio se extiende por Puerto Calma... Pulsa {MenuKeyHint} para ver el grupo.")
            spawn{ MenuLoop(Player) }
            if (AutoStartDelay > 0.0):
                Sleep(AutoStartDelay)
                StartBattle(Player, TestEncounter(), false)
            ExploreLoop(Player)

    OnStartTriggered(MaybeAgent:?agent):void =
        if (not InBattle?, Agent := MaybeAgent?, Player := player[Agent]):
            spawn{ StartBattle(Player, TestEncounter(), false) }

    # --- Guardado ---

    LoadGame(Player:player):void =
        var Data:save_data = save_data{}
        if (not ResetSaveOnStart?, Saved := SaveTable[Player]):
            set Data = Saved
        set Party = for (Index -> Kind : PartyOrder(), Index < StartingPartySize):
            SavedLevel := if (L := Data.Levels[Index]) then L else 1
            SavedXP := if (X := Data.XPs[Index]) then X else 0
            SavedTier := if (T := Data.Tiers[Index]) then T else 0
            SavedPart := if (E := Data.Equipped[Index]) then PartituraFromInt(E) else partitura.Ninguna
            Hero := MakeHero(Kind, SavedLevel, SavedTier, SavedPart)
            Hero.ResetForBattle()
            set Hero.XP = SavedXP
            Hero
        set Items = Data.Items
        set OwnedPartituras = for (Code : Data.Owned, Code > 0) { PartituraFromInt(Code) }
        for (Opened : Data.OpenedChests, Chest := Chests[Opened]):
            set Chest.Opened = true
            Chest.Marker.Hide()
        if (Data.HasRespawn?):
            set MaybeRespawn = option{vector3{X := Data.RespawnX, Y := Data.RespawnY, Z := Data.RespawnZ}}

    SaveGame(Player:player):void =
        # Partimos de lo guardado para no perder los niveles de héroes que aún no están en el grupo.
        var Old:save_data = save_data{}
        if (Saved := SaveTable[Player]):
            set Old = Saved
        NewLevels := for (Index -> Kind : PartyOrder()):
            if (Hero := Party[Index]) then Hero.Level else if (L := Old.Levels[Index]) then L else 1
        NewXPs := for (Index -> Kind : PartyOrder()):
            if (Hero := Party[Index]) then Hero.XP else if (X := Old.XPs[Index]) then X else 0
        NewTiers := for (Index -> Kind : PartyOrder()):
            if (Hero := Party[Index]) then Hero.Tier else if (T := Old.Tiers[Index]) then T else 0
        NewEquipped := for (Index -> Kind : PartyOrder()):
            if (Hero := Party[Index]) then PartituraToInt(Hero.Equipped) else if (E := Old.Equipped[Index]) then E else 0
        NewOwned := for (P : OwnedPartituras) { PartituraToInt(P) }
        NewOpened := for (Index -> Chest : Chests, Chest.Opened?) { Index }
        var NewHasRespawn:logic = false
        var Point:vector3 = vector3{X := 0.0, Y := 0.0, Z := 0.0}
        if (Saved := MaybeRespawn?):
            set NewHasRespawn = true
            set Point = Saved
        CurrentItems := Items
        NewData := save_data{Levels := NewLevels, XPs := NewXPs, Items := CurrentItems, Tiers := NewTiers, Equipped := NewEquipped, Owned := NewOwned, OpenedChests := NewOpened, HasRespawn := NewHasRespawn, RespawnX := Point.X, RespawnY := Point.Y, RespawnZ := Point.Z}
        if (Player.IsActive[], set SaveTable[Player] = NewData) {}

    # --- Exploración ---

    # Comprueba varias veces por segundo si el jugador está cerca de un marcador.
    ExploreLoop(Player:player)<suspends>:void =
        loop:
            Sleep(0.2)
            if (not InBattle?, not InMenu?, Character := Player.GetFortCharacter[]):
                Position := Character.GetTransform().Translation
                CheckChests(Player, Position)
                CheckRestSpots(Player, Position)
                MaybeEncounter := FindEncounter(Position)
                if (Encounter := MaybeEncounter?):
                    Outcome := StartBattle(Player, Encounter.Enemies, true)
                    AfterEncounter(Player, Encounter, Outcome)

    # Devuelve el encuentro activo dentro del radio (o nada). Rearma los lejanos.
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
        else if (Outcome = battle_outcome.Fled):
            # Hay que alejarse para que el encuentro vuelva a activarse.
            set Encounter.Armed = false
            Notify("Has huido. Aléjate para recuperar el aliento.")
        else:
            HealParty()
            set Encounter.Armed = false
            if (Point := MaybeRespawn?, Character := Player.GetFortCharacter[]):
                if (Character.TeleportTo[Point, Character.GetTransform().Rotation]) {}
            Notify("Despiertas junto al último faro.")
        SaveGame(Player)
        UpdateExploreHud()

    CheckRestSpots(Player:player, Position:vector3):void =
        for (Rest : RestSpots):
            Dist := Distance(Position, Rest.Marker.GetTransform().Translation)
            if (Dist > TriggerRadius * 1.6):
                set Rest.Armed = true
            else if (Dist <= TriggerRadius, Rest.Armed?):
                set Rest.Armed = false
                HealParty()
                # Reaparecemos un poco delante del faro.
                set MaybeRespawn = option{Rest.Marker.GetTransform().Translation + vector3{X := 250.0, Y := 0.0, Z := 50.0}}
                for (Encounter : Encounters):
                    set Encounter.Defeated = false
                    Encounter.Marker.Show()
                SaveGame(Player)
                Notify("Descansas junto al faro. Grupo recuperado. Partida guardada. Los Mudos regresan...")
                UpdateExploreHud()

    CheckChests(Player:player, Position:vector3):void =
        for (Chest : Chests, not Chest.Opened?):
            if (Distance(Position, Chest.Marker.GetTransform().Translation) <= TriggerRadius):
                set Chest.Opened = true
                Chest.Marker.Hide()
                var Message:string = "Cofre:"
                if (Chest.Tonics > 0):
                    set Items = Items + Chest.Tonics
                    set Message = Message + " +{Chest.Tonics} tónico(s)."
                if (not Chest.Partitura = partitura.Ninguna):
                    if (not HasPartitura[Chest.Partitura]):
                        set OwnedPartituras = OwnedPartituras + array{Chest.Partitura}
                    set Message = Message + " ¡{PartituraName(Chest.Partitura)}! {PartituraDesc(Chest.Partitura)}"
                if (Chest.UpgradesInstruments?):
                    UpgradeInstruments()
                    set Message = Message + " ¡Resina de la Campana! Los instrumentos del grupo mejoran."
                SaveGame(Player)
                Notify(Message + " Equípalo en el menú del grupo.")
                UpdateExploreHud()

    HasPartitura(P:partitura)<transacts><decides>:void =
        Found := for (Owned : OwnedPartituras, Owned = P) { Owned }
        Found.Length > 0

    # +1 nivel de instrumento a todo el grupo (máximo 3).
    UpgradeInstruments():void =
        set Party = for (Hero : Party):
            RebuildHero(Hero, Hero.Tier + 1, Hero.Equipped)

    # Crea de nuevo un héroe con otro equipo, conservando nivel, experiencia y vida perdida.
    RebuildHero(Hero:combatant, NewTier:int, NewPart:partitura):combatant =
        Rebuilt := MakeHero(Hero.Kind, Hero.Level, NewTier, NewPart)
        set Rebuilt.XP = Hero.XP
        set Rebuilt.HP = Max(Min(Hero.HP + (Rebuilt.MaxHP - Hero.MaxHP), Rebuilt.MaxHP), 1)
        Rebuilt

    # --- Menú del grupo ---

    MenuLoop(Player:player)<suspends>:void =
        loop:
            MenuInput.PressedEvent.Await()
            if (not InBattle?, not InMenu?):
                set InMenu = true
                PartyMenu(Player)
                set InMenu = false

    PartyMenu(Player:player)<suspends>:void =
        if (UI := GetPlayerUI[Player]):
            if (Explore := MaybeExplore?):
                Explore.Hide()
            Screen := battle_ui{PlayerUI := UI}
            Screen.Init()
            Screen.Show()
            loop:
                RefreshMenu(Screen)
                Screen.SetMessage("Grupo: elige un héroe.")
                Labels := for (Hero : Party) { "{Hero.Name}  Nv{Hero.Level}" }
                Pick := Screen.Ask(Labels, array{}, true)
                if (Pick < 0):
                    break
                HeroMenu(Pick, Screen)
            Screen.Hide()
            if (Explore := MaybeExplore?):
                Explore.Show()
            SaveGame(Player)
            UpdateExploreHud()

    HeroMenu(Index:int, Screen:battle_ui)<suspends>:void =
        loop:
            RefreshMenu(Screen)
            if (Hero := Party[Index]):
                Screen.SetMessage(HeroSummary(Hero))
            Pick := Screen.Ask(array{"Cambiar partitura"}, array{}, true)
            if (Pick <> 0):
                break
            ChoosePartitura(Index, Screen)

    ChoosePartitura(Index:int, Screen:battle_ui)<suspends>:void =
        Available := for (P : OwnedPartituras, not IsEquippedByOther[P, Index]) { P }
        Labels := for (P : Available) { PartituraName(P) }
        if (Available.Length = 0):
            Screen.SetMessage("No tienes partituras libres. Búscalas en los cofres.")
        else:
            Screen.SetMessage("Elige una partitura.")
        Pick := Screen.Ask(Labels + array{"Quitar partitura"}, array{}, true)
        if (Pick >= 0):
            var NewPart:partitura = partitura.Ninguna
            if (Chosen := Available[Pick]):
                set NewPart = Chosen
            set Party = for (I -> Hero : Party):
                if (I = Index) then RebuildHero(Hero, Hero.Tier, NewPart) else Hero

    IsEquippedByOther(P:partitura, Index:int)<transacts><decides>:void =
        Others := for (I -> Hero : Party, I <> Index, Hero.Equipped = P) { Hero }
        Others.Length > 0

    HeroSummary(Hero:combatant):string =
        "{Hero.Name} Nv{Hero.Level} ({Hero.XP}/{XPToNext(Hero.Level)} exp)   PV {Hero.HP}/{Hero.MaxHP}   Ataque {Hero.Attack}   Defensa {Hero.Defense}   Velocidad {Hero.Speed}\nInstrumento: {InstrumentName(Hero.Kind, Hero.Tier)}   Partitura: {PartituraName(Hero.Equipped)} {PartituraDesc(Hero.Equipped)}"

    RefreshMenu(Screen:battle_ui):void =
        Lines := for (Hero : Party):
            "{Hero.Name} Nv{Hero.Level}   PV {Hero.HP}/{Hero.MaxHP}   {InstrumentName(Hero.Kind, Hero.Tier)}   {PartituraName(Hero.Equipped)}"
        Screen.SetPartyLines(Lines)
        Screen.SetEnemyLines(array{})
        Screen.SetHarmony("Tónicos {Items}   Partituras: {OwnedPartituras.Length}/{AllPartituras().Length}")

    HealParty():void =
        for (Hero : Party):
            Hero.ResetForBattle()

    Notify(Text:string):void =
        if (Explore := MaybeExplore?):
            Explore.Notify(Text)

    UpdateExploreHud():void =
        if (Explore := MaybeExplore?):
            var Line:string = ""
            for (Hero : Party):
                set Line = Line + "{Hero.Name} Nv{Hero.Level}  PV {Hero.HP}/{Hero.MaxHP}     "
            Explore.SetHeroLine(Line + "Tónicos {Items}")

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

    # Combate completo: entrar en la arena, jugar las rondas y volver.
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

            # Los héroes caídos vuelven con 1 PV para poder seguir (como en un JRPG tras huir).
            for (Hero : Party):
                Hero.ClearStatus()
                if (Hero.HP <= 0):
                    set Hero.HP = 1
            set HarmonyTurns = 0
            Enemies := BuildEnemies(Kinds)

            Screen := battle_ui{PlayerUI := UI}
            Screen.Init()
            EnterArena(Player, Enemies)
            Screen.Show()
            Refresh(Screen, Enemies, "")
            if (Enemies.Length > 1):
                Screen.SetMessage("¡Los Mudos te rodean!")
            else:
                Screen.SetMessage("¡Un Mudo bloquea el camino!")
            Sleep(1.5)

            set Outcome = BattleLoop(Enemies, Screen)
            Screen.HideMenu()
            if (Outcome = battle_outcome.Victory):
                Screen.SetMessage("¡Victoria! Los Mudos vuelven a ser piedra.")
                Sleep(1.5)
                GrantVictoryRewards(Enemies, Screen)
            else if (Outcome = battle_outcome.Defeat):
                Screen.SetMessage("Derrota... El Silencio os alcanza.")
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

    # Experiencia, subidas de nivel y tónico aleatorio.
    GrantVictoryRewards(Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:void =
        var TotalXP:int = 0
        for (Slot : Enemies):
            set TotalXP = TotalXP + Slot.Fighter.XPReward
        for (Hero : Party):
            set Hero.XP = Hero.XP + TotalXP
        var Message:string = "+{TotalXP} de experiencia."
        set Party = for (Hero : Party):
            Updated := LevelUp(Hero)
            if (Updated.Level > Hero.Level):
                set Message = Message + " ¡{Updated.Name} sube al nivel {Updated.Level}!"
            Updated
        if (GetRandomFloat(0.0, 1.0) < TonicDropChance):
            set Items = Items + 1
            set Message = Message + " Encuentras un tónico."
        Screen.SetMessage(Message)
        Refresh(Screen, Enemies, "")

    # Sube niveles mientras haya experiencia suficiente. Conserva la vida perdida.
    LevelUp(Hero:combatant):combatant =
        var Current:combatant = Hero
        loop:
            Need := XPToNext(Current.Level)
            if (Current.XP >= Need, Current.Level < MaxLevel()):
                NewHero := MakeHero(Current.Kind, Current.Level + 1, Current.Tier, Current.Equipped)
                set NewHero.XP = Current.XP - Need
                set NewHero.HP = Max(Min(Current.HP + (NewHero.MaxHP - Current.MaxHP), NewHero.MaxHP), 1)
                set Current = NewHero
            else:
                break
        Current

    EnterArena(Player:player, Enemies:[]enemy_slot):void =
        for (Slot : Enemies):
            Slot.Prop.Show()
            if (Slot.Prop.TeleportTo[Slot.Home]) {}
        # Joel y Kesh solo se ven si están en el grupo.
        for (Index -> Prop : HeroProps):
            if (Party[Index + 1]):
                Prop.Show()
            else:
                Prop.Hide()
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

    # Rondas: todos actúan por orden de velocidad hasta que un bando cae o el jugador huye.
    BattleLoop(Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:battle_outcome =
        var Outcome:battle_outcome = battle_outcome.Fled
        var Finished:logic = false
        loop:
            Order := TurnOrder(Enemies)
            var TurnIndex:int = 0
            loop:
                if (Finished? or TurnIndex >= Order.Length):
                    break
                if (Actor := Order[TurnIndex], not Actor.Fighter.IsDefeated[]):
                    if (Slot := Actor.MaybeEnemy?):
                        EnemyTurn(Slot, Enemies, Screen)
                    else:
                        Fled := HeroTurn(Actor.Fighter, Enemies, Screen)
                        if (Fled?):
                            set Outcome = battle_outcome.Fled
                            set Finished = true
                    Refresh(Screen, Enemies, "")
                    if (not Finished?):
                        if (AliveCount(Enemies) = 0):
                            set Outcome = battle_outcome.Victory
                            set Finished = true
                        else if (AliveHeroes().Length = 0):
                            set Outcome = battle_outcome.Defeat
                            set Finished = true
                set TurnIndex = TurnIndex + 1
            if (Finished?):
                break
            if (HarmonyTurns > 0):
                set HarmonyTurns = HarmonyTurns - 1
        Outcome

    # Orden de la ronda: héroes y enemigos vivos, de más a menos velocidad.
    TurnOrder(Enemies:[]enemy_slot):[]turn_actor =
        Heroes := for (Hero : AliveHeroes()) { turn_actor{Fighter := Hero} }
        Foes := for (Slot : Enemies, not Slot.Fighter.IsDefeated[]) { turn_actor{Fighter := Slot.Fighter, MaybeEnemy := option{Slot}} }
        var Sorted:[]turn_actor = array{}
        for (Actor : Heroes + Foes):
            var Inserted:logic = false
            var NewList:[]turn_actor = array{}
            for (Existing : Sorted):
                if (not Inserted?, Actor.Fighter.Speed > Existing.Fighter.Speed):
                    set NewList = NewList + array{Actor}
                    set Inserted = true
                set NewList = NewList + array{Existing}
            if (not Inserted?):
                set NewList = NewList + array{Actor}
            set Sorted = NewList
        Sorted

    # Turno de un héroe: Quemadura y menú. Devuelve true si el grupo huye.
    HeroTurn(Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:logic =
        Burn := Hero.StartTurn()
        Refresh(Screen, Enemies, Hero.Name)
        if (Burn > 0):
            Screen.SetMessage("{Hero.Name} sufre la quemadura: {Burn} de daño.")
            Sleep(1.0)
        if (Hero.IsDefeated[]):
            return false
        Fled := PlayerTurn(Hero, Enemies, Screen)
        Refresh(Screen, Enemies, "")
        if (not Fled?):
            Sleep(1.2)
        Fled

    # Menú del héroe activo. Devuelve true si huye.
    PlayerTurn(Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:logic =
        var Fled:logic = false
        loop:
            Screen.SetMessage("Turno de {Hero.Name}: elige una acción.")
            CanUseSkill := logic{AnySkillAffordable[Hero]}
            Main := Screen.Ask(
                array{"Atacar", "Habilidades", "Tónico (x{Items})", "Huir"},
                array{true, CanUseSkill, logic{Items > 0}, true},
                false)

            if (Main = 0):
                MaybeTarget := ChooseTarget(Enemies, Screen)
                if (Target := MaybeTarget?):
                    Screen.HideMenu()
                    Damage := CalculateDamage(Hero, Target.Fighter, HarmonyMultiplier())
                    Target.Fighter.TakeDamage(Damage)
                    if (Hero.BurnOnAttack?):
                        set Target.Fighter.BurnTurns = Max(Target.Fighter.BurnTurns, 2)
                    set Hero.AP = Min(Hero.AP + 1, MaxAP)
                    Screen.SetMessage("{Hero.Name} golpea a {Target.Fighter.Name}: {Damage} de daño.")
                    CheckDefeated(Target)
                    break
            else if (Main = 1):
                MaybeSkill := ChooseSkill(Hero, Screen)
                if (ChosenSkill := MaybeSkill?):
                    Used := UseSkill(ChosenSkill, Hero, Enemies, Screen)
                    if (Used?):
                        break
            else if (Main = 2):
                if (Items > 0):
                    MaybeAlly := ChooseAlly(Screen)
                    if (Ally := MaybeAlly?):
                        Screen.HideMenu()
                        set Items = Items - 1
                        Ally.Heal(TonicHeal)
                        Screen.SetMessage("{Hero.Name} da un tónico a {Ally.Name}: +{TonicHeal} PV.")
                        break
            else if (Main = 3):
                Screen.HideMenu()
                set Fled = true
                break
        Fled

    # Submenú de habilidades del héroe. Devuelve la elegida o nada si pulsa Volver.
    ChooseSkill(Hero:combatant, Screen:battle_ui)<suspends>:?skill =
        Labels := for (S : Hero.Skills) { "{S.Name} ({S.Cost} PA)" }
        Enabled := for (S : Hero.Skills) { logic{Hero.AP >= S.Cost} }
        Screen.SetMessage("{Hero.Name}: elige una habilidad ({Hero.AP} PA).")
        Pick := Screen.Ask(Labels, Enabled, true)
        if (Chosen := Hero.Skills[Pick], Hero.AP >= Chosen.Cost):
            option{Chosen}
        else:
            false

    # Aplica una habilidad. Devuelve false si el jugador se echa atrás al elegir objetivo.
    UseSkill(Chosen:skill, Hero:combatant, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:logic =
        var Used:logic = false
        if (Chosen.TargetsAlly?):
            MaybeAlly := ChooseAlly(Screen)
            if (Ally := MaybeAlly?):
                Screen.HideMenu()
                if (Chosen.HealAmount > 0):
                    Ally.Heal(Chosen.HealAmount)
                if (Chosen.GiveAP > 0):
                    set Ally.AP = Min(Ally.AP + Chosen.GiveAP, MaxAP)
                Screen.SetMessage("¡{Chosen.Name}! {Hero.Name} ayuda a {Ally.Name}.")
                set Used = true
        else if (Chosen.HarmonyTurns > 0):
            Screen.HideMenu()
            set HarmonyTurns = Chosen.HarmonyTurns
            Screen.SetMessage("¡{Chosen.Name}! El grupo hace +25 % de daño durante {Chosen.HarmonyTurns} rondas.")
            set Used = true
        else if (Chosen.HitsAll?):
            Screen.HideMenu()
            for (Slot : Enemies, not Slot.Fighter.IsDefeated[]):
                ApplySkillTo(Chosen, Hero, Slot)
            Screen.SetMessage("¡{Chosen.Name}! {Hero.Name} golpea a todos los enemigos.")
            set Used = true
        else:
            MaybeTarget := ChooseTarget(Enemies, Screen)
            if (Target := MaybeTarget?):
                Screen.HideMenu()
                Damage := ApplySkillTo(Chosen, Hero, Target)
                Screen.SetMessage("¡{Chosen.Name}! {Target.Fighter.Name} recibe {Damage} de daño.")
                set Used = true
        if (Used?):
            set Hero.AP = Hero.AP - Chosen.Cost
            # Kesh paga con su propia vida (nunca la deja a 0).
            if (Chosen.SelfCostPercent > 0.0, Cost := Floor[Hero.MaxHP * Chosen.SelfCostPercent]):
                Hero.TakeDamage(Min(Max(Cost, 1), Max(Hero.HP - 1, 0)))
        Used

    # Daño y estados de una habilidad sobre un enemigo. Devuelve el daño hecho.
    ApplySkillTo(Chosen:skill, Hero:combatant, Slot:enemy_slot):int =
        var Damage:int = 0
        if (Chosen.Multiplier > 0.0):
            set Damage = CalculateDamage(Hero, Slot.Fighter, Chosen.Multiplier * HarmonyMultiplier())
            Slot.Fighter.TakeDamage(Damage)
        if (Chosen.BurnTurns > 0):
            set Slot.Fighter.BurnTurns = Max(Slot.Fighter.BurnTurns, Chosen.BurnTurns)
        if (Chosen.StunTurns > 0):
            set Slot.Fighter.StunTurns = Max(Slot.Fighter.StunTurns, Chosen.StunTurns)
        if (Chosen.WeakTurns > 0):
            set Slot.Fighter.WeakTurns = Max(Slot.Fighter.WeakTurns, Chosen.WeakTurns)
        CheckDefeated(Slot)
        Damage

    # Elige un enemigo vivo. Con uno solo no pregunta.
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

    # Elige un aliado vivo. Con uno solo no pregunta.
    ChooseAlly(Screen:battle_ui)<suspends>:?combatant =
        Alive := AliveHeroes()
        if (Alive.Length = 1, Only := Alive[0]):
            option{Only}
        else:
            Labels := for (Hero : Alive) { "{Hero.Name} (PV {Hero.HP}/{Hero.MaxHP})" }
            Screen.SetMessage("Elige a un aliado.")
            Pick := Screen.Ask(Labels, array{}, true)
            if (Ally := Alive[Pick]):
                option{Ally}
            else:
                false

    # Turno de un enemigo: Quemadura, Aturdimiento o ataque (con combo) contra un héroe al azar.
    EnemyTurn(Slot:enemy_slot, Enemies:[]enemy_slot, Screen:battle_ui)<suspends>:void =
        Enemy := Slot.Fighter
        Burn := Enemy.StartTurn()
        if (Burn > 0):
            Screen.SetMessage("{Enemy.Name} arde: {Burn} de daño.")
            CheckDefeated(Slot)
            Refresh(Screen, Enemies, "")
            Sleep(1.0)
        if (Enemy.IsDefeated[]):
            return
        if (Enemy.StunTurns > 0):
            set Enemy.StunTurns = Enemy.StunTurns - 1
            Screen.SetMessage("{Enemy.Name} está aturdido y pierde su turno.")
            Sleep(1.2)
            return

        Alive := AliveHeroes()
        if (Target := Alive[GetRandomInt(0, Alive.Length - 1)]):
            Pattern := Enemy.Pattern
            Hits := Pattern.FollowUpGaps.Length + 1
            if (Hits > 1):
                Screen.SetMessage("¡{Enemy.Name} prepara {Pattern.Name} contra {Target.Name}! ({Hits} golpes)")
            else:
                Screen.SetMessage("¡{Enemy.Name} prepara {Pattern.Name} contra {Target.Name}!")
            ResolveHit(Slot, Target, Screen, GetRandomFloat(Pattern.MinWindup, Pattern.MaxWindup))
            Refresh(Screen, Enemies, "")
            var HitIndex:int = 0
            loop:
                if (HitIndex >= Pattern.FollowUpGaps.Length):
                    break
                if (Gap := Pattern.FollowUpGaps[HitIndex], not Target.IsDefeated[], not Enemy.IsDefeated[]):
                    ResolveHit(Slot, Target, Screen, Gap)
                    Refresh(Screen, Enemies, "")
                set HitIndex = HitIndex + 1
            Sleep(1.2)

    # Un golpe enemigo con su ventana de reacción.
    ResolveHit(Slot:enemy_slot, Target:combatant, Screen:battle_ui, Windup:float)<suspends>:void =
        Enemy := Slot.Fighter
        ImpactTime := GetSimulationElapsedTime() + Windup
        spawn{ AnimateAttack(Slot, Windup) }

        Result := WaitForReaction(ImpactTime)
        # Si el jugador reaccionó antes, esperamos al impacto para mostrar el resultado a tiempo.
        Remaining := ImpactTime - GetSimulationElapsedTime()
        if (Remaining > 0.0):
            Sleep(Remaining)

        if (Result = dodge_result.Parry):
            set Target.AP = Min(Target.AP + 1, MaxAP)
            if (Target.UsesRhythm?):
                set Target.Rhythm = Min(Target.Rhythm + 2, MaxRhythm)
            Counter := CalculateDamage(Target, Enemy, CounterMultiplier)
            Enemy.TakeDamage(Counter)
            CheckDefeated(Slot)
            Screen.SetMessage("¡CONTRATIEMPO! {Target.Name} bloquea y contraataca: {Counter} de daño.")
        else if (Result = dodge_result.Dodge):
            if (Target.UsesRhythm?):
                set Target.Rhythm = Min(Target.Rhythm + 1, MaxRhythm)
            Screen.SetMessage("¡{Target.Name} esquiva el golpe!")
        else:
            Damage := CalculateDamage(Enemy, Target, Enemy.Pattern.HitMultiplier)
            Target.TakeDamage(Damage)
            set Target.Rhythm = 0
            if (Enemy.Pattern.WeakTurns > 0):
                set Target.WeakTurns = Max(Target.WeakTurns, Enemy.Pattern.WeakTurns)
            if (Result = dodge_result.Early):
                Screen.SetMessage("¡Demasiado pronto! {Enemy.Name} golpea a {Target.Name}: {Damage} de daño.")
            else:
                Screen.SetMessage("{Enemy.Name} golpea a {Target.Name}: {Damage} de daño.")

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

    HarmonyMultiplier()<transacts>:float =
        if (HarmonyTurns > 0) then HarmonyBonus else 1.0

    AliveHeroes()<transacts>:[]combatant =
        for (Hero : Party, not Hero.IsDefeated[]) { Hero }

    AliveCount(Enemies:[]enemy_slot)<transacts>:int =
        Alive := for (Slot : Enemies, not Slot.Fighter.IsDefeated[]) { Slot }
        Alive.Length

    AnySkillAffordable(Hero:combatant)<transacts><decides>:void =
        Affordable := for (S : Hero.Skills, Hero.AP >= S.Cost) { S }
        Affordable.Length > 0

    # Actualiza la interfaz. ActiveName marca con ▶ al héroe que tiene el turno.
    Refresh(Screen:battle_ui, Enemies:[]enemy_slot, ActiveName:string):void =
        PartyLines := for (Hero : Party):
            Marker := if (Hero.Name = ActiveName) then "▶ " else "   "
            if (Hero.IsDefeated[]):
                "{Marker}{Hero.Name}: fuera de combate"
            else:
                RhythmText := if (Hero.UsesRhythm?) then "   Ritmo {Hero.Rhythm}" else ""
                "{Marker}{Hero.Name} Nv{Hero.Level}   PV {Hero.HP}/{Hero.MaxHP}   PA {Hero.AP}{RhythmText}{Hero.StatusText()}"
        Screen.SetPartyLines(PartyLines)
        EnemyLines := for (Slot : Enemies):
            if (Slot.Fighter.IsDefeated[]):
                "{Slot.Fighter.Name}: derrotado"
            else:
                "{Slot.Fighter.Name}   PV {Slot.Fighter.HP}/{Slot.Fighter.MaxHP}{Slot.Fighter.StatusText()}"
        Screen.SetEnemyLines(EnemyLines)
        if (HarmonyTurns > 0):
            Screen.SetHarmony("Armonía: {HarmonyTurns} ronda(s)   Tónicos {Items}")
        else:
            Screen.SetHarmony("Tónicos {Items}")
