//+build windows
package meta

import "core:fmt"
import "core:c/libc"

when !ODIN_DEBUG {

runtime_assert_ignore :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    runtime_assert(.Ignore, condition, formatted_string, args);
}

runtime_assert_cleanup :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    runtime_assert(.CleanUp, condition, formatted_string, args);
}

runtime_assert_abort :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    runtime_assert(.CanAbort, condition, formatted_string, args);
}

runtime_assert :: proc(notification: AppNotification, condition: bool, formatted_string: string, args: ..any) {
    switch notification {
        case .Ignore:
            if !condition {
                fmt.print("\x1b[31m[RUNTIME_ASSERTION]:\x1b[0m");
                fmt.println(fmt.tprintf(formatted_string, args));
            }
        case .CleanUp:
            if !condition {
                fmt.print("\x1b[31m[ABORT_ASSERTION]:\x1b[0m");
                fmt.println(fmt.tprintf(formatted_string, ..args));
                revert_changes_in_program();
                libc.abort();
            }
        case .CanAbort:
            if !condition {
                fmt.print("\x1b[31m[ABORT_ASSERTION]:\x1b[0m");
                fmt.println(fmt.tprintf(formatted_string, args));
                libc.abort();
            }
    }
}

todo :: #force_inline proc(location := #caller_location) {
    runtime_assert_ignore(false, "[%s]: This functionality is not yet implemented!", location);
}
} //! (!ODIN_DEBUG)