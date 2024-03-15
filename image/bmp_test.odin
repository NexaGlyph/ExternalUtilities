package main

import "core:log"

import image "ExternalUtilities/image"
import performance "ExternalUtilities/performance_profiler"

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

        image.write(&generated_image, image.FileWriteDescriptor {
            write_format = .BMP,
            file_path = "bgr8.bmp",
        });
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

        image.write(&generated_image, image.FileWriteDescriptor {
            write_format = .BMP,
            file_path = "bgr16",
        });
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

        image.write(&generated_image, image.FileWriteDescriptor {
            write_format = .BMP,
            file_path = "bgr32",
        });
    }
    stamp = performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));
}