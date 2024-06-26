//+build windows
package bkpr

import "base:intrinsics"

import "core:fmt"

import D3D11 "vendor:directx/d3d11"

BKPR_Resource :: union {
    BKPR_Texture,
    BKPR_Text,
    BKPR_Line,
    BKPR_Polygon,
    BKPR_Particle,
}

BKPR_ResourceUpdateType :: enum {
    BKPR_ResourceBase_UpdatePosition,
    BKPR_ResourceBase_UpdateColor,

    BKPR_Texture_UpdateMemory,

    BKPR_Text_UpdateString,
}

@(private)
/* this should be only illustrative structure of the NexaCore's utils_mem.Object */
GPU_MemoryComponent :: struct {
    vertex_buffer: rawptr,
    render_bufffer: rawptr,
}
BKPR_ResourceBase :: struct {
    pos: PositionComponent,
    col: ColorComponent,
    _memory: GPU_MemoryComponent,
}

/* TEXTURE */
BKPR_TextureDesc :: struct {
    using _: PositionComponentData, // for BKPR_Texture._base.pos
    using _: ColorComponentData, // for BKPR_Texture._base.color
    using _: TextureMemoryComponentData, // for BKPR_Texture.texture
}
BKPR_Texture :: struct {
    #subtype _base: BKPR_ResourceBase,
    texture: ^D3D11.ITexture2D,
}

BKPR_ImmTextureVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Texture);
BKPR_UnqTextureVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Texture);
BKPR_ShrTextureVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Texture);
BKPR_ImmTexture       :: BKPR_PointerImmutable(BKPR_Texture);
BKPR_UnqTexture       :: BKPR_PointerUnique(BKPR_Texture);
BKPR_ShrTexture       :: BKPR_PointerShared(BKPR_Texture);

/* BASE TEXTURE VTABLE */
@(private)
vtable_address_imm_texture :: proc(this: ^BKPR_ImmTexture) -> ^BKPR_Texture {
    fmt.println("Returning immutable texture address!");
    return this^.resource_ref;
}
@(private)
vtable_address_unq_texture :: proc(this: ^BKPR_UnqTexture) -> ^BKPR_Texture {
    fmt.println("Returning unique texture address!");
    return this^.resource_ref;
}
@(private)
vtable_dump_imm_texture :: proc(this: ^BKPR_ImmTexture) {
    fmt.println("Dumping immutable texture!");
}
@(private)
vtable_dump_unq_texture :: proc(this: ^BKPR_UnqTexture) {
    fmt.println("Dumping unique texture!");
}

/* UNIQUE TEXTURE VTABLE */
@(private)
vtable_unique_texture_update_pos :: proc(this: ^BKPR_UnqTexture, pos: PositionComponentData) {
    this^.resource_ref^._base.pos.data = pos;
    fmt.printf("Value of pos component of pointer unique of type [BKPR_UnqTexture] changed to: %v\n", this^.resource_ref^._base.pos);
}
@(private)
vtable_unique_texture_update_col :: proc(this: ^BKPR_UnqTexture, col: ColorComponentData) {
    this^.resource_ref^._base.col.data = col;
    fmt.printf("Value of col component of pointer unique of type [BKPR_UnqTexture] changed to: %v\n", this^.resource_ref^._base.col);
}

@(private)
vtable_unique_update_texture :: proc(this: ^BKPR_UnqTexture, cmd_update_type: BKPR_ResourceUpdateType, update_data: rawptr) {
    switch cmd_update_type {
        case .BKPR_ResourceBase_UpdateColor:
            this->update_col((cast(^ColorComponentData)update_data)^);
        case .BKPR_ResourceBase_UpdatePosition:
            this->update_pos((cast(^PositionComponentData)update_data)^);

        case .BKPR_Texture_UpdateMemory:
            update_data := cast(^TextureMemoryComponentData)update_data;
            fmt.printf("Updating texture's memory with value: %v!", update_data^);

        case .BKPR_Text_UpdateString:
            assert(false, "Invalid cmd_update_type!");
    }
}
@(private)
vtable_unique_recreate_texture :: proc(this: ^BKPR_UnqTexture, update_data: rawptr) {
    update_data := cast(^BKPR_TextureDesc)update_data;
    fmt.printf("Recreating texture with data: %v", update_data^);
}

/* TEXT */
BKPR_TextDesc :: struct {
    using _: PositionComponentData, // for BKPR_Text._base.pos
    using _: ColorComponentData, // for BKPR_Text._base.color
    using _: TextComponentData, // for BKPR_Text.text
}
BKPR_Text :: struct {
    #subtype _base: BKPR_ResourceBase,
    text: string,
}

BKPR_ImmTextVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Text);
BKPR_UnqTextVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Text);
BKPR_ShrTextVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Text);
BKPR_ImmText       :: BKPR_PointerImmutable(BKPR_Text);
BKPR_UnqText       :: BKPR_PointerUnique(BKPR_Text);
BKPR_ShrText       :: BKPR_PointerShared(BKPR_Text);

/* BASE TEXT VTABLE */
@(private)
vtable_address_imm_text :: proc(this: ^BKPR_ImmText) -> ^BKPR_Text {
    fmt.println("Returning immutable text address!");
    return this^.resource_ref;
}
@(private)
vtable_address_unq_text :: proc(this: ^BKPR_UnqText) -> ^BKPR_Text {
    fmt.println("Returning unique text address!");
    return this^.resource_ref;
}
@(private)
vtable_dump_imm_text :: proc(this: ^BKPR_ImmText) {
    fmt.println("Dumping immutable text!");
}
@(private)
vtable_dump_unq_text :: proc(this: ^BKPR_UnqText) {
    fmt.println("Dumping unique text!");
}

/* UNIQUE TEXT VTABLE */
@(private)
vtable_unique_text_update_pos :: proc(this: ^BKPR_UnqText, pos: PositionComponentData) {
    this^.resource_ref^._base.pos.data = pos;
    fmt.printf("Value of pos component of pointer unique of type [BKPR_UnqText] changed to: %v\n", this^.resource_ref^._base.pos);
}
@(private)
vtable_unique_text_update_col :: proc(this: ^BKPR_UnqText, col: ColorComponentData) {
    this^.resource_ref^._base.col.data = col;
    fmt.printf("Value of col component of pointer unique of type [BKPR_UnqText] changed to: %v\n", this^.resource_ref^._base.col);
}

@(private)
vtable_unique_update_text :: proc(this: ^BKPR_UnqText, cmd_update_type: BKPR_ResourceUpdateType, update_data: rawptr) {
    switch cmd_update_type {
        case .BKPR_ResourceBase_UpdateColor:
            this->update_col((cast(^ColorComponentData)update_data)^);
        case .BKPR_ResourceBase_UpdatePosition:
            this->update_pos((cast(^PositionComponentData)update_data)^);

        case .BKPR_Texture_UpdateMemory:
            assert(false, "Invalid cmd_update_type!");

        case .BKPR_Text_UpdateString:
            update_data := cast(^TextComponentData)update_data;
            fmt.printf("Updating text's memory with value: %v!", update_data^);
            this^.resource_ref^.text = string(update_data^.text_buffer);
    }
}
@(private)
vtable_unique_recreate_text :: proc(this: ^BKPR_UnqText, update_data: rawptr) {
    update_data := cast(^BKPR_TextDesc)update_data;
    fmt.printf("Recreating texture with data: %v", update_data^);
}

/* POLYGON */
BKPR_PolygonDesc :: struct {

}
BKPR_Polygon :: struct {

}
BKPR_ImmPolygonVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Polygon);
BKPR_UnqPolygonVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Polygon);
BKPR_ShrPolygonVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Polygon);
BKPR_ImmPolygon       :: BKPR_PointerImmutable(BKPR_Polygon);
BKPR_UnqPolygon       :: BKPR_PointerUnique(BKPR_Polygon);
BKPR_ShrPolygon       :: BKPR_PointerShared(BKPR_Polygon);

/* LINE */
BKPR_LineDesc :: struct {

}
BKPR_Line :: struct {

}
BKPR_ImmLineVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Line);
BKPR_UnqLineVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Line);
BKPR_ShrLineVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Line);
BKPR_ImmLine       :: BKPR_PointerImmutable(BKPR_Line);
BKPR_UnqLine       :: BKPR_PointerUnique(BKPR_Line);
BKPR_ShrLine       :: BKPR_PointerShared(BKPR_Line);

/* PARTICLE */
BKPR_ParticleDesc :: struct {

}
BKPR_Particle :: struct {

}
BKPR_ImmParticleVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Particle);
BKPR_UnqParticleVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Particle);
BKPR_ShrParticleVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Particle);
BKPR_ImmParticle       :: BKPR_PointerImmutable(BKPR_Particle);
BKPR_UnqParticle       :: BKPR_PointerUnique(BKPR_Particle);
BKPR_ShrParticle       :: BKPR_PointerShared(BKPR_Particle);