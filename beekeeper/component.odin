//+build windows
package bkpr

import "core:fmt"

BKPR_ResourceCommandUpdateProc :: #type proc(component: rawptr, update_data: rawptr);

BKPR_Component :: struct($DATA: typeid) {
    data: DATA,
}

/* GENERAL */
PositionComponentData :: struct {
    pos: [2]u16,
}
#assert(size_of(PositionComponentData) == 2 * size_of(u16))

PositionComponent :: BKPR_Component(PositionComponentData);

ColorComponentData :: struct {
    col: [4]u8,
}
#assert(size_of(PositionComponentData) == 4 * size_of(u8))

ColorComponent :: BKPR_Component(ColorComponentData);
/*! GENERAL */

/* TEXTURE */
TextureMemoryComponentData :: struct {
    buffer: []ColorComponentData,
}

update_texture_memory :: proc(resoruce: ^BKPR_UnqTexture, component: TextureMemoryComponentData) {
    fmt.printf("Updating texture memory!");
}
/*! TEXTURE */

/* TEXT */
TextComponentData :: struct {
    text_buffer: []u8,
}
TextComponent :: BKPR_Component(TextComponentData);
/*! TEXT */