//+build windows
package meta

import "core:io"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:odin/ast"

// GENERAL
package_active_file_changed :: #force_inline proc(pckg: ^PackageContext, src: string, location: string) {
    pckg^.active_file^ = PackageFile { src = strings.clone(src), location = strings.clone(location) };
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
    api_call_attribute^ = CustomProcAttribute {
        decl_spec = decl_spec,
        attr_type = call_type,
        pckg = pckg,
        resolved = false, // will be resolved once we find parse all the functions in all packages
        location = location,
    };
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
    debug_only_attribute^ = CustomProcAttribute {
        decl_spec = decl_spec,
        attr_type = .DEBUG_ONLY,
        pckg = pckg,
        location = location,
    };

    project := cast(^ProjectContext)context.user_ptr;
    fmt_proc_new(&project^.formatter);
    debug_assert_cleanup(
        inspect_attribute_debug_only(debug_only_attribute, ast_file),
        "Function marked as 'debug only' is not located inside debug when statement!\nFunction: %v\n",
        project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
    );

    debug_only_attribute^.resolved = true;
}

inspect_attribute_debug_only :: proc(debug_only_attribute: ^CustomProcAttribute, ast_file: ^ast.File) -> bool {
    _parse_when_cond :: proc(expr: ast.Any_Expr) -> (ident: ^ast.Ident, reversed: bool) {
        // expressions possible:
        // Paren_Expr <-> Binary_Expr/Unary_Expr <-> Ident ("NexaConst_Debug")
        ok: bool;
        #partial switch e in expr {
            case ^ast.Paren_Expr:
                ident, ok = e.expr.derived_expr.(^ast.Ident);
                debug_assert_abort(false, "Complex expression parsing and boolean eval is not yet supported for NexaAttr_DebugOnly; Please just use 'when NexaConst_Debug'");
            case ^ast.Binary_Expr:
                ident, ok = e.left.derived_expr.(^ast.Ident); //note: what about Yoda notation ?????
                debug_assert_abort(false, "Complex expression parsing and boolean eval is not yet supported for NexaAttr_DebugOnly; Please just use 'when NexaConst_Debug'");
            case ^ast.Unary_Expr:
                ident, ok = e.expr.derived_expr.(^ast.Ident);
                if e.op.kind == .Not do reversed = true;
                debug_assert_cleanup(ok, "Failed to parse 'when' condition! It seems that the logic is too obscure to evaluate the primitve check for 'NexaConst_Debug'");
            case ^ast.Ident:
                ident = e;
            case:
                debug_assert_cleanup(false, "Invalid expression when parsing when block! %v\n", e);
        }
        return;
    }

    _interate_decls_for_debug_only_proc :: proc(stmts: []^ast.Stmt, debug_only_attribute: CustomProcAttributeDeclSpec) -> bool {
        for stmt in stmts {
            #partial switch s in stmt^.derived {
                case ^ast.Value_Decl:
                    if proc_expr, ok := s.values[0].derived_expr.(^ast.Proc_Lit); ok {
                        if proc_expr == debug_only_attribute.proc_decl do return true;
                    }
            }
        }
        return false;
    }

    for decl in ast_file^.decls {
        #partial switch d in decl^.derived_stmt {
            case ^ast.When_Stmt:
                ident, reversed := _parse_when_cond(d.cond.derived_expr);
                if ident.name == "ODIN_DEBUG" || ident.name == "NexaConst_Debug" {
                    stmts: []^ast.Stmt;
                    if reversed { // else block is where the function should be
                        stmts = d.else_stmt.derived_stmt.(^ast.Block_Stmt).stmts;
                    } else {
                        stmts = d.body.derived_stmt.(^ast.Block_Stmt).stmts;
                    }
                    if _interate_decls_for_debug_only_proc(stmts, debug_only_attribute^.decl_spec) do return true;
                }
        }
    }

    return false;
}
//! DEBUG ONLY

// MAIN THREAD ONLY
check_attribute_main_thread :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    not_yet_implemented();
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
        project^.launcher_entry^ = CustomProcAttribute {
            decl_spec = decl_spec,
            attr_type = .LAUNCHER_ENTRY,
            pckg = pckg,
            resolved = false, // will be resolved once we find the "main" function 
            location = location,
        };
        // check whether the params and return type fit the description
    } else {
        fmt_proc_new(&project^.formatter);
        debug_assert_cleanup(
            false,
            "There can be only one procedure with NexaAttr_LauncherEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
            project^.formatter->Proc_AttributeLocation(project^.launcher_entry^.decl_spec.attribute)->Proc_DeclLocation(project^.launcher_entry^.decl_spec.proc_decl)->Build(),
            project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
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
        project^.app_entry^ = CustomProcAttribute {
            decl_spec = decl_spec,
            attr_type = .APPLICATION_ENTRY,
            pckg = pckg,
            resolved = false, // will be resolved once we find the "main" function 
            location = location,
        };
    } else {
        fmt_proc_new(&project^.formatter);
        debug_assert_cleanup(
            false,
            "There can be only one procedure with NexaAttr_ApplicationEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
            project^.formatter->Proc_AttributeLocation(project^.app_entry^.decl_spec.attribute)->Proc_DeclLocation(project^.app_entry^.decl_spec.proc_decl)->Build(),
            project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
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
        project := cast(^ProjectContext)context.user_ptr;
        fmt_proc_new(&project^.formatter);
        debug_assert_ignore(
            false,
            "Cannot mark procedure with NexaAttr_Inline that has already been tagged to be inlined\nProc: [%v]",
            project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
        );
        return; // do not register when it is useless
    }
    inline_attr := append_attribute();
    inline_attr^ = CustomProcAttribute {
        decl_spec = decl_spec,
        attr_type = .INLINE,
        pckg = pckg,
        resolved = true,
        location = location,
    };
    modify_proc_inline(decl_spec.proc_decl, pckg, location);
}

modify_proc_inline :: proc(proc_decl: ^ast.Proc_Lit, pckg: ^PackageContext, location: string) {
    // access writer for the specific file 
    handle, ok := os.open(location, os.O_WRONLY);
    debug_assert_cleanup(ok == os.ERROR_NONE, "Failed to open file %s\nFile open error: %v\n", location, ok);
    defer os.close(handle);
    writer := os.stream_from_handle(handle);
    // we have to always reset the buffer for the writer with the one that has the 'original' file, a.k.a authors code
    end := proc_decl.body.derived_stmt.(^ast.Block_Stmt)^.open.offset;
    begin := proc_decl.pos.offset;
    gb := gap_buffer_init(end - begin);
    gap_buffer_copy(&gb, pckg^.active_file^.src[begin:end]);
    // todo: tprintf instead of this ...
    gap_buffer_insert(&gb, 0, "#force_inline ");
    io.write_string(writer, pckg^.active_file^.src[:begin]);
    io.write_string(writer, gap_buffer_to_string(&gb)); 
    io.write_string(writer, pckg^.active_file^.src[end:]);
    gap_buffer_dump(&gb);
}
//! INLINE

// CORE INIT
check_attribute_core_init :: proc(
    decl_spec: CustomProcAttributeDeclSpec,
    pckg: ^PackageContext,
    location: string,
) {
    core_init_attr := append_attribute();
    core_init_attr^ = CustomProcAttribute {
        decl_spec = decl_spec,
        attr_type = .CORE_INIT,
        pckg = pckg,
        location = location,
    };

    inspect_attribute_core_init(decl_spec);

    core_init_attr^.resolved = true;
}

inspect_attribute_core_init :: proc(decl_spec: CustomProcAttributeDeclSpec) {
    _detect_context_user_ptr_access :: proc(stmt: ^ast.Stmt, decl_spec: CustomProcAttributeDeclSpec) -> bool {
        #partial switch s in stmt.derived {
            case ^ast.Expr_Stmt:
                return _contains_context_user_ptr(s.expr);
            case ^ast.Block_Stmt:
                _traverse_stmts(s.stmts, decl_spec);
            case ^ast.Assign_Stmt:
                project := cast(^ProjectContext)context.user_ptr;
                fmt_proc_new(&project^.formatter);
                for expr in s.lhs {
                    debug_assert_cleanup(
                        _contains_context_user_ptr(expr),
                        "Procedure marked as 'CoreInit' is using context.user_ptr which is prohibited!\nDecl: %v",
                        project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
                    );
                }
                for expr in s.rhs {
                    debug_assert_cleanup(
                        _contains_context_user_ptr(expr),
                        "Procedure marked as 'CoreInit' is using context.user_ptr which is prohibited!\nDecl: %v",
                        project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
                    );
                }
        }
        return false;
    }

    _contains_context_user_ptr :: proc(expr: ^ast.Expr) -> bool {
        #partial switch e in expr.derived_expr {
            case ^ast.Selector_Expr:
                if e.field.name == "user_ptr" && e.expr.derived_expr.(^ast.Ident).name == "context" {
                    return true;
                }
            case ^ast.Call_Expr:
                contains := false;
                for i := 0; i < len(e.args) && !contains; i += 1 do contains = _contains_context_user_ptr(expr);
                return contains;
            case ^ast.Paren_Expr:
                return _contains_context_user_ptr(e.expr);
            case ^ast.Binary_Expr:
                return _contains_context_user_ptr(e.left) || _contains_context_user_ptr(e.right);
            case ^ast.Ident:
                fmt.printf("\x1b[33mIdent name when looking for context.user_ptr: %v\x1b[0m\n", e.name);
                return e.name == "context.user_ptr";
        }
        return false;
    }

    _traverse_stmts :: #force_inline proc(stmts: []^ast.Stmt, decl_spec: CustomProcAttributeDeclSpec) {
        project := cast(^ProjectContext)context.user_ptr;
        fmt_proc_new(&project^.formatter);
        for stmt in stmts {
            debug_assert_cleanup(
                _detect_context_user_ptr_access(stmt, decl_spec), 
                "Procedure marked as 'CoreInit' is using context.user_ptr which is prohibited!\nDecl: %v",
                project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
            );
        }
    }

    block, ok := decl_spec.proc_decl.body.derived_stmt.(^ast.Block_Stmt);
    project := cast(^ProjectContext)context.user_ptr;
    fmt_proc_new(&project^.formatter);
    debug_assert_cleanup(
        ok,
        "Failed to cast proc body!Decl: %v\n",
        project^.formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Build(),
    );
    _traverse_stmts(block.stmts, decl_spec);
}

//! CORE INIT
