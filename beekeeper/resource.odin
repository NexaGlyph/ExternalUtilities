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

/* TEXTURE */
BKPR_TextureDesc :: struct {

}
BKPR_TextureUpdateDesc :: struct {

}
BKPR_Texture :: ^D3D11.ITexture2D;

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
vtable_unique_update_texture :: proc(this: ^BKPR_UnqTexture, update_desc: rawptr) {
    // update_desc := cast(^BKPR_TextureUpdateDesc)update_desc;
    fmt.println("Updating texture!");
}

/* TEXT */
BKPR_TextDesc :: struct {
    dummy_text_buffer: []u8,
}
BKPR_TextUpdateDesc :: struct {
    dummy_text_buffer: []u8,
}
BKPR_Text :: struct {
    dummy_text: string,
    dummy_color: string,
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
vtable_unique_update_text :: proc(this: ^BKPR_UnqText, update_desc: rawptr) {
    update_desc := cast(^BKPR_TextUpdateDesc)update_desc;
    fmt.println("Updating text!");
    this^.resource_ref^.dummy_text = string(update_desc^.dummy_text_buffer);
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