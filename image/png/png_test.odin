package main

import "core:log"

import image       "../../image"
import performance "../../performance_profiler"
import png         "../png"

main :: proc() {
    context.logger = log.create_console_logger();
   
    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR8{
            size = image.IMAGE_SIZE(500, 500),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        png.png_write_bgr8(&generated_image, "bgr8.png");
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR16{
            size = image.IMAGE_SIZE(1920, 1080),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT16_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        png.png_write_bgr16(&generated_image, "bgr16.png");
        assert(false, "do the 'file extension checking'");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR32{
            size = image.IMAGE_SIZE(1920, 1080),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT32_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        png.png_write_bgr32(&generated_image, "bgr32.png");
        assert(false, "do the 'file extension checking'");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));
}