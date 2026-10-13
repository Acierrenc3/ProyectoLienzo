# battle_ui.verse — Interfaz del combate: estado de los combatientes, mensajes y menús.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# Convierte un texto en `message` para los widgets.
ToMessage<localizes>(Text:string):message = "{Text}"

# Interfaz reutilizable: un menú de hasta 6 opciones + "Volver".
# Ask() devuelve el índice de la opción elegida (0-5) o -1 si se pulsa "Volver".
battle_ui := class:
    PlayerUI:player_ui

    PartyText0:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 24.0}
    PartyText1:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 24.0}
    PartyText2:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 24.0}
    EnemyText0:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    EnemyText1:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    EnemyText2:text_block = text_block{DefaultTextColor := NamedColors.Tomato, DefaultTextSize := 26.0}
    MessageText:text_block = text_block{DefaultTextColor := NamedColors.Gold, DefaultTextSize := 32.0}
    HarmonyText:text_block = text_block{DefaultTextColor := NamedColors.SkyBlue, DefaultTextSize := 22.0}

    # Los textos de los botones se asignan en ShowMenu().
    Button0:button_regular = button_regular{}
    Button1:button_regular = button_regular{}
    Button2:button_regular = button_regular{}
    Button3:button_regular = button_regular{}
    Button4:button_regular = button_regular{}
    Button5:button_regular = button_regular{}
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
        Button4.OnClick().Subscribe(OnButton4)
        Button5.OnClick().Subscribe(OnButton5)
        BackButton.OnClick().Subscribe(OnBack)

        Hud := canvas:
            Slots := array:
                MakeSlot(MessageText, 0.50, 0.06)
                MakeSlot(EnemyText0, 0.50, 0.12)
                MakeSlot(EnemyText1, 0.50, 0.16)
                MakeSlot(EnemyText2, 0.50, 0.20)
                MakeSlot(HarmonyText, 0.24, 0.64)
                MakeSlot(PartyText0, 0.24, 0.68)
                MakeSlot(PartyText1, 0.24, 0.72)
                MakeSlot(PartyText2, 0.24, 0.76)
        set MaybeHud = option{Hud}

        MenuBox := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                MakeMenuSlot(Button0)
                MakeMenuSlot(Button1)
                MakeMenuSlot(Button2)
                MakeMenuSlot(Button3)
                MakeMenuSlot(Button4)
                MakeMenuSlot(Button5)
                MakeMenuSlot(BackButton)
        Menu := canvas:
            Slots := array:
                MakeSlot(MenuBox, 0.84, 0.62)
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
        Buttons:[]button_regular = array{Button0, Button1, Button2, Button3, Button4, Button5}
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

    SetHarmony(Text:string):void =
        HarmonyText.SetText(ToMessage(Text))

    # Actualiza las líneas del grupo (hasta 3). Las que sobran quedan vacías.
    SetPartyLines(Lines:[]string):void =
        Texts:[]text_block = array{PartyText0, PartyText1, PartyText2}
        for (Index -> Text : Texts):
            if (Line := Lines[Index]):
                Text.SetText(ToMessage(Line))
            else:
                Text.SetText(ToMessage(""))

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
    OnButton4(Message:widget_message):void = Choice.Signal(4)
    OnButton5(Message:widget_message):void = Choice.Signal(5)
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

# Interfaz durante la exploración: estado del héroe y mensajes.
explore_ui := class:
    PlayerUI:player_ui
    HeroText:text_block = text_block{DefaultTextColor := NamedColors.White, DefaultTextSize := 24.0}
    MessageText:text_block = text_block{DefaultTextColor := NamedColors.Gold, DefaultTextSize := 30.0}
    var MaybeHud:?canvas = false
    var Visible:logic = false
    # Cada mensaje nuevo invalida el borrado programado del anterior.
    var MessageId:int = 0

    Init():void =
        Hud := canvas:
            Slots := array:
                MakeSlot(MessageText, 0.50, 0.10)
                MakeSlot(HeroText, 0.15, 0.80)
        set MaybeHud = option{Hud}

    Show():void =
        if (not Visible?, Hud := MaybeHud?):
            PlayerUI.AddWidget(Hud, player_ui_slot{InputMode := ui_input_mode.None})
            set Visible = true

    Hide():void =
        if (Visible?, Hud := MaybeHud?):
            PlayerUI.RemoveWidget(Hud)
            set Visible = false

    SetHeroLine(Text:string):void =
        HeroText.SetText(ToMessage(Text))

    # Muestra un mensaje y lo borra pasados unos segundos.
    Notify(Text:string):void =
        set MessageId = MessageId + 1
        MessageText.SetText(ToMessage(Text))
        spawn{ ClearLater(MessageId) }

    ClearLater(Id:int)<suspends>:void =
        Sleep(4.0)
        if (Id = MessageId):
            MessageText.SetText(ToMessage(""))
