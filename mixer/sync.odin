package mixer

import tr "core:thread"

@(private="package")
Scheduler :: struct {
	thread: ^tr.Thread,
	play:   #type proc(
		using mixer: ^Mixer,
		sound_id: SoundID,
		config: PlaybackSoundConfig = DEFAULT_PLAYBACK_SOUND_CONFIG,
	),
}

@(private="package")
init_scheduler :: proc() -> (s: Scheduler) {
	s.play = scheduler_play;
	return;
}

@(private="package")
scheduler_play :: proc(
	mixer: ^Mixer,
	sound_id: SoundID,
	config: PlaybackSoundConfig = DEFAULT_PLAYBACK_SOUND_CONFIG,
) {
    sound_id := sound_id;
    config   := config;
    mixer^.thread = tr.create(_scheduler_play);
	mixer^.thread^.user_args[0] = auto_cast mixer;
	mixer^.thread^.user_args[1] = auto_cast &sound_id;
	mixer^.thread^.user_args[2] = auto_cast &config;
	tr.start(mixer^.thread);
}

@(private="package")
_scheduler_play :: proc(using thread: ^tr.Thread) {
	_play(
		cast(^Mixer)user_args[0],
		(cast(^SoundID)user_args[1]),
		(cast(^PlaybackSoundConfig)user_args[2]),
	);
    tr.destroy(thread);
}

@(private="package")
dump_scheduler :: proc(using scheduler: Scheduler) {
	if thread != nil do tr.destroy(thread);
}