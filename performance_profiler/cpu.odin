package performance_profiler

CPUTimeStampDescription :: struct {
    function: cstring,
}

CPUTimeStamp :: struct {
    begin   : f32,
    end     : f32,
    _desc   : CPUTimeStampDescription, 
}

begin_time_stamp :: proc() {
    assert(false, "TO DO!");
}

end_time_stamp :: proc() {
    assert(false, "TO DO!");
}

CPUTimer :: struct {
    stamps : [dynamic]CPUTimeStamp,
}

init_cpu_timer :: proc() -> CPUTimer {
    return CPUTimer {
        stamps = make([dynamic]CPUTimeStamp),
    };
}

dump_cpu_timer :: proc(timer: ^CPUTimer) {
    delete(timer^.stamps);
}