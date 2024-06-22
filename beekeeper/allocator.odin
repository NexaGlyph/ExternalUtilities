//+build windows
package bkpr

import "base:runtime"

import "core:fmt"

BKPR_AllocatorProc  :: runtime.Allocator_Proc;
BKPR_AllocatorMode  :: runtime.Allocator_Mode;
BKPR_AllocatorError :: runtime.Allocator_Error;

when BKPR_DEBUG_TRACKER_ENABLED {

BKPR_Allocator      :: struct #no_copy {
    data: []byte,
    size: u32,
    used: u32,
    tracker: BKPR_AllocatorTracker,
}

}
else  {

BKPR_Allocator      :: struct #no_copy {
    data: []byte,
    size: u32,
    used: u32,
}

} //! BKPR_DEBUG_TRACKER_ENABLED

init_bkpr_allocator :: #force_inline proc(bkpr_alloc: ^BKPR_Allocator, size: u32, source_alloc := context.allocator) {
    bkpr_alloc^.data = make([]byte, size);
    assert(len(bkpr_alloc^.data) > 0, "Failed to allocate BKPR's heap buffer from context.allocator!");

    when BKPR_DEBUG_TRACKER_ENABLED do bkpr_alloc^.tracker = init_bkpr_tracker();
    bkpr_alloc^.size = size;
    bkpr_alloc^.used = 0;

    fmt.printf("Initializing BKPR_Allocator with size: %v\n", size);
}

@(require_results)
bkpr_allocator_bare :: proc(bkpr_alloc: ^BKPR_Allocator) -> runtime.Allocator {
    return runtime.Allocator {
        procedure = bkpr_allocator_proc,
        data = bkpr_alloc,
    };
}

bkpr_allocator_proc :: proc(allocator_data: rawptr, mode: BKPR_AllocatorMode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location: runtime.Source_Code_Location = #caller_location) -> ([]byte, BKPR_AllocatorError)
{
    bkpr_alloc := cast(^BKPR_Allocator)allocator_data;
    switch mode {
        case .Alloc:
            if bkpr_alloc^.used + cast(u32)size > bkpr_alloc^.size {
                // fmt.printf("used: %v; size: %v; used + size: %v, alloc_size: %v", bkpr_alloc^.used, size, bkpr_alloc^.used + cast(u32)size, bkpr_alloc^.size);
                fmt.printf("Failed to Allocate memory: BKPR_Allocator out of memory!\nRequested size: %v\nCaller location: %v\n", size, location);
                return nil, BKPR_AllocatorError.Out_Of_Memory;
            }
            slice := bkpr_alloc^.data[bkpr_alloc^.used:size];
            bkpr_alloc^.used += cast(u32)size;
            fmt.printf("BKPR_Allocator returning memory block of size: %v!\nCaller location: %v\n", size, location);
            return slice, nil;

        case .Free:
            bkpr_alloc^.used -= cast(u32)size;
            assert(false, "TODO: Somehow notify the pool...");
            assert(false, "TODO: Somehow check the tracker...");

        case .Free_All:
            bkpr_alloc^.used = 0;
            assert(false, "TODO: Somehow notify the pool(s)...");

        case .Resize:           fallthrough;
        case .Query_Features:   fallthrough;
        case .Query_Info:       fallthrough;
        case .Alloc_Non_Zeroed: fallthrough;

        case .Resize_Non_Zeroed: assert(false, "Invalid operation for BKPR_Allocator!");
    }

    return {}, {}; // not gonna happen...
}

dump_bkpr_allocator :: #force_inline proc(bkpr_alloc: ^BKPR_Allocator) {
    delete(bkpr_alloc^.data);
}