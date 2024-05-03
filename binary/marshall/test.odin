package marshall

import "core:math/rand"
import "core:fmt"

/*
OFFICIAL (PROGRAM-IN-USE) TYPES
*/
StructIndexed1 :: struct {
    value: i8,
}

StructIndexed2 :: struct {
    value1: i16,
    value2: StructIndexed1,
}

StructIndexed3 :: struct {
    value1: i32,
    value2: StructIndexed1,
    value3: StructIndexed2,
}

MyCustomStruct :: struct {
    value_: string,
    value1: StructIndexed1,
    value2: StructIndexed2,
    value3: StructIndexed3,
}

/*
MARSHALL'D TYPES
*/
Mapping_MyCustomStruct  :: MappingVariable {
    sizes = { size_of(byte) * 10, size_of(i8), size_of(i16), size_of(i8), size_of(i32), size_of(i8), size_of(i16), size_of(i8), },
    properties = {
        MappingVariableProperty { // string
            value = {
                index = 0,
                name = "[string]::value_",
            },
        },
        MappingVariableProperty { // StructIndexed1
            value = {
                index = MappingIndexNext,
                name = "[StructIndexed1]",
                next = {
                    MappingVariableProperty { // i8 -> arbitrary
                        value = {
                            index = 1,
                            name = "::[i8]value",
                        },
                    },
                },
            },
        },
        MappingVariableProperty { // StructIndexed2
            value = {
                index = MappingIndexNext,
                name = "[StructIndexed2]",
                next = {
                    MappingVariableProperty { // i16 -> arbitrary
                        value = {
                            index = 2,
                            name = "::[i16]value1",
                        }
                    },
                    MappingVariableProperty { // StructIndexed1
                        value = {
                            index = MappingIndexNext,
                            name = "::[StructIndexed1]",
                            next = {
                                MappingVariableProperty { // i8 -> arbitrary
                                    value = {
                                        index = 3,
                                        name = "::[i8]value",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        MappingVariableProperty { // StructIndexed3
            value = {
                index = MappingIndexNext,
                name = "[StructIndexed3]",
                next = {
                    MappingVariableProperty { // i32 -> arbitrary
                        value = {
                            index = 4,
                            name = "::[i32]value1",
                        },
                    },
                    MappingVariableProperty {
                        value = {
                            index = MappingIndexNext,
                            name = "::[StructIndexed1]value2",
                            next = {
                                MappingVariableProperty { // i8 -> arbitrary
                                    value = {
                                        index = 5,
                                        name = "::[i8]value",
                                    }
                                },
                            },
                        },
                    },
                    MappingVariableProperty { // StructIndexed2
                        value = {
                            index = MappingIndexNext,
                            name = "::[StructIndexed2]value3",
                            next = {
                                MappingVariableProperty { // i16 -> arbitrary
                                    value = {
                                        index = 6,
                                        name = "::[i16]value1",
                                    },
                                },
                                MappingVariableProperty { // StructIndexed1
                                    value = {
                                        index = MappingIndexNext,
                                        name = "::[StructIndexed1]value2",
                                        next = {
                                            MappingVariableProperty {
                                                value = {
                                                    index = 7,
                                                    name = "::[i8]value",
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
Marshall_MyCustomStruct :: MarshallVariable(MyCustomStruct);

generate_custom_struct_instance :: proc() -> ^MyCustomStruct {
    my_struct := new(MyCustomStruct);
    my_struct^ = {
        value_ = "1234567890",
        value1 = StructIndexed1 {
            value = i8(rand.int_max(127)),
        },
        value2 = StructIndexed2 {
            value1 = i16(rand.int_max(1 << 15 - 1)),
            value2 = StructIndexed1 {
                value = i8(rand.int_max(127)),
            },
        },
        value3 = StructIndexed3 {
            value1 = i32(rand.int31()),
            value2 = StructIndexed1 {
                value = i8(rand.int_max(127)),
            },
            value3 = StructIndexed2 {
                value1 = i16(rand.int_max(1 << 15 - 1)),
                value2 = StructIndexed1 {
                    value = i8(rand.int_max(127)),
                },
            },
        },
    };
    return my_struct;
}

assert_eq_struct1 :: proc(inst1: StructIndexed1, inst2: StructIndexed1) {
    assert(inst1.value == inst2.value);
}

assert_eq_struct2 :: proc(inst1: StructIndexed2, inst2: StructIndexed2) {
    assert(inst1.value1 == inst2.value1);
    assert_eq_struct1(inst1.value2, inst2.value2);
}

assert_eq_struct3 :: proc(inst1: StructIndexed3, inst2: StructIndexed3) {
    assert(inst1.value1 == inst2.value1);
    assert_eq_struct1(inst1.value2, inst2.value2);
    assert_eq_struct2(inst1.value3, inst2.value3);
}

assert_eq :: proc(inst1: ^MyCustomStruct, inst2: ^MyCustomStruct) {
    assert_eq_struct1(inst1.value1, inst2.value1);
    assert_eq_struct2(inst1.value2, inst2.value2);
    assert_eq_struct3(inst1.value3, inst2.value3);
}

print_my_custom_struct :: proc(my_struct: ^MyCustomStruct) {
    fmt.println(my_struct.value_);
    fmt.printf("StructIndex1: {{\n\t%v,\n}}\n", my_struct.value1.value);
    fmt.printf("StructIndex2: {{\n\t%v,\n\tStructIndex1: {{\n\t\t%v\n\t}}\n}\n", my_struct.value2.value1, my_struct.value2.value2.value);
    fmt.printf("StructIndex3: {{\n\t%v,\n\tStructIndex1: {{\n\t\t%v\n\t}}\n\tStructIndex2: {{\n\t\t%v,\n\t\t%v\n\t}}\n}\n", my_struct.value3.value1, my_struct.value3.value2.value, my_struct.value3.value3.value1, my_struct.value3.value3.value2.value);
}

main :: proc() {

    my_custom_struct_instance := generate_custom_struct_instance();
    my_custom_struct_instance2: ^MyCustomStruct = nil;
    fmt.print("Custom Struct Created!\n");
    // print_my_custom_struct(my_custom_struct_instance);

    /* SERIALIZATION */
    instance_ptr := cast(rawptr)(my_custom_struct_instance);
    data_serialized := serialize(&instance_ptr, Mapping_MyCustomStruct, Marshall_MyCustomStruct);
    serialization_debug(&data_serialized);
    defer dump_marshall(&data_serialized);

    /* DESERIALIZATION */
    {
        data_deserialized := deserialize(&data_serialized);
        my_custom_struct_instance2 = cast(^MyCustomStruct)(data_deserialized);
    }

    // print_my_custom_struct(my_custom_struct_instance2);
    assert_eq(my_custom_struct_instance, my_custom_struct_instance2);
}