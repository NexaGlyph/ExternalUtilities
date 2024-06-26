//+build windows
package bkpr

import "base:intrinsics"

import "core:fmt"

BKPR_TexturePool  :: BKPR_Pool(BKPR_Texture);
BKPR_TextPool     :: BKPR_Pool(BKPR_Text);
BKPR_PolygonPool  :: BKPR_Pool(BKPR_Polygon);
BKPR_LinePool     :: BKPR_Pool(BKPR_Line);
BKPR_ParticlePool :: BKPR_Pool(BKPR_Particle);

BKPR_PoolSizeDescription :: struct {
    len: int,
    byte_size: int,
    alignment: int,
}
POOL_SIZE_DESCRIPTION :: #force_inline proc(num_elements: int, $T: typeid/BKPR_PoolObject($RESOURCE)) -> BKPR_PoolSizeDescription 
    where intrinsics.type_is_variant_of(BKPR_Resource, RESOURCE) 
{
    return BKPR_PoolSizeDescription {
        len = num_elements,
        byte_size = size_of(T),
        alignment = align_of(T),
    };
}
POOL_SIZES := map[InitFlags]BKPR_PoolSizeDescription {
    {.Texture}  = { 100, size_of(BKPR_PoolObject(BKPR_Texture)) , align_of(BKPR_PoolObject(BKPR_Texture))  },
    {.Text}     = { 50 , size_of(BKPR_PoolObject(BKPR_Text))    , align_of(BKPR_PoolObject(BKPR_Text))     },
    {.Polygon}  = { 200, size_of(BKPR_PoolObject(BKPR_Polygon)) , align_of(BKPR_PoolObject(BKPR_Polygon))  },
    {.Line}     = { 10 , size_of(BKPR_PoolObject(BKPR_Line))    , align_of(BKPR_PoolObject(BKPR_Line))     },
    {.Particle} = { 400, size_of(BKPR_PoolObject(BKPR_Particle)), align_of(BKPR_PoolObject(BKPR_Particle)) },
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
        resource_ref = resource,
        type = .Immutable,
        vtable = BKPR_ImmTextureVTABLE{
            dump = vtable_dump_imm_texture,
            address = vtable_address_imm_texture,
        },
    };
}
@(private)
_init_bkpr_unq_texture :: proc(resource: ^BKPR_Texture, texture_desc: BKPR_TextureDesc) -> BKPR_UnqTexture {
    return BKPR_UnqTexture {
        resource_ref    = resource,
        type   = .Unique,
        vtable = BKPR_UnqTextureVTABLE{
            dump = vtable_dump_unq_texture,
            address = vtable_address_unq_texture,

            update_pos = vtable_unique_texture_update_pos,
            update_col = vtable_unique_texture_update_col,

            update = vtable_unique_update_texture,
            recreate = vtable_unique_recreate_texture,
        },
    };
}

init_bkpr_imm_texture :: #force_inline proc(manager: ^BKPR_Manager, texture_desc: BKPR_TextureDesc, location := #caller_location) -> Maybe(BKPR_ImmTexture) {
    res_ptr := next(&manager^.texture_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_texture := _init_bkpr_imm_texture(res_ptr, texture_desc);
        track(&manager^.allocator.tracker, &imm_texture._base, location);
        return imm_texture;
    } else do return _init_bkpr_imm_texture(res_ptr, texture_desc);
}
init_bkpr_unq_texture :: #force_inline proc(manager: ^BKPR_Manager, texture_desc: BKPR_TextureDesc, location := #caller_location) -> Maybe(BKPR_UnqTexture) {
    res_ptr := next(&manager^.texture_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_texture := _init_bkpr_unq_texture(res_ptr, texture_desc);
        track(&manager^.allocator.tracker, &unq_texture._base, location);
        return unq_texture;
    }
    else do return _init_bkpr_unq_texture(res_ptr, texture_desc);
}

dump_bkpr_texture_resource :: #force_inline proc(texture_pool: ^BKPR_TexturePool, texture: ^BKPR_Pointer($a, $b)) {
    fmt.println("Release texture resource with id: %v", query_id(texture_pool, texture^));
    delete_from_bkpr_pool_by_ptr(texture_pool, texture);
}
/*! TEXTURE */

/* TEXT */
@(private)
_init_bkpr_imm_text :: proc(resource: ^BKPR_Text, text_desc: BKPR_TextDesc) -> BKPR_ImmText {
    resource^.text = string(text_desc.text_buffer);
    resource^._base.col.data = { text_desc.col };
    resource^._base.pos.data = { text_desc.pos };
    return BKPR_ImmText {
        resource_ref = resource,
        type   = .Immutable,
        vtable = BKPR_ImmTextVTABLE{
            dump = vtable_dump_imm_text,
            address = vtable_address_imm_text,
        },
    };
}
@(private)
_init_bkpr_unq_text :: proc(resource: ^BKPR_Text, text_desc: BKPR_TextDesc) -> BKPR_UnqText {
    resource^.text = string(text_desc.text_buffer);
    resource^._base.col.data = { text_desc.col };
    resource^._base.pos.data = { text_desc.pos };
    return BKPR_UnqText {
        resource_ref = resource,
        type   = .Unique,
        vtable = BKPR_UnqTextVTABLE{
            dump = vtable_dump_unq_text,
            address = vtable_address_unq_text,

            update_pos = vtable_unique_text_update_pos,
            update_col = vtable_unique_text_update_col,

            update = vtable_unique_update_text,
            recreate = vtable_unique_recreate_text,
        },
    };
}

init_bkpr_imm_text :: #force_inline proc(manager: ^BKPR_Manager, text_desc: BKPR_TextDesc, location := #caller_location) -> Maybe(BKPR_ImmText) {
    res_ptr := next(&manager^.text_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_text := _init_bkpr_imm_text(res_ptr, text_desc);
        track(&manager^.allocator.tracker, &imm_text._base, location);
        return imm_text;
    } else do return _init_bkpr_imm_text(res_ptr, text_desc);
}
init_bkpr_unq_text :: #force_inline proc(manager: ^BKPR_Manager, text_desc: BKPR_TextDesc, location := #caller_location) -> Maybe(BKPR_UnqText) {
    res_ptr := next(&manager^.text_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_text := _init_bkpr_unq_text(res_ptr, text_desc);
        track(&manager^.allocator.tracker, &unq_text._base, location);
        return unq_text;
    }
    else do return _init_bkpr_unq_text(res_ptr, text_desc);
}

dump_bkpr_text_resource :: #force_inline proc(text_pool: ^BKPR_TextPool, text: ^BKPR_Pointer($a, $b)) {
    fmt.println("Release text resource with id: %v", query_id(text_pool, text^));
    delete_from_bkpr_pool_by_ptr(text_pool, text);
}
/*! TEXT */

/* POLYGON */
@(private)
_init_bkpr_imm_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_ImmPolygon {
    assert(false);
    return BKPR_ImmPolygon {
        resource_ref    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmPolygonVTABLE{},
    };
}
@(private)
_init_bkpr_unq_polygon :: proc(resource: ^BKPR_Polygon, polygon_desc: BKPR_PolygonDesc) -> BKPR_UnqPolygon {
    assert(false);
    return BKPR_UnqPolygon {
        resource_ref    = resource,
        type   = .Unique,
        vtable = BKPR_UnqPolygonVTABLE{},
    };
}

init_bkpr_imm_polygon :: #force_inline proc(manager: ^BKPR_Manager, polygon_desc: BKPR_PolygonDesc, location := #caller_location) -> Maybe(BKPR_ImmPolygon) {
    res_ptr := next(&manager^.polygon_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_polygon := _init_bkpr_imm_polygon(res_ptr, polygon_desc);
        track(&manager^.allocator.tracker, &imm_polygon._base, location);
        return imm_polygon;
    } else do return _init_bkpr_imm_polygon(res_ptr, polygon_desc);
}
init_bkpr_unq_polygon :: #force_inline proc(manager: ^BKPR_Manager, polygon_desc: BKPR_PolygonDesc, location := #caller_location) -> Maybe(BKPR_UnqPolygon) {
    res_ptr := next(&manager^.polygon_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_polygon := _init_bkpr_unq_polygon(res_ptr, polygon_desc);
        track(&manager^.allocator.tracker, &unq_polygon._base, location);
        return unq_polygon;
    }
    else do return _init_bkpr_unq_polygon(res_ptr, polygon_desc);
}

dump_bkpr_polygon_resource :: #force_inline proc(polygon_pool: ^BKPR_PolygonPool, polygon: ^BKPR_Pointer($a, $b)) {
    fmt.println("Release polygon resource with id: %v", query_id(polygon_pool, polygon^));
    delete_from_bkpr_pool_by_ptr(polygon_pool, polygon);
}
/*! POLYGON */

/* LINE */
@(private)
_init_bkpr_imm_line :: proc(resource: ^BKPR_Line, line_desc: BKPR_LineDesc) -> BKPR_ImmLine {
    assert(false);
    return BKPR_ImmLine {
        resource_ref    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmLineVTABLE{},
    };
}
@(private)
_init_bkpr_unq_line :: proc(resource: ^BKPR_Line, line_desc: BKPR_LineDesc) -> BKPR_UnqLine {
    assert(false);
    return BKPR_UnqLine {
        resource_ref    = resource,
        type   = .Unique,
        vtable = BKPR_UnqLineVTABLE{},
    };
}
init_bkpr_imm_line :: #force_inline proc(manager: ^BKPR_Manager, line_desc: BKPR_LineDesc, location := #caller_location) -> Maybe(BKPR_ImmLine) {
    res_ptr := next(&manager^.line_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_line := _init_bkpr_imm_line(res_ptr, line_desc);
        track(&manager^.allocator.tracker, &imm_line._base, location);
        return imm_line;
    } else do return _init_bkpr_imm_line(res_ptr, line_desc);
}
init_bkpr_unq_line :: #force_inline proc(manager: ^BKPR_Manager, line_desc: BKPR_LineDesc, location := #caller_location) -> Maybe(BKPR_UnqLine) {
    res_ptr := next(&manager^.line_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_line := _init_bkpr_unq_line(res_ptr, line_desc);
        track(&manager^.allocator.tracker, &unq_line._base, location);
        return unq_line;
    }
    else do return _init_bkpr_unq_line(res_ptr, line_desc);
}
/*! LINE */

/* PARTICLE */
@(private)
_init_bkpr_imm_particle :: proc(resource: ^BKPR_Particle, particle_desc: BKPR_ParticleDesc) -> BKPR_ImmParticle {
    assert(false);
    return BKPR_ImmParticle {
        resource_ref    = resource,
        type   = .Immutable,
        vtable = BKPR_ImmParticleVTABLE{},
    };
}
@(private)
_init_bkpr_unq_particle :: proc(resource: ^BKPR_Particle, particle_desc: BKPR_ParticleDesc) -> BKPR_UnqParticle {
    assert(false);
    return BKPR_UnqParticle {
        resource_ref    = resource,
        type   = .Unique,
        vtable = BKPR_UnqParticleVTABLE{},
    };
}

init_bkpr_imm_particle :: #force_inline proc(manager: ^BKPR_Manager, particle_desc: BKPR_ParticleDesc, location := #caller_location) -> Maybe(BKPR_ImmParticle) {
    res_ptr := next(&manager^.particle_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        imm_particle := _init_bkpr_imm_particle(res_ptr, particle_desc);
        track(&manager^.allocator.tracker, &imm_particle._base, location);
        return imm_particle;
    } else do return _init_bkpr_imm_particle(res_ptr, particle_desc);
}

init_bkpr_unq_particle :: #force_inline proc(manager: ^BKPR_Manager, particle_desc: BKPR_ParticleDesc, location := #caller_location) -> Maybe(BKPR_UnqParticle) {
    res_ptr := next(&manager^.particle_pool);
    if res_ptr == nil do return nil;
    when BKPR_DEBUG_TRACKER_ENABLED {
        unq_particle := _init_bkpr_unq_particle(res_ptr, particle_desc);
        track(&manager^.allocator.tracker, &unq_particle._base, location);
        return unq_particle;
    }
    else do return _init_bkpr_unq_particle(res_ptr, particle_desc);
}
/*! PARTICLE */