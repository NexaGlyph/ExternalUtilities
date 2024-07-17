package mixer

PlaybackState :: enum {
    Stopped,
    Paused,
    Playing,
}

PlaybackSoundConfig :: struct {
    start: int,
    end: int,
    blend: bool, // whether it should start immediately even if other sound is playing 
}

DEFAULT_PLAYBACK_SOUND_CONFIG :: PlaybackSoundConfig {
    start = 0, // start from the beginning
    end = -1, // -1 for the end of the track
    blend = false,
}

PlaybackQueue :: struct {

}

init_queue :: proc() -> PlaybackQueue {
    assert(false, "TO DO!");
    return {};
}

change_queue_state :: proc(using queue: ^PlaybackQueue, state: PlaybackState) {
    assert(false, "TO DO!");
    switch(state) {
        case .Paused:
        case .Playing:
        case .Stopped:
            break;
    }
}

enqueue_sound :: proc(mixer: ^Mixer, sound_id: SoundID) {
    assert(false, "TO DO!");
}

dequeue_sound :: proc(mixer: ^Mixer, sound_id: SoundID) {
    assert(false, "TO DO!");
}

dump_queue :: proc(using queue: ^PlaybackQueue) {
    assert(false, "TO DO!");
}