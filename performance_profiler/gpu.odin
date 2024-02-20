package performance_profiler

import D3D11 "vendor:directx/d3d11"

GPUTimeStampDescription :: struct {

}

GPUTimeStamp :: struct {
    begin: ^D3D11.IQuery,
    end: ^D3D11.IQuery,
    _desc : GPUTimeStampDescription,
}

GPUTimer :: struct {
    stamps: [dynamic]GPUTimeStamp,
}

init_gpu_timer :: proc() -> GPUTimer {
    return GPUTimer {
        stamps = make([dynamic]GPUTimeStamp),
    };
}

dump_gpu_timer :: proc(timer: ^GPUTimer) {
    for stamp in timer^.stamps {
        stamp.begin->Release();
        stamp.end->Release();
    }
    delete(timer^.stamps);
}