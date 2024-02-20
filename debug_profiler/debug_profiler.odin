package debug_profiler

import "core:log"
import "core:dynlib"

import renderdoc "../renderdoc"

DebugProfilerInitFlags :: bit_set[DebugProfilerInitFlag];
DebugProfilerInitFlag  :: enum {
    NONE      = 0,
    RENDERDOC = 2,
}

DebugProfiler :: struct {
    renderdoc_handler: renderdoc.RENDERDOC_HANDLER ,
}

init :: proc(init_flags: DebugProfilerInitFlags) -> (dp: DebugProfiler) {
    if (init_flags & {.RENDERDOC}) == {.RENDERDOC} {
        ok := true;
        dp.renderdoc_handler.renderdoc_lib, ok = dynlib.load_library("renderdoc.dll");
        log.infof("library loaded");
        assert(ok, "Could not load renderdoc.dll");
        
        // find the proc address of this function - not part of the rdoc_api struct
        renderdoc.RENDERDOC_GetAPI = cast(renderdoc.pRENDERDOC_GetAPI)dynlib.symbol_address(dp.renderdoc_handler.renderdoc_lib, "RENDERDOC_GetAPI");
        assert(renderdoc.RENDERDOC_GetAPI != nil, "Could not load renderdoc.RENDERDOC_GetAPI");
        
        // load all the other ones from the struct
        // assert(renderdoc.RENDERDOC_StartFrameCapture != nil, "Could not load renderdoc.RENDERDOC_StartFrameCapture");
        // renderdoc._load_instance_proc_addr(&dp.renderdoc_handler);
        
        res := renderdoc.RENDERDOC_GetAPI(.eRENDERDOC_API_Version_1_3_0, cast(^rawptr)&dp.renderdoc_handler.rdoc_api);
        assert(res == 1, "failed to get the RENDERDOC API");
    }
    return;
}

dump :: proc(using dp: ^DebugProfiler) {
    if renderdoc_handler.rdoc_api != nil {
        log.infof("unloading library...");
        dynlib.unload_library(renderdoc_handler.renderdoc_lib);
        log.infof("library unloded");
    }
}