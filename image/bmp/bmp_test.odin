package main

import "core:log"

import bmp "../bmp"
import image "../../image"
import performance "../../performance_profiler"
LOGGER_AVAILABLE :: #config(LOGGER_AVAILABLE, false); // if 'image' package can communicate to other packages, use custom logging
import logger "../../logger"

main :: proc() {
    context.logger = log.create_console_logger();

    when LOGGER_AVAILABLE {
        logger.log_custom(logger.GREEN, "[TEST BEGIN]")
    }
    else {
        log.warnf("[TEST BEGIN]");
    }

    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    log.infof("IMAGE WRITING");

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR8{
            size = image.IMAGE_SIZE(800, 600),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        bmp.bmp_write_bgr(&generated_image, "bgr8.bmp");
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR16{
            size = image.IMAGE_SIZE(800, 600),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT16_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        bmp.bmp_write_bgr(&generated_image, "bgr16");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR32{
            size = image.IMAGE_SIZE(800, 600),
        };
        image.generate_random_image_ubgr(&generated_image);
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT32_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        bmp.bmp_write_bgr(&generated_image, "bgr32.bmp");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    log.infof("IMAGE READING");

    performance.begin(&profiler);
    {
        raw_image, err := bmp.bmp_read_bgr_auto("bgr8.bmp");
        defer image.dump_raw(&raw_image);
        log.infof("%v", err);
        assert(err == .E_NONE, "FAILED TO READ BITMAP FILE!");
        assert(raw_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(raw_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        img := image.from_raw_bgr(&raw_image, image.BGR8);
        defer image.dump_image2(&img);

        bmp.bmp_write_bgr(&img, "bgr8_after_write");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    // performance.begin(&profiler);
    // {
    //     raw_image, err := bmp.bmp_read_bgr_auto("bgr16.bmp");
    //     defer image.dump_raw(&raw_image);
    //     assert(err == .E_NONE, "FAILED TO READ BITMAP FILE!");
    //     assert(raw_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
    //     assert(raw_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT16_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

    //     img := image.from_raw_bgr(&raw_image, image.BGR16);
    //     defer image.dump_image2(&img);

    //     bmp.bmp_write_bgr(&img, "bgr16_after_write");
    // }
    // stamp = performance.end(&profiler);

    // log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    performance.begin(&profiler);
    {
        raw_image, err := bmp.bmp_read_bgr_auto("bgr32.bmp");
        defer image.dump_raw(&raw_image);
        assert(err == .E_NONE, "FAILED TO READ BITMAP FILE!");
        assert(raw_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(raw_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT32_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        img := image.from_raw_bgr(&raw_image, image.BGR32);
        defer image.dump_image2(&img);

        bmp.bmp_write_bgr(&img, "bgr32_after_write");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

    when LOGGER_AVAILABLE {
        logger.log_custom(logger.GREEN, "[TEST END]")
    }
    else {
        log.warnf("[TEST END]");
    }
}