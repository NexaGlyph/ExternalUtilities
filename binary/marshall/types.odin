package marshall

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