package mixer

Sound :: struct #no_copy {
    format_type: AudioFormatType,
    using data: struct #raw_union {
        mp3: MP3_DESC,
        wav: WAV_DESC,
    },
    audio_effect: AudioEffect,
}

init_sound :: proc(sound_name: string) -> Sound {
    assert(false, "TO DO!");
    return {};
}

apply_audio_effect :: proc(sound: ^Sound, effect: AudioEffect) {
    assert(false, "TO DO!");
}

dump_sound :: proc(sound: ^Sound) {
    assert(false, "TO DO!");
}