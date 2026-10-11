# Dispositivo de prueba de la Fase 0: comprueba que el ciclo Claude Code -> UEFN funciona.
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

hello_device := class(creative_device):

    # Se ejecuta al empezar la partida.
    OnBegin<override>()<suspends>:void =
        Print("Proyecto Lienzo: Verse funciona")
