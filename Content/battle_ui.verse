# battle_ui.verse — Interfaz del combate: estado de los combatientes, mensajes y menú de turno.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# Convierte un texto en `message` para los widgets.
ToMessage<localizes>(Text:string):message = "{Text}"

# Acciones que el jugador puede elegir en su turno.
battle_action := enum:
    Attack
    Skill
    Item
    Flee

battle_ui := class:
    PlayerUI:player_ui

    HeroText:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 30.0}
    EnemyText:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 30.0}
    MessageText:text_block = text_block{DefaultTextColor := NamedColors.Gold, DefaultTextSize := 34.0}

    # Los textos de los botones se asignan en Init() y Refresh().
    AttackButton:button_loud = button_loud{}
    SkillButton:button_regular = button_regular{}
    ItemButton:button_regular = button_regular{}
    FleeButton:button_quiet = button_quiet{}

    # Se emite cuando el jugador pulsa un botón del menú.
    ActionChosen:event(battle_action) = event(battle_action){}

    var MaybeHud:?canvas = false
    var MaybeMenu:?canvas = false
    var MenuVisible:logic = false

    # Prepara los widgets y suscribe los botones. Llamar una vez tras crear la interfaz.
    Init():void =
        AttackButton.SetText(ToMessage("Atacar"))
        SkillButton.SetText(ToMessage("Redoble"))
        ItemButton.SetText(ToMessage("Tónico"))
        FleeButton.SetText(ToMessage("Huir"))
        AttackButton.OnClick().Subscribe(OnAttackClicked)
        SkillButton.OnClick().Subscribe(OnSkillClicked)
        ItemButton.OnClick().Subscribe(OnItemClicked)
        FleeButton.OnClick().Subscribe(OnFleeClicked)

        Hud := canvas:
            Slots := array:
                MakeSlot(HeroText, 0.20, 0.82)
                MakeSlot(EnemyText, 0.80, 0.15)
                MakeSlot(MessageText, 0.50, 0.06)
        set MaybeHud = option{Hud}

        MenuBox := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                MakeMenuSlot(AttackButton)
                MakeMenuSlot(SkillButton)
                MakeMenuSlot(ItemButton)
                MakeMenuSlot(FleeButton)
        Menu := canvas:
            Slots := array:
                MakeSlot(MenuBox, 0.82, 0.72)
        set MaybeMenu = option{Menu}

    # Muestra el estado del combate (sin menú).
    Show():void =
        if (Hud := MaybeHud?):
            PlayerUI.AddWidget(Hud, player_ui_slot{InputMode := ui_input_mode.None})

    # Quita toda la interfaz del combate.
    Hide():void =
        HideMenu()
        if (Hud := MaybeHud?):
            PlayerUI.RemoveWidget(Hud)

    # Muestra el menú de turno. Los botones que no se pueden usar quedan desactivados.
    ShowMenu(CanUseSkill:logic, CanUseItem:logic):void =
        SkillButton.SetEnabled(CanUseSkill)
        ItemButton.SetEnabled(CanUseItem)
        if (not MenuVisible?, Menu := MaybeMenu?):
            PlayerUI.AddWidget(Menu, player_ui_slot{InputMode := ui_input_mode.All})
            set MenuVisible = true

    # Oculta el menú para que el teclado vuelva a llegar al juego (esquivas).
    HideMenu():void =
        if (MenuVisible?, Menu := MaybeMenu?):
            PlayerUI.RemoveWidget(Menu)
            set MenuVisible = false

    # Espera a que el jugador elija una acción.
    WaitForAction()<suspends>:battle_action =
        ActionChosen.Await()

    SetMessage(Text:string):void =
        MessageText.SetText(ToMessage(Text))

    # Actualiza vida, PA y objetos.
    Refresh(Hero:combatant, Enemy:combatant, AP:int, Items:int, SkillCost:int):void =
        HeroText.SetText(ToMessage("{Hero.Name}   PV {Hero.HP}/{Hero.MaxHP}   PA {AP}   Tónicos {Items}"))
        EnemyText.SetText(ToMessage("{Enemy.Name}   PV {Enemy.HP}/{Enemy.MaxHP}"))
        SkillButton.SetText(ToMessage("Redoble ({SkillCost} PA)"))
        ItemButton.SetText(ToMessage("Tónico (x{Items})"))

    OnAttackClicked(Message:widget_message):void = ActionChosen.Signal(battle_action.Attack)
    OnSkillClicked(Message:widget_message):void = ActionChosen.Signal(battle_action.Skill)
    OnItemClicked(Message:widget_message):void = ActionChosen.Signal(battle_action.Item)
    OnFleeClicked(Message:widget_message):void = ActionChosen.Signal(battle_action.Flee)

# Ranura de canvas centrada en una posición relativa de la pantalla (0.0 a 1.0).
MakeSlot(W:widget, X:float, Y:float):canvas_slot =
    canvas_slot:
        Anchors := anchors{Minimum := vector2{X := X, Y := Y}, Maximum := vector2{X := X, Y := Y}}
        Alignment := vector2{X := 0.5, Y := 0.5}
        SizeToContent := true
        Widget := W

MakeMenuSlot(W:widget):stack_box_slot =
    stack_box_slot:
        Widget := W
        HorizontalAlignment := horizontal_alignment.Fill
        Padding := margin{Top := 6.0, Bottom := 6.0}
