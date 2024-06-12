package marshall

import "../../binary"

write_mapping :: proc() {
    assert(false, "TODO!");
}

write_marshall :: proc() {
    assert(false, "TODO!");
}

write :: proc { write_mapping_file, write_mapping_io, write_marshall, }

EXTENSION_MAPPING :: ".mrmap";
EXTENSION_MARSHALL :: ".mr";
check_extensions :: proc(file_path: string, expected_extension: string) -> string {
    pos := len(file_path) - len(expected_extension)
    for char, index in expected_extension {
        if file_path[pos + index] != char do return file_path + expected_extension;
    }
    return file_path;
}

write_mapping_file :: proc(file_path: string, mapping: MappingVariable) {
    file_path = check_extensions(file_path, EXTENSION_MAPPING);
    assert(false, "TODO!");
}

write_mapping_io :: proc(writer: binary.Writer, mapping: MappingVariable) {
    assert(false, "TODO!");
}

write_marshall :: proc() {
    assert(false, "TODO!");
}

read  :: proc { read_mapping_file, read_mapping_io, read_marshall, }

read_mapping_file :: proc() {
    assert(false, "TODO!");
}

read_mapping_io :: proc() {
    assert(false, "TODO!");
}

read_marshall :: proc() {
    assert(false, "TODO!");
}