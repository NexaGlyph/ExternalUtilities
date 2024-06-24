//+build windows
package bkpr

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
BKPR_Texture :: ^D3D11.ITexture2D;

BKPR_ImmTextureVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Texture);
BKPR_UnqTextureVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Texture);
BKPR_ShrTextureVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Texture);
BKPR_ImmTexture       :: BKPR_Pointer(BKPR_Texture, BKPR_ImmTextureVTABLE);
BKPR_UnqTexture       :: BKPR_Pointer(BKPR_Texture, BKPR_UnqTextureVTABLE);
BKPR_ShrTexture       :: BKPR_Pointer(BKPR_Texture, BKPR_ShrTextureVTABLE);

/* TEXT */
BKPR_TextDesc :: struct {

}
BKPR_Text :: struct {

}
BKPR_ImmTextVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Text);
BKPR_UnqTextVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Text);
BKPR_ShrTextVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Text);
BKPR_ImmText       :: BKPR_Pointer(BKPR_Text, BKPR_ImmTextVTABLE);
BKPR_UnqText       :: BKPR_Pointer(BKPR_Text, BKPR_UnqTextVTABLE);
BKPR_ShrText       :: BKPR_Pointer(BKPR_Text, BKPR_ShrTextVTABLE);

/* POLYGON */
BKPR_PolygonDesc :: struct {

}
BKPR_Polygon :: struct {

}
BKPR_ImmPolygonVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Polygon);
BKPR_UnqPolygonVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Polygon);
BKPR_ShrPolygonVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Polygon);
BKPR_ImmPolygon       :: BKPR_Pointer(BKPR_Polygon, BKPR_ImmPolygonVTABLE);
BKPR_UnqPolygon       :: BKPR_Pointer(BKPR_Polygon, BKPR_UnqPolygonVTABLE);
BKPR_ShrPolygon       :: BKPR_Pointer(BKPR_Polygon, BKPR_ShrPolygonVTABLE);

/* LINE */
BKPR_LineDesc :: struct {

}
BKPR_Line :: struct {

}
BKPR_ImmLineVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Line);
BKPR_UnqLineVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Line);
BKPR_ShrLineVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Line);
BKPR_ImmLine       :: BKPR_Pointer(BKPR_Line, BKPR_ImmLineVTABLE);
BKPR_UnqLine       :: BKPR_Pointer(BKPR_Line, BKPR_UnqLineVTABLE);
BKPR_ShrLine       :: BKPR_Pointer(BKPR_Line, BKPR_ShrLineVTABLE);

/* PARTICLE */
BKPR_ParticleDesc :: struct {

}
BKPR_Particle :: struct {

}
BKPR_ImmParticleVTABLE :: BKPR_PointerImmutableVTABLE(BKPR_Particle);
BKPR_UnqParticleVTABLE :: BKPR_PointerUniqueVTABLE(BKPR_Particle);
BKPR_ShrParticleVTABLE :: BKPR_PointerSharedVTABLE(BKPR_Particle);
BKPR_ImmParticle       :: BKPR_Pointer(BKPR_Particle, BKPR_ImmParticleVTABLE);
BKPR_UnqParticle       :: BKPR_Pointer(BKPR_Particle, BKPR_UnqParticleVTABLE);
BKPR_ShrParticle       :: BKPR_Pointer(BKPR_Particle, BKPR_ShrParticleVTABLE);