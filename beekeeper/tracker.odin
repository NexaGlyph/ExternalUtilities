//+build windows
package bkpr

import "base:runtime"

import "core:fmt"

when BKPR_DEBUG_TRACKER_ENABLED {

BKPR_AllocatorTrackerItemData :: struct {
    location: runtime.Source_Code_Location,
    last_ref: rawptr,
}
BKPR_AllocatorTrackerID :: distinct u32;

@(private="file")
TRACK_INDENT := u32(0);

@(private="file")
TRACK_INDENT_INCREMENT :: #force_inline proc() -> u32 {
    TRACK_INDENT += 1;
    return TRACK_INDENT;
}
@(private="file")
TRACK_INDENT_DECREMENT :: #force_inline proc() -> u32 {
    TRACK_INDENT += 1;
    return TRACK_INDENT;
}

BKPR_AllocatorTrack :: map[BKPR_AllocatorTrackerID]BKPR_AllocatorTrackerItemData;
BKPR_AllocatorTracker :: struct #no_copy {
    track: BKPR_AllocatorTrack,
}

init_bkpr_tracker :: proc() -> BKPR_AllocatorTracker {
    return { make(BKPR_AllocatorTrack), };
}

track :: proc(tracker: ^BKPR_AllocatorTracker, ptr: ^BKPR_Pointer($MEMORY, $VTABLE), loation: runtime.Source_Code_Location) {
    @(static)
    tracking_id := u32(0);

    tracker^.track[1 << (TRACK_INDENT + 8) | tracking_id] = {
        location = location,
        last_ref = ptr,
    };

    tracking_id += 1;
    fmt.println(tracking_id);
}

untrack_block :: proc(tracker: ^BKPR_AllocatorTracker) {
    for key in tracker^.track {
        if key & (1 << (TRACK_INDENT + 8)) != 0 {
            fmt.printf("\x1b[32m[Untracking] --- ");
            fmt.printf("\x1b[0m%v\n", tracker^.track[key]);

            delete_key(&tracker^.track, key);
        }
    }
}

untrack_all :: #force_inline proc(tracker: ^BKPR_AllocatorTracker) {
    for key in tracker^.track {
        if key & (1 << (TRACK_INDENT + 8)) != 0 do delete_key(&tracker^.track, key);
    }
}

untrack :: #force_inline proc(tracker: ^BKPR_AllocatorTracker, ptr: ^BKPR_Pointer($MEMORY, $VTABLE)) {
    for key, val in tracker^.track {
        if val.last_ref == ptr {
            fmt.println("Deleting key: %v", key);
            delete_key(&tracker^.track, key);

            fmt.println("Key deleted");
        }
    }
}

block_check :: proc(tracker: ^BKPR_AllocatorTracker) -> []BKPR_AllocatorTrackerItemData {
    block_leaks := make([dynamic]BKPR_AllocatorTrackerItemData);
    for key in tracker^.track {
        if key & (1 << (TRACK_INDENT + 8)) != 0 do append(&block_leaks, tracker^.track[key]);
    }
    return block_leaks[:];
}

block_check_auto :: proc(tracker: ^BKPR_AllocatorTracker) {
    block_leaks := block_check(tracker); defer delete(block_leaks);
    for leak in block_leaks {
        fmt.printf("\x1b[31m[Memory leak] ---");
        fmt.printf("\x1b[0m%v", leak);
    }
}

begin_track :: proc() {
    TRACK_INDENT_INCREMENT();
}
end_track :: proc() {
    TRACK_INDENT_DECREMENT();
}

} //! BKPR_DEBUG_TRACKER_ENABLED