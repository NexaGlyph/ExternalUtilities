package ex_utils

import "core:os"

import "debug_profiler"
import "logger"

/* DEBUG PROFILER */
DebugProfilerInitFlags :: debug_profiler.DebugProfilerInitFlags;
DebugProfiler          :: debug_profiler.DebugProfiler;

@(private="package")
init_debug_profiler :: #force_inline proc(init_flags: DebugProfilerInitFlags) -> (dp: DebugProfiler) {
    return debug_profiler.init(init_flags);
}

@(private="package")
dump_debug_profiler :: #force_inline proc(dp: ^DebugProfiler) {
    debug_profiler.dump(dp);
}

/* LOGGER */
Logger :: logger.Logger;

@(private="package")
init_logger :: #force_inline proc(file_name: string = "output.log", write_modes: int = os.O_CREATE | os.O_TRUNC) -> (Logger) {
    return logger.init(file_name, write_modes);
}

@(private="package")
dump_logger :: #force_inline proc(_logger: ^Logger) {
    logger.dump(_logger);
}

init :: proc { init_debug_profiler, init_logger }
dump :: proc { dump_debug_profiler, dump_logger }