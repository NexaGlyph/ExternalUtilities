package test

import bkpr "../"

/**
 * @brief tests the functionality of BKPR_PointerShared
 */
test3 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    return false;
}

/**
 * @brief tests the functionality of BKPR_PointerUnique
 */
test2 :: proc(beekeeper: ^bkpr.BKPR_Manager) -> bool {
    return false;
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
    }
    when bkpr.BKPR_DEBUG_TRACKER_ENABLED do bkpr.block_check(&beekeeper^.allocator.tracker);
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