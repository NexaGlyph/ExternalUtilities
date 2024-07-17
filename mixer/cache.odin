package mixer

SoundID :: i32;

get_id :: proc(sound_name: string) -> SoundID {
    assert(false, "TO DO!");
    return 0;
}

DEFAULT_SOUND_CACHE_SIZE :: 16;
SoundCache :: map[SoundID]Sound;

init_cache :: #force_inline proc(size: int) -> SoundCache {
    return make_map(SoundCache, size);
}

load_or_push_sound :: proc(cache: ^SoundCache, sound_name: string) -> ^Sound {
    id := get_id(sound_name);
    sound, found := &cache[id];
    if found do return sound;
    cache[id] = init_sound(sound_name);
    return &cache[id];
}

dump_cache :: #force_inline proc(cache: ^SoundCache) {
    for _, val in cache do dump_sound(&val);
    delete_map(cache^);
}