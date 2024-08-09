//+build windows
package meta

import "core:c/libc"
import "core:fmt"
import "core:odin/ast"
import "core:mem"
import "core:strconv"

/** @brief describes how the debug assertions should be handled in the application runtime */
AppNotification :: enum {
    /** @brief ignore result of assertion */
    Ignore = 0,
    /** @brief should revert changes and return */
    CleanUp,
    /** @brief does not have to revert changes, just return */
    CanAbort,
}

debug_assert_ignore :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.Ignore, condition, formatted_string, args);
}
debug_assert_cleanup :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.CleanUp, condition, formatted_string, args);
}
debug_assert_abort :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    debug_assert(.CanAbort, condition, formatted_string, args);
}

debug_assert :: proc(notification: AppNotification, condition: bool, formatted_string: string, args: ..any) {
    switch notification {
        case .Ignore:
            debug_runtime_assert(condition, formatted_string, args);
        case .CleanUp:
            if !condition {
                fmt.print("\x1b[31m[ABORT_ASSERTION]:\x1b[0m");
                fmt.println(fmt.tprintf(formatted_string, ..args));
                revert_changes();
                libc.abort();
            }
        case .CanAbort:
            debug_abort_assert(condition, formatted_string, args);
    }
}

wait :: #force_inline proc() {
    for libc.getchar() != '\n' do continue;
}

/** @brief functions checks the condition, halts and waits for the user to continue */
@(private="file")
debug_runtime_assert :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    if !condition {
        fmt.print("\x1b[31m[RUNTIME_ASSERTION]:\x1b[0m");
        fmt.println(fmt.tprintf(formatted_string, args));
        wait();
    }
}

/** @brief function checks the condition and aborts the program if it is not met */
@(private="file")
debug_abort_assert :: #force_inline proc(condition: bool, formatted_string: string, args: ..any) {
    if !condition {
        fmt.print("\x1b[31m[ABORT_ASSERTION]:\x1b[0m");
        fmt.println(fmt.tprintf(formatted_string, args));
        libc.abort();
    }
} 

todo :: #force_inline proc(location := #caller_location) {
    debug_abort_assert(false, "[%s]: TODO!", location);
}

not_yet_implemented :: #force_inline proc(location := #caller_location) {
    debug_runtime_assert(false, "[%s]: This functionality is not yet implemented!", location);
}

// formatter
/** @brief contains basic (we can say common) information for Formatter_ProcData/Struct variants */
Formatter_BaseData :: struct {
    location: string,
    specifier_line: int,
}
Formatter_ProcDataLocation :: struct {
    location: string,
    line: int,
}
/** @brief contains all the possible information about the procedure that can be formatted into a fmt message */
Formatter_ProcData :: struct {
    using base: Formatter_BaseData,
    attribute_location: Formatter_ProcDataLocation,
    proc_location: Formatter_ProcDataLocation,
    proc_name: string,
    ident: string,
    field_specifier: string,
}
Formatter_ProcDataFactory :: struct {
    // methods
    Proc_AttributeLocation: #type proc "cdecl" (this: ^Formatter_ProcDataFactory, attribute: ^ast.Attribute) -> ^Formatter_ProcDataFactory,
    Proc_DeclLocation:      #type proc "cdecl" (this: ^Formatter_ProcDataFactory, proc_decl: ^ast.Proc_Lit) -> ^Formatter_ProcDataFactory,
    Proc_Field:             #type proc "cdecl" (this: ^Formatter_ProcDataFactory, field: ^ast.Field_Value) -> ^Formatter_ProcDataFactory,
    Proc_Ident:             #type proc "cdecl" (this: ^Formatter_ProcDataFactory, ident: ^ast.Ident) -> ^Formatter_ProcDataFactory,
    Build:                  #type proc "odin"  (this: ^Formatter_ProcDataFactory) -> string,
    // member data
    _data: Formatter_ProcData,
}
@(private="file")
fmt_proc_attribute_location :: proc "cdecl" (this: ^Formatter_ProcDataFactory, attribute: ^ast.Attribute) -> ^Formatter_ProcDataFactory {
    this^._data.attribute_location = {
        location = "todo",
        line = attribute^.node.pos.line,
    };
    return this;
}
@(private="file")
fmt_proc_decl_location :: proc "cdecl" (this: ^Formatter_ProcDataFactory, proc_decl: ^ast.Proc_Lit) -> ^Formatter_ProcDataFactory {
    this^._data.proc_location = {
        location = "todo",
        line = proc_decl^.node.pos.line,
    };
    return this;
}
@(private="file")
fmt_proc_field :: proc "cdecl" (this: ^Formatter_ProcDataFactory, field: ^ast.Field_Value) -> ^Formatter_ProcDataFactory {
    ident, _ := field.field.derived_expr.(^ast.Ident);
    lit, _ := field.value.derived_expr.(^ast.Basic_Lit);
    this^._data.ident = ident^.name;
    this^._data.field_specifier = lit^.tok.text;
    return this;
}
@(private="file")
fmt_proc_ident :: proc "cdecl" (this: ^Formatter_ProcDataFactory, ident: ^ast.Ident) -> ^Formatter_ProcDataFactory {
    this^._data.ident = ident.name;
    return this;
}
@(private="file")
fmt_proc_build :: proc(this: ^Formatter_ProcDataFactory) -> string {
    src := fmt.tprintf(
        "Decl spec [found in file: %s; line: %s]\n\tAttribute [found at line: %s]:\n\t\tprototype: %s;\n\t\tfielded: %v;\n\t\ttype: %s;\n\tProc [found at line: %s]:\n\t\tprototype: %s;\n\t\tproc_name: %s\n",
        // base
        unspecified(this^._data.location),
        unspecified(this^._data.specifier_line),
        // proc attribute
        unspecified(this^._data.attribute_location.line),
        unspecified(this^._data.attribute_location.location),
        len(this^._data.field_specifier) > 0 ? true : false,
        unspecified(this^._data.ident),
        // proc decl
        unspecified(this^._data.proc_location.line),
        unspecified(this^._data.proc_location.location),
        unspecified(this^._data.proc_name),
    );
    //fmt.println(src);
    return src;
}
@(private="file")
unspecified_string :: proc(str: string) -> string {
    if len(str) > 0 do return "UNSPECIFIED";
    return str;
}
@(private="file")
unspecified_int :: proc(i: int) -> string {
    if i > 0 {
        buff := make([]byte, 4, context.temp_allocator);
        return strconv.itoa(buff, i);
    }
    return "UNSPECIFIED";
}
@(private="file")
unspecified :: proc { unspecified_int, unspecified_string }
/** @brief contains all the possible information about the struct that can be formatted into a fmt message */
Formatter_StructData :: struct {
    using base: Formatter_BaseData,
}
Formatter_StructDataFactory :: struct {
    //todo when the struct tagging will be supported
}
/** @brief struct used to store factories when working with format_### functions, basically an interface (kind of...) */
IFormatter :: struct {
    using proc_factory: ^Formatter_ProcDataFactory,
    using struct_factory: ^Formatter_StructDataFactory,
}
/** @brief prepares the struct factory for new formatting */
/** @note should be called before every new "Build" of factory */
fmt_struct_new :: proc(formatter: ^IFormatter) {
    todo();
    // if formatter^.struct_factory == nil do formatter^.struct_factory = new(Formatter_StructDataFactory);
    // mem.zero_item(&formatter^.struct_factory^._data);
}
/** @brief prepares the procedure factory for new formatting */
/** @note should be called before every new "Build" of factory */
fmt_proc_new :: proc(formatter: ^IFormatter) {
    if formatter^.proc_factory == nil {
        formatter^.proc_factory = new(Formatter_ProcDataFactory);
        formatter^.proc_factory.Proc_AttributeLocation = fmt_proc_attribute_location;
        formatter^.proc_factory.Proc_DeclLocation = fmt_proc_decl_location;
        formatter^.proc_factory.Proc_Field = fmt_proc_field;
        formatter^.proc_factory.Proc_Ident = fmt_proc_ident;
        formatter^.proc_factory.Build = fmt_proc_build;
    }
    mem.zero_item(&formatter^.proc_factory^._data);
}
