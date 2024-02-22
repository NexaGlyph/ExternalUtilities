package image

import "core:math/rand"

IMAGE_SIZE :: #force_inline proc(#any_int x, y: u32) -> ImageSize {
    return ImageSize{ x, y }; 
}

Image :: struct #no_copy {
    size: ImageSize,
    uuid: ImageTypeUUID,
    using _ : #type struct #raw_union {
        RGBA: #type struct {
            data: [][4]byte,
        },
        RGB: #type struct {
            data: [][3]byte,
        },
    },
}

generate_random_image :: proc(using img: ^Image, location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    
    if uuid == BGR_UUID {
        RGB.data  = make([][3]byte, size.x * size.y);
        
        for i in 0..<size.y {
            for j in 0..<size.x {
                #no_bounds_check RGB.data[j * (i + 1)].rgb = {
                    cast(byte)rand.float32() * 255, // R
                    cast(byte)rand.float32() * 255, // G
                    cast(byte)rand.float32() * 255, // B
                }; 
            }
        }
       
        return;
    }
    if uuid == RGBA_UUID {
        RGBA.data = make([][4]byte, size.x * size.y);
        
        for i in 0..<size.y {
            for j in 0..<size.x {
                RGBA.data[j * (i + 1)].rgba = {
                    cast(byte)rand.float32() * 255, // R
                    cast(byte)rand.float32() * 255, // G
                    cast(byte)rand.float32() * 255, // B
                    255,                            // A
                }; 
            }
        }
       
        return;
    }

    assert(false, "Unknown/invalid UUID provided...", location);
}

dump_image :: #force_inline proc(using img: ^Image) {
    if uuid == BGR_UUID  do delete(RGB.data);
    if uuid == RGBA_UUID do delete(RGBA.data);
}
