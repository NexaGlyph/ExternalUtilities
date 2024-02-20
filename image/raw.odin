package image;

RawImageDescriptor :: ImageInfoUUID;

RawImage :: struct {
    size: ImageSize,
    data: rawptr, // raw_data of the PixelType[]

    // additional
    info: RawImageDescriptor,
}

@(private="file")
bgr_to_raw :: #force_inline proc(using img: ^Image2(BGR($PixelData))) -> RawImage {
    return {
        size = size,
        data = raw_data(data),
        info = info, 
    };
}

@(private="file")
rgba_to_raw :: #force_inline proc(using img: ^Image2(RGBA($PixelData))) -> (ri: RawImage) {
    ri.size = size;
    ri.data = raw_data(data);
    ri.info = info;
    return;
}

to_raw :: proc { bgr_to_raw, rgba_to_raw }

// @(private="file")
// from_raw_bgr :: #force_inline proc(using img: ^RawImage) -> Image2(BGR($PixelData)) {

// }
// @(private="file")
// from_raw_rgba :: #force_inline proc(using img: ^RawImage) -> Image2(RGBA($PixelData)) {

// }