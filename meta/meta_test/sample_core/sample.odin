package test

import "core:fmt"

/**
 * 1. this should inline the function, warn if it is already marked as inlined
 */
@(private)
@(NexaAttr_Inline)
some_proc :: #force_inline proc() {
    fmt.println("Hello from 'some_proc'; My attributes are: private/inline");
}

MyStruct :: struct {
    x: int,
}

/**
 * 1. should check for invisibility outside the "NexaCore"
 */
@(NexaAttr_APICall)
api_proc :: proc() {
}

/**
 * 1. can be ignored...
 */
@(NexaAttr_APICall="external")
api_proc2 :: proc() {
}

when ODIN_DEBUG {

/**
 * 1. should be automatically put inside NexaConst_Debug and NexaConst_DebugX blocks
 */
@(NexaAttr_DebugOnly)
debug_proc :: proc() {
}

}

/**
 * 1. should check whether this proc is launcher into another process (thread)
 */
@(NexaAttr_MainThreadOnly)
main_thread :: proc() {
}

/**
 * 1. ought to be without context.user_ptr access...
 */
@(NexaAttr_CoreInit)
init :: proc() -> int {
    val :: 5;
    _ = context.user_ptr; // should assert here
    return val;
}