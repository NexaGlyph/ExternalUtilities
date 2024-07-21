package main

import                "core:math"
import                "core:math/rand"
import                "core:log"
import                "core:mem"
import core_image_bmp "core:image/bmp"

import image        "nexa_external:image"
import bmp          "nexa_external:image/bmp"
import performance  "nexa_external:performance_profiler"
import logger       "nexa_external:logger"

test_image_write_random :: proc(profiler: ^performance.CPUTimer, img: $T/image.Image2($PixelT), $write_loc: string) {
    performance.begin(profiler);
    {
        img := img;
        image.generate_random_image_ubgr(&img);
        defer image.dump_image2(&img);
        bmp.bmp_write_bgr(&img, write_loc);
    }
    stamp := performance.end(profiler);
    log.infof("Time taken [\x1b[33m%s\x1b[0m]: %v ms", write_loc, performance.delta_milliseconds(stamp));
}

ColorGradient :: struct($PixelT: typeid) {
    begin: PixelT,
    end: PixelT,
}
ColorGradient8  :: ColorGradient(image.BGR8);
ColorGradient16 :: ColorGradient(image.BGR16);
ColorGradient32 :: ColorGradient(image.BGR32);

// this call invalidates the passed "img" param because the format does not have to be one byte per channel...
@(require_results)
test_image_write :: proc(profiler: ^performance.CPUTimer, img: $T/image.Image2($PixelT), color: ColorGradient(PixelT), $write_loc: string) -> image.ImageBGR8 {
    performance.begin(profiler);
    img := img;
    img_refactored := image.reinterpret_image_bgr(image.ImageBGR8, T, &img);
    {
        delta_color := [3]f32 {
            cast(f32)(color.end.r.data - color.begin.r.data) / cast(f32)(img.size.x - 1),
            cast(f32)(color.end.g.data - color.begin.g.data) / cast(f32)(img.size.x - 1),
            cast(f32)(color.end.b.data - color.begin.b.data) / cast(f32)(img.size.x - 1),
        }

        mem.zero_slice(img.data);
        img_refactored.data[0] = {
            { data = cast(u8)color.begin.r.data, },
            { data = cast(u8)color.begin.g.data, },
            { data = cast(u8)color.begin.b.data, },
        };
        for x in 0..<img.size.x {
            for y in 0..<img.size.y {
                img_refactored.data[y * img.size.x + x].r.data = cast(u8)(f32(color.begin.r.data) + cast(f32)(x) * delta_color[0]);
                img_refactored.data[y * img.size.x + x].g.data = cast(u8)(f32(color.begin.g.data) + cast(f32)(x) * delta_color[1]);
                img_refactored.data[y * img.size.x + x].b.data = cast(u8)(f32(color.begin.b.data) + cast(f32)(x) * delta_color[2]);
            }
        }

        bmp.bmp_write_bgr(&img_refactored, write_loc);
    }
    stamp := performance.end(profiler);
    log.infof("Time taken [\x1b[33m%s\x1b[0m]: %v ms", write_loc, performance.delta_milliseconds(stamp));
    return img_refactored;
}

test_image_read :: proc(profiler: ^performance.CPUTimer, $PixelT: typeid/image.BGR, $read_loc: string, $after_write_loc: string) {
    performance.begin(profiler);
    {
        // read getting RawImage
        // raw_img, rerr := bmp.bmp_read_bgr_auto(read_loc); // this causes crash inside the bmp_write_auto, reason yet unknown...
        img, rerr := bmp.bmp_read_bgr8(read_loc);
        log.assertf(rerr == .E_NONE, "FAILED TO READ BITMAP FILE! Err: %v", rerr);
        // note: this bmp_write_auto is faster but does not support any other image than that with UINT8_UUID set
        raw_img := image.bgr_to_raw(&img);
        defer image.dump_raw(&raw_img);
        assert(bmp.bmp_write_auto(&raw_img, after_write_loc) == .E_NONE);
    }
    stamp := performance.end(profiler);
    log.infof("Time taken [\x1b[33m%s\x1b[0m]: %v ms", read_loc, performance.delta_milliseconds(stamp));
}

main :: proc() {
    context.logger = log.create_console_logger();

    logger.log_custom(logger.GREEN, "[TEST BEGIN]")

    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    log.infof("IMAGE WRITING");

    // BGR BW
    {
        img := image.ImageBGR8{
            size = image.IMAGE_SIZE(800, 600),
            info = (image.UINT8_UUID << 4) | image.BGR_UUID,
            data = make([]image.BGR8, 800 * 600),
        };

        for i in 0..<len(img.data) {
            if rand.float32() > 0.5 {
                img.data[i].r = { data = 255, };
                img.data[i].g = { data = 255, };
                img.data[i].b = { data = 255, };
            } else {
                img.data[i].r = { data = 0, };
                img.data[i].g = { data = 0, };
                img.data[i].b = { data = 0, };
            }
        }
        test_image_write_random(&profiler, img, "bgr8_bw/random.bmp");
        new_img := test_image_write(&profiler, img, ColorGradient8 {
            begin = {
                r = { data = 0, },
                g = { data = 0, },
                b = { data = 0, },
            },
            end = {
                r = { data = 255, },
                g = { data = 255, },
                b = { data = 255, },
            },
        }, "bgr8_bw/gradient.bmp");
        image.dump_image2(&new_img);
    }

    // BGR8 WRITE
    {
        img := image.ImageBGR8{
            size = image.IMAGE_SIZE(800, 600),
            info = image.BGR_UUID | (image.UINT8_UUID << 4),
            data = make([]image.BGR8, 800 * 600),
        };
        test_image_write_random(&profiler, img, "bgr8/random.bmp");
        new_img := test_image_write(&profiler, img, ColorGradient8 {
            begin = {
                r = { data = 0, },
                g = { data = 100, },
                b = { data = 200, },
            },
            end = {
                r = { data = 200, },
                g = { data = 100, },
                b = { data = 0, },
            },
        }, "bgr8/gradient.bmp");
        image.dump_image2(&new_img);
    }

    // BGR16 WRITE
    {
        img := image.ImageBGR16{
            size = image.IMAGE_SIZE(800, 600),
            info = image.BGR_UUID | (image.UINT16_UUID << 4),
            data = make([]image.BGR16, 800 * 600),
        };
        test_image_write_random(&profiler, img, "bgr16/random.bmp");
        new_img := test_image_write(&profiler, img, ColorGradient16{
            begin = {
                r = { data = 0, },
                g = { data = 100, },
                b = { data = 200, },
            },
            end = {
                r = { data = 200, },
                g = { data = 100, },
                b = { data = 0, },
            },
        }, "bgr16/gradient.bmp");
        image.dump_image2(&new_img);
    }

    // // BGR32 WRITE
    {
        img := image.ImageBGR32{
            size = image.IMAGE_SIZE(800, 600),
            info = image.BGR_UUID | (image.UINT32_UUID << 4),
            data = make([]image.BGR32, 800 * 600),
        };
        test_image_write_random(&profiler, img, "bgr32/random.bmp");
        new_img := test_image_write(&profiler, img, ColorGradient32 {
            begin = {
                r = { data = 30, },
                g = { data = 60, },
                b = { data = 90, },
            },
            end = {
                r = { data = 120, },
                g = { data = 150, },
                b = { data = 180, },
            }, 
        }, "bgr32/gradient.bmp");
        image.dump_image2(&new_img);
    }

    log.infof("IMAGE READING");
    {
        test_image_read(&profiler, image.BGR8, "bgr8_bw/random.bmp", "bgr8_bw/random_after.bmp");
        test_image_read(&profiler, image.BGR8, "bgr8_bw/gradient.bmp", "bgr8_bw/gradient_after.bmp");
    }
    {
        test_image_read(&profiler, image.BGR8, "bgr8/random.bmp", "bgr8/random_after.bmp");
        test_image_read(&profiler, image.BGR8, "bgr8/gradient.bmp", "bgr8/gradient_after.bmp");
    }
    {
        test_image_read(&profiler, image.BGR16, "bgr16/random.bmp", "bgr16/random_after.bmp");
        test_image_read(&profiler, image.BGR16, "bgr16/gradient.bmp", "bgr16/gradient_after.bmp");
    }
    {
        test_image_read(&profiler, image.BGR32, "bgr32/random.bmp", "bgr32/random_after.bmp");
        test_image_read(&profiler, image.BGR32, "bgr32/gradient.bmp", "bgr32/gradient_after.bmp");
    }

    logger.log_custom(logger.GREEN, "[TEST END]");
}