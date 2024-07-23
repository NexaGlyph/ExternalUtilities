//+build windows
package test

import "base:intrinsics"

import "core:fmt"
// import "core:strings"
// import "core:io"
import "core:math/rand"

import marshall "../"

assert_serialization :: #force_inline proc(err: marshall.Marshall_Error, byte_data: []byte, $T: typeid) {
    fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
    fmt.assertf(len(byte_data) == size_of(T), "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m; sizes do not match: %v[byte_data] :: %v[size_of(%v)]\n", len(byte_data), size_of(T), type_info_of(T));
}
assert_deserialization :: #force_inline proc(err: marshall.Marshall_Error, val, deserialized: $T) {
    fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
    fmt.assertf(val == deserialized, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with two conflicting values: %v[expected] :: %v[deserialized]", val, deserialized);
}

test_ints :: proc() {
    test :: proc($T: typeid, proc_name: string) 
        where intrinsics.type_is_integer(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        _test(val, proc_name);
    }
    test_s :: proc($T: typeid, proc_name: string) 
        where intrinsics.type_is_integer(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        val *= -1;
        _test(val, proc_name);
    }
    _test :: proc(val: $T, proc_name: string) 
        where intrinsics.type_is_integer(T)
    {
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        assert_serialization(err, byte_data, T);
        deserialized: T = 0;
        err = marshall.deserialize(deserialized, byte_data);
        assert_deserialization(err, val, deserialized);
        fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", proc_name, type_info_of(T));
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");
    test_s(i16le, #procedure);
    test_s(i32le, #procedure);
    test_s(i64le, #procedure);
    test_s(i16be, #procedure);
    test_s(i32be, #procedure);
    test_s(i64be, #procedure);
    test_s(i8,    #procedure);
    test_s(i16,   #procedure);
    test_s(i32,   #procedure);
    test_s(i64,   #procedure);
    test_s(int,   #procedure); // same as i64...

    test(u16le, #procedure);
    test(u32le, #procedure);
    test(u64le, #procedure);
    test(u16be, #procedure);
    test(u32be, #procedure);
    test(u64be, #procedure);
    test(u8,    #procedure);
    test(u16,   #procedure);
    test(u32,   #procedure);
    test(u64,   #procedure);
    test(uint,  #procedure); // same as u64...
    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_floats :: proc() {
    test :: proc($T: typeid)
        where intrinsics.type_is_float(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(
            len(byte_data) == marshall.marshall_serialized_size(val), 
            "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m; sizes do not match: %v[byte_data] :: %v[size_of(%v)]\n", 
            len(byte_data), marshall.marshall_serialized_size(val), type_info_of(T)
        );
        deserialized: T = 0;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        if deserialized > val - 0.1 && deserialized < val + 0.1 {}
        else do assert_deserialization(err, val, deserialized);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");

    for _ in 0..<100 do test(f16le);
    fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f16le));
    for _ in 0..<100 do test(f32le);
    fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f32le));
    for _ in 0..<100 do test(f64le);
    fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f64le));

    // for _ in 0..<100 do test(f16be);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f16be));
    // for _ in 0..<100 do test(f32be);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f32be));
    // for _ in 0..<100 do test(f64be);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f64be));

    // for _ in 0..<100 do test(f16);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f16));
    // for _ in 0..<100 do test(f32);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f32));
    // for _ in 0..<100 do test(f64);
    // fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", #procedure, type_info_of(f64));

    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_bools :: proc() {
    test :: proc(b: bool, proc_name: string) {
        byte_data, err := marshall.serialize(b);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(b))
        deserialized := !b;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        assert(err == .None);
        assert(b == deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m bool\n", proc_name);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");

    test(false, #procedure);
    test(true, #procedure);

    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_runes :: proc() {
    test :: proc(r: rune, proc_name: string) {
        byte_data, err := marshall.serialize(r);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(r))
        deserialized: rune = 0;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        assert(err == .None);
        assert(r == deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m rune\n", proc_name);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");

    test('A', #procedure);
    test('Z', #procedure);
    test('#', #procedure);
    test('😊', #procedure);

    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_strings :: proc() {
    test_string :: proc(str: string, proc_name: string) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(str) == (len(byte_data) - 4) / 4);
        deserialized: string = "";
        err = marshall.deserialize(deserialized, byte_data);
        // fmt.printf("Official string: %v\nMarshalled: %v\n", str, deserialized);
        assert(err == .None);
        assert(str == deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m string\n", proc_name);
    }

    test_cstring :: proc(str: cstring, proc_name: string) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(str) == (len(byte_data) - 4) / 4);
        deserialized: cstring = "";
        err = marshall.deserialize(deserialized, byte_data);
        assert(err == .None);
        assert(str == deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m cstring\n", proc_name);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");

    test_string("Some String", #procedure);
    test_string("d4wad8wa48c48sa87 23qe12\n\t\r", #procedure);

    test_cstring("Some String", #procedure);
    test_cstring("d4wad8wa48c48sa87 23qe12\n\t\r", #procedure);

    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_arrays :: proc() {
    test_slices :: proc(slice: $T/[]$E, proc_name: string, eq_proc: #type proc(s1, s2: T)) {
        byte_data, err := marshall.serialize(slice);
        defer delete(byte_data);
        fmt.printf("%v\n\n", slice);
        assert(err == .None);
        deserialized: []E;
        defer delete(deserialized);
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        fmt.printf("Deserialization error: %v\nMarshalled: %v\n", err, deserialized);
        assert(err == .None);
        eq_proc(slice, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m slice\n", proc_name);
    }
    test_dyn_arrays :: proc(dyn_array: $T/[dynamic]$E, proc_name: string, eq_proc: #type proc(d1, d2: T)) {
        byte_data, err := marshall.serialize(dyn_array);
        defer delete(byte_data);
        fmt.assertf(err == .None, "Failed to serialize data: %v\n", err);
        deserialized: T = {};
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        fmt.assertf(err == .None, "Failed to deserialize data: %v\n", err);
        eq_proc(dyn_array, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m dyn_array\n", proc_name);
    }
    test_fixed_arrays :: proc(array: $T/[$N]$E, proc_name: string, eq_proc: #type proc(a1, a2: T)) {
        byte_data, err := marshall.serialize(dyn_array);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == len(dyn_array) * size_of(E));
        deserialized: T = {};
        err = marshall.deserialize(marshall.MARSHALL_ANY(&deserialized), byte_data);
        assert(err == .None);
        eq_proc(array, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m dyn_array\n", proc_name);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");
    // arbitrary
    {
        slice := make([]int, 10);
        for i in 0..<10 do slice[i] = rand.int_max(4329832);
        test_slices(slice, #procedure, proc(s1, s2: []int) {
            for val, idx in s1 {
                fmt.printf("%v \t %v\n", val, s2[idx]);
                assert(val == s2[idx]);
            }
        });
        delete(slice);
    }
    // indexable
    { // not going to work right now....
        slice := make([][]int, 10);
        for i in 0..<10 {
            slice[i] = make([]int, rand.int_max(9) + 1); // todo fix blank arrays
            for j in 0..<len(slice[i]) { 
                slice[i][j] = rand.int_max(4329832);
            }
        }
        test_slices(slice, #procedure, proc(s1, s2: [][]int) {
            assert(len(s1) == len(s2));
            for arr, i in s1 {
                assert(len(arr) == len(s2[i]));
                for val, j in arr {
                    assert(val == s2[i][j]);
                }
            }
        });
        delete(slice);
    }
    // indexable string
    {
        // slice := make([]string, 10);
        // for i in 0..<10 {
        //     characters := make([]byte, 100);
        //     for j in 0..<len(characters) {
        //         characters[j] = cast(byte)rand.float32_range(65, 90);
        //     }
        //     slice[i] = string(characters);
        //     delete(characters);
        // }
        // test_slices(slice, #procedure, proc(s1, s2: []string) {
        //     for val, idx in s1 {
        //         assert(val == s2[idx]);
        //     }
        // });
        // delete(slice);
    }
    // blank
    {
        // slice := make([]int, 0);
        // test_slices(slice, #procedure, proc(s1, s2: []int) {
        // });
        // delete(slice);
    }

    // arbitrary
    {
        dyn_array := make([dynamic]f32le);
        for i in 0..<10 do append(&dyn_array, cast(f32le)rand.float32_range(0, 1000000000));
        test_dyn_arrays(dyn_array, #procedure, proc(d1, d2: [dynamic]f32le) {
            for val, idx in d1 do assert(val == d2[idx]);
        });
        delete(dyn_array);
    }
    // indexable string
    {
        dyn_array := make([dynamic]string);
        for i in 0..<rand.int_max(20) + 1 {
            characters := make([]byte, rand.int_max(100) + 1);
            for j in 0..<len(characters) {
                characters[j] = cast(byte)rand.float32_range(65, 90);
            }
            append(&dyn_array, string(characters));
            delete(characters);
        }
        test_dyn_arrays(dyn_array, #procedure, proc(s1, s2: [dynamic]string) {
            for val, idx in s1 do assert(val == s2[idx]);
        });
        delete(dyn_array);
    }
    // blank
    {
        dyn_array := make([dynamic]int);
        test_dyn_arrays(dyn_array, #procedure, proc(d1, d2: [dynamic]int) {
            for val, idx in d1 do assert(val == d2[idx]);
        });
        delete(dyn_array);
    }

    {
        assert(false, "TODO fixed size arrays test");
    }
    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

test_pointers :: proc() {
    test_multi_pointers :: proc() {}
    test_pointers :: proc() {}
}

test_distincts :: proc() {
}

test_structs :: proc() {

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
    dummy_cstrings := [?]cstring {
        "hello",
        " world",
        "\n",
        "from",
        " marshall",
        " test!",
        "\n",
    };
    my_struct := Marshall_Test_Serialize_Struct {
        indent = {
            prop1 = 10,
            prop2 = "MyProp2Value",
            prop3 = &dummy_int,
        },
        val1 = raw_data(dummy_cstrings[:]),
        val2 = make_dynamic_array([dynamic]i32),
        val3 = ._2,
    };
    serialized, err := marshall.serialize(&my_struct);
    assert(err == .None, "Failed to serialize data!");
    my_struct_deserialized: Marshall_Test_Serialize_Struct;
    err = marshall.deserialize(&my_struct_deserialized, serialized);
    {
        assert(my_struct.indent.prop1 == my_struct_deserialized.indent.prop1);
        assert(my_struct.indent.prop2 == my_struct_deserialized.indent.prop2);
        assert(my_struct.indent.prop3^ == my_struct_deserialized.indent.prop3^);
        for index in 0..<len(dummy_cstrings) {
            assert(my_struct.val1[index] == my_struct_deserialized.val1[index]);
        }
        assert(len(my_struct.val2) == len(my_struct_deserialized.val2));
        assert(my_struct.val3 == my_struct_deserialized.val3);
    }

}

main :: proc() {

    test_ints();
    test_floats();
    test_bools();
    test_runes();
    test_strings();
    test_arrays();
    test_pointers();
    test_distincts();
    test_structs();

}