//+build windows
package bkpr

import "core:fmt"

when BKPR_DEBUG_TRACKER_ENABLED {

/**
 * @brief initializes the BKPR_Allocator and associated pools based on the value of @see InitiFlags
 */
init :: proc(manager: ^BKPR_Manager, init_flags: InitFlags = InitFlags_Proprietary) {
    actual_sizes := [len(InitFlag) - 1]BKPR_SizesDebug{};
    actual_sizes_len := 0;
    for key in POOL_SIZES {
        if key & init_flags != {} {
            actual_sizes[actual_sizes_len] = BKPR_SizesDebug {
                size = POOL_SIZES[key], pool = key,
            };
            actual_sizes_len += 1;
        }
    }

    check_init_bkpr_pool :: proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator, size: BKPR_PoolSizeDescription) {
        if res := init_bkpr_pool(pool, allocator, size); res != .None {
            fmt.printf("\x1b[31mBKPR POOL ALLOCATION ERROR! %v\n\x1b[0m", res);
            assert(false);
        }
    }
    // reserved (allocator) call
    if .Reserved in init_flags          do init_bkpr_allocator(&manager^.allocator, actual_sizes[:actual_sizes_len]);

    if InitFlags.Texture in init_flags  do check_init_bkpr_pool(&manager.texture_pool, &manager.allocator, POOL_SIZES[{.Texture}]);
    if InitFlags.Text in init_flags     do check_init_bkpr_pool(&manager.text_pool, &manager.allocator, POOL_SIZES[{.Text}]);
    if InitFlags.Polygon in init_flags  do check_init_bkpr_pool(&manager.polygon_pool, &manager.allocator, POOL_SIZES[{.Polygon}]);
    if InitFlags.Line in init_flags     do check_init_bkpr_pool(&manager.line_pool, &manager.allocator, POOL_SIZES[{.Line}]);
    if InitFlags.Particle in init_flags do check_init_bkpr_pool(&manager.particle_pool, &manager.allocator, POOL_SIZES[{.Particle}]);
}

/**
 * @brief deletes the memory of either whole BKPR_Allocator (DumpFlags.Proprietary) or just some of its pools (DumpFlags.*)
 */
dump :: proc(manager: ^BKPR_Manager, dump_flags: DumpFlags = DumpFlags_Proprietary) {
    if .Reserved in dump_flags {
        dump_bkpr_allocator(&manager^.allocator);
        return;
    }

    dump_checked :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator) {
        if pool == nil {
            fmt.printf("\x1b[31mThe pool [%v] you want to dump was not initialized!\n\x1b[0m", type_info_of(RESOURCE));
            return;
        }
        if res := dump_bkpr_pool(pool, allocator); res != .None do fmt.printf("Pool failed to deallocate with error: %v\n", res);
    }

    if DumpFlags.Texture in dump_flags  do dump_checked(&manager^.texture_pool, &manager^.allocator);
    if DumpFlags.Text in dump_flags     do dump_checked(&manager^.text_pool,  &manager^.allocator);
    if DumpFlags.Polygon in dump_flags  do dump_checked(&manager^.polygon_pool, &manager^.allocator);
    if DumpFlags.Line in dump_flags     do dump_checked(&manager^.line_pool, &manager^.allocator);
    if DumpFlags.Particle in dump_flags do dump_checked(&manager^.particle_pool, &manager^.allocator);
}

} else {

/**
 * @brief initializes the BKPR_Allocator and associated pools based on the value of @see InitiFlags
 */
init :: proc(manager: ^BKPR_Manager, init_flags: InitFlags = InitFlags_Proprietary) {
    actual_sizes := [len(InitFlag) - 1]BKPR_PoolSizeDescription{};
    actual_sizes_len := 0;
    for key in POOL_SIZES {
        if key & init_flags != {} do actual_sizes[actual_sizes_len] = POOL_SIZES[key];
        actual_sizes_len += 1;
    }

    // reserved (allocator) call
    if .Reserved in init_flags          do init_bkpr_allocator(&manager^.allocator, actual_sizes[:actual_sizes_len]);

    if InitFlags.Texture in init_flags  do _ = init_bkpr_pool(&manager.texture_pool, &manager.allocator, POOL_SIZES[{.Texture}]);
    if InitFlags.Text in init_flags     do _ = init_bkpr_pool(&manager.text_pool, &manager.allocator, POOL_SIZES[{.Text}]);
    if InitFlags.Polygon in init_flags  do _ = init_bkpr_pool(&manager.polygon_pool, &manager.allocator, POOL_SIZES[{.Polygon}]);
    if InitFlags.Line in init_flags     do _ = init_bkpr_pool(&manager.line_pool, &manager.allocator, POOL_SIZES[{.Line}]);
    if InitFlags.Particle in init_flags do _ = init_bkpr_pool(&manager.particle_pool, &manager.allocator, POOL_SIZES[{.Particle}]);
}

/**
 * @brief deletes the memory of either whole BKPR_Allocator (DumpFlags.Proprietary) or just some of its pools (DumpFlags.*)
 */
dump :: proc(manager: ^BKPR_Manager, dump_flags: DumpFlags = DumpFlags_Proprietary) {
    if .Reserved in dump_flags {
        dump_bkpr_allocator(&manager^.allocator);
        return;
    }

    if DumpFlags.Texture in dump_flags  do _ = dump_bkpr_pool(&manager^.texture_pool, &manager^.allocator);
    if DumpFlags.Text in dump_flags     do _ = dump_bkpr_pool(&manager^.text_pool,  &manager^.allocator);
    if DumpFlags.Polygon in dump_flags  do _ = dump_bkpr_pool(&manager^.polygon_pool, &manager^.allocator);
    if DumpFlags.Line in dump_flags     do _ = dump_bkpr_pool(&manager^.line_pool, &manager^.allocator);
    if DumpFlags.Particle in dump_flags do _ = dump_bkpr_pool(&manager^.particle_pool, &manager^.allocator);
}

} //! BKPR_DEBUG_TRACKER_ENABLED