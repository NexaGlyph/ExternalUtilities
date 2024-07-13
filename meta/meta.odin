//+build windows
package meta

import "core:fmt"
import "core:os"

import "core:odin/parser"
import "core:odin/ast"
// import "core:reflect"

main :: proc() {
    check_file_contents("meta_test/sample_inline.odin");
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

    for decl in ast_file.decls {
        #partial switch d in decl.derived {
            case ^ast.Value_Decl:
                for attribute in d.attributes {
                    expr_loop: for expr in attribute.elems {
                        field_value: ^ast.Field_Value;
                        field_value, ok = expr.derived.(^ast.Field_Value);
                        if !ok {
                            ident: ^ast.Ident;
                            ident, ok = expr.derived.(^ast.Ident);
                            if !ok do break expr_loop;
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
                                * @brief should be defined on a procedure that has main app loop in it
                                */
                                case "NexaAttr_ApplicationEntry":
                                    if app_entry do assert(false, "Can be only one app entry!");
                                    app_entry = true;
                                    app_entry_check(decl, file_buffer);
                                /**
                                * @brief marks function to be "inlined" (same as #force_inline)
                                */
                                case "NexaAttr_Inline":
                                    index := proc_inline(decl);
                                    assert(index != 0);
                                    append(&proc_inline_indices, index);
                                // ignore all others
                            }
                            break expr_loop;
                        }
                        fmt.printf("Parsing: %s\n", ast_file.src[field_value.pos.offset:field_value.end.offset]);
                        ///
                        ident: ^ast.Ident;
                        ident, ok = field_value.field.derived_expr.(^ast.Ident);
                        if !ok do break expr_loop;
                        fmt.printf("Ident name: %s\n", ident.name);
                        ///
                        if ast_file.src[field_value.sep.offset] == 61 /* "=" */ {
                            ///
                            lit: ^ast.Basic_Lit;
                            lit, _ = field_value.value.derived_expr.(^ast.Basic_Lit);
                            fmt.printf("Basic lit token: %s\n", lit.tok.text);
                            switch ident.name {
                                /**
                                * @brief this attribute tells meta to error on any access of the specified member outisde NexaAttr_APICall
                                */
                                case "NexaAttr_PrivateMember":
                                    assert(false, "TODO");
                                /**
                                * @brief this should signify that the call comes from NexaCore, further ident can be specified:
                                *   1. "internal" ... only NexaCore itself can access this function
                                *   2. "external" ... can be accessed outside NexaCore
                                */
                                case "NexaAttr_APICall":
                                    assert(false, "TODO");
                                // ignore all others
                            }
                        }
                    }
                }
        }
    }

    prev_len := len(file_buffer);
    for index in &proc_inline_indices {
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
            ident, ok := s.names[0].derived.(^ast.Ident);
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
    }
}