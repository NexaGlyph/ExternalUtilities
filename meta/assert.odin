//+build windows
package meta

/** @brief describes how the assertions should be handled in the application runtime */
AppNotification :: enum {
    /** @brief ignore result of assertion */
    Ignore = 0,
    /** @brief should revert changes and return */
    CleanUp,
    /** @brief does not have to revert changes, just return */
    CanAbort,
}

massert_ignore :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    when ODIN_DEBUG do debug_assert_ignore(condition, formatted_string, args);
    else do runtime_assert_ignore(condition, formatted_string, args);
}

massert_cleanup :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    when ODIN_DEBUG do debug_assert_cleanup(condition, formatted_string, args);
    else do runtime_assert_cleanup(condition, formatted_string, args);
}

massert_abort :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    when ODIN_DEBUG do debug_assert_abort(condition, formatted_string, args);
    else do runtime_assert_abort(condition, formatted_string, args);
}