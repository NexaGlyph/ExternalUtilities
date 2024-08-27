package struct_test

import "core:fmt"
import "core:math/rand"

import marshall "nexa_external:binary/marshall"

run :: proc() {

    test_struct_default :: proc() {
        // basic
        {
            Struct :: struct {
                elements: []Struct_Element "NexaTag_Marshallable",
            }
            Struct_Element :: struct {
                prop1: string "NexaTag_Marshallable",
                prop2: string "NexaTag_Marshallable",
                prop3: int,
            }

            string_rand_gen :: proc() -> string {
                byte_rand_gen :: #force_inline proc() -> byte {
                    return cast(byte)rand.int_max(26) + 65;
                }
                bytes := make([]byte, rand.int_max(5));
                for &b in bytes do b = byte_rand_gen();
                return string(bytes);
            }
            my_struct := Struct {
                elements = make([]Struct_Element, 31),
            };
            defer {
                for e in my_struct.elements {
                    delete(e.prop1);
                    delete(e.prop2);
                }
                delete(my_struct.elements);
            }
            for &e in my_struct.elements {
                e = Struct_Element {
                    prop1 = string_rand_gen(),
                    prop2 = string_rand_gen(),
                    prop3 = rand.int_max(312093012),
                };
            }
            serialized, err := marshall.serialize(my_struct);
            fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
            my_struct_deserialized: Struct;
            err = marshall.deserialize(my_struct_deserialized, serialized);
            fmt.assertf(err == .None, "\x1b[34mDeserialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
            defer {
                for e in my_struct_deserialized.elements {
                    delete(e.prop1);
                    delete(e.prop2);
                }
                delete(my_struct_deserialized.elements);
            }

            equals :: #force_inline proc(e1: Struct_Element, e2: Struct_Element) {
                _equals :: #force_inline proc(e1: Struct_Element, e2: Struct_Element) -> bool {
                    return e1.prop1 == e2.prop1 && e1.prop2 == e2.prop2;
                }
                fmt.assertf(_equals(e1, e2), "Values do not match!\n%v :: %v", e1, e2);
            }

            for e, index in my_struct_deserialized.elements do equals(my_struct.elements[index], e);
        }

        {
            Marshall_Test_Serialize_Struct_Indent :: struct {
                prop1: int,
                prop2: string,
                prop3: ^int,
            }

            Marshall_Test_Serialize_Struct_Enum :: enum {
                _0,
                _1,
                _2,
                _3,
            }

            Marshall_Test_Serialize_Struct :: struct {
                indent: Marshall_Test_Serialize_Struct_Indent   "NexaTag_Marshallable",
                val1: [^]cstring                                "NexaTag_Marshallable",
                val2: [dynamic]i32                              "NexaTag_Marshallable",
                val3: Marshall_Test_Serialize_Struct_Enum       "NexaTag_Marshallable",
                val4: #type proc() -> bool, // not going to be serialized
            }

            dummy_string :: "MyProp2Value";
            dummy_int := 10;
            dummy_cstring: cstring = "Henlo";
            my_struct := Marshall_Test_Serialize_Struct {
                indent = {
                    prop1 = 10,
                    prop2 = dummy_string,
                    prop3 = &dummy_int,
                },
                val1 = &dummy_cstring,
                val2 = make_dynamic_array([dynamic]i32),
                val3 = ._2,
            };
            serialized, err := marshall.serialize(my_struct);
            fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
            my_struct_deserialized: Marshall_Test_Serialize_Struct;
            err = marshall.deserialize(my_struct_deserialized, serialized);
            fmt.assertf(err == .None, "\x1b[34mDeserialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
            {
                custom_assert :: proc(v1, v2: $T, index: string) {
                    fmt.assertf(
                        v1 == v2,
                        "%s:\n\t%v :: %v",
                        index, v1, v2,
                    );
                }
                custom_assert(
                    my_struct.indent.prop1, my_struct_deserialized.indent.prop1, "Prop1",
                );
                custom_assert(
                    my_struct.indent.prop2, my_struct_deserialized.indent.prop2, "Prop2",
                );
                custom_assert(
                    my_struct.indent.prop3^, my_struct_deserialized.indent.prop3^, "Prop3",
                );
                custom_assert(
                    my_struct.val1[0], my_struct_deserialized.val1[0], "Val1",
                );
                custom_assert(
                    len(my_struct.val2), len(my_struct_deserialized.val2), "Val2",
                );
                custom_assert(
                    my_struct.val3, my_struct_deserialized.val3, "Val3"
                );
            }
            fmt.printf("\t\x1b[32mPassed... \x1b[0mMarshall_Test_Serialize_Struct\n");
        }
    }

    test_struct_indented :: proc() {
        fmt.printf("\x1b[33m\tTODO\x1b[0m\n");
    }

    test_struct_recursive :: proc() {
        Struct_Superior :: struct {
            inferiors: []^Struct_Inferior "NexaTag_Marshallable",
        }

        Struct_Inferior :: struct {
            inferior: ^Struct_Inferior "NexaTag_Marshallable",
            superior: ^Struct_Superior "NexaTag_Marshallable",
        }

        fmt.printf("\x1b[33m\tTODO\x1b[0m\n");
    }

    fmt.println("\nBeginning [STRUCT]");
    fmt.println("-----------------------------");
    test_struct_default();
    test_struct_indented();
    test_struct_recursive();
    fmt.println("-----------------------------");
    fmt.println("Ending [STRUCT]\n");
}