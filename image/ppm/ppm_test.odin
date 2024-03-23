package main

import "core:log"

import image       "../../image"
import performance "../../performance_profiler"
import ppm         "../ppm"

main :: proc() {
    context.logger = log.create_console_logger();

    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR8{
            size = image.IMAGE_SIZE(1920, 1080),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        ppm.ppm_write2_bgr(&generated_image, "bgr8.ppm");
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));
}