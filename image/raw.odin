package image;

// import "core:mem"

RawImageDescriptor :: ImageInfoUUID;

RawImage :: struct {
    size: ImageSize,
    data: rawptr, // raw_data of the PixelType[]

    // additional
    info: RawImageDescriptor,
}

bgr_to_raw :: #force_inline proc "contextless" (using img: ^Image2(BGR($PixelData))) -> RawImage {
    return {
        size = size,
        data = raw_data(data),
        info = info, 
    };
}

rgba_to_raw :: #force_inline proc "contextless" (using img: ^Image2(RGBA($PixelData))) -> (ri: RawImage) {
    ri.size = size;
    ri.data = raw_data(data);
    ri.info = info;
    return;
}

from_raw_bgr :: #force_inline proc(using img: ^RawImage, $PixelT: typeid) -> (final_img: Image2(PixelT)) { 
    final_img.size = size;
    final_img.info = info;
    final_img.data = make([]PixelT, size.x * size.y);
    mem.copy(raw_data(final_img.data), data, size_of(PixelT) * int(size.x * size.y));
    return;
}

from_raw_rgba :: #force_inline proc(using img: ^RawImage) -> Image2(RGBA($PixelData)) {
    assert(false, "TODO!");
}

dump_raw :: #force_inline proc(using img: ^RawImage) {
    free(data);
}