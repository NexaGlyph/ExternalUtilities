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
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    api_call_attribute := append_attribute();
    api_call_attribute^.decl_spec = decl_spec;
    api_call_attribute^.attr_type = call_type;
    api_call_attribute^.pckg = pckg;
    api_call_attribute^.resolved = false; // will be resolved once we find parse all the functions in all packages
    api_call_attribute^.location = location;
}
//! API CALL

// DEBUG ONLY
check_attribute_debug_only :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    ast_file: ^ast.File,
    pckg: ^PackageContext,
    location: string,
) {
    debug_only_attribute := append_attribute();
    debug_only_attribute^.decl_spec = decl_spec;
    debug_only_attribute^.attr_type = .DEBUG_ONLY;
    debug_only_attribute^.pckg = pckg;
    debug_only_attribute^.location = location;

    inspect_attribute_debug_only(debug_only_attribute, ast_file);

    debug_only_attribute^.resolved = true;
}

inspect_attribute_debug_only :: proc(debug_only_attribute: ^CustomProcAttribute, ast_file: ^ast.File) {
    parse_when_cond :: proc(expr: ast.Any_Expr) -> ^ast.Ident {
        // expressions possible:
        // Paren_Expr <-> Binary_Expr/Unary_Expr <-> Ident ("NexaConst_Debug")
        ident: ^ast.Ident;
        ok: bool;
        #partial switch e in expr {
            case ^ast.Paren_Expr:
                ident, ok = e.expr.derived_expr.(^ast.Ident);
            case ^ast.Binary_Expr:
                ident, ok = e.left.derived_expr.(^ast.Ident); //note: what about Yoda notation ?????
            case ^ast.Unary_Expr:
                ident, ok = e.expr.derived_expr.(^ast.Ident);
                debug_assert_cleanup(ok, "Failed to parse 'when' condition! It seems that the logic is too obscure to evaluate the primitve check for 'NexaConst_Debug'");
        }
        return ident;
    }
    for decl in ast_file^.decls {
        #partial switch d in decl^.derived_stmt {
            case ^ast.When_Stmt:
                ident := parse_when_cond(d.cond.derived_expr);
                debug_assert_ignore(false, "%v", ident.name);
                if ident.name == "ODIN_DEBUG" || ident.name == "NexaConst_Debug" {
                }
        }
    }
}
//! DEBUG ONLY

// MAIN THREAD ONLY
check_attribute_main_thread :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    todo();
}
//! MAIN THREAD ONLY

// LAUNCHER ENTRY
check_attribute_launcher_entry :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    // project^.launcher_entry can be only one, so this block should never be executed once the launcher_entry is populated
    project := cast(^ProjectContext)context.user_ptr;
    if project^.launcher_entry == nil {
        // set the application entry to the project context
        project^.launcher_entry = append_attribute();
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
    todo();
}
//! LAUNCHER ENTRY

// APP ENTRY
check_attribute_application_entry :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    // project^.app_entry can be only one, so this block should never be executed once the app_entry is populated
    project := cast(^ProjectContext)context.user_ptr;
    if project^.app_entry == nil {
        // set the application entry to the project context
        project^.app_entry = append_attribute();
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
    inline_attr := append_attribute();
    inline_attr^.decl_spec = decl_spec;
    inline_attr^.attr_type = .INLINE;
    inline_attr^.pckg = pckg;
    inline_attr^.resolved = true;
    inline_attr^.location = location;
}

modify_proc_inline :: proc() {
    todo();
}
//! INLINE

// CORE INIT
check_attribute_core_init :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    core_init_attr := append_attribute();
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
