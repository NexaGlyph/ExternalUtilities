//+build windows
package bkpr

import "base:runtime"

import "core:fmt"
import "core:mem"

BKPR_AllocatorProc  :: runtime.Allocator_Proc;
BKPR_AllocatorMode  :: runtime.Allocator_Mode;
BKPR_AllocatorError :: runtime.Allocator_Error;

/**
 * @brief represents an array of pointers to each pool (the max size of this array will be the maximum possible pools registered)
 * each BKPR_Pool (BKPR_AllocatorItem) will be allocated individually (even though this may be seen as inefficient since the buffer is not contiguous)
 * for the convenience of possible freeing during the application runtime
 * @note the order of the BKPR_AllocatorItem is not being preserved as is in the InitFlag enum!
 */
BKPR_AllocatorPools      :: [len(InitFlag) - 1]BKPR_AllocatorPoolData; 
BKPR_AllocatorPoolData   :: []byte;/*> represents one whole buffer for a BKPR_Pool */

BKPR_AllocatorFreeBlocks     :: [len(InitFlag) - 1]bool;
BKPR_ALLOCATORBLOCK_FREE     :: false;
BKPR_ALLOCATORBLOCK_NOT_FREE :: !BKPR_ALLOCATORBLOCK_FREE;

when !BKPR_DEBUG_TRACKER_ENABLED {

BKPR_Allocator      :: struct #no_copy {
    data: BKPR_AllocatorPools,
    free_blocks: BKPR_AllocatorFreeBlocks,
    source_allocator: runtime.Allocator,
}

init_bkpr_allocator :: #force_inline proc(bkpr_alloc: ^BKPR_Allocator, sizes: []BKPR_PoolSizeDescription, source_alloc := context.allocator) {
    bkpr_alloc^.source_allocator = source_alloc;

    for size, index in sizes {
        bkpr_alloc^.data[index] = make(BKPR_AllocatorPoolData, _calculate_aligned_byte_size(size), source_alloc);
        assert(len(bkpr_alloc^.data[index]) > 0, "Failed to allocate BKPR's heap buffer from context.allocator!");
    }
}

}
else  {

BKPR_Allocator      :: struct #no_copy {
    data: BKPR_AllocatorPools,
    free_blocks: BKPR_AllocatorFreeBlocks,
    source_allocator: runtime.Allocator,

    tracker: BKPR_AllocatorTracker, // debug
}

BKPR_SizesDebug :: #type struct {
    size: BKPR_PoolSizeDescription,
    pool: InitFlags,
}

init_bkpr_allocator :: #force_inline proc(bkpr_alloc: ^BKPR_Allocator, sizes: []BKPR_SizesDebug, source_alloc := context.allocator) {
    bkpr_alloc^.source_allocator = source_alloc;

    for debug_size, index in sizes {
        bkpr_alloc^.data[index] = make(BKPR_AllocatorPoolData, _calculate_aligned_byte_size(debug_size.size), source_alloc);
        assert(len(bkpr_alloc^.data[index]) > 0, "Failed to allocate BKPR's heap buffer from context.allocator!\n");

        fmt.printf("Creating BKPR_AllocatorPoolData of size: %d; for pool: %v\n", len(bkpr_alloc^.data[index]), debug_size.pool);
    }

    when BKPR_DEBUG_TRACKER_ENABLED do bkpr_alloc^.tracker = init_bkpr_tracker(source_alloc);
}

} //! BKPR_DEBUG_TRACKER_ENABLED


@(private="file")
_calculate_aligned_byte_size :: #force_inline proc(size: BKPR_PoolSizeDescription) -> int {
    fmt.printf("Calculated aligned byte size: %v; out of %v, %v, %v\n", size.len * size.byte_size * size.alignment, size.len, size.byte_size, size.alignment);
    return size.len * mem.align_forward_int(size.byte_size, size.alignment);
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
    size := size;
    if alignment != 0 do size = mem.align_forward_int(size, alignment);

    switch mode {
        case .Alloc:
            // check for a pool with the requested size and if it is actually free
            for pool_data, index in &bkpr_alloc^.data {
                if bkpr_alloc^.free_blocks[index] == BKPR_ALLOCATORBLOCK_FREE { // check for free block
                    if len(pool_data) == size { 
                        bkpr_alloc^.free_blocks[index] = BKPR_ALLOCATORBLOCK_NOT_FREE;
                        when BKPR_DEBUG_TRACKER_ENABLED do fmt.printf("Returning pool data of size: %vB\n", len(pool_data));
                        return pool_data, nil;
                    }
                    if len(pool_data) == 0 { // buffer has been already deleted, can be reallocated again
                        pool_data = make(BKPR_AllocatorPoolData, size, bkpr_alloc^.source_allocator);
                        bkpr_alloc^.free_blocks[index] = BKPR_ALLOCATORBLOCK_NOT_FREE;
                        when BKPR_DEBUG_TRACKER_ENABLED do fmt.printf("Reallocating previously free'd buffer! New size: %vB\n", size);
                        assert(len(pool_data) > 0, "Failed to reallocate!");
                        return pool_data, nil;
                    }
                }
            }

            fmt.printf("\033[48:5:208mFailed to find desired pool, returning nil!\n\x1b[0m");
            return nil, nil;

        case .Free:
            if old_memory == nil {
                fmt.println("Old memory is nil!");
                return nil, nil;
            }

            // check if the dumping is for the whole buffer of pool
            fmt.printf("\x1b[31mPool marked for deletion with size: %v\n\x1b[0m", old_size);
            for pool_data, index in bkpr_alloc^.data {
                if len(pool_data) == old_size && bkpr_alloc^.free_blocks[index] == BKPR_ALLOCATORBLOCK_NOT_FREE {
                    if res := delete_slice(pool_data, bkpr_alloc^.source_allocator); res != .None do return nil, res;
                    fmt.printf("\x1b[32mDeleting pool data successfully\x1b[0m\n");
                    bkpr_alloc^.free_blocks[index] = BKPR_ALLOCATORBLOCK_FREE;
                    break;
                }
            }

            return nil, nil;
            
        case .Free_All: 
            for free_block, index in bkpr_alloc^.free_blocks {
                if free_block == BKPR_ALLOCATORBLOCK_NOT_FREE do delete(bkpr_alloc^.data[index], bkpr_allocator_bare(bkpr_alloc));
            }

        case .Resize:           fallthrough;
        case .Query_Features:   fallthrough;
        case .Query_Info:       fallthrough;
        case .Alloc_Non_Zeroed: fallthrough;

        case .Resize_Non_Zeroed: assert(false, "Invalid operation for BKPR_Allocator!");
    }

    return {}, {}; // not gonna happen...
}

dump_bkpr_allocator :: #force_inline proc(bkpr_alloc: ^BKPR_Allocator) {
    free_all(bkpr_allocator_bare(bkpr_alloc));
}