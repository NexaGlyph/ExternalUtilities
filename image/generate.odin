package image

import "core:mem"
import "core:math/rand"

/* PIXEL DATA BIT RANDOM GENERATION */
generate_random_pixel_data_ubgr :: #force_inline proc($PixelDataT: typeid/PixelData($U, $S)) -> BGR(PixelDataT) {
    return BGR(PixelDataT) {
        b = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        g = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        r = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        x = PixelDataT { data = cast(U)(0) },
    };
}

generate_random_pixel_data_sbgr :: #force_inline proc($PixelDataT: typeid/PixelData($U, $S)) -> BGR(PixelDataT) {
    return BGR(PixelDataT) {
        b = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        g = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        r = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        x = PixelDataT { data_s = cast(S)(0) },
    }
}

/* IMAGE DATA RANDOM GENERATION */
generate_random_image_ubgr :: proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_ubgr(PixelDataT);
    if info == 0 do info = BGR_UUID | (query_uUUID(PixelDataT) << 4);
}

generate_random_image_sbgr :: #force_inline proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_sbgr(PixelDataT);
    if info == 0 do info = BGR_UUID | (query_sUUID(PixelDataT) << 4);
}

generate_random_image_urgba :: proc(using img: ^Image2(RGBA($PixelDataT)), location := #caller_location) {
    assert(false, "to do!");
}

generate_random_image_srgba :: #force_inline proc(using img: ^Image2(RGBA($PixelDataT)), location := #caller_location) {
    assert(false, "to do!");
}
