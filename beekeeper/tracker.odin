//+build windows
package bkpr

import "base:intrinsics"
import "base:runtime"

import "core:fmt"

when BKPR_DEBUG_TRACKER_ENABLED {

BKPR_AllocatorTrackerItemData :: struct {
    location: runtime.Source_Code_Location,
    last_ref: rawptr,
}
BKPR_AllocatorTrackerID :: distinct u32;

BKPR_AllocatorTrack :: map[BKPR_AllocatorTrackerID]BKPR_AllocatorTrackerItemData;
BKPR_AllocatorTracker :: struct #no_copy {
    track: BKPR_AllocatorTrack,
    tracking_id: BKPR_AllocatorTrackerID,
    track_indent: BKPR_AllocatorTrackerID,
}

init_bkpr_tracker :: #force_inline proc(source_allocator: runtime.Allocator) -> BKPR_AllocatorTracker {
    return { make(BKPR_AllocatorTrack, allocator=source_allocator), 0, 0 };
}

track :: proc(tracker: ^BKPR_AllocatorTracker, ptr: ^BKPR_Pointer($MEMORY, $VTABLE), location := #caller_location) {
    tracker^.track[1 << (tracker^.track_indent + 8) | tracker^.tracking_id] = {
        location = location,
        last_ref = ptr^.resource_ref,
    };

    tracker^.tracking_id += 1;
}

untrack_all :: #force_inline proc(tracker: ^BKPR_AllocatorTracker) {
    for key in tracker^.track {
        if key & (1 << (tracker^.track_indent + 8)) != 0 do delete_key(&tracker^.track, key);
    }
}

untrack_record :: proc {
    untrack_record_deduct, untrack_record_manual,
}

@(private)
untrack_record_manual :: #force_inline proc(tracker: ^BKPR_AllocatorTracker, record: []BKPR_Pointer($MEMORY, $VTABLE))
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY) 
{
    record := record;
    for r in &record do untrack(tracker, &r);
}

@(private)
untrack_record_deduct :: #force_inline proc(tracker: ^BKPR_AllocatorTracker, record: []BKPR_AllocatorTrackerItemData) {
    record := record;
    for r in &record {
        for key, val in tracker^.track {
            if val.last_ref == r.last_ref do delete_key(&tracker^.track, key);
        }
    }
}

untrack_block :: proc(tracker: ^BKPR_AllocatorTracker) {
    for key in tracker^.track {
        if key & (1 << (tracker^.track_indent + 8)) != 0 {
            fmt.printf("\x1b[32m[Untracking] ---\n");
            fmt.printf("\x1b[0m%v\n", tracker^.track[key]);

            delete_key(&tracker^.track, key);
        }
    }
}

untrack :: #force_inline proc(tracker: ^BKPR_AllocatorTracker, ptr: ^BKPR_Pointer($MEMORY, $VTABLE)) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)    
{
    for key, val in tracker^.track {
        if val.last_ref == ptr^.resource_ref {
            fmt.printf("\x1b[32m[Untracking] ---\n");
            fmt.printf("\x1b[0m%v\n", tracker^.track[key]);
            delete_key(&tracker^.track, key);
            break;
        }
    }
}

@(require_results)
block_check :: proc(tracker: ^BKPR_AllocatorTracker) -> []BKPR_AllocatorTrackerItemData {
    block_leaks := make([dynamic]BKPR_AllocatorTrackerItemData);
    for key in tracker^.track {
        // indent := 1 << (tracker^.track_indent + 8);
        // fmt.printf("Comparing key: %v and with track indent: %d\n", key, indent);
        if key & (1 << (tracker^.track_indent + 8)) != 0 do append(&block_leaks, tracker^.track[key]);
    }
    return block_leaks[:];
}

block_check_auto :: proc(tracker: ^BKPR_AllocatorTracker) {
    block_leaks := block_check(tracker); defer delete(block_leaks);
    if len(block_leaks) == 0 {
        fmt.printf("\x1b[32m[No leaks detected at indent %v] ---\x1b[0m\n", tracker^.track_indent);
    }
    else {
        for leak in block_leaks {
            fmt.printf("\x1b[31m[Memory leak] ---\n");
            fmt.printf("\x1b[0m%v\n", leak);
        }
    }

    end_track(tracker); // added for convenience of not having to call two functions...
}

begin_track :: #force_inline proc "contextless" (tracker: ^BKPR_AllocatorTracker) {
    tracker^.track_indent += 1;
}
end_track :: #force_inline proc "contextless" (tracker: ^BKPR_AllocatorTracker) {
    tracker^.track_indent -= 1;
}

} //! BKPR_DEBUG_TRACKER_ENABLED