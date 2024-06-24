//+build windows
package bkpr

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
//>>>NOTE: NEED TO FIND A WAY TO MAKE THIS COMPILE-TIME DEDUCEABLE
//*     1. maybe by adding custom tags (attributes) to functions like @(constexpr) or @(overloadable_return)
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

/* TEXTURE */
@(private)
_init_bkpr_imm_texture :: proc(resource: ^BKPR_Texture, texture_desc: BKPR_TextureDesc) -> BKPR_ImmTexture {
    return BKPR_ImmTexture {
        mem = resource,
        type = .Immutable,
        vtable = BKPR_ImmTextureVTABLE{
            base = {
                address = address_texture,
                address_of = address_of_texture,
                dump = dump_texture,
            },
        },
    };
}
@(private)
_init_bkpr_unq_texture :: proc(resource: ^BKPR_Texture, texture_desc: BKPR_TextureDesc) -> BKPR_UnqTexture {
    return BKPR_UnqTexture {
        mem    = resource,
        type   = .Unique,
        vtable = BKPR_UnqTextureVTABLE{},
    };
}

init_bkpr_imm_texture :: #force_inline proc(manager: ^BKPR_Manager, texture_desc: BKPR_TextureDesc, location := #caller_location) -> Maybe(BKPR_ImmTexture) {
    res_ptr := next(&manager^.texture_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_texture := _init_bkpr_imm_texture(res_ptr, texture_desc);
        track(&manager^.allocator.tracker, &imm_texture, location);
        return imm_texture;
    } else do return _init_bkpr_imm_texture(res_ptr, texture_desc);
}
init_bkpr_unq_texture :: #force_inline proc(manager: ^BKPR_Manager, texture_desc: BKPR_TextureDesc, location := #caller_location) -> Maybe(BKPR_UnqTexture) {
    res_ptr := next(&manager^.texture_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_texture := _init_bkpr_unq_texture(res_ptr, texture_desc);
        track(&manager^.allocator.tracker, &unq_texture, location);
        return unq_texture;
    }
    else do return _init_bkpr_unq_texture(res_ptr, texture_desc);
}
/*! TEXTURE */

/* TEXT */
@(private)
_init_bkpr_imm_text :: proc(resource: ^BKPR_Text, text_desc: BKPR_TextDesc) -> BKPR_ImmText {
    return BKPR_ImmText {
        mem    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmTextVTABLE{},
    };
}
@(private)
_init_bkpr_unq_text :: proc(resource: ^BKPR_Text, text_desc: BKPR_TextDesc) -> BKPR_UnqText {
    return BKPR_UnqText {
        mem    = resource,
        type   = .Unique,
        vtable = BKPR_UnqTextVTABLE{},
    };
}

init_bkpr_imm_text :: #force_inline proc(manager: ^BKPR_Manager, text_desc: BKPR_TextDesc, location := #caller_location) -> Maybe(BKPR_ImmText) {
    res_ptr := next(&manager^.text_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_text := _init_bkpr_imm_text(res_ptr, text_desc);
        track(&manager^.allocator.tracker, &imm_text, location);
        return imm_text;
    } else do return _init_bkpr_imm_text(res_ptr, text_desc);
}
init_bkpr_unq_text :: #force_inline proc(manager: ^BKPR_Manager, text_desc: BKPR_TextDesc, location := #caller_location) -> Maybe(BKPR_UnqText) {
    res_ptr := next(&manager^.text_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_text := _init_bkpr_unq_text(res_ptr, text_desc);
        track(&manager^.allocator.tracker, &unq_text, location);
        return unq_text;
    }
    else do return _init_bkpr_unq_text(res_ptr, text_desc);
}
/*! TEXT */

/* POLYGON */
@(private)
_init_bkpr_imm_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_ImmPolygon {
    return BKPR_ImmPolygon {
        mem    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmPolygonVTABLE{},
    };
}
@(private)
_init_bkpr_unq_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_UnqPolygon {
    return BKPR_UnqPolygon {
        mem    = resource,
        type   = .Unique,
        vtable = BKPR_UnqPolygonVTABLE{},
    };
}
init_bkpr_imm_polygon :: #force_inline proc(manager: ^BKPR_Manager, polygon_desc: BKPR_PolygonDesc, location := #caller_location) -> Maybe(BKPR_ImmPolygon) {
    res_ptr := next(&manager^.polygon_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_polygon := _init_bkpr_imm_polygon(res_ptr, polygon_desc);
        track(&manager^.allocator.tracker, &imm_polygon, location);
        return imm_polygon;
    } else do return _init_bkpr_imm_polygon(res_ptr, polygon_desc);
}
init_bkpr_unq_polygon :: #force_inline proc(manager: ^BKPR_Manager, polygon_desc: BKPR_PolygonDesc, location := #caller_location) -> Maybe(BKPR_UnqPolygon) {
    res_ptr := next(&manager^.polygon_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_polygon := _init_bkpr_unq_polygon(res_ptr, polygon_desc);
        track(&manager^.allocator.tracker, &unq_polygon, location);
        return unq_polygon;
    }
    else do return _init_bkpr_unq_polygon(res_ptr, polygon_desc);
}
/*! POLYGON */

/* LINE */
@(private)
_init_bkpr_imm_line :: proc(resource: ^BKPR_Line, line_desc: BKPR_LineDesc) -> BKPR_ImmLine {
    return BKPR_ImmLine {
        mem    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmLineVTABLE{},
    };
}
@(private)
_init_bkpr_unq_line :: proc(resource: ^BKPR_Line, line_desc: BKPR_LineDesc) -> BKPR_UnqLine {
    return BKPR_UnqLine {
        mem    = resource,
        type   = .Unique,
        vtable = BKPR_UnqLineVTABLE{},
    };
}
init_bkpr_imm_line :: #force_inline proc(manager: ^BKPR_Manager, line_desc: BKPR_LineDesc, location := #caller_location) -> Maybe(BKPR_ImmLine) {
    res_ptr := next(&manager^.line_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_line := _init_bkpr_imm_line(res_ptr, line_desc);
        track(&manager^.allocator.tracker, &imm_line, location);
        return imm_line;
    } else do return _init_bkpr_imm_line(res_ptr, line_desc);
}
init_bkpr_unq_line :: #force_inline proc(manager: ^BKPR_Manager, line_desc: BKPR_LineDesc, location := #caller_location) -> Maybe(BKPR_UnqLine) {
    res_ptr := next(&manager^.line_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_line := _init_bkpr_unq_line(res_ptr, line_desc);
        track(&manager^.allocator.tracker, &unq_line, location);
        return unq_line;
    }
    else do return _init_bkpr_unq_line(res_ptr, line_desc);
}
/*! LINE */

/* PARTICLE */
@(private)
_init_bkpr_imm_particle :: proc(resource: ^BKPR_Particle, particle_desc: BKPR_ParticleDesc) -> BKPR_ImmParticle {
    return BKPR_ImmParticle {
        mem    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmParticleVTABLE{},
    };
}
@(private)
_init_bkpr_unq_particle :: proc(resource: ^BKPR_Particle, particle_desc: BKPR_ParticleDesc) -> BKPR_UnqParticle {
    return BKPR_UnqParticle {
        mem    = resource,
        type   = .Unique,
        vtable = BKPR_UnqParticleVTABLE{},
    };
}

init_bkpr_imm_particle :: #force_inline proc(manager: ^BKPR_Manager, particle_desc: BKPR_ParticleDesc, location := #caller_location) -> Maybe(BKPR_ImmParticle) {
    res_ptr := next(&manager^.particle_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_particle := _init_bkpr_imm_particle(res_ptr, particle_desc);
        track(&manager^.allocator.tracker, &imm_particle, location);
        return imm_particle;
    } else do return _init_bkpr_imm_particle(res_ptr, particle_desc);
}

init_bkpr_unq_particle :: #force_inline proc(manager: ^BKPR_Manager, particle_desc: BKPR_ParticleDesc, location := #caller_location) -> Maybe(BKPR_UnqParticle) {
    res_ptr := next(&manager^.particle_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_particle := _init_bkpr_unq_particle(res_ptr, particle_desc);
        track(&manager^.allocator.tracker, &unq_particle, location);
        return unq_particle;
    }
    else do return _init_bkpr_unq_particle(res_ptr, particle_desc);
}
/*! PARTICLE */