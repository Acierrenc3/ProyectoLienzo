# battle_ui.verse — Interfaz del combate: estado de los combatientes, mensajes y menús.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# Convierte un texto en `message` para los widgets.
ToMessage<localizes>(Text:string):message = "{Text}"

# Interfaz reutilizable: un menú de hasta 4 opciones + "Volver".
# Ask() devuelve el índice de la opción elegida (0-3) o -1 si se pulsa "Volver".
battle_ui := class:
    PlayerUI:player_ui

    HeroText:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 28.0}
    EnemyText0:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    EnemyText1:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    EnemyText2:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    MessageText:text_block = text_block{DefaultTextColor := NamedColors.Gold, DefaultTextSize := 32.0}

    # Los textos de los botones se asignan en ShowMenu().
    Button0:button_regular = button_regular{}
    Button1:button_regular = button_regular{}
    Button2:button_regular = button_regular{}
    Button3:button_regular = button_regular{}
    BackButton:button_quiet = button_quiet{}

    # Se emite con el índice del botón pulsado (-1 = Volver).
    Choice:event(int) = event(int){}

    var MaybeHud:?canvas = false
    var MaybeMenu:?canvas = false
    var MenuVisible:logic = false

    # Prepara los widgets y suscribe los botones. Llamar una vez tras crear la interfaz.
    Init():void =
        BackButton.SetText(ToMessage("Volver"))
        Button0.OnClick().Subscribe(OnButton0)
        Button1.OnClick().Subscribe(OnButton1)
        Button2.OnClick().Subscribe(OnButton2)
        Button3.OnClick().Subscribe(OnButton3)
        BackButton.OnClick().Subscribe(OnBack)

        Hud := canvas:
            Slots := array:
                MakeSlot(MessageText, 0.50, 0.06)
                MakeSlot(EnemyText0, 0.50, 0.12)
                MakeSlot(EnemyText1, 0.50, 0.16)
                MakeSlot(EnemyText2, 0.50, 0.20)
                MakeSlot(HeroText, 0.24, 0.82)
        set MaybeHud = option{Hud}

        MenuBox := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                MakeMenuSlot(Button0)
                MakeMenuSlot(Button1)
                MakeMenuSlot(Button2)
                MakeMenuSlot(Button3)
                MakeMenuSlot(BackButton)
        Menu := canvas:
            Slots := array:
                MakeSlot(MenuBox, 0.84, 0.68)
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

    # Muestra el menú con las etiquetas dadas. Enabled[i] = false desactiva la opción i.
    ShowMenu(Labels:[]string, Enabled:[]logic, AllowBack:logic):void =
        Buttons:[]button_regular = array{Button0, Button1, Button2, Button3}
        for (Index -> Button : Buttons):
            if (Label := Labels[Index]):
                Button.SetText(ToMessage(Label))
                Button.SetVisibility(widget_visibility.Visible)
                if (IsOn := Enabled[Index]):
                    Button.SetEnabled(IsOn)
                else:
                    Button.SetEnabled(true)
            else:
                Button.SetVisibility(widget_visibility.Collapsed)
        if (AllowBack?):
            BackButton.SetVisibility(widget_visibility.Visible)
        else:
            BackButton.SetVisibility(widget_visibility.Collapsed)
        if (not MenuVisible?, Menu := MaybeMenu?):
            PlayerUI.AddWidget(Menu, player_ui_slot{InputMode := ui_input_mode.All})
            set MenuVisible = true

    # Oculta el menú para que el teclado vuelva a llegar al juego (esquivas).
    HideMenu():void =
        if (MenuVisible?, Menu := MaybeMenu?):
            PlayerUI.RemoveWidget(Menu)
            set MenuVisible = false

    # Muestra un menú y espera la elección del jugador.
    Ask(Labels:[]string, Enabled:[]logic, AllowBack:logic)<suspends>:int =
        ShowMenu(Labels, Enabled, AllowBack)
        Choice.Await()

    SetMessage(Text:string):void =
        MessageText.SetText(ToMessage(Text))

    # Actualiza la línea del héroe.
    SetHeroLine(Text:string):void =
        HeroText.SetText(ToMessage(Text))

    # Actualiza las líneas de los enemigos (hasta 3). Las que sobran quedan vacías.
    SetEnemyLines(Lines:[]string):void =
        Texts:[]text_block = array{EnemyText0, EnemyText1, EnemyText2}
        for (Index -> Text : Texts):
            if (Line := Lines[Index]):
                Text.SetText(ToMessage(Line))
            else:
                Text.SetText(ToMessage(""))

    OnButton0(Message:widget_message):void = Choice.Signal(0)
    OnButton1(Message:widget_message):void = Choice.Signal(1)
    OnButton2(Message:widget_message):void = Choice.Signal(2)
    OnButton3(Message:widget_message):void = Choice.Signal(3)
    OnBack(Message:widget_message):void = Choice.Signal(-1)

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
