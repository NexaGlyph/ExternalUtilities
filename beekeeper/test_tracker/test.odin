//+build windows
package test

import "core:fmt"

import bkpr "../"

when bkpr.BKPR_DEBUG_TRACKER_ENABLED {

should_leak :: proc(beekeeper: ^bkpr.BKPR_Manager) {
    ok := false;
    for _ in 0..<5 {
        _, ok /* LEAK */ = bkpr.init_bkpr_imm_particle(beekeeper, {}).?;
        assert(ok, "Allocation exceeded!");
    }
}

should_not_leak :: proc(beekeeper: ^bkpr.BKPR_Manager) {
    particle_record := make([]bkpr.BKPR_ImmParticle, 5);
    ok := false;
    for i in 0..<5 {
        particle_record[i], ok = bkpr.init_bkpr_imm_particle(beekeeper, {}).?;
        if !ok do break; // allocation exceeded, break
    }
    // clean
    tracked := bkpr.block_check(&beekeeper.allocator.tracker);
    assert(len(particle_record) == len(tracked), "Failed to track all the initialized particles!");
    bkpr.untrack_record(&beekeeper.allocator.tracker, particle_record);
}

main :: proc() {
    //>>>NOTE: TODO FIX THE ALLOCATION SIZE BEING TOO LARGE

    beekeeper := bkpr.BKPR_Manager {};
    bkpr.init(&beekeeper, {.Reserved, .Texture, .Particle, .Polygon});

    // initialize texture
    bkpr.begin_track(&beekeeper.allocator.tracker);
    fmt.println("----------------------------");
    fmt.println("Beginning tracking Indent: 1");
    fmt.println("----------------------------");
    {

        _ /* NO LEAK, CHECK BOTTOM */= bkpr.init_bkpr_imm_texture(&beekeeper, bkpr.BKPR_TextureDesc {});

        bkpr.begin_track(&beekeeper.allocator.tracker)
        fmt.println("----------------------------");
        fmt.println("Beginning tracking Indent: 2");
        fmt.println("----------------------------");
        {

            _ /* LEAK HERE (indent 2) */ = bkpr.init_bkpr_unq_texture(&beekeeper, bkpr.BKPR_TextureDesc{});

            my_polys := make([dynamic]bkpr.BKPR_UnqPolygon);
            for i in 0..<3 {
                my_poly, ok := bkpr.init_bkpr_unq_polygon(&beekeeper, bkpr.BKPR_PolygonDesc{}).?;
                if ok do append(&my_polys, my_poly);
            }

            fmt.println("Untracking Indent 2");
            for poly in &my_polys do bkpr.untrack(&beekeeper.allocator.tracker, &poly._base);

            {
                bkpr.begin_track(&beekeeper.allocator.tracker);
                fmt.println("------------------------------");
                fmt.println("Beginning tracking Indent: 3.1");
                fmt.println("------------------------------");
                should_leak(&beekeeper);
                fmt.println("-------------------------------------");
                fmt.println("Ended tracking Indent: 3.1 [SHOULD LEAK]");
                fmt.println("-------------------------------------");
                record := bkpr.block_check(&beekeeper.allocator.tracker);
                for r in record {
                    fmt.printf("\x1b[31m[Memory leak] ---\n");
                    fmt.printf("\x1b[0m%v\n", r);
                }
                delete(record);
                bkpr.untrack_record(&beekeeper.allocator.tracker, record);
                bkpr.end_track(&beekeeper.allocator.tracker);
            }

            {
                bkpr.begin_track(&beekeeper.allocator.tracker);
                fmt.println("------------------------------");
                fmt.println("Beginning tracking Indent: 3.2");
                fmt.println("------------------------------");
                should_not_leak(&beekeeper);
                fmt.println("-----------------------------------------------");
                fmt.println("Ended tracking Indent: 3.2 [SHOULD BE NO LEAKS]");
                fmt.println("-----------------------------------------------");
                bkpr.block_check_auto(&beekeeper.allocator.tracker);
            }

        }
        fmt.println("---------------------------------------------");
        fmt.println("Ended tracking Indent: 2 [SHOULD HAVE 1 LEAK]");
        fmt.println("---------------------------------------------");
        bkpr.block_check_auto(&beekeeper.allocator.tracker);
    }
    fmt.println("Untracking Indent 1");
    bkpr.untrack_block(&beekeeper.allocator.tracker);
    fmt.println("---------------------------------------------");
    fmt.println("Ended tracking Indent: 1 [SHOULD BE NO LEAKS]");
    fmt.println("---------------------------------------------");
    bkpr.block_check_auto(&beekeeper.allocator.tracker);

    bkpr.dump(&beekeeper);

}

} //!BKPR_DEBUG_TRACKER_ENABLED