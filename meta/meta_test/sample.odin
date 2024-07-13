//+build windows
package test

import "base:intrinsics"

/**
 * 1. this should inline the function, warn if it is already marked as inlined
 */
@(private)
@(NexaAttr_Inline)
some_proc :: proc() {
}

Resource :: union {
    Image,
    Texture,
    Text,
    Atlas,
}

@(NexaAttr_PrivateMember="buffer")
Image :: struct {
    buffer: []u8,
    size: [2]u32,
}
Texture :: struct {}
Text :: struct {}
Atlas :: struct {}

accept_resource_any :: proc(r: Resource) 
{
    switch resource in r {
        case Image: #assert(type_of(resource) == Image, "Image!");
        case Texture: #assert(type_of(resource) == Texture, "Texture!");
        case Text: #assert(type_of(resource) == Text, "Text!");
        case Atlas: #assert(type_of(resource) == Atlas, "Atlas!");
    }
}

/**
 * 1. this should check whether the params of the functions are correct
 * 2. should check the uniqueness of the attribute (can be only one App entry)
 * 3. should check the return type
 * 4. should bind this automatically into the core.extern_main
 */
@(NexaAttr_ApplicationEntry)
extern_main :: proc() {
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

/**
 * 1. should be automatically put inside NexaConst_Debug and NexaConst_DebugX blocks
 */
@(NexaAttr_DebugOnly)
debug_proc :: proc() {
}

/**
 * 1. should check whether this proc is launcher into another process (thread)
 */
@(NexaAttr_MainThreadOnly)
main_thread :: proc() {
}