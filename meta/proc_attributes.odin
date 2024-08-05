//+build windows
package meta

import "core:fmt"
import "core:strings"
import "core:odin/ast"

// GENERAL
package_active_file_changed :: proc(pckg: ^PackageContext, src: string) {
    pckg^.active_file^ = strings.clone(src);
}
//! GENERAL

// API CALL
check_attribute_api_call :: proc(
    call_type: CustomProcAttributeType,
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    todo();
}
//! API CALL

// DEBUG ONLY
check_attribute_debug_only :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    todo();
}
//! DEBUG ONLY

// MAIN THREAD ONLY
check_attribute_main_thread :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    todo();
}
//! MAIN THREAD ONLY

// LAUNCHER ENTRY
check_attribute_launcher_entry :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    // project^.launcher_entry can be only one, so this block should never be executed once the launcher_entry is populated
    if project^.launcher_entry == nil {
        // set the application entry to the project context
        project^.launcher_entry = append_attribute(project);
        project^.launcher_entry^.decl_spec = decl_spec;
        project^.launcher_entry^.attr_type = .LAUNCHER_ENTRY;
        project^.launcher_entry^.pckg = pckg;
        project^.launcher_entry^.resolved = false; // will be resolved once we find the "main" function 
        project^.launcher_entry^.location = location;
        // check whether the params and return type fit the description
    } else {
        debug_assert_cleanup(
            false,
            "There can be only one procedure with NexaAttr_LauncherEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
            format_debug_info_from_decl_spec(project^.launcher_entry^.decl_spec),
            format_debug_info_from_decl_spec(decl_spec),
        );
    }
}

check_attribute_launcher_entry_schema :: proc() {
    assert(false, "todo");
}
//! LAUNCHER ENTRY

// APP ENTRY
check_attribute_application_entry :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    // project^.app_entry can be only one, so this block should never be executed once the app_entry is populated
    if project^.app_entry == nil {
        // set the application entry to the project context
        project^.app_entry = append_attribute(project);
        project^.app_entry^.decl_spec = decl_spec;
        project^.app_entry^.attr_type = .APPLICATION_ENTRY;
        project^.app_entry^.pckg = pckg;
        project^.app_entry^.resolved = false; // will be resolved once we find the "main" function 
        project^.app_entry^.location = location;
    } else {
        debug_assert_cleanup(
            false,
            "There can be only one procedure with NexaAttr_ApplicationEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
            format_debug_info_from_decl_spec(project^.app_entry^.decl_spec),
            format_debug_info_from_decl_spec(decl_spec),
        );
    }
}
//! APP ENTRY

// INLINE
check_attribute_inline :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    if decl_spec.proc_decl^.inlining == .Inline {
        debug_assert_ignore(
            false,
            "Cannot mark procedure with NexaAttr_Inline that has already been tagged to be inlined\nProc: [%v]",
            format_debug_info_from_decl_spec(decl_spec),
        );
        return; // do not register when it is useless
    }
    inline_attr := append_attribute(project);
    inline_attr^.decl_spec = decl_spec;
    inline_attr^.attr_type = .INLINE;
    inline_attr^.pckg = pckg;
    inline_attr^.resolved = true;
    inline_attr^.location = location;
}

modify_proc_inline :: proc() {
}
//! INLINE

// CORE INIT
check_attribute_core_init :: proc(
    project: ^ProjectContext,
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    core_init_attr := append_attribute(project);
    core_init_attr^.decl_spec = decl_spec;
    core_init_attr^.attr_type = .CORE_INIT;
    core_init_attr^.pckg = pckg;
    core_init_attr^.location = location;
    inspect_attribute_core_init(decl_spec.proc_decl.body.derived_stmt);
    core_init_attr^.resolved = true;
}

inspect_attribute_core_init :: proc(body: ast.Any_Stmt) {
    block, ok := body.(^ast.Block_Stmt);
    debug_assert_ignore(ok, "Failed to cast proc body!"); // todo: change to cleanup
    for stmt in block.stmts {
        // check for context.user_ptr access
        fmt.printf("[CORE_INIT] Stmt: %v\n", stmt);
    }
}
//! CORE INIT
