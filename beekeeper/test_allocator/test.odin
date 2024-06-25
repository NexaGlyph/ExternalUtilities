package test

import "core:fmt"

import bkpr "../"

/**
 * @brief tests allocation of custom pools and custom resources! (TODO)
 */
test3 :: proc() -> bool {
    return false;
}

/**
 * @brief tests allocator initialization and dumpin as well as custom deletion and reallocation of pools
 * this will check: BKPR_AllocatorMode.*{All, Free_All, Free}
 */
test2 :: proc() -> bool {

    beekeper := bkpr.BKPR_Manager{};
    fmt.println("BKPR INIT");
    fmt.println("--------------------------");
    bkpr.init(&beekeper);
    fmt.println("--------------------------");

    fmt.println("\x1b[33mDeleting line pool: \x1b[0m");
    res := bkpr.dump_bkpr_pool(&beekeper.line_pool, &beekeper.allocator);
    if res != .None do return false;
    fmt.println("---------------------");

    fmt.println("\x1b[33mReallocating line pool: \x1b[0m");
    res = bkpr.init_bkpr_pool(&beekeper.line_pool, &beekeper.allocator, bkpr.POOL_SIZE_DESCRIPTION(100, bkpr.BKPR_PoolObject(bkpr.BKPR_Line)));
    if res != .None do return false;
    fmt.println("---------------------");

    fmt.println("BKPR DUMP");
    bkpr.dump(&beekeper);
    fmt.println("--------------------------");

    return true;
}

/**
 * @brief basic test, initialize and dump allocator and all of its pools
 * this will check: BKPR_AllocatorMode.*{All, Free_All}
 */
test1 :: proc() -> bool {

    beekeper := bkpr.BKPR_Manager{};
    fmt.println("BKPR INIT");
    fmt.println("--------------------------");
    bkpr.init(&beekeper);
    fmt.println("--------------------------");

    fmt.println("BKPR DUMP");
    bkpr.dump(&beekeper);
    fmt.println("--------------------------");

    return true;
}

main :: proc() {

    if !test1() do fmt.printf("\x1b[31mFailed to pass test1!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test1!\n\x1b[0m");

    if !test2() do fmt.printf("\x1b[31mFailed to pass test2!\n\x1b[0m");
    else do fmt.printf("\x1b[32mPassed test2!\n\x1b[0m");

}