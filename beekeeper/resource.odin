//+build windows
package bkpr

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
BKPR_Texture :: struct {

}
BKPR_ImmTexture :: BKPR_Pointer(BKPR_Texture, BKPR_PointerImmutableVTABLE);
BKPR_UnqTexture :: BKPR_Pointer(BKPR_Texture, BKPR_PointerUniqueVTABLE);
BKPR_ShrTexture :: BKPR_Pointer(BKPR_Texture, BKPR_PointerSharedVTABLE);

/* TEXT */
BKPR_TextDesc :: struct {

}
BKPR_Text :: struct {

}

/* LINE */
BKPR_LineDesc :: struct {

}
BKPR_Line :: struct {

}

/* POLYGON */
BKPR_PolygonDesc :: struct {

}
BKPR_Polygon :: struct {

}
BKPR_ImmPolygon :: BKPR_Pointer(BKPR_Polygon, BKPR_PointerImmutableVTABLE);
BKPR_UnqPolygon :: BKPR_Pointer(BKPR_Polygon, BKPR_PointerUniqueVTABLE);
BKPR_ShrPolygon :: BKPR_Pointer(BKPR_Polygon, BKPR_PointerSharedVTABLE);

/* PARTICLE */
BKPR_ParticleDesc :: struct {

}
BKPR_Particle :: struct {

}