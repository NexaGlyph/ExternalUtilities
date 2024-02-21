package optional

Optional :: struct($T: typeid) {
    _val: T,
}

init :: proc(val: $T) -> Optional(T) {
    return {
        _val = val,
    };
}

get :: proc(this: ^Optional($T)) -> ^T {
    return &this^._val;
}