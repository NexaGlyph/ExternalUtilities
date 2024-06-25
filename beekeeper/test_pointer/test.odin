package test

import bkpr "../"

/**
 * @brief tests the functionality of BKPR_PointerShared
 */
test3 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.begin_track(&beekeeper^.allocator.tracker);
    {
    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check(&beekeeper^.allocator.tracker);

    return true;
}

/**
 * @brief tests the functionality of BKPR_PointerUnique
 */
test2 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.begin_track(&beekeeper^.allocator.tracker);
    {
        unq_text_desc := bkpr.BKPR_TextDesc {
            make([]u8, 4),
        };
        unq_text_desc.dummy_text_buffer[0] = 116;
        unq_text_desc.dummy_text_buffer[1] = 101;
        unq_text_desc.dummy_text_buffer[2] = 120;
        unq_text_desc.dummy_text_buffer[3] = 116;
        defer delete(unq_text_desc.dummy_text_buffer);

        unq_text, ok := bkpr.init_bkpr_unq_text(beekeeper, unq_text_desc).?;
        defer unq_text->dump();
        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do defer bkpr.untrack(&beekeeper^.allocator.tracker, &unq_text);

        // check basic functions
        if unq_text->address() != &unq_text.resource_ref do return false;
        new_dummy_text_buffer := make([]u8, 8);
        {
            new_dummy_text_buffer[0] = 110;
            new_dummy_text_buffer[1] = 101;
            new_dummy_text_buffer[2] = 119;
            new_dummy_text_buffer[3] = 95;
            new_dummy_text_buffer[4] = 116;
            new_dummy_text_buffer[5] = 101;
            new_dummy_text_buffer[6] = 120;
            new_dummy_text_buffer[7] = 116;
        }
        unq_text->update(&{new_dummy_text_buffer});
        if unq_text.resource_ref.dummy_text != "new_text" do return false;
    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check(&beekeeper^.allocator.tracker);

    return true;
}

/**
 * @brief tests the functionality of BKPR_PointerImmutable
 */
test1 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.begin_track(&beekeeper^.allocator.tracker);
    {
        imm_polygon, ok := bkpr.init_bkpr_imm_polygon(&beekeeper, {}).?;
        if !ok do return false;

        // check basic functions
        if imm_polygon->address() != &imm_polygon.resource_ref do return false;

        when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.untrack(&beekeeper^.allocator.tracker, &imm_polygon);
        imm_polygon->dump(); // cannot test this one other than just see it NOT fail xD
    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check(&beekeeper^.allocator.tracker);

    return true;
}

main :: proc() {

    beekeeper := bkpr.BKPR_Manager{};
    bkpr.init(&beekeeper);

    if !test1() do fmt.printf("\x1b[31mFailed to pass test1!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test1!\n\x1b[0m");

    if !test2() do fmt.printf("\x1b[31mFailed to pass test2!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test2!\n\x1b[0m");

    if !test3() do fmt.printf("\x1b[31mFailed to pass test3!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test3!\n\x1b[0m");

    bkpr.dump(&beekeeper);

}