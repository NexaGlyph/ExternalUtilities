//+build windows
package meta

import "core:fmt"
import "core:strings"
import "core:os"
import "core:io"
import "core:path/filepath"

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
    /** @brief storing the "previous" - tagged struct declaration line (of pos from struct_decl.pos) */
    struct_previous_line_decl: string,
    /** @brief stores type of tag */
    tag_type: CustomStructTagType,
    /** @brief stores pointer to the package to which it belongs to */
    pckg: ^PackageContext,
}

CustomProcAttributeType :: enum {
    API_CALL_INTERNAL = 1,
    API_CALL_EXTERNAL,
    DEBUG_ONLY,
    MAIN_THREAD_ONLY,
    APPLICATION_ENTRY,
    LAUNCHER_ENTRY,
    INLINE,
    CORE_INIT,
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
    /** @brief stores the statement declared by the user, this is going to be used to revert all the modifications of the meta after compilation */
    proc_previous_line_decl: string,
    /** @brief stores the type of the attribute */
    attr_type: CustomProcAttributeType,
    /** @brief contains a pointer to a package which it is defined in */
    pckg: ^PackageContext,
    /** @brief signals if the attribute has been correctly checked in the projects (if not, collapse_unresolved should have it) */
    resolved: bool,
    /** @brief stores the file location */
    location: string,
}

/** @brief contains all the custom tags and attributes from the package */
PackageContext :: struct {
    /** @brief file location of this package */
    location: string,
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
    packages: [3]PackageContext,

    /** @brief points to the precise attribute with the CustomProcAttributeType.APPLICATION_ENTRY */
    app_entry: ^CustomProcAttribute,
    /** @brief pointer to the attribute with the CustomProcAttributeType.LAUNCHER_ENTRY*/
    launcher_entry: ^CustomProcAttribute,
}

init_project :: #force_inline proc(curr_demo_dir, nexa_core_dir, external_dir: string) -> (project: ProjectContext) {
    project.tags = make([dynamic]CustomStructTag);
    project.attributes = make([dynamic]CustomProcAttribute);
    
    project.packages[0] = init_package(curr_demo_dir);
    project.packages[1] = init_package(nexa_core_dir);
    project.packages[2] = init_package(external_dir);

    project.app_entry = nil;
    project.launcher_entry = nil;
    return;
}

dump_project :: #force_inline proc(project: ^ProjectContext) {
    for &pckg in project^.packages do dump_package(&pckg);
    delete(project^.tags);
    delete(project^.attributes);
}

append_attribute :: #force_inline proc(project: ^ProjectContext) -> ^CustomProcAttribute {
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
check_nexa_project :: proc(curr_demo_dir, nexa_core_dir, external_dir: string) {
    project := init_project(curr_demo_dir, nexa_core_dir, external_dir);
    defer dump_project(&project);
    fmt.printf("Checking folder [NEXA_CORE]: %s\n", nexa_core_dir);
    check_nexa_core(nexa_core_dir, &project);
    fmt.printf("Checking folder [EXTERNAL_UTILS]: %s\n", external_dir);
    check_external_utils(external_dir, &project);
    fmt.printf("Checking folder [DEMO]: %s\n", curr_demo_dir);
    check_demo(curr_demo_dir, &project);
    // some attributes / tags can be only defined once we have parsed everything
    collapse_unresolved(&project);
}

check_project_dir :: #force_inline proc(dir: string, project: ^ProjectContext) -> PackageContext {
    info, err := os.lstat(dir);
    assert(err == os.ERROR_NONE);
    // defer os.file_info_delete(info);
    return check_folder(info, project);
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

check_folder :: proc(folder_info: os.File_Info, project: ^ProjectContext) -> (pckg: PackageContext) {

    assert(folder_info.is_dir == true);
	file_infos := read_dir(folder_info.fullpath);
	defer os.file_info_slice_delete(file_infos);

    p := parser.default_parser();
    ast_file: ast.File;
    handle: os.Handle;
    err: os.Errno;
    reader: io.Reader;
    file_buffer: []u8;

    pckg = init_package("");
    pckg.location = strings.clone(folder_info.fullpath);

    for file_info in file_infos {
        if file_info.is_dir do append(&pckg.subpackages, check_folder(file_info, project));
        else {
            handle, err = os.open(file_info.fullpath, os.O_RDWR);
            defer os.close(handle);
            fmt.assertf(err == os.ERROR_NONE, "Failed to read file(%s)! [Err: %v]\n", file_info.fullpath, err);
            reader = os.stream_from_handle(handle);

            file_buffer = make([]u8, file_info.size);
            l, e := io.read_full(reader, file_buffer[:]);
            fmt.assertf(l == len(file_buffer) && e == .None, "Failed to read buffer! Error: %v; Lengths: %d :: %d", e, l, len(file_buffer));
            ast_file = ast.File{
                src = string(file_buffer),
            };
            ast_file.fullpath = strings.clone(file_info.fullpath); // this file_info.full_path is only temporarily allocated...

            if parser.parse_file(&p, &ast_file) != true {
                fmt.printf("%v\n", p.tok);
                fmt.assertf(false, "Failed to parse file!(%s)\nErr count: %d\n", file_info.fullpath, p.error_count);
            }
            check_file(&p, &ast_file, &pckg, project, os.stream_from_handle(handle));
            delete(file_buffer);
        }
    }

    return pckg;
}

format_debug_info_from_decl_spec_struct :: proc(decl_spec: CustomStructTagDeclSpec) -> string {
    assert(false, "TODO");
    return "";
}
format_debug_info_from_decl_spec_proc :: proc(decl_spec: CustomProcAttributeDeclSpec) -> string {
    assert(false, "TODO");
    return "";
}
format_debug_info_from_decl_spec :: proc { format_debug_info_from_decl_spec_proc, format_debug_info_from_decl_spec_struct, }

check_file :: proc(p: ^parser.Parser, ast_file: ^ast.File, pckg: ^PackageContext, project: ^ProjectContext, writer: io.Writer) {
    for decl in ast_file.decls {
        #partial switch d in decl.derived {
            case ^ast.Value_Decl:
                #partial switch expr in d.values[0].derived_expr {
                    case ^ast.Proc_Lit:
                        check_attributes_proc(d, expr, ast_file, pckg, project, writer);
                    case ^ast.Struct_Type:
                        check_tags_struct(d, expr, ast_file, pckg, project, writer);
                }
        }
    }
}

check_tags_struct :: proc(d: ^ast.Value_Decl, ast_struct: ^ast.Struct_Type, ast_file: ^ast.File, pckg: ^PackageContext, project: ^ProjectContext, writer: io.Writer) {
    return;
}
check_attributes_proc :: proc(d: ^ast.Value_Decl, ast_proc: ^ast.Proc_Lit, ast_file: ^ast.File, pckg: ^PackageContext, project: ^ProjectContext, writer: io.Writer) {
    for attribute in d.attributes {
        expr_loop: for expr in attribute.elems {
            field_value, is_fielded_attr := expr.derived.(^ast.Field_Value);
            // either a special value is specified (e.g. "internal"/"external") or not
            // if not, parse just the Ident
            if !is_fielded_attr {
                check_attributes_proc_non_fielded(expr, CustomProcAttributeDeclSpec{ ast_proc, attribute }, ast_file, pckg, project, writer);
                break expr_loop;
            }
            check_attributes_proc_fielded(field_value, CustomProcAttributeDeclSpec{ ast_proc, attribute }, ast_file, pckg, project, writer);
        }
    }
}
check_attributes_proc_fielded :: proc(field_value: ^ast.Field_Value, decl_spec: CustomProcAttributeDeclSpec, ast_file: ^ast.File, pckg: ^PackageContext, project: ^ProjectContext, writer: io.Writer) {
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
                assert(false, "TODO");
            case:
                // note: maybe should be only warned, not error'd
                assert(false, "Unknown attribute");
        }
    }
}
check_attributes_proc_non_fielded :: proc(expr: ^ast.Expr, decl_spec: CustomProcAttributeDeclSpec, ast_file: ^ast.File, pckg: ^PackageContext, project: ^ProjectContext, writer: io.Writer) {
    ident, ok := expr.derived.(^ast.Ident);
    if !ok do return;
    fmt.printf("Ident name: %s\n", ident.name);
    switch ident.name {
        /**
        * @brief automatically assumes "internal" ident, see NexaAttr_APICall below
        */
        case "NexaAttr_APICall":
            assert(false, "TODO");
        /**
        * @brief this attribute tells meta to treat the proc as only defined in Debug modes (Debug/DebugX)
        */
        case "NexaAttr_DebugOnly":
            assert(false, "TODO");
        /**
        * @brief marks function to be called from application (main) thread
        */
        case "NexaAttr_MainThreadOnly":
            assert(false, "TODO");
        /**
        * @brief unique attribute; defines a function that should be bound to "core.extern_launch"
        */
        case "NexaAttr_LauncherEntry":
            // project^.launcher_entry can be only one, so this block should never be executed once the launcher_entry is populated
            if project^.launcher_entry == nil {
                // set the application entry to the project context
                project^.launcher_entry = append_attribute(project);
                project^.launcher_entry^.decl_spec = decl_spec;
                project^.launcher_entry^.attr_type = .LAUNCHER_ENTRY;
                project^.launcher_entry^.pckg = pckg;
                project^.launcher_entry.resolved = false; // will be resolved once we find the "main" function 
                project^.launcher_entry.location = ast_file^.fullpath;
            } else {
                fmt.assertf(
                    false,
                    "There can be only one procedure with NexaAttr_LauncherEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
                    format_debug_info_from_decl_spec(project^.launcher_entry^.decl_spec),
                    format_debug_info_from_decl_spec(decl_spec),
                );
            }
        /**
        * @brief unique attribute; defines a function that should be bound to "core.extern_main"
        */
        case "NexaAttr_ApplicationEntry":
            // project^.app_entry can be only one, so this block should never be executed once the app_entry is populated
            fmt.printf("\x1b[33m%v\x1b[0m\n", project^.app_entry);
            if project^.app_entry == nil {
                // set the application entry to the project context
                project^.app_entry = append_attribute(project);
                project^.app_entry^.decl_spec = decl_spec;
                project^.app_entry^.attr_type = .APPLICATION_ENTRY;
                project^.app_entry^.pckg = pckg;
                project^.app_entry.resolved = false; // will be resolved once we find the "main" function 
                project^.app_entry.location = ast_file^.fullpath;
            } else {
                fmt.assertf(
                    false,
                    "There can be only one procedure with NexaAttr_ApplicationEntry defined!\nFound this one: [%v]; while previous defined here: [%v]",
                    format_debug_info_from_decl_spec(project^.app_entry^.decl_spec),
                    format_debug_info_from_decl_spec(decl_spec),
                );
            }
        /**
        * @brief marks function to be "inlined" (same as #force_inline)
        */
        case "NexaAttr_Inline":
            assert(false, "TODO");
        /**
            * @brief function that has prohibited access (this can be only done on "NexaAttr_APICall" procs) to NexaContext since this proc is/could be called BEFORE context init
            */
        case "NexaAttr_CoreInit":
            assert(false, "TODO");
        // ignore all others
    }
}

collapse_unresolved :: proc(project: ^ProjectContext) {
    for attr in project^.attributes {
        if !attr.resolved {
            #partial switch attr.attr_type {
                case .APPLICATION_ENTRY:
                    resolve_app_entry(project);
                case .LAUNCHER_ENTRY:
                    resolve_launcher_entry(project);

                case:
                    fmt.assertf(false, "This attribute[%v] should have been resolved; Internal error", attr.attr_type);
            }
        }
    }
}

resolve_app_entry :: proc(project: ^ProjectContext) {
    // first ensure that the app entry is located inside the demo package
    fmt.printf("%s :: %s", project^.packages[0].location, project^.app_entry.pckg^.location);
    if project^.packages[0].location != project^.app_entry.pckg^.location {
        fmt.printf("\x1b[31mERR:\x1b[0m App entry is not located inside the same package as the demo!\n");
        revert_changes(project);
    } else {
        // if it is located, create a main function that will contain the bindings for the app entry function
        fmt.printf("JEEEEEEEEJJ");
    }
}

resolve_launcher_entry :: proc(project: ^ProjectContext) {
    assert(false, "TODO");
}

revert_changes :: proc(project: ^ProjectContext) {
    handle: os.Handle;
    err: os.Errno;
    _len: i64;
    for tag in project^.tags {
        _ = tag;
    }
    for i := 0; i < len(project^.attributes); i += 1 {
        // open a file for read/write
        handle, err = os.open(project^.attributes[i].location, os.O_RDWR);
        //TODO: fix on erroring (backup ???)
        if err != os.ERROR_NONE do fmt.assertf(false, "Dip shit this is...\bFailed to open file! [Err: %v]\n", err);
        _len, err = os.file_size(handle);
        //TODO: fix on erroring (backup ???)
        if err != os.ERROR_NONE do fmt.assertf(false, "Dip shit this is...\nFailed to determine file size! [Err: %v]\n", err);
        file_buffer := make([]u8, _len);
        defer delete(file_buffer);
        read_len: int;
        read_len, err = os.read_full(handle, file_buffer);
        //TODO: fix on erroring (backup ???)
        assert(cast(i64)read_len == _len);
        // scane for all attributes that have the same file location (avoiding redundancy of opening a file)
        for j := i; j < len(project^.attributes); j += 1 {
            if project^.attributes[i].location == project^.attributes[j].location {
                attr := &project^.attributes[j];
                copy_from_string(
                    file_buffer[attr^.decl_spec.proc_decl.pos.offset:attr^.decl_spec.proc_decl.end.offset],
                    attr^.proc_previous_line_decl
                );
            }
        }
        //TODO: fix on erroring (backup ???)
        read_len, err = os.write_string(handle, string(file_buffer));
        assert(read_len == len(file_buffer) && err == os.ERROR_NONE);
        //TODO: fix on erroring (backup ???)
        assert(os.close(handle) == os.ERROR_NONE);
    }
}

check_file_contents :: proc(file_name: string) {
    p := parser.Parser{};
    handle, err := os.open(file_name, os.O_RDONLY);
    if err != os.ERROR_NONE {
        fmt.printf("Failed to read file! [Err: %v]\n", err);
        return;
    }
    _len: i64;
    _len, err = os.file_size(handle);
    if err != os.ERROR_NONE {
        fmt.printf("Failed to determine file size! [Err: %v]\n", err);
        return;
    }
    file_buffer := make([]u8, _len);
    defer delete(file_buffer);
    read_len: int;
    read_len, err = os.read_full(handle, file_buffer);
    assert(os.close(handle) == os.ERROR_NONE);
    assert(cast(i64)read_len == _len);
    if err != os.ERROR_NONE {
        fmt.printf("Failed to read file buffer! [Err: %v]\n", err);
        return;
    }
    ast_file := ast.File{
        src = string(file_buffer),
        fullpath = file_name,
    };
    ok := false;

    if ok = parser.parse_file(&p, &ast_file); !ok {
        fmt.println("Failed to parse file!");
        return;
    }

    // for inlined procs
    proc_inline_indices := make([dynamic]int);
    defer delete(proc_inline_indices);
    // for application entry point
    app_entry := false;
    _ = app_entry;


    prev_len := len(file_buffer);
    for &index in proc_inline_indices {
        if index > prev_len / 2 do index += len(file_buffer) - prev_len;
        file_buffer = insert_into_file_buffer(
            file_buffer,
            {35, 102, 111, 114, 99, 101, 95, 105, 110, 108, 105, 110, 101}, 
            index,
        );
    }
    handle, err = os.open(file_name, os.O_WRONLY);
    if err != os.ERROR_NONE {
        fmt.printf("Failed to open file! [Err: %v]\n", err);
        return;
    }
    read_len, err = os.write_string(handle, string(file_buffer));
    if read_len != len(file_buffer) || err != os.ERROR_NONE {
        fmt.println("Failed to rewrite file!");
        return;
    }
}

insert_into_file_buffer :: proc(file_buffer: []byte, what: []byte, offset: int) -> []byte {
    assert(offset > 0 && offset < len(file_buffer));

    new_buffer := make([]byte, len(file_buffer) + offset);
    copy_slice(new_buffer[:offset], file_buffer[:offset]);
    copy_slice(new_buffer[offset:offset + len(what)], what);
    copy_slice(new_buffer[offset + len(what):], file_buffer[offset:]);
    delete(file_buffer);

    return new_buffer;
}

// NexaAttr_Inline
proc_inline :: proc(stmt: ^ast.Stmt) -> int {
    #partial switch s in stmt.derived {
        case ^ast.Value_Decl:
            fmt.printf("%v\n", s);
            // assert(len(s.names) == 1)
            // should assume that the name is one since it is a function...
            // todo
            ident, _ := s.names[0].derived.(^ast.Ident);
            return ident.end.offset + 3;
        case:
            find_correct_node(s);
    }
    return 0;
}

// NexaAttr_ApplicationEntry
app_entry_check :: proc(stmt: ^ast.Stmt, buffer: []byte) {
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
        case ^ast.Bit_Field_Type:
            fmt.printf("%v\n", v);
        case ^ast.Bit_Field_Field:
            fmt.printf("%v\n", v);
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
        case ^ast.Bit_Field_Type:
            fmt.printf("%v\n", v);
    }
}