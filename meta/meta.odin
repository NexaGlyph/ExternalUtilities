//+build windows
package meta

import "core:fmt"
import "core:os"

import "core:odin/parser"
import "core:odin/ast"

main :: proc() {
    check_file_contents("meta_test/sample.odin");
}

check_file_contents :: proc(file_name: string) {
    p := parser.Parser{};
    file, ok := os.read_entire_file_from_filename(file_name);
    defer delete(file);
    if !ok {
        fmt.println("Failed to read file!");
        return;
    }
    ast_file := ast.File{
        src = string(file),
        fullpath = file_name,
    };

    if ok = parser.parse_file(&p, &ast_file); !ok {
        fmt.println("Failed to parse file!");
        return;
    }

    for decl in ast_file.decls {
        #partial switch d in decl.derived {
            case ^ast.Value_Decl:
                for attribute in d.attributes {
                    expr_loop: for expr in attribute.elems {
                        field_value, ok := expr.derived.(^ast.Field_Value);
                        fmt.printf("Parsing: %s\n", string(file[field_value.pos.offset:field_value.end.offset]));
                        if !ok do break expr_loop;
                        ///
                        ident: ^ast.Ident;
                        ident, ok = field_value.field.derived_expr.(^ast.Ident);
                        if !ok do break expr_loop;
                        fmt.printf("Ident name: %s\n", ident.name);
                        ///
                        if file[field_value.sep.offset] != 61 /* "=" */ do break expr_loop;
                        ///
                        lit: ^ast.Basic_Lit;
                        lit, ok = field_value.value.derived_expr.(^ast.Basic_Lit);
                        if !ok do break expr_loop;
                        fmt.printf("Basic lit token: %s\n", lit.tok.text);
                        
                        switch ident.name {
                            case "NexaAttr_PrivateMember":
                                assert(false, "TODO");
                                break;
                            // ignore all others
                        }
                    }
                }
        }
    }
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