//+build windows
package bkpr

import "core:fmt"

BKPR_TexturePool  :: BKPR_Pool(BKPR_Texture);
BKPR_TextPool     :: BKPR_Pool(BKPR_Text);
BKPR_PolygonPool  :: BKPR_Pool(BKPR_Polygon);
BKPR_LinePool     :: BKPR_Pool(BKPR_Line);
BKPR_ParticlePool :: BKPR_Pool(BKPR_Particle);

POOL_SIZES := map[InitFlags]int {
    {.Texture}  = 100 * size_of(BKPR_PoolObject(BKPR_Texture))  * align_of(BKPR_PoolObject(BKPR_Texture)),
    {.Text}     = 50  * size_of(BKPR_PoolObject(BKPR_Text))     * align_of(BKPR_PoolObject(BKPR_Text)),
    {.Polygon}  = 200 * size_of(BKPR_PoolObject(BKPR_Polygon))  * align_of(BKPR_PoolObject(BKPR_Polygon)),
    {.Line}     = 10  * size_of(BKPR_PoolObject(BKPR_Line))     * align_of(BKPR_PoolObject(BKPR_Line)),
    {.Particle} = 400 * size_of(BKPR_PoolObject(BKPR_Particle)) * align_of(BKPR_PoolObject(BKPR_Particle)),
};

/* Custom Pool functions */
@(private)
_init_bkpr_imm_texture :: proc(resource: ^BKPR_Texture, texture_desc: BKPR_TextureDesc) -> BKPR_ImmTexture {
    return BKPR_ImmTexture {};
}
@(private)
_init_bkpr_unq_texture :: proc(resource: ^BKPR_Texture, texture_desc: BKPR_TextureDesc) -> BKPR_UnqTexture {
    return BKPR_UnqTexture {};
}

init_bkpr_imm_texture :: #force_inline proc(pool: ^BKPR_TexturePool, texture_desc: BKPR_TextureDesc) -> BKPR_ImmTexture {
    return _init_bkpr_imm_texture(next(pool), texture_desc);
}
init_bkpr_unq_texture :: #force_inline proc(pool: ^BKPR_TexturePool, texture_desc: BKPR_TextureDesc) -> BKPR_UnqTexture {
    return _init_bkpr_unq_texture(next(pool), texture_desc);
}
//>>>NOTE: NEED TO FIND A WAY TO MAKE THIS COMPILE-TIME DEDUCEABLE
// init_bkpr_texture :: #force_inline proc(
//     $TEXTURE_TYPE: typeid/BKPR_Pointer(BKPR_Texture, $a),
//     pool: ^BKPR_TexturePool,
//     desc: BKPR_TextureDesc
// ) -> TEXTURE_TYPE
// {
//     fmt.println("Initializing BKPR_Texture!");
//     switch {
//         case a == BKPR_PointerImmutableVTABLE:
//             return _init_bkpr_imm_texture(next(pool));
//         case a == BKPR_PointerUniqueVTABLE:
//             return _init_bkpr_unq_texture(next(pool));
//         case a == BKPR_PointerSharedVTABLE:
//             return _init_bkpr_shr_texture(next(pool));
//     }
// }

init_bkpr_text :: proc(pool: ^BKPR_TextPool, desc: BKPR_TextDesc) {
    fmt.println("Initializing BKPR_Text!");
}

@(private)
_init_bkpr_imm_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_ImmPolygon {
    return BKPR_ImmPolygon {};
}
@(private)
_init_bkpr_unq_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_UnqPolygon {
    return BKPR_UnqPolygon {};
}

init_bkpr_imm_polygon :: #force_inline proc(pool: ^BKPR_PolygonPool, polygon_desc: BKPR_PolygonDesc) -> BKPR_ImmPolygon {
    return _init_bkpr_imm_polygon(next(pool), polygon_desc);
}
init_bkpr_unq_polygon :: #force_inline proc(pool: ^BKPR_PolygonPool, polygon_desc: BKPR_PolygonDesc) -> BKPR_UnqPolygon {
    return _init_bkpr_unq_polygon(next(pool), polygon_desc);
}

init_bkpr_polygon :: proc(pool: ^BKPR_PolygonPool, desc: BKPR_PolygonDesc) {
    fmt.println("Initializing BKPR_Polygon!");
}

init_bkpr_line :: proc(pool: ^BKPR_LinePool, desc: BKPR_LineDesc) {
    fmt.println("Initializing BKPR_Line!");
}

init_bkpr_particle :: proc(pool: ^BKPR_ParticlePool, desc: BKPR_ParticleDesc) {
    fmt.println("Initializing BKPR_Particle!");
}

init_bkpr_resource :: proc {
    // init_bkpr_texture,
    init_bkpr_text,
    init_bkpr_polygon,
    init_bkpr_line,
    init_bkpr_particle,
}