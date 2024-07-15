package mixer

Mixer :: struct {
    cache: SoundCache,
    device: DeviceManager,
    volume: f32,
    is_playing: bool,
    queue: PlaybackQueue,
    using _scheduler: Scheduler,
}

// Function to initialize the audio manager
init :: proc(device_configs: DeviceConfiguraion, num_sounds: int = DEFAULT_SOUND_CACHE_SIZE) -> (mixer: Mixer) {
    mixer.cache = init_cache(num_sounds);
    mixer.device = init_device_manager(device_configs);
    mixer.volume = 1.0;
    mixer.is_playing = false;
    mixer.queue = init_queue();
    return;
}

configure_output_device :: proc(mixer: ^Mixer, format: SoundFormat) {
    assert(false, "TO DO!");
}

configure_input_device :: proc(mixer: ^Mixer, format: SoundFormat) {
    assert(false, "TO DO!");
}

// Function to load a sound to the cache
load :: proc(using mixer: ^Mixer, filename: string) -> SoundID {
    assert(false, "TO DO!");
    return 0;
}

// Function to play a sound
play :: proc(using mixer: ^Mixer, sound_id: SoundID, config: PlaybackSoundConfig = DEFAULT_PLAYBACK_SOUND_CONFIG) {
    (mixer^).play(mixer, sound_id, config);
    mixer.is_playing = true;
}

@(private="package")
_play :: proc(using mixer: ^Mixer, sound_id: ^SoundID, config: ^PlaybackSoundConfig) {
    // enqueue the sound
    enqueue_sound(mixer, sound_id^);
}

// Function to pause a sound
pause :: proc(using mixer: ^Mixer, sound_id: SoundID) {
    mixer.is_playing = false;
}

// Function to stop a sound
stop :: proc(using mixer: ^Mixer, sound_id: SoundID) {
    mixer.is_playing = false;
}

set_volume :: #force_inline proc(using mixer: ^Mixer, new_volume: f32) {
    volume = new_volume;
}

get_playback_state :: proc(mixer: ^Mixer) -> PlaybackState {
    assert(false, "TO DO!");
    return PlaybackState.Paused;
}

// Function to unload a sound from the cache
unload :: proc(using mixer: ^Mixer, sound_id: SoundID) {}

// Function to clean up the audio manager
dump :: #force_inline proc(using mixer: ^Mixer) {
    dump_cache(&mixer.cache);
    dump_device_manager(&mixer.device);
    dump_queue(&mixer.queue);
}