//+build windows
package test

import "core:os"

import meta "../../meta"

main :: proc() {
    meta.debug_assert_abort(len(os.args) >= 4, "Invalid number of arguments!");
    meta.check_nexa_project(os.args[1], os.args[2], os.args[3]);
}