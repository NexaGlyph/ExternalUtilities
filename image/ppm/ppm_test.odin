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
            size = image.IMAGE_SIZE(50, 50),
        };
        image.generate_random_image_ubgr(&generated_image);
        for i in 0..<generated_image.size.x * generated_image.size.y do generated_image.data[i] = image.BlackBGR;
        defer image.dump_image2(&generated_image);
        
        assert(generated_image.info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK == image.BGR_UUID, "UUID (IMAGE_TYPE) IS INCORRECT");
        assert(generated_image.info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK == (image.UINT8_UUID << 4), "UUID (PIXEL_TYPE) IS INCORRECT");

        /* CENTER -> UPPER LEFT CORNER */
        {
            line := image.LineBGR8 {
                pos  = image.Position {
                    image.Vertex { 0, 0 },
                    image.Vertex { 25, 25 },
                },
                fill = image.WhiteBGR,
            }
            log.info("WhiteBGR");
            image.insert_line(&generated_image, line);
        }
        /* CENTER -> UPPER RIGHT CORNER */
        {
            line := image.LineBGR8 {
                pos  = image.Position {
                    image.Vertex { 25, 25 },
                    image.Vertex { 50, 0 },
                },
                fill = image.BlueBGR,
            }
            log.info("BlueBGR");
            image.insert_line(&generated_image, line);
        }
        /* CENTER -> LOWER RIGHT CORNER */
        {
            line := image.LineBGR8 {
                pos  = image.Position {
                    image.Vertex { 25, 25 },
                    image.Vertex { 50, 50 },
                },
                fill = image.RedBGR,
            }
            log.info("RedBGR");
            image.insert_line(&generated_image, line);
        }
        /* CENTER -> LOWER LEFT CORNER */
        {
            line := image.LineBGR8 {
                pos  = image.Position {
                    image.Vertex { 25, 25 },
                    image.Vertex { 0, 50 },
                },
                fill = image.GreenBGR,
            }
            log.error("GreenBGR");
            image.insert_line(&generated_image, line);
        }

        ppm.ppm_write2_bgr(&generated_image, "bgr8.ppm");
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %v ms", performance.delta_milliseconds(stamp));
}