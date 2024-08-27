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
/**
 * @brief procedure to get the name of the function
 * @note this should be only temporary solution (should fix the deletion of ast.src on 'check_file' exit)
 */
get_proc_name_no_handle :: proc(attr: ^CustomProcAttribute) -> string {
    project := cast(^ProjectContext)context.user_ptr;
    // open the file where the original procedure declaration resides in
    handle, err := os.open(attr^.location, os.O_RDONLY);
    defer {
        err = os.close(handle);
        fmt_proc_new(&project^.formatter);
        massert_cleanup(err == os.ERROR_NONE, "Failed to close the file; file close err: %v\n", err);
    }
    fmt_proc_new(&project^.formatter);
    massert_cleanup(err == os.ERROR_NONE, "Failed to open the file; file open err: %v\n", err);
    // allocate (slightly larger) buffer for the name of the procedure
    body_offset := attr^.decl_spec.proc_decl.body.pos.offset;
    proc_offset := attr^.decl_spec.proc_decl.pos.offset - attr^.decl_spec.proc_decl.pos.column + 1;
    file_buffer := make([]byte, body_offset - proc_offset);
    defer delete(file_buffer);
    read: int;
    // read the file at the offset - should be the procedure declaration
    read, err = os.read_at(handle, file_buffer[:], cast(i64)proc_offset);
    fmt_proc_new(&project^.formatter);
    massert_cleanup(err == os.ERROR_NONE && read == body_offset - proc_offset, "Failed to read file!; file read err: %v\n", err);
    // get the index where the name ends
    proc_name_end_index := strings.index_any(string(file_buffer), "::") - 1;
    fmt_proc_new(&project^.formatter);
    massert_cleanup(
        proc_name_end_index != -1,
        "Failed to determine the name of the procedure!\n\tTried at line: %v;\n\tTried with string: %v;\n\tAttribute: %s\n",
        attr^.decl_spec.proc_decl.pos.line,
        string(file_buffer),
        project.formatter->Proc_AttributeLocation(attr^.decl_spec.attribute)->Proc_DeclLocation(attr^.decl_spec.proc_decl)->Build(),
    );
    // strip the end of the name (if it contains a space e.g. ' ::')
    for file_buffer[proc_name_end_index] == ' ' do proc_name_end_index -= 1;
    return strings.clone_from(file_buffer[:proc_name_end_index + 1]);
}

/** @brief call this function to get a name of a procedure out of attribute when you already have the source file */
get_proc_name_src :: #force_inline proc(attr: ^CustomProcAttribute, src: string) -> string {
    project := cast(^ProjectContext)context.user_ptr;
    proc_name_line := src[attr^.decl_spec.proc_decl.pos.offset - attr^.decl_spec.proc_decl.pos.column + 1 : attr^.decl_spec.proc_decl.body.pos.offset];
    // get the index where the name ends
    proc_name_end_index := strings.index_any(proc_name_line, "::") - 1;
    when ODIN_DEBUG {
        fmt_proc_new(&project^.formatter);
        massert_cleanup(
            proc_name_end_index != -1,
            "Failed to determine the name of the procedure!\n\tTried at line: %v;\n\tTried with string: %v;\n\tAttribute: %s\n",
            attr^.decl_spec.proc_decl.pos.line,
            proc_name_line,
            project.formatter->Proc_AttributeLocation(attr^.decl_spec.attribute)->Proc_DeclLocation(attr^.decl_spec.proc_decl)->Build(),
        );
    } else {
    }
    // strip the end of the name (if it contains a space e.g. ' ::')
    for proc_name_line[proc_name_end_index] == ' ' do proc_name_end_index -= 1;
    return strings.clone_from(proc_name_line[:proc_name_end_index + 1]);
}

get_proc_name :: proc { get_proc_name_no_handle, get_proc_name_src }

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
    src: string "NexaTag_Marshallable",
    location: string "NexaTag_Marshallable",
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

dump_string_s :: #force_inline proc(str: string) {
    if len(str) > 0 do delete_string(str);
}

dump_package :: proc(using pckg: ^PackageContext) {
    fmt.printf("\t[DUMP PACKAGE]\n");
    defer fmt.printf("\t\x1b[33m[DUMP PACKAGE]: Success\x1b[0m\n");
    // delete cloned location
    dump_string_s(location);
    // delete cloned files
    for file in files {
        dump_string_s(file.src);
        dump_string_s(file.location);
    }
    delete(files);
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
    fmt.printf("[DUMP PROJECT]\n");
    defer fmt.printf("\x1b[33m[DUMP PROJECT]: Success\x1b[0m\n");
    for &pckg in project^.packages do dump_package(&pckg);
    delete(project^.tags);
    delete(project^.attributes);
    fmt_proc_dump(&project^.formatter);
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
    fmt.printf("Checking folder [NEXA_CORE]: %s\n", core_dir);
    check_nexa_core(core_dir, &project.packages[.CORE]);
    fmt.printf("Checking folder [EXTERNAL_UTILS]: %s\n", external_dir);
    check_external_utils(external_dir, &project.packages[.EXTERNAL]);
    fmt.printf("Checking folder [DEMO]: %s\n", demo_dir);
    check_demo(demo_dir, &project.packages[.DEMO]);
    // some attributes / tags can be only defined once we have parsed everything
    collapse_unresolved();
    // save the backup
    save_backup();
}

check_project_dir :: #force_inline proc(dir: string, pckg: ^PackageContext) {
    info, err := os.lstat(dir);
    massert_cleanup(err == os.ERROR_NONE, "Internal meta error: Failed to gather info for project directory; Os error: %v\n", err);
    // defer os.file_info_delete(info);
    check_folder(info, pckg);
}

check_nexa_core      :: check_project_dir;
check_external_utils :: check_project_dir;
check_demo           :: check_project_dir;

read_dir :: proc(dir_name: string) -> []os.File_Info {
	handle, err := os.open(dir_name, os.O_RDONLY);
    project := cast(^ProjectContext)context.user_ptr;
	massert_cleanup(err == os.ERROR_NONE, "Failed to open directory[%s]! Err: %v", dir_name, err);
	defer os.close(handle);
	file_infos: []os.File_Info;
	file_infos, err = os.read_dir(handle, -1);
	massert_cleanup(err == os.ERROR_NONE, "Failed to read directory[%s]! Err: %v", dir_name, err);
	return file_infos;
}

check_folder :: proc(folder_info: os.File_Info, pckg: ^PackageContext) {

    massert_cleanup(folder_info.is_dir == true, "Internal meta error: Expected a package/directory; found: %v", folder_info);
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
        pckg.active_file^.location = strings.clone(file_info.fullpath);
        if file_info.is_dir {
            append(&pckg.subpackages, init_package(file_info.fullpath));
            check_folder(file_info, &pckg.subpackages[len(pckg.subpackages) - 1]);
        }
        else {
            handle, err = os.open(file_info.fullpath, os.O_RDONLY);
            massert_cleanup(err == os.ERROR_NONE, "Failed to read file[%s]! Err: %v\n", file_info.fullpath, err);
            reader = os.stream_from_handle(handle);

            file_buffer = make([]u8, file_info.size);
            l, e := io.read_full(reader, file_buffer[:]);
            os.close(handle);
            massert_cleanup(l == len(file_buffer) && e == .None, "Failed to read buffer! Error: %v; Lengths: %d :: %d", e, l, len(file_buffer));
            ast_file = ast.File{
                src = string(file_buffer),
                fullpath = pckg.active_file^.location,
            };

            massert_cleanup(
                parser.parse_file(&p, &ast_file),
                "Failed to parse file[%s]! Err count: %d\n",
                file_info.fullpath, p.error_count,
            );
            check_file(&p, &ast_file, pckg);
            delete(file_buffer); // NOTE: this is wrong, because in some cases we need to be able to access the expressions' tokenizer strings which are only shallow copied from this exact buffer...
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
                    massert_abort(ok, "Internal meta error: This call should always pass...");
                    _internal_iterate_decls(p, body_block.stmts, ast_file, pckg);
                    if d.else_stmt != nil {
                        body_block, ok  = d.else_stmt.derived_stmt.(^ast.Block_Stmt);
                        massert_abort(ok, "Internal meta error: This call should always pass...");
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

        formatter := &(cast(^ProjectContext)context.user_ptr)^.formatter;
        fmt_proc_new(formatter);
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
                    massert_ignore(
                        false,
                        "Invalid type of 'APICall' specifier provided!\nExpected [internal] or [external], but received [%s]!\nDecl: %v\n",
                        lit.tok.text, formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Proc_Field(field_value)->Build(),
                    );
                }
            case:
                massert_ignore(
                    false,
                    "Found unknown attribute! Decl: %v\n",
                    formatter->Proc_AttributeLocation(decl_spec.attribute)->Proc_DeclLocation(decl_spec.proc_decl)->Proc_Field(field_value)->Build(),
                );
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
                    fmt_proc_new(&project^.formatter);
                    massert_cleanup(
                        false,
                        "Internal meta error: The attribute[%v] should have been resolved\nDecl: %v\n",
                        attr.attr_type, project^.formatter->Proc_AttributeLocation(attr.decl_spec.attribute)->Proc_DeclLocation(attr.decl_spec.proc_decl)->Build(),
                    );
            }
        }
    }
}

/** @brief should check all packages "outisde" the defined package (but also checks whether it is used inside, if yes, should warn) */
resolve_api_call_external :: proc(attr: ^CustomProcAttribute) {
    project := cast(^ProjectContext)context.user_ptr;
    proc_name: string = get_proc_name(attr);
    defer delete_string(proc_name);
    for &pckg in project^.packages {
        if attr^.pckg == &pckg { // does not matter that the call is "external", the function does not have to be used at all BUT it cannot be used inside the package
            massert_ignore(
                !check_proc_usage(
                    &pckg,
                    ProcUsage_Descriptor {
                        attr^.decl_spec.proc_decl.derived_expr,
                        attr^.location,
                        proc_name,
                    },
                    false
                ), 
                "Failed to resolve api call external for: %v\n", attr,
            );
            attr^.resolved = true;
            return;
        }
        for &subpackage in pckg.subpackages {
            if attr^.pckg == &subpackage {
                massert_ignore(
                    !check_proc_usage(
                        &subpackage,
                        ProcUsage_Descriptor {
                            attr^.decl_spec.proc_decl.derived_expr,
                            attr^.location,
                            proc_name,
                        },
                        false,
                    ), 
                    "Failed to resolve api call external for: %v\n", attr,
                );
                attr^.resolved = true;
                return;
            }
        }
    }
    massert_abort(false, "Unexpected error: attribute was not found among packages or their descendats!");
}

resolve_api_call_internal :: proc(attr: ^CustomProcAttribute) {
    project := cast(^ProjectContext)context.user_ptr;
    proc_name: string = get_proc_name(attr);
    defer delete_string(proc_name);
    for &pckg in project^.packages {
        if attr^.pckg != &pckg { // does not matter that the call is "external", the function does not have to be used at all BUT it cannot be used inside the package
            massert_ignore(
                !check_proc_usage(
                    &pckg,
                    ProcUsage_Descriptor {
                        attr^.decl_spec.proc_decl.derived_expr,
                        attr^.location,
                        proc_name,
                    }, 
                    true,
                ), 
                "Failed to resolve api call external for: %v\n", attr,
            );
        }
        for &subpackage in pckg.subpackages {
            if attr^.pckg != &subpackage {
                massert_ignore(
                    !check_proc_usage(
                        &pckg,
                        ProcUsage_Descriptor {
                            attr^.decl_spec.proc_decl.derived_expr,
                            attr^.location,
                            proc_name,
                        }, 
                        true,
                    ), 
                    "Failed to resolve api call external for: %v\n", attr,
                );
            }
        }
    }
    // it is fine utils this point 'cause not asserts were given, call is not located outside its package
}

/** @brief struct to handle common properties needed for the 'check_proc_usage_folder' proc */
ProcUsage_Descriptor :: struct {
    expr: ast.Any_Expr,
    origin_file: string,
    proc_name: string,
}
/** @brief checks usage of certain procedure in a package */
check_proc_usage_folder :: proc(pckg: ^PackageContext, using desc: ProcUsage_Descriptor, $is_internal: bool) -> bool {
    for file in pckg^.files {
        if origin_file == file.location && is_internal do continue;
        if check_proc_usage(file.src, proc_name) do return true;
    }
    for &subpackage in pckg^.subpackages {
        if check_proc_usage_folder(&subpackage, desc, is_internal) do return true;
    }
    return false;
}

/** @brief checks usage of certain procedure in a file */
check_proc_usage_file :: #force_inline proc(file_src: string, proc_name: string) -> bool {
    ast_file := ast.File{
        src = file_src,
    };

    p := parser.default_parser();
    if parser.parse_file(&p, &ast_file) != true {
        massert_cleanup(false, "Failed to parse file!\nErr count: %d\n", p.error_count);
    }

    _visit :: proc(visitor: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
        //fmt.printf("%v :: %v\n", visitor, node);
        if visitor == nil || node == nil do return nil;
        call_expr, ok := node^.derived.(^ast.Call_Expr);
        if ok {
            // check if the call is that of proc_name
            selector: ^ast.Selector_Expr;
            ident: ^ast.Ident;
            selector, ok = call_expr.expr.derived_expr.(^ast.Selector_Expr);
            if ok do ident = selector.field;
            else do ident, _ = call_expr.expr.derived_expr.(^ast.Ident);

            visitor_data := cast(^VisitorData)visitor^.data;
            fmt.println();
            if ident.name == visitor_data^.proc_name {
                visitor_data^.found = true;
                return nil;
            }
        }
        return visitor;
    }
    VisitorData :: struct {
        proc_name: string,
        found: bool,
    }
    visitor_data := VisitorData {
        proc_name,
        false,
    };
    visitor := ast.Visitor {
        visit = _visit,
        data = &visitor_data,
    };
    for &decl in ast_file.decls {
        ast.walk(&visitor, &decl.stmt_base);
        if visitor_data.found == true do return true;
    }
    return false;
} 

check_proc_usage :: proc { check_proc_usage_file, check_proc_usage_folder }

resolve_app_entry :: #force_inline proc() {
    resolve_entry(.APPLICATION_ENTRY);
}
resolve_launcher_entry :: #force_inline proc() {
    resolve_entry(.LAUNCHER_ENTRY);
}
resolve_entry :: proc(entry_type: CustomProcAttributeType) {
    project := cast(^ProjectContext)context.user_ptr;
    entry: ^CustomProcAttribute;
    if entry_type == .APPLICATION_ENTRY do entry = project^.app_entry;
    else if entry_type == .LAUNCHER_ENTRY do entry = project^.launcher_entry;

    // first ensure that the app entry is located inside the demo package
    massert_cleanup(
        project^.packages[.DEMO].location == entry.pckg^.location,
        "Entry[%v] is not located inside the same package as the demo!",
        entry_type,
    );

    _assert :: #force_inline proc(err: os.Errno, entry: ^CustomProcAttribute) {
        formatter := &(cast(^ProjectContext)context.user_ptr)^.formatter;
        fmt_proc_new(formatter);
        massert_cleanup(
            err == os.ERROR_NONE,
            "Failed to manipulate with file in which attribute: %v\n resides in.\nFile error: %v\n",
            formatter->Proc_AttributeLocation(entry^.decl_spec.attribute)->Build(),
            err,
        );
    }
    /** @brief since there is a lot of redundant code but at the same time want to remain efficient, if 'main' proc is found in a file, this struct will be populated with the already computed data */
    ContainsMain_Params :: struct {
        handle: os.Handle,
        ast_file: ast.File,
        main_decl: ^ast.Proc_Lit,
        entry: ^CustomProcAttribute,
    }
    // secondly, ensure that there is a 'main' function in the DEMO package
    _contains_main_decl :: proc(location: string, using params: ^ContainsMain_Params) -> bool {
        err: os.Errno;
        handle, err = os.open(location, os.O_RDWR);
        _assert(err, entry);
        size: i64;
        size, err = os.file_size(handle);
        _assert(err, entry);
        file_buffer := make([]byte, size);
        read_len: int;
        read_len, err = os.read_full(handle, file_buffer);
        massert_cleanup(size == cast(i64)read_len, "failed to read the whole file!");
        _assert(err, entry);
        ast_file = ast.File {
            src = string(file_buffer),
            fullpath = location,
        };
        p := parser.default_parser();
        massert_cleanup(
            parser.parse_file(&p, &ast_file),
            "Failed to parse file!\nErr count: %d\n", p.error_count
        );
        // check for main function
        _visit :: proc(visitor: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
            if visitor == nil || node == nil do return nil;
            proc_lit, ok := node^.derived.(^ast.Proc_Lit);
            if ok {
                proc_offset := proc_lit^.pos.offset - proc_lit^.pos.column + 1;
                visitor_data := cast(^VisitorData)visitor^.data;
                i := proc_offset;
                for ; visitor_data^.src[i] != ':' && visitor_data^.src[i + 1] != ':'; i += 1 do continue;
                i -= 1;
                for visitor_data^.src[i] == ' ' do i -= 1;
                i += 1;
                when ODIN_DEBUG do fmt.printf("Checking proc for entry: %v\n", string(visitor_data^.src[proc_offset : i]));
                if string(visitor_data^.src[proc_offset : i]) == "main" {
                    visitor_data^.found = true;
                    visitor_data^.decl^ = proc_lit;
                    return nil;
                }
            }
            return visitor;
        }
        VisitorData :: struct {
            src: string,
            found: bool,
            decl: ^^ast.Proc_Lit,
        }
        visitor_data := VisitorData {
            src = string(file_buffer),
            found = false,
            decl = &main_decl,
        };
        visitor := ast.Visitor {
            visit = _visit,
            data = &visitor_data,
        };
        for &decl in ast_file.decls {
            ast.walk(&visitor, &decl.stmt_base);
            if visitor_data.found == true do return true;
        }
        delete(file_buffer);
        return false;
    }
    _check_main :: proc(pckg: ^PackageContext, params: ^ContainsMain_Params) -> bool {
        for file in pckg^.files {
            if _contains_main_decl(file.location, params) do return true;
        }
        for subpackage in pckg^.subpackages {
            for file in subpackage.files {
                if _contains_main_decl(file.location, params) do return true;
            }
        }
        return false;
    }

    // check whether 'main' procedure and app_entry are located inside the same folder (should be expected but not mandatory...)
    contains := ContainsMain_Params{};
    contains.entry = entry;
    FMT_APPLICATION_ENTRY   :: "core.extern_main = %s;\n";
    FMT_LAUNCHER_ENTRY      :: "core.extern_launch = %s;\n";
    _write_anew :: proc(
        contains: ContainsMain_Params,
        proc_name: string,
        entry: ^CustomProcAttribute,
    ) {
        defer {
            delete_string(contains.ast_file.src);
            delete_string(proc_name);
            err := os.close(contains.handle);
            _assert(err, entry);
        }
        main_block, _ := contains.main_decl^.body.derived.(^ast.Block_Stmt); 
        main_proc_decl_begin := main_block.open.offset;
        _ = os.ftruncate(contains.handle, 0);
        _, _ = os.seek(contains.handle, 0, 0);
        writer := os.stream_from_handle(contains.handle);
        io.write_string(
            writer,
            contains.ast_file.src[:main_proc_decl_begin + 1],
        );
        io.write_string(
            writer,
            fmt.tprintf(
                entry^.attr_type == .APPLICATION_ENTRY ? FMT_APPLICATION_ENTRY : FMT_LAUNCHER_ENTRY,
                proc_name,
            ),
        );
        io.write_string(
            writer,
            contains.ast_file.src[main_proc_decl_begin + 1:],
        )
    }
    if _contains_main_decl(entry^.location, &contains) {
        _write_anew(contains, get_proc_name(entry, contains.ast_file.src), entry);
        return;
    }
    if _check_main(&project^.packages[.DEMO], &contains) {
        _write_anew(contains, get_proc_name(entry), entry);
        return;
    }

    massert_cleanup(
        false,
        "Failed to locate 'main' function in 'DEMO' directory (%s)\n",
        project^.packages[.DEMO].location,
    );
}

revert_changes_in_program :: proc() {
    project := cast(^ProjectContext)context.user_ptr;

    fmt.println("Reverting changes now...");
    _revert_change :: proc(pckg: ^PackageContext) {
        for file in pckg.files {
            if len(file.src) > 0 do revert_changes_file(file);
        }
    }

    for &pckg in project^.packages do _revert_change(&pckg);
    dump_project(project);
}

revert_changes_file :: proc(file: PackageFile) {
    handle: os.Handle;
    err: os.Errno;

    // open a file for read/write
    handle, err = os.open(file.location, os.O_WRONLY);
    massert_cleanup(err == os.ERROR_NONE, "Internal meta error: Failed to open file[%s]; Os error: %d\n", file.location, err);
    os.ftruncate(handle, 0);
    write_len: int;
    write_len, err = os.write_string(handle, file.src);
    massert_cleanup(
        write_len == len(file.src) && err == os.ERROR_NONE, 
        "Internal meta error: Failed to write the file buffer of expected size! Os error: %d; Lengths: %v[Expected] :: %v[Written]\n",
        err, len(file.src), write_len,
    );
    err = os.close(handle);
    massert_cleanup(
        err == os.ERROR_NONE,
        "Internal meta error: Failed to close file; Os error: %d\n",
        err,
    );
}

/*
* ================================
*          ProjectBackup
* ================================
*/

import marshall "nexa_external:binary/marshall"

Backup :: []PackageFile;
BACKUP_FILENAME :: "project-backup.txt";

revert_changes :: proc(backup: Backup) {
    for file in backup {
        revert_changes_file(file);
    }
}

/**
 * @brief loads the backup (in this sense loads & writes into the project again)
 */
load_backup :: proc() {
    backup, err := marshall.marshall_read(Backup, BACKUP_FILENAME);
    for b in backup do fmt.printf("BACKUP [%s]:\n%s\n", b.location, b.src);
    massert_abort(err == .None, "Failed to load backup! Marshall err: %v", err);
    revert_changes(backup);
}

/**
 * @brief saves the files that were overwritten by meta into a single file
 */
save_backup :: proc() {
    project := cast(^ProjectContext)context.user_ptr;

    fmt.println("Saving backup...");
    _register_file :: #force_inline proc(pckg: ^PackageContext, files_to_backup: ^[dynamic]PackageFile) {
        for file in pckg^.files {
            if len(file.src) > 0 do append(files_to_backup, PackageFile {
                location = strings.clone(file.location),
                src = strings.clone(file.src),
            });
        }
    }

    files_to_backup := make([dynamic]PackageFile);
    defer {
        // fmt.printf("\x1b[32mBEFORE WRITE\x1b[0m\n");
        // for b in files_to_backup do fmt.printf("BACKUP [%s]:\n%s\n", b.location, b.src);

        err := marshall.marshall_write(files_to_backup[:], BACKUP_FILENAME);

        // fmt.printf("\x1b[32mAFTER WRITE\x1b[0m\n");
        // for b in files_to_backup do fmt.printf("BACKUP [%s]:\n%s\n", b.location, b.src);

        for f in files_to_backup {
            delete_string(f.location);
            delete_string(f.src);
        }
        delete(files_to_backup);
        if err != .None {
            revert_changes_in_program();
            massert_abort(false, "Failed to save the original files into backup!\nReverting changes now...");
        }
    }

    for &pckg in project^.packages do _register_file(&pckg, &files_to_backup);
    dump_project(project);
}