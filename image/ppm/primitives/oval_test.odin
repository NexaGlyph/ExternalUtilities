package oval_test

import "core:log"

import image "../../../image"
import performance "../../../performance_profiler"
import ppm "../../ppm"

main :: proc() {
    context.logger = log.create_console_logger();

    profiler := performance.init_cpu_timer();
    defer performance.dump_cpu_timer(&profiler);

    performance.begin(&profiler);
    {
        img := image.ImageBGR8 {
            size = image.IMAGE_SIZE(50, 50),
            data = make([]image.BGR8, 50 * 50),
            info = image.BGR_UUID | image.UINT8_UUID << 4, // do not need it now
        }

        for datum in &img.data do datum = image.CyanBGR; 

        {
            image.insert_circle_fill(&img, image.OvalBGR8 {
                pos = { 0, 0 },
                radius = 25,
                fill = image.RedBGR, 
            });
        }
        {
            image.insert_circle(&img, image.OvalBGR8 {
                pos = { 0, 0 },
                radius = 25,
                fill = image.BlackBGR, 
            });
        }
        {
            image.insert_circle_fill(&img, image.OvalBGR8 {
                pos = { 10, 10 },
                radius = 15,
                fill = image.OrangeBGR, 
            });
        }
        {
            image.insert_circle_fill(&img, image.OvalBGR8 {
                pos = { 20, 20 },
                radius = 5,
                fill = image.YellowBGR, 
            });
        }

        ppm.ppm_write2_bgr(&img, "bgr8.ppm");
    }
    stamp := performance.end(&profiler);

    log.infof("Time taken: %vms", performance.delta_milliseconds(stamp));
}