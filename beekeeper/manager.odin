//+build windows
package bkpr

BKPR_Manager :: struct #no_copy {
    allocator: BKPR_Allocator,

    texture_pool: BKPR_TexturePool,
    text_pool: BKPR_TextPool,
    polygon_pool: BKPR_PolygonPool,
    line_pool: BKPR_LinePool,
    particle_pool: BKPR_ParticlePool,
}