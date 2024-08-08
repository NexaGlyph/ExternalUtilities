//+build windows
package meta

import "core:fmt"
import "core:strings"
import "core:os"
import "core:io"

import "core:odin/parser"
import "core:odin/ast"
// import "core:reflect"

CustomStructTagType :: enum {
    PRIVATE_MEMBER = 1,
}
/** @brief used to mark the expression of the struct containing the attribute applied upon it */
CustomStructTagDeclSpec :: struct {
    struct_decl: ^ast.Struct_Type,
    attribute: ^ast.Attribute,
}
/**
 * @brief specifies the location and type of the custom tag
 * @note these tags have to be reconstructed before compilation, so we store the data of the "previous" - tagged version of the struct before the compilation but change the file subsequently,
 * therefore we have to also store what the line was specifically about and replace it back again after compilation succeeds
 */
CustomStructTag :: struct {
    /** @brief storing the declaration */
    decl_spec: CustomStructTagDeclSpec,
    /** @brief stores type of tag */
    tag_type: CustomStructTagType,
    /** @brief stores pointer to the package to which it belongs to */
    pckg: ^PackageContext,
}

dump_tag :: #force_inline proc(tag: ^CustomStructTag) {
    todo();
}

CustomProcAttributeType :: enum {
    // file non-modifying
    API_CALL_INTERNAL = 1,
    API_CALL_EXTERNAL,
    DEBUG_ONLY,
    MAIN_THREAD_ONLY,
    CORE_INIT,
    // file modifying
    APPLICATION_ENTRY = 100,
    LAUNCHER_ENTRY,
    INLINE,
}
/** @brief used to mark the expression of the procedure containing the attribute applied upon it */
CustomProcAttributeDeclSpec :: struct {
    proc_decl: ^ast.Proc_Lit,
    attribute: ^ast.Attribute,
}
/** @brief stores the basic procedure attribute config */
CustomProcAttribute :: struct {
    /** @brief stores the declaration of the proc */
    decl_spec: CustomProcAttributeDeclSpec,
    /** @brief stores the type of the attribute */
    attr_type: CustomProcAttributeType,
    /** @brief contains a pointer to a package which it is defined in */
    pckg: ^PackageContext,
    /** @brief signals if the attribute has been correctly checked in the projects (if not, collapse_unresolved should have it) */
    resolved: bool,
    /** @brief stores the file location */
    location: string,
}
dump_attribute :: #force_inline proc(attr: ^CustomProcAttribute) {
    delete_string(attr^.location);
}

/** @brief specifies the type of package (only accounts for the three important "HEADS") */
PackageType :: enum {
    DEMO = 0,
    CORE,
    EXTERNAL,
}
PackageFile :: struct {
    src: string,
    location: string,
}
/** @brief contains all the custom tags and attributes from the package */
PackageContext :: struct {
    /** @brief file location of this package */
    location: string,
    /** @brief contains whole files before 'meta' made changes to it (set to 'nil' if there are not any) */
    files: []PackageFile,
    /** @brief file currently being manipulated with (potentially) */
    active_file: ^PackageFile,
    /** @brief contains all "subpackages" that are located in the root folder of this package */
    subpackages: [dynamic]PackageContext,
}

init_package :: #force_inline proc(dir: string) -> PackageContext {
    return PackageContext {
        location = dir,
        subpackages = make([dynamic]PackageContext),
    };
}

dump_package :: proc(using pckg: ^PackageContext) {
    // delete cloned location
    delete_string(location);
    // delete cloned files
    for file in files {
        if len(file.src) > 0 {
            delete_string(file.src);
            delete_string(file.location);
        }
    }
    // discard any subpackages
    for &subpackage in subpackages do dump_package(&subpackage);
    delete(subpackages);
}

/** @brief holds the context of the 'whole' project demo, contains information easily accessible to the check_file proc */
ProjectContext :: struct {
    /** @brief holds all the tags defined in the package */
    tags: [dynamic]CustomStructTag,
    /** @brief holds all the attributes defined in the package */
    attributes: [dynamic]CustomProcAttribute,

    /** @brief contains precisely three packages: NexaCore, ExternalUtilities, Demo */
    packages: [PackageType]PackageContext,

    /** @brief points to the precise attribute with the CustomProcAttributeType.APPLICATION_ENTRY */
    app_entry: ^CustomProcAttribute,
    /** @brief pointer to the attribute with the CustomProcAttributeType.LAUNCHER_ENTRY*/
    launcher_entry: ^CustomProcAttribute,

    /** @brief formatter used to save data to be formatted for console (useful since not every attribute requires the same info to be printed) */
    formatter: IFormatter,
}

init_project :: #force_inline proc(curr_demo_dir, nexa_core_dir, external_dir: string) -> (project: ProjectContext) {
    project.tags = make([dynamic]CustomStructTag);
    project.attributes = make([dynamic]CustomProcAttribute);
    
    project.packages[.DEMO] = init_package(curr_demo_dir);
    project.packages[.CORE] = init_package(nexa_core_dir);
    project.packages[.EXTERNAL] = init_package(external_dir);

    project.app_entry = nil;
    project.launcher_entry = nil;
    return;
}

dump_project :: #force_inline proc(project: ^ProjectContext) {
    for &pckg in project^.packages do dump_package(&pckg);
    delete(project^.tags);
    delete(project^.attributes);
}

append_attribute :: #force_inline proc() -> ^CustomProcAttribute {
    project := cast(^ProjectContext)context.user_ptr;
    append(&project^.attributes, CustomProcAttribute {});
    return &project^.attributes[len(project^.attributes) - 1];
}

append_tag :: proc(project: ^ProjectContext) -> ^CustomStructTag {
    append(&project^.tags, CustomStructTag{});
    return &project^.tags[len(project^.tags) - 1];
}

/**
 * @brief checks the whole Nexa project (current Demo + ExternalUtilities/NexaCore)
 * @note this project should be launched implicitly by the NexaCLI and not by the user manually,
 * if no "meta"/precompile is intended to be used, just compile the Demo with odin comp. with ignore-unknown-attributes 
 */
check_nexa_project :: proc(demo_dir, core_dir, external_dir: string) {
    project := init_project(demo_dir, core_dir, external_dir);
    context.user_ptr = &project;
    defer dump_project(&project);
    fmt.printf("Checking folder [NEXA_CORE]: %s\n", core_dir);
    check_nexa_core(core_dir, &project.packages[.CORE]);
    fmt.printf("Checking folder [EXTERNAL_UTILS]: %s\n", external_dir);
    check_external_utils(external_dir, &project.packages[.EXTERNAL]);
    fmt.printf("Checking folder [DEMO]: %s\n", demo_dir);
    check_demo(demo_dir, &project.packages[.DEMO]);
    // some attributes / tags can be only defined once we have parsed everything
    collapse_unresolved();
    wait();
    revert_changes();
}

check_project_dir :: #force_inline proc(dir: string, pckg: ^PackageContext) {
    info, err := os.lstat(dir);
    assert(err == os.ERROR_NONE);
    // defer os.file_info_delete(info);
    check_folder(info, pckg);
}

check_nexa_core      :: check_project_dir;
check_external_utils :: check_project_dir;
check_demo           :: check_project_dir;

read_dir :: proc(dir_name: string) -> []os.File_Info {
	handle, err := os.open(dir_name, os.O_RDONLY);
	fmt.assertf(err == os.ERROR_NONE, "Failed to open directory! Err: %v", err);
	defer os.close(handle);
	file_infos: []os.File_Info;
	file_infos, err = os.read_dir(handle, -1);
	fmt.assertf(err == os.ERROR_NONE, "Failed to read directory! Err: %v", err);
	return file_infos;
}

check_folder :: proc(folder_info: os.File_Info, pckg: ^PackageContext) {

    assert(folder_info.is_dir == true);
	file_infos := read_dir(folder_info.fullpath);
	defer os.file_info_slice_delete(file_infos);

    p := parser.default_parser();
    ast_file: ast.File;
    handle: os.Handle;
    err: os.Errno;
    reader: io.Reader;
    file_buffer: []u8;

    pckg.files = make([]PackageFile, len(file_infos));

    for file_info, index in file_infos {
        pckg.active_file = &pckg.files[index];
        if file_info.is_dir {
            append(&pckg.subpackages, init_package(file_info.fullpath));
            check_folder(file_info, &pckg.subpackages[len(pckg.subpackages) - 1]);
        }
        else {
            handle, err = os.open(file_info.fullpath, os.O_RDONLY);
            fmt.assertf(err == os.ERROR_NONE, "Failed to read file(%s)! [Err: %v]\n", file_info.fullpath, err);
            reader = os.stream_from_handle(handle);

            file_buffer = make([]u8, file_info.size);
            l, e := io.read_full(reader, file_buffer[:]);
            os.close(handle);
            fmt.assertf(l == len(file_buffer) && e == .None, "Failed to read buffer! Error: %v; Lengths: %d :: %d", e, l, len(file_buffer));
            ast_file = ast.File{
                src = string(file_buffer),
            };
            ast_file.fullpath = strings.clone(file_info.fullpath); // this file_info.full_path is only temporarily allocated...

            if parser.parse_file(&p, &ast_file) != true {
                fmt.printf("%v\n", p.tok);
                fmt.assertf(false, "Failed to parse file!(%s)\nErr count: %d\n", file_info.fullpath, p.error_count);
            }
            check_file(&p, &ast_file, pckg);
            delete(file_buffer);
        }
    }
}

check_file :: proc(p: ^parser.Parser, ast_file: ^ast.File, pckg: ^PackageContext) {
    _internal_iterate_decls :: proc(p: ^parser.Parser, decls: []^ast.Stmt, ast_file: ^ast.File, pckg: ^PackageContext) {
        for decl in decls {
            #partial switch d in decl.derived {
                case ^ast.Value_Decl:
                    #partial switch expr in d.values[0].derived_expr {
                        case ^ast.Proc_Lit:
                            check_attributes_proc(d, expr, ast_file, pckg);
                        case ^ast.Struct_Type:
                            check_tags_struct(d, expr, ast_file, pckg);
                    }
                case ^ast.When_Stmt:
                    body_block, ok := d.body.derived_stmt.(^ast.Block_Stmt);
                    debug_assert_abort(ok, "Internal error. This call should always pass...");
                    _internal_iterate_decls(p, body_block.stmts, ast_file, pckg);
                    if d.else_stmt != nil {
                        body_block, ok  = d.else_stmt.derived_stmt.(^ast.Block_Stmt);
                        debug_assert_abort(ok, "Internal error. This call should always pass...");
                        _internal_iterate_decls(p, body_block.stmts, ast_file, pckg);
                    }
            }
        }
    }

    _internal_iterate_decls(p, ast_file^.decls[:], ast_file, pckg);
}

check_tags_struct :: proc(d: ^ast.Value_Decl, ast_struct: ^ast.Struct_Type, ast_file: ^ast.File, pckg: ^PackageContext) {
    return;
}
check_attributes_proc :: proc(d: ^ast.Value_Decl, ast_proc: ^ast.Proc_Lit, ast_file: ^ast.File, pckg: ^PackageContext) {
    for attribute in d.attributes {
        expr_loop: for expr in attribute.elems {
            field_value, is_fielded_attr := expr.derived.(^ast.Field_Value);
            // either a special value is specified (e.g. "internal"/"external") or not
            // if not, parse just the Ident
            if !is_fielded_attr {
                check_attributes_proc_non_fielded(expr, CustomProcAttributeDeclSpec{ ast_proc, attribute }, ast_file, pckg);
                break expr_loop;
            }
            check_attributes_proc_fielded(field_value, CustomProcAttributeDeclSpec{ ast_proc, attribute }, ast_file, pckg);
        }
    }
}
check_attributes_proc_fielded :: proc(
    field_value: ^ast.Field_Value,
    decl_spec: CustomProcAttributeDeclSpec,
    ast_file: ^ast.File,
    pckg: ^PackageContext,
) {
    ident, ok := field_value.field.derived_expr.(^ast.Ident);
    if !ok do return;
    if ast_file.src[field_value.sep.offset] == 61 /* "=" */ {
        lit: ^ast.Basic_Lit;
        lit, _ = field_value.value.derived_expr.(^ast.Basic_Lit);
        switch ident.name {
            /**
            * @brief this should signify that the call comes from NexaCore, further ident can be specified:
            *   1. "internal" ... only NexaCore itself can access this function
            *   2. "external" ... can be accessed outside NexaCore
            */
            case "NexaAttr_APICall":
                if lit.tok.text == `"internal"` do check_attribute_api_call(.API_CALL_INTERNAL, decl_spec, pckg, ast_file^.fullpath);
                else if lit.tok.text == `"external"` do check_attribute_api_call(.API_CALL_EXTERNAL, decl_spec, pckg, ast_file^.fullpath);
                else {
                    debug_assert_ignore(
                        false,
                        "Invalid type of 'APICall' specifier provided!\nExpected [internal] or [external], but received [%s]",
                        lit.tok.text
                    );
                }
            case:
                // note: maybe should be only warned, not error'd
                assert(false, "Unknown attribute");
        }
    }
}
check_attributes_proc_non_fielded :: proc(
    expr: ^ast.Expr, 
    decl_spec: CustomProcAttributeDeclSpec, 
    ast_file: ^ast.File,
    pckg: ^PackageContext,
) {
    ident, ok := expr.derived.(^ast.Ident);
    if !ok do return;
    fmt.printf("Ident name: %s\n", ident.name);
    switch ident.name {
        /**
        * @brief automatically assumes "internal" ident, see NexaAttr_APICall fielded
        */
        case "NexaAttr_APICall":
            check_attribute_api_call(.API_CALL_INTERNAL, decl_spec, pckg, ast_file^.fullpath);
        /**
        * @brief this attribute tells meta to expect the proc as only defined in Debug modes (Debug/DebugX)
        */
        case "NexaAttr_DebugOnly":
            check_attribute_debug_only(decl_spec, ast_file, pckg, ast_file^.fullpath);
        /**
        * @brief marks function to be called from application (main) thread
        */
        case "NexaAttr_MainThreadOnly":
            check_attribute_main_thread(decl_spec, pckg, ast_file^.fullpath);
        /**
        * @brief unique attribute; defines a function that should be bound to "core.extern_launch"
        */
        case "NexaAttr_LauncherEntry":
            package_active_file_changed(pckg, ast_file^.src, ast_file^.fullpath);
            check_attribute_launcher_entry(decl_spec, pckg, ast_file^.fullpath);
        /**
        * @brief unique attribute; defines a function that should be bound to "core.extern_main"
        */
        case "NexaAttr_ApplicationEntry":
            package_active_file_changed(pckg, ast_file^.src, ast_file^.fullpath);
            check_attribute_application_entry(decl_spec, pckg, ast_file^.fullpath);
        /**
        * @brief marks function to be "inlined" (same as #force_inline)
        */
        case "NexaAttr_Inline":
            package_active_file_changed(pckg, ast_file^.src, ast_file^.fullpath);
            check_attribute_inline(decl_spec, pckg, ast_file^.fullpath);
        /**
        * @brief function that has prohibited access (this can be only done on "NexaAttr_APICall" procs) to NexaContext since this proc is/could be called BEFORE context init
        */
        case "NexaAttr_CoreInit":
            check_attribute_core_init(decl_spec, pckg, ast_file^.fullpath);
        // ignore all others
    }
}

collapse_unresolved :: proc() {
    project := cast(^ProjectContext)context.user_ptr;
    for &attr in project^.attributes {
        if !attr.resolved {
            #partial switch attr.attr_type {
                case .API_CALL_EXTERNAL:
                    resolve_api_call_external(&attr);
                case .API_CALL_INTERNAL:
                    resolve_api_call_internal(&attr);
                case .APPLICATION_ENTRY:
                    resolve_app_entry();
                case .LAUNCHER_ENTRY:
                    resolve_launcher_entry();

                case:
                    fmt.assertf(false, "This attribute[%v] should have been resolved; Internal error", attr.attr_type);
            }
        }
    }
}

/** @brief should check all packages "outisde" the defined package (but also checks whether it is used inside, if yes, should warn) */
resolve_api_call_external :: proc(attr: ^CustomProcAttribute) {
    project := cast(^ProjectContext)context.user_ptr;
    for &pckg in project^.packages {
        if attr^.pckg == &pckg { // does not matter that the call is "external", the function does not have to be used at all BUT it cannot be used inside the package
            debug_assert_ignore(
                !check_proc_usage(&pckg, attr^.decl_spec.proc_decl.derived_expr), 
                "Failed to resolve api call external for: %v\n", attr,
            );
            attr^.resolved = true;
            return;
        }
        for &subpackage in pckg.subpackages {
            if attr^.pckg == &subpackage {
                debug_assert_ignore(
                    !check_proc_usage(&subpackage, attr^.decl_spec.proc_decl.derived_expr), 
                    "Failed to resolve api call external for: %v\n", attr,
                );
                attr^.resolved = true;
                return;
            }
        }
    }
    debug_assert_abort(false, "Unexpected error: attribute was not found among packages or their descendats!");
}

resolve_api_call_internal :: proc(attr: ^CustomProcAttribute) {
    project := cast(^ProjectContext)context.user_ptr;
    for &pckg in project^.packages {
        if attr^.pckg != &pckg { // does not matter that the call is "external", the function does not have to be used at all BUT it cannot be used inside the package
            debug_assert_ignore(
                !check_proc_usage(&pckg, attr^.decl_spec.proc_decl.derived_expr), 
                "Failed to resolve api call external for: %v\n", attr,
            );
            attr^.resolved = true;
            return;
        }
        for &subpackage in pckg.subpackages {
            if attr^.pckg != &subpackage {
                debug_assert_ignore(
                    !check_proc_usage(&subpackage, attr^.decl_spec.proc_decl.derived_expr), 
                    "Failed to resolve api call external for: %v\n", attr,
                );
                attr^.resolved = true;
                return;
            }
        }
    }
    debug_assert_abort(false, "Unexpected error: attribute was not found among packages or their descendats!");
}

/** @brief checks usage of certain procedure in a package */
check_proc_usage_folder :: proc(pckg: ^PackageContext, expr: ast.Any_Expr) -> bool {
    for file in pckg^.files {
        fmt.printf("Expression to get proc_name from: %v\n", expr);
        if check_proc_usage(file.src, "") do return true;
    }
    for &subpackage in pckg^.subpackages {
        if check_proc_usage_folder(&subpackage, expr) do return true;
    }
    return false;
}

//todo: more optimal way of doing this!!
/** @brief checks usage of certain procedure in a file */
check_proc_usage_file :: #force_inline proc(file_src: string, proc_name: string) -> bool {
    return strings.contains(file_src, proc_name);
} 

check_proc_usage :: proc { check_proc_usage_file, check_proc_usage_folder }

resolve_app_entry :: proc() {
    project := cast(^ProjectContext)context.user_ptr;

    // first ensure that the app entry is located inside the demo package
    debug_assert_cleanup(project^.packages[.DEMO].location == project^.app_entry.pckg^.location, "App entry is not located inside the same package as the demo!");
}

resolve_launcher_entry :: proc() {
    assert(false, "TODO");
}

revert_changes :: proc() {
    project := cast(^ProjectContext)context.user_ptr;

    fmt.println("Reverting changes now...");
    _revert_change :: proc(pckg: ^PackageContext) {
        handle: os.Handle;
        err: os.Errno;

        for file in pckg.files {
            if len(file.src) > 0 {
                // open a file for read/write
                handle, err = os.open(file.location, os.O_WRONLY);
                //TODO: fix on erroring (backup ???)
                fmt.assertf(err == os.ERROR_NONE, "Dip shit this is...\bFailed to open file! [Err: %v]\n", err);
                //TODO: fix on erroring (backup ???)
                write_len: int;
                write_len, err = os.write_string(handle, file.src);
                fmt.printf("%v\n", err);
                fmt.printf("%v\n", write_len);
                assert(write_len == len(file.src) && err == os.ERROR_NONE);
                //TODO: fix on erroring (backup ???)
                assert(os.close(handle) == os.ERROR_NONE);
                delete_string(file.src);
                delete_string(file.location);
            }
        }
        for &subpackage in pckg^.subpackages do _revert_change(&subpackage);
        dump_package(pckg);
    }

    for &pckg in project^.packages do _revert_change(&pckg);
    dump_project(project);
}

//>>>NOTE: DELETE ON RELEASE
@(private)
find_correct_node :: proc(value: ast.Any_Node) {
    switch v in value {
        case ^ast.Package:
            fmt.printf("Package: %v", v);
        case ^ast.File:
            fmt.printf("File: %v", v);
        case ^ast.Comment_Group:
            fmt.printf("Comment group: %v", v);
        case ^ast.Bad_Expr:
            fmt.printf("Bad expression: %v", v);
        case ^ast.Ident:
            fmt.printf("Ident: %v", v);
        case ^ast.Implicit:
            fmt.printf("Implicit: %v", v);
        case ^ast.Undef:
            fmt.printf("Undef: %v", v);
        case ^ast.Basic_Lit:
            fmt.printf("Basic Lit: %v", v);
        case ^ast.Basic_Directive:
            fmt.printf("Basic directive: %v", v);
        case ^ast.Ellipsis:
            fmt.printf("Ellipsis: %v", v);
        case ^ast.Proc_Lit:
            fmt.printf("Proc_Lit: %v", v);
        case ^ast.Comp_Lit:
            fmt.printf("Comp_Lit: %v", v);
        case ^ast.Tag_Expr:
            fmt.printf("Tag_Expr: %v", v);
        case ^ast.Unary_Expr:
            fmt.printf("Unary_Expr: %v", v);
        case ^ast.Binary_Expr:
            fmt.printf("Binary_Expr: %v", v);
        case ^ast.Paren_Expr:
            fmt.printf("Paren_Expr: %v", v);
        case ^ast.Selector_Expr:
            fmt.printf("Selector_Expr: %v", v);
        case ^ast.Implicit_Selector_Expr:
            fmt.printf("Implicit_Selector_Expr: %v", v);
        case ^ast.Selector_Call_Expr:
            fmt.printf("Selector_Call_Expr: %v", v);
        case ^ast.Index_Expr:
            fmt.printf("Index_Expr: %v", v);
        case ^ast.Deref_Expr:
            fmt.printf("Deref_Expr: %v", v);
        case ^ast.Slice_Expr:
            fmt.printf("Slice_Expr: %v", v);
        case ^ast.Matrix_Index_Expr:
            fmt.printf("Matrix_Index_Expr: %v", v);
        case ^ast.Call_Expr:
            fmt.printf("Call_Expr: %v", v);
        case ^ast.Field_Value:
            fmt.printf("Field_Value: %v", v);
        case ^ast.Ternary_If_Expr:
            fmt.printf("Ternary_If_Expr: %v", v);
        case ^ast.Ternary_When_Expr:
            fmt.printf("Ternary_When_Expr: %v", v);
        case ^ast.Or_Else_Expr:
            fmt.printf("Or_Else_Expr: %v", v);
        case ^ast.Or_Return_Expr:
            fmt.printf("Or_Return_Expr: %v", v);
        case ^ast.Or_Branch_Expr:
            fmt.printf("Or_Branch_Expr: %v", v);
        case ^ast.Type_Assertion:
            fmt.printf("Type_Assertion: %v", v);
        case ^ast.Type_Cast:
            fmt.printf("Type_Cast: %v", v);
        case ^ast.Auto_Cast:
            fmt.printf("Auto_Cast: %v", v);
        case ^ast.Inline_Asm_Expr:
            fmt.printf("Inline_Asm_Expr: %v", v);
        case ^ast.Proc_Group:
            fmt.printf("Proc_Group: %v", v);
        case ^ast.Typeid_Type:
            fmt.printf("Typeid_Type: %v", v);
        case ^ast.Helper_Type:
            fmt.printf("Helper_Type: %v", v);
        case ^ast.Distinct_Type:
            fmt.printf("Distinct_Type: %v", v);
        case ^ast.Poly_Type:
            fmt.printf("Poly_Type: %v", v);
        case ^ast.Proc_Type:
            fmt.printf("Proc_Type: %v", v);
        case ^ast.Pointer_Type:
            fmt.printf("Pointer_Type: %v", v);
        case ^ast.Multi_Pointer_Type:
            fmt.printf("Multi_Pointer_Type: %v", v);
        case ^ast.Array_Type:
            fmt.printf("Array_Type: %v", v);
        case ^ast.Dynamic_Array_Type:
            fmt.printf("Dynamic_Array_Type: %v", v);
        case ^ast.Struct_Type:
            fmt.printf("Struct_Type: %v", v);
        case ^ast.Union_Type:
            fmt.printf("Union_Type: %v", v);
        case ^ast.Enum_Type:
            fmt.printf("Enum_Type: %v", v);
        case ^ast.Bit_Set_Type:
            fmt.printf("Bit_Set_Type: %v", v);
        case ^ast.Map_Type:
            fmt.printf("Map_Type: %v", v);
        case ^ast.Relative_Type:
            fmt.printf("Relative_Type: %v", v);
        case ^ast.Matrix_Type:
            fmt.printf("Matrix_Type: %v", v);
        case ^ast.Bad_Stmt:
            fmt.printf("Bad_Stmt: %v", v);
        case ^ast.Empty_Stmt:
            fmt.printf("Empty_Stmt: %v", v);
        case ^ast.Expr_Stmt:
            fmt.printf("Expr_Stmt: %v", v);
        case ^ast.Tag_Stmt:
            fmt.printf("Tag_Stmt: %v", v);
        case ^ast.Assign_Stmt:
            fmt.printf("Assign_Stmt: %v", v);
        case ^ast.Block_Stmt:
            fmt.printf("Block_Stmt: %v", v);
        case ^ast.If_Stmt:
            fmt.printf("If_Stmt: %v", v);
        case ^ast.When_Stmt:
            fmt.printf("When_Stmt: %v", v);
        case ^ast.Return_Stmt:
            fmt.printf("Return_Stmt: %v", v);
        case ^ast.Defer_Stmt:
            fmt.printf("Defer_Stmt: %v", v);
        case ^ast.For_Stmt:
            fmt.printf("For_Stmt: %v", v);
        case ^ast.Range_Stmt:
            fmt.printf("Range_Stmt: %v", v);
        case ^ast.Inline_Range_Stmt:
            fmt.printf("Inline_Range_Stmt: %v", v);
        case ^ast.Case_Clause:
            fmt.printf("Case_Clause: %v", v);
        case ^ast.Switch_Stmt:
            fmt.printf("Switch_Stmt: %v", v);
        case ^ast.Type_Switch_Stmt:
            fmt.printf("Type_Switch_Stmt: %v", v);
        case ^ast.Branch_Stmt:
            fmt.printf("Branch_Stmt: %v", v);
        case ^ast.Using_Stmt:
            fmt.printf("Using_Stmt: %v", v);
        case ^ast.Bad_Decl:
            fmt.printf("Bad_Decl: %v", v);
        case ^ast.Value_Decl:
            fmt.printf("Value_Decl: %v", v);
        case ^ast.Package_Decl:
            fmt.printf("Package Decl: %v", v);
        case ^ast.Import_Decl:
            fmt.printf("Import Decl: %v", v);
        case ^ast.Foreign_Block_Decl:
            fmt.printf("Foreign block decl: %v", v);
        case ^ast.Foreign_Import_Decl:
            fmt.printf("Foreign import decl: %v", v);
        case ^ast.Attribute:
            fmt.printf("Attribute: %v", v);
        case ^ast.Field:
            fmt.printf("Field: %v", v);
        case ^ast.Field_List:
            fmt.printf("Field list: %v", v);
        // case ^ast.Bit_Field_Type:
        //     fmt.printf("%v\n", v);
        // case ^ast.Bit_Field_Field:
        //     fmt.printf("%v\n", v);
    }
}

find_correct_expr :: proc(value: ast.Any_Expr) {
    switch v in value {
        case ^ast.Bad_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Ident:
            fmt.printf("%v\n", v);
        case ^ast.Implicit:
            fmt.printf("%v\n", v);
        case ^ast.Undef:
            fmt.printf("%v\n", v);
        case ^ast.Basic_Lit:
            fmt.printf("%v\n", v);
        case ^ast.Basic_Directive:
            fmt.printf("%v\n", v);
        case ^ast.Ellipsis:
            fmt.printf("%v\n", v);
        case ^ast.Proc_Lit:
            fmt.printf("%v\n", v);
        case ^ast.Comp_Lit:
            fmt.printf("%v\n", v);
        case ^ast.Tag_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Unary_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Binary_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Paren_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Selector_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Implicit_Selector_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Selector_Call_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Index_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Deref_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Slice_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Matrix_Index_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Call_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Field_Value:
            fmt.printf("%v\n", v);
        case ^ast.Ternary_If_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Ternary_When_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Or_Else_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Or_Return_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Or_Branch_Expr:
            fmt.printf("%v\n", v);
        case ^ast.Type_Assertion:
            fmt.printf("%v\n", v);
        case ^ast.Type_Cast:
            fmt.printf("%v\n", v);
        case ^ast.Auto_Cast:
            fmt.printf("%v\n", v);
        case ^ast.Inline_Asm_Expr:
            fmt.printf("%v\n", v);

        case ^ast.Proc_Group:
            fmt.printf("%v\n", v);

        case ^ast.Typeid_Type:
            fmt.printf("%v\n", v);
        case ^ast.Helper_Type:
            fmt.printf("%v\n", v);
        case ^ast.Distinct_Type:
            fmt.printf("%v\n", v);
        case ^ast.Poly_Type:
            fmt.printf("%v\n", v);
        case ^ast.Proc_Type:
            fmt.printf("%v\n", v);
        case ^ast.Pointer_Type:
            fmt.printf("%v\n", v);
        case ^ast.Multi_Pointer_Type:
            fmt.printf("%v\n", v);
        case ^ast.Array_Type:
            fmt.printf("%v\n", v);
        case ^ast.Dynamic_Array_Type:
            fmt.printf("%v\n", v);
        case ^ast.Struct_Type:
            fmt.printf("%v\n", v);
        case ^ast.Union_Type:
            fmt.printf("%v\n", v);
        case ^ast.Enum_Type:
            fmt.printf("%v\n", v);
        case ^ast.Bit_Set_Type:
            fmt.printf("%v\n", v);
        case ^ast.Map_Type:
            fmt.printf("%v\n", v);
        case ^ast.Relative_Type:
            fmt.printf("%v\n", v);
        case ^ast.Matrix_Type:
            fmt.printf("%v\n", v);
        // case ^ast.Bit_Field_Type:
        //     fmt.printf("%v\n", v);
    }
}
