package mixer

foreign import "external/lib/libaudio.lib" {
    open_audio_odvice :: proc "cdecl" (odesc: ^OutputDeviceDescription) -> HWAVEOUT {

    }
}