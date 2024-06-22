//+build windows
package bkpr

/**
 * @brief initializes the BKPR_Allocator and associated pools based on the value of @see InitiFlags
 */
init :: proc(manager: ^BKPR_Manager, init_flags: InitFlags) {
    actual_size := u32(0);
    for key in POOL_SIZES {
        if key & init_flags != {} do actual_size += cast(u32)POOL_SIZES[key];
    }
    init_bkpr_allocator(&manager^.allocator, actual_size);

    if InitFlags.Texture in init_flags  do init_bkpr_pool(&manager.texture_pool, &manager.allocator, POOL_SIZES[{.Texture}]);
    if InitFlags.Text in init_flags     do init_bkpr_pool(&manager.text_pool, &manager.allocator, POOL_SIZES[{.Text}]);
    if InitFlags.Polygon in init_flags  do init_bkpr_pool(&manager.polygon_pool, &manager.allocator, POOL_SIZES[{.Polygon}]);
    if InitFlags.Line in init_flags     do init_bkpr_pool(&manager.line_pool, &manager.allocator, POOL_SIZES[{.Line}]);
    if InitFlags.Particle in init_flags do init_bkpr_pool(&manager.particle_pool, &manager.allocator, POOL_SIZES[{.Particle}]);
}

/**
 * @brief deletes the memory of either whole BKPR_Allocator (DumpFlags.All) or just some of its pools (DumpFlags.*)
 */
dump :: proc(manager: ^BKPR_Manager, dump_flags: DumpFlags = {.All}) {
    if DumpFlags.All in dump_flags {
        dump_bkpr_allocator(&manager^.allocator);
        return;
    }

    //>>>NOTE: MAKE THIS DEBUG ONLY
    dump_checked :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator) {
        assert(pool != nil, "The pool you want to dump was not initialized!");
        dump_bkpr_pool(pool, allocator);
    }

    if DumpFlags.Texture in dump_flags  do dump_checked(&manager^.texture_pool, &manager^.allocator);
    if DumpFlags.Text in dump_flags     do dump_checked(&manager^.text_pool,  &manager^.allocator);
    if DumpFlags.Polygon in dump_flags  do dump_checked(&manager^.polygon_pool, &manager^.allocator);
    if DumpFlags.Line in dump_flags     do dump_checked(&manager^.line_pool, &manager^.allocator);
    if DumpFlags.Particle in dump_flags do dump_checked(&manager^.particle_pool, &manager^.allocator);
}