package main

import "core:log"
import "core:mem"

import bmp "../bmp"
import image "../../image"
import performance "../../performance_profiler"
import logger "../../logger"

main :: proc() {
    context.logger = log.create_console_logger();

    logger.log_custom(logger.GREEN, "[TEST BEGIN]")

    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    log.infof("IMAGE READING");

    performance.begin(&profiler);
    {
        generated_image := image.ImageBGR8{
            size = image.IMAGE_SIZE(800, 600),
            info = (image.UINT8_UUID << 4) | image.BGR_UUID,
        };
        generated_image.data = make([]image.BGR8, 800 * 600);

        for i in 0..<len(generated_image.data) {
            if i % 4 == 0 {
                generated_image.data[i].r = { data = 127, };
                generated_image.data[i].g = { data = 127, };
                generated_image.data[i].b = { data = 127, };
            } else {
                generated_image.data[i].r = { data = 0, };
                generated_image.data[i].g = { data = 0, };
                generated_image.data[i].b = { data = 0, };
            }
        }
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        raw_image := image.bgr_to_raw(&generated_image);
        res := bmp.bmp_write_auto(&raw_image, "bgr8_bw.bmp");
        assert(res == .E_NONE);
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

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
    stamp = performance.end(&profiler);

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

    logger.log_custom(logger.ORANGE, "[WRITING TEST DISABLED (RawImage buffer erroring on copy when trying to read/rewrite the array!)]");
    logger.log_custom(logger.GREEN, "[TEST END]")
    /*
    log.infof("IMAGE WRITING");

    performance.begin(&profiler);
    {
        raw_image, err := bmp.bmp_read_bgr_auto("bgr8_bw.bmp");
        // defer image.dump_raw(&raw_image);
        assert(err == .E_NONE, "FAILED TO READ BITMAP FILE!");
        assert(raw_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(raw_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        img := image.from_raw_bgr(&raw_image, image.BGR8);
        defer image.dump_image2(&img);

        log.infof("write before");
        assert(bmp.bmp_write_auto(&raw_image, "bgr8_bw_after_write") == .E_NONE);
        log.infof("write after");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

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

    performance.begin(&profiler);
    {
        raw_image, err := bmp.bmp_read_bgr_auto("bgr16.bmp");
        defer image.dump_raw(&raw_image);
        assert(err == .E_NONE, "FAILED TO READ BITMAP FILE!");
        assert(raw_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(raw_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT16_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        img := image.from_raw_bgr(&raw_image, image.BGR16);
        defer image.dump_image2(&img);

        bmp.bmp_write_bgr(&img, "bgr16_after_write");
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));

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

    */
}