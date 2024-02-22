package optional

Optional :: struct($T: typeid) {
    _val: T,
}

init :: proc(val: $T) -> Optional(T) {
    return {
        _val = val,
    };
}

NO_PTR :: true;

get_copy :: proc(this: ^Optional($T), _: bool) -> T {
    return this^._val;
}

get_ptr :: proc(this: ^Optional($T)) -> ^T {
    return &this^._val;
}

get :: proc { get_copy, get_ptr }