//+build windows
package meta

import "core:c/libc"
import "core:fmt"

when ODIN_DEBUG {

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
            if !condition {
                fmt.print("\x1b[31m[RUNTIME_ASSERTION]:\x1b[0m");
                fmt.println(fmt.tprintf(formatted_string, args));
                wait();
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

wait :: #force_inline proc() {
    for libc.getchar() != '\n' do continue;
}

todo :: #force_inline proc(location := #caller_location) {
    debug_assert_abort(false, "[%s]: TODO!", location);
}
} //! ODIN_DEBUG