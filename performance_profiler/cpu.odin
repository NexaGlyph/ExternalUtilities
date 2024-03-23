package performance_profiler

import "core:time"
import "core:runtime"

CPUTimeStampDescription :: struct {
    function: runtime.Source_Code_Location,
}

CPUTimeStamp :: struct {
    begin   : i64,
    end     : i64,
    _desc   : CPUTimeStampDescription, 
}

begin_time_stamp :: #force_inline proc "contextless" (location := #caller_location) -> CPUTimeStamp {
    return {
        begin = time.now()._nsec,
        end = 0,
        _desc = {
            function = location,
        },
    };
}

end_time_stamp :: #force_inline proc "contextless" (using stamp: ^CPUTimeStamp) {
    end = time.now()._nsec; 
}

delta_seconds :: #force_inline proc "contextless" (using cpu: ^CPUTimeStamp) -> i64 {
    return (end - begin) / 1e9;
}

delta_milliseconds :: #force_inline proc "contextless" (using cpu: ^CPUTimeStamp) -> i64 {
    return (end - begin) / 1e6;
}

delta_microseconds :: #force_inline proc "contextless" (using cpu: ^CPUTimeStamp) -> i64 {
    return (end - begin) / 1e3;
}

CPUTimer :: struct {
    stamps : [dynamic]CPUTimeStamp,
}

init_cpu_timer :: proc() -> CPUTimer {
    return CPUTimer {
        stamps = make([dynamic]CPUTimeStamp),
    };
}

begin :: proc(using timer: ^CPUTimer, location := #caller_location) {
    stamp: CPUTimeStamp = {};
    stamp = begin_time_stamp(location);
    append(&stamps, stamp);
}

end :: proc(using timer: ^CPUTimer) -> ^CPUTimeStamp {
    end_time_stamp(&stamps[len(stamps) - 1]);
    return &stamps[len(stamps) - 1];
}

dump_cpu_timer :: proc(timer: ^CPUTimer) {
    delete(timer^.stamps);
}