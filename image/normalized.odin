package image;

Unorm :: distinct f32;

UnormRGB :: struct #align (4) { // even though there is no alpha channel, we will pad the struct as if there were 4th byte
    r, g, b: Unorm,
}
UnormBGR :: struct {
    using bgr: #type struct #packed {
        b, g, r: Unorm,
        x: u8,
    },
}
UNORM_BGR :: #force_inline proc(b: Unorm, g: Unorm, r: Unorm) -> UnormBGR {
    return {
        b = b,
        g = g, 
        r = r,
    };
}
UnormRGBA :: struct {
    using rgba: #type struct #packed {
        r, g, b, a: Unorm,
    },
}

@(private="file")
NormalizedBuffer :: struct($PixelType: typeid) #no_copy {
    size: ImageSize,
    data: []PixelType,
}

UnormImageBGR  :: NormalizedBuffer(UnormBGR);
UnormImageRGBA :: NormalizedBuffer(UnormRGBA);

copy_transform :: proc($FROM: typeid, $TO: typeid, data: []FROM, transform_func: #type proc(val: FROM) -> TO) -> ^[]TO {
    copy_buffer := make([]TO, len(data));
    for i in 0..<len(data) do copy_buffer[i] = transform_func(data[i]);
    return &copy_buffer;
}

@(private="file")
to_normalized1 :: proc(using img: ^Image) {
    assert(false, "TO DO!");
}

@(private="file")
to_normalized_bgr :: proc(using img: ^Image2(BGR($PixelData))) -> UnormImageBGR {
    return {
        size = size,
        data = copy_transform(BGR, UnormBGR, data, proc(val: BGR) -> UnormBGR {
            return UNORM_BGR(
                cast(Unorm)(val.bgr.b) / 255, cast(Unorm)(val.bgr.g) / 255, cast(Unorm)(val.bgr.r) / 255,
            );
        })^,
    };
}

// @(private="file")
// to_normalized_rgba :: proc(using img: ^ImageRGBA) {
//     assert(false, "TO DO!");
// }

to_normalized :: proc { to_normalized1, to_normalized_bgr, /*to_normalized_rgba*/ }

@(private="file")
dump_normalized1 :: proc(using img: ^NormalizedBuffer) {
    assert(false, "TO DO!");
}

@(private="file")
dump_normalized_bgr :: #force_inline proc(using img: ^UnormImageBGR) {
    delete(data);
}

@(private="file")
dump_normalized_rgba :: proc(using img: ^UnormImageRGBA) {
    assert(false, "TO DO!");
}

dump_normalized :: proc { dump_normalized1, dump_normalized_bgr, dump_normalized_rgba }