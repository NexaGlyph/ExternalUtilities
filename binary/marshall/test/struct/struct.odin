package struct_test

import "core:fmt"

import marshall "nexa_external:binary/marshall"

run :: proc() {

    Marshall_Test_Serialize_Struct :: struct {
        indent: #type struct {
            prop1: int,
            prop2: string,
            prop3: ^int,
        } "NexaTag_Marshallable",
        val1: [^]cstring "NexaTag_Marshallable",
        val2: [dynamic]i32 "NexaTag_Marshallable",
        val3: #type enum {
            _0,
            _1,
            _2,
            _3,
        } "NexaTag_Marshallable",
        val4: #type proc() -> bool, // not going to be deserialized
    }

    dummy_int := 10;
    dummy_cstring: cstring = "Henlo";
    my_struct := Marshall_Test_Serialize_Struct {
        indent = {
            prop1 = 10,
            prop2 = "MyProp2Value",
            prop3 = &dummy_int,
        },
        val1 = &dummy_cstring,
        val2 = make_dynamic_array([dynamic]i32),
        val3 = ._2,
    };
    serialized, err := marshall.serialize(&my_struct);
    fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
    my_struct_deserialized: Marshall_Test_Serialize_Struct;
    err = marshall.deserialize(&my_struct_deserialized, serialized);
    {
        assert(my_struct.indent.prop1 == my_struct_deserialized.indent.prop1);
        assert(my_struct.indent.prop2 == my_struct_deserialized.indent.prop2);
        assert(my_struct.indent.prop3^ == my_struct_deserialized.indent.prop3^);
        assert(my_struct.val1[0] == my_struct_deserialized.val1[0]);
        assert(len(my_struct.val2) == len(my_struct_deserialized.val2));
        assert(my_struct.val3 == my_struct_deserialized.val3);
    }

}