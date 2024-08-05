//+build windows
package meta

import "core:c/libc"
import "core:fmt"

/** @brief describes how the debug assertions should be handled in the application runtime */
AppNotification :: enum {
    /** @brief ignore result of assertion */
    Ignore = 0,
    /** @brief should revert changes and return */
    CleanUp,
    /** @brief does not have to revert changes, just return */
    CanAbort,
}

debug_assert_ignore :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.Ignore, condition, formatted_string, args);
}
debug_assert_cleanup :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.CleanUp, condition, formatted_string, args);
}
debug_assert_abort :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.CanAbort, condition, formatted_string, args);
}

debug_assert :: proc(notification: AppNotification, condition: bool, formatted_string: string, args: ..any) {
    switch notification {
        case .Ignore:
            debug_runtime_assert(condition, formatted_string, args);
        case .CleanUp:
            if !condition {
                //todo: access NexaContext via "context.user_ptr" and clean the resources; the API should handle the exit
                debug_abort_assert(false, formatted_string, args);
            }
        case .CanAbort:
            debug_abort_assert(condition, formatted_string, args);
    }
}

/** @brief functions checks the condition, halts and waits for the user to continue */
@(private="file")
debug_runtime_assert :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    if !condition {
        fmt.printf("\x1b[31m[RUNTIME_ASSERTION]:\x1b[0m %s", fmt.tprintf(formatted_string, args));
        for libc.getchar() != '\n' do continue;
    }
}

/** @brief function checks the condition and aborts the program if it is not met */
@(private="file")
debug_abort_assert :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    if !condition {
        fmt.printf("\x1b[31m[ABORT_ASSERTION]:\x1b[0m %s", fmt.tprintf(formatted_string, args));
        libc.abort();
    }
} 

todo :: #force_inline proc(location := #caller_location) {
    debug_abort_assert(false, "[%s]: TODO!", location);
}