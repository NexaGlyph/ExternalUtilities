//+build windows
package test

import "core:fmt"

import bkpr "../"

main :: proc() {

    beekeeper := bkpr.BKPR_Manager {};
    bkpr.init(&beekeeper, {.Texture} | {.Polygon} | {.Particle});

    // initialize texture
    bkpr.begin_track();
    fmt.println("Beginning tracking Indent: 1");
    {

        _ = bkpr.init_bkpr_imm_texture(&beekeeper.texture_pool, bkpr.BKPR_TextureDesc {});

        bkpr.begin_track()
        fmt.println("Beginning tracking Indent: 2");
        {

            _ = bkpr.init_bkpr_unq_texture(&beekeeper.texture_pool, bkpr.BKPR_TextureDesc{});

            my_polys := [3]bkpr.BKPR_UnqPolygon{};
            for i in 0..<3 {
                my_polys[i] = bkpr.init_bkpr_unq_polygon(&beekeeper.polygon_pool, bkpr.BKPR_PolygonDesc{});
            }

            for poly in &my_polys do bkpr.untrack(&beekeeper.allocator.tracker, &poly);

        }
        bkpr.end_track();
        fmt.println("Ended tracking Indent: 2");

    }
    bkpr.end_track();
    fmt.println("Ended tracking Indent: 1");

    bkpr.dump(&beekeeper, {.Texture} | {.Polygon} | {.Particle} | {.Line});

}