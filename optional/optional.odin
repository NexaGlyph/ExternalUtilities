package optional

Optional :: struct($T: typeid) {
    has_val: bool,
    _val: T,
}

init_value :: proc(val: $T) -> Optional(T) {
    return {
        has_val = true,
        _val = val,
    };
}

init_empty :: proc($T: typeid) -> Optional(T) {
    return Optional(T) {
        has_val = false,
    };
}

init :: proc { init_empty, init_value }

some :: #force_inline proc(this: ^Optional($T)) -> bool {
    return this^.has_val;
}

NO_PTR :: true;

get_copy :: proc(this: ^Optional($T), _: bool) -> T {
    return this^._val;
}

get_ptr :: proc(this: ^Optional($T)) -> ^T {
    return &this^._val;
}

get :: proc { get_copy, get_ptr }