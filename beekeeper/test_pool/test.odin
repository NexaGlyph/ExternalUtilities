package test

import "core:fmt"

import bkpr "../"

/**
 * @brief basic test, initialize and dump pool(s)
 */
test1 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    return true;
}

/**
 * @brief tests pools' resource managemenet
 */
test2 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.begin_track(&beekeeper^.allocator.tracker);
    {
        //* note: this is not a "correct" approach as if you would find in real code, but needed for this check...
        imm_textures := make([dynamic]bkpr.BKPR_ImmTexture, 3); defer delete(imm_textures);
        imm_texture_ids := make([dynamic]bkpr.BKPR_PoolObjectID, 3); defer delete(imm_texture_ids);
        for i in 0..<3 {
            imm_texture, ok := bkpr.init_bkpr_imm_texture(beekeeper, bkpr.BKPR_TextureDesc{}).?;
            if ok {
                append(&imm_textures, imm_texture);
                append(&imm_texture_ids, bkpr.query_id(&beekeeper^.texture_pool, imm_texture._base));
            }
        }

        // if a texture is deleted, the id of the instantly created one after that
        // will have the same id...
        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.untrack(&beekeeper^.allocator.tracker, &imm_textures[len(imm_textures) - 1]._base);
        bkpr.dump_bkpr_texture_resource(&beekeeper^.texture_pool, &imm_textures[len(imm_textures) - 1]._base);
        imm_texture, ok := bkpr.init_bkpr_imm_texture(beekeeper, bkpr.BKPR_TextureDesc{}).?;
        if id := bkpr.query_id(&beekeeper^.texture_pool, imm_texture._base); id > 0 {
            if id != imm_texture_ids[len(imm_texture_ids) - 1] {
                fmt.printf("%v :: %v\n", id, imm_texture_ids[len(imm_texture_ids) - 1])
                return false;
            }
        } else do return false;

        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.untrack_record(&beekeeper^.allocator.tracker, imm_textures[:]);
    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check_auto(&beekeeper^.allocator.tracker);

    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.begin_track(&beekeeper^.allocator.tracker);
    {
        text_buffer := make([]u8, 5);
        text_buffer[0] = 84; // T
        text_buffer[1] = 69; // E
        text_buffer[2] = 83; // S
        text_buffer[3] = 84; // T
        text_buffer[4] = 10; // \n

        // TODO: Make one function out of this...
        display_text_immutable :: proc(text: ^bkpr.BKPR_ImmText) {
            fmt.printf("Displaying text: %v\n", text->address()^.dummy_text);
        }
        display_text_unique :: proc(text: ^bkpr.BKPR_UnqText) {
            fmt.printf("Displaying text: %v\n", text->address()^.dummy_text);
        }

        imm_text, _ := bkpr.init_bkpr_imm_text(beekeeper, { text_buffer }).?;
        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do defer bkpr.untrack(&beekeeper^.allocator.tracker, &imm_text._base);
        defer bkpr.dump_bkpr_text_resource(&beekeeper^.text_pool, &imm_text._base);
        fmt.println("Display immutable text....\n");
        display_text_immutable(&imm_text);

        unq_text, _ := bkpr.init_bkpr_unq_text(beekeeper, { text_buffer }).?;
        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do defer bkpr.untrack(&beekeeper^.allocator.tracker, &unq_text._base);
        defer bkpr.dump_bkpr_text_resource(&beekeeper^.text_pool, &unq_text._base);
        fmt.println("Display unique text....\n");
        display_text_unique(&unq_text);
        fmt.println("Display unique text after update [SHOULD SEE 'NEW!']....\n");
        {
            update_text_desc := bkpr.BKPR_TextUpdateDesc{
                dummy_text_buffer = make([]u8, 5),
            };
            // [78, 69, 87, 33, 10]
            update_text_desc.dummy_text_buffer[0] = 78; // N
            update_text_desc.dummy_text_buffer[1] = 69; // E
            update_text_desc.dummy_text_buffer[2] = 87; // W
            update_text_desc.dummy_text_buffer[3] = 33; // !
            update_text_desc.dummy_text_buffer[4] = 10; // \n;
            unq_text->update(&update_text_desc);
        }
        display_text_unique(&unq_text);

    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check_auto(&beekeeper^.allocator.tracker);

    return true;
}

main :: proc() {
    
    beekeeper := bkpr.BKPR_Manager{};
    bkpr.init(&beekeeper);

    if !test1(&beekeeper) do fmt.printf("\x1b[31mFailed to pass test1!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test1!\n\x1b[0m");

    if !test2(&beekeeper) do fmt.printf("\x1b[31mFailed to pass test2!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test2!\n\x1b[0m");

    bkpr.dump(&beekeeper);

}