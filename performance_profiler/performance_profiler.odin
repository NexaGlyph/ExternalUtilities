package performance_profiler

// import D3D11 "vendor:directx/d3d11"

import "../logger"

PerformanceProfiler :: struct {
    // PERFORMANCE HELPER WINDOWS
    // WMI (WINDOWS MANAGEMENT INSTRUMENTATION)
    gpu_timer: GPUTimer,
    cpu_timer: CPUTimer,
    logger   : logger.Logger,
}

init_performance_profiler :: proc() -> PerformanceProfiler {
    return {
        gpu_timer = init_gpu_timer(),
        cpu_timer = init_cpu_timer(),
        logger = logger.init("performance.log"),
    };
}

dump_performance_profiler :: proc(profiler: ^PerformanceProfiler) {
    dump_gpu_timer(&profiler.gpu_timer);
    dump_cpu_timer(&profiler.cpu_timer);
    logger.dump(&profiler.logger);
}