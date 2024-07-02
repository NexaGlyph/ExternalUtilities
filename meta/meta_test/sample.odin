//+build windows
package test

import "base:intrinsics"

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