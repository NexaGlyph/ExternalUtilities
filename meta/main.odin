//+build windows
package meta

import "core:os"

main :: proc() {
    if len(os.args) == 2 {
        if os.args[1] == "REVERT_CHANGES" do load_backup();
    }
    assert(len(os.args) >= 4, "Invalid number of arguments!");
    check_nexa_project(os.args[1], os.args[2], os.args[3]);
}