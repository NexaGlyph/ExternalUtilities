package marshall

import "../../binary"

import "base:intrinsics"
import "core:mem"
import "core:fmt"
import "core:strings"

/* MAPPING */
VariableSizeIndex :: distinct u16;
MappingIndexNext  :: ~VariableSizeIndex(0); 
VariableSize      :: u16;

MappingVariable :: struct {
    sizes: []VariableSize,
    properties: []MappingVariableProperty,
}
MappingVariableProperty :: struct {
    value: MappingVariableArbitrary,
}
when ODIN_DEBUG {
    MappingVariableArbitrary :: struct {
        index: VariableSizeIndex,
        name: string,
        next: []MappingVariableProperty,
    }
}
else {
    MappingVariableArbitrary :: struct {
        index: VariableSizeIndex,
        next: []MappingVariableProperty,
    }
}

/* SERIALIZED TYPE */
MarshallIndex :: struct {
    index: u32,
    size: u16,
}
MarshallVariable :: struct($T: typeid) {
    type: typeid,
    byte_map: []byte,
    properties: []MarshallVariableProperty,
}
MarshallVariableProperty :: struct {
    value: ^MarshallVariableArbitrary,
}
when ODIN_DEBUG {
    MarshallVariableArbitrary :: struct {
        index: MarshallIndex,
        name: string,
        next: ^MarshallVariableArbitrary,
    }
}
else {
    MarshallVariableArbitrary :: struct {
        value: MarshallIndex,
        next: ^MarshallVariableArbitrary,
    }
}

property_end :: #force_inline proc "fastcall" (variable: ^MarshallVariableArbitrary) -> bool {
    return variable^.next == nil;
}

index_range :: #force_inline proc "fastcall" (marshall_index: MarshallIndex) -> (u32, u16) {
    return marshall_index.index, u16(marshall_index.index) + marshall_index.size;
}

serialize :: proc { serialize_by_map, serialize_by_file }

serialize_by_map :: #force_inline proc(data_to_serialize: ^rawptr, mapping: MappingVariable, $Out_T: typeid/MarshallVariable($In_T)) -> Out_T {
    out := MarshallVariable(In_T){};
    out.type = In_T;
    out.byte_map, out.properties = property_scan(data_to_serialize, mapping);
    return out;
}

property_scan :: proc(data_to_serialize: ^rawptr, mapping: MappingVariable) -> ([]byte, []MarshallVariableProperty) {
    /* PROPERTY_SCAN INTERNAL TYPES */
    MappingData :: #type struct {
        property: MappingVariableProperty,
        sizes: []VariableSize,
        index: ^u16,
    }
    SerializationData :: #type struct {
        data_to_serialize: ^rawptr,
        marshall_byte_map: []byte,
        index_offset: ^u16,
        previous_variable: ^MarshallVariableArbitrary,
    }
    /* PROPERTY_SCAN INTERNAL RECURSIVE FUNCTIONS */
    variable_scan :: #force_inline proc(mapping_data: MappingData, serialization_data: SerializationData) {
        idx := serialization_data.index_offset^;
        marshall_byte_offset := mapping_data.sizes[mapping_data.index^];
        serialization_data.previous_variable^.index = MarshallIndex {
            u32(idx), marshall_byte_offset,
        };
        serialization_data.previous_variable^.next = nil;
        mem.copy(
            raw_data(serialization_data.marshall_byte_map[idx : idx + marshall_byte_offset]),
            raw_data(mem.byte_slice(mem.ptr_offset(serialization_data.data_to_serialize, idx), marshall_byte_offset)),
            int(marshall_byte_offset),
        );
        serialization_data.index_offset^ += marshall_byte_offset;
    }
    variable_scan_recurisve :: proc(mapping_data: MappingData, serialization_data: SerializationData) {
        when ODIN_DEBUG do serialization_data.previous_variable^.name = mapping_data.property.value.name;

        if mapping_data.property.value.index != MappingIndexNext {
            variable_scan(mapping_data, serialization_data);
            return;
        }
        for next_property in mapping_data.property.value.next {
            // TODO: "byline" array
            serialization_data.previous_variable^.next = new(MarshallVariableArbitrary);
            variable_scan_recurisve(
                MappingData {
                    next_property,
                    mapping_data.sizes,
                    mapping_data.index,
                },
                SerializationData {
                    serialization_data.data_to_serialize,
                    serialization_data.marshall_byte_map,
                    serialization_data.index_offset,
                    serialization_data.previous_variable^.next,
                },
            );
        }
    }
    
    marshall_byte_map   := make([]byte, mapping_size(mapping.sizes));
    marshall_properties := make([]MarshallVariableProperty, len(mapping.properties));
    variable_index, property_index := u16(0), u16(0);
    for property in mapping.properties {
        previous := new(MarshallVariableArbitrary);
        marshall_properties[property_index] = MarshallVariableProperty { previous };

        if property.value.index != MappingIndexNext {
            when ODIN_DEBUG do previous^.name = property.value.name;

            fmt.println(previous^.name);

            marshall_byte_offset := mapping.sizes[property_index];
            previous^.index = MarshallIndex {
                u32(variable_index), marshall_byte_offset,
            }
            previous.next = nil;
            mem.copy(
                raw_data(marshall_byte_map[variable_index : variable_index + marshall_byte_offset]),
                raw_data(mem.byte_slice(mem.ptr_offset(data_to_serialize, variable_index), marshall_byte_offset)),
                int(marshall_byte_offset),
            );
            variable_index += marshall_byte_offset;
        }
        else {
            variable_scan_recurisve(
                MappingData {
                    property,
                    mapping.sizes,
                    &property_index,
                },
                SerializationData {
                    data_to_serialize,
                    marshall_byte_map,
                    &variable_index,
                    previous,
                },
            );
        }
        property_index += 1;
    }
    return marshall_byte_map, marshall_properties;
}

mapping_size :: #force_inline proc "fastcall" (sizes: []VariableSize) -> u16 {
    total := u16(0);
    for size in sizes do total += size;
    return total;
}

serialize_by_file :: proc(data_to_serialize: ^$In_T, file_path: string, $Out_T: typeid) -> Out_T 
    where intrinsics.type_is_specialization_of(Out_T, MarshallVariable) {
        assert(false, "TODO!");
        return Out_T{};
}

when ODIN_DEBUG {
    serialization_debug :: proc(variable: ^MarshallVariable($T)) {

        variable_debug :: proc(var: ^MarshallVariableArbitrary, name_chain: ^[dynamic]string, byte_map: []byte) {
            append(name_chain, var^.name);
            if property_end(var) {
                from, to := index_range(var^.index);
                fmt.println(strings.concatenate(name_chain[:]));
                clear(name_chain);
            }
            else do variable_debug(var^.next, name_chain, byte_map);
        }

        name_chain := make([dynamic]string);
        for property in variable.properties {
            variable_debug(property.value, &name_chain, variable^.byte_map);
        }
    }

    deserialization_debug :: proc(variable: rawptr) {
        assert(false, "TODO!");
    }
}

deserialize :: proc(data_to_deserialize: ^$In_T) -> rawptr
    where intrinsics.type_is_specialization_of(In_T, MarshallVariable) {
        variable_scan :: proc(
            variable: ^MarshallVariableArbitrary, 
            byte_map: []byte,
            out: ^rawptr,
        ) {
            if property_end(variable) {
                from, to := index_range(variable^.index);
                offset_out := mem.ptr_offset(out, from);
                mem.copy(
                    offset_out,
                    raw_data(byte_map[from : to]),
                    int(variable^.index.size),
                );
            }
            else {
                variable_scan(variable.next, byte_map, out);
            }
        }

        out: rawptr = raw_data(make([]byte, len(data_to_deserialize.byte_map)));
        for property in data_to_deserialize^.properties {
            variable_scan(property.value, data_to_deserialize.byte_map, &out);
        }

        return out;
}

dump_marshall :: proc(serialized: ^MarshallVariable($T)) {
    
    dump_value :: proc(value: ^MarshallVariableArbitrary) {
        if property_end(value) do free(value);
        else {
            assert(false, "TODO: ALL THE PREVIOUS ONES ARE ALSO ALLOCATED!");
            dump_value(value^.next);
        }
    }

    for property in serialized.properties do dump_value(property.value);
}

write :: proc(writer: binary.Writer) {}

read  :: proc(writer: binary.Reader) {}