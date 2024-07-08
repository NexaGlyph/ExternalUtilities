//+build windows
package test

import "base:intrinsics"

import "core:fmt"
// import "core:strings"
// import "core:io"
import "core:math/rand"

import marshall "../"

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
    val4: #type proc() -> bool, // not going to be marshalled
}

test_ints :: proc() {
    test :: proc($T: typeid, proc_name: string) 
        where intrinsics.type_is_integer(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(val))
        marshalled: T = 0;
        err = marshall.deserialize(marshalled, byte_data);
        assert(err == .None);
        assert(val == marshalled);
        fmt.printf("%s\t\x1b[32mPassed...\x1b[0m %v\n", proc_name, type_info_of(T));
    }

    test(i16le, #procedure);
    test(i32le, #procedure);
    test(i64le, #procedure);
    test(u16le, #procedure);
    test(u32le, #procedure);
    test(u64le, #procedure);

    test(i16be, #procedure);
    test(i32be, #procedure);
    test(i64be, #procedure);
    test(u16be, #procedure);
    test(u32be, #procedure);
    test(u64be, #procedure);

    test(u8,   #procedure);
    test(u16,  #procedure);
    test(u32,  #procedure);
    test(u64,  #procedure);
    test(uint, #procedure); // same as u64...
    test(i8,   #procedure);
    test(i16,  #procedure);
    test(i32,  #procedure);
    test(i64,  #procedure);
    test(int,  #procedure); // same as i64...
}

test_floats :: proc() {
    test :: proc($T: typeid)
        where intrinsics.type_is_float(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(val))
        marshalled: T = 0;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        assert(err == .None);
        fmt.printf("%v : %v", val, marshalled);
        assert(val == marshalled);
        fmt.printf("\x1b[32mPassed...\x1b[0m %v\n", type_info_of(T));
    }

    test(f16le);
    test(f32le);

    test(f16be);
    test(f32be);

    test(f16);
    test(f32);
}

test_bools :: proc() {
    test :: proc(b: bool, proc_name: string) {
        byte_data, err := marshall.serialize(b);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(b))
        marshalled := !b;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        assert(err == .None);
        assert(b == marshalled);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m bool\n", proc_name);
    }

    test(false, #procedure);
    test(true, #procedure);
}

test_runes :: proc() {
    test :: proc(r: rune, proc_name: string) {
        byte_data, err := marshall.serialize(r);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(r))
        marshalled: rune = 0;
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        assert(err == .None);
        assert(r == marshalled);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m rune\n", proc_name);
    }

    test('A', #procedure);
    test('Z', #procedure);
    test('#', #procedure);
    test('😊', #procedure);
}

test_strings :: proc() {
    test_string :: proc(str: string, proc_name: string) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(str) == (len(byte_data) - 4) / 4);
        marshalled: string = "";
        err = marshall.deserialize(marshalled, byte_data);
        fmt.printf("Official string: %v\nMarshalled: %v\n", str, marshalled);
        assert(err == .None);
        assert(str == marshalled);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m string\n", proc_name);
    }

    test_cstring :: proc(str: cstring, proc_name: string) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(str) == (len(byte_data) - 4) / 4);
        marshalled: cstring = "";
        err = marshall.deserialize(marshalled, byte_data);
        assert(err == .None);
        assert(str == marshalled);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m cstring\n", proc_name);
    }

    test_string("Some String", #procedure);
    test_string("d4wad8wa48c48sa87 23qe12\n\t\r", #procedure);

    test_cstring("Some String", #procedure);
    test_cstring("d4wad8wa48c48sa87 23qe12\n\t\r", #procedure);
}

test_arrays :: proc() {
    test_slices :: proc(slice: $T/[]$E, proc_name: string, eq_proc: #type proc(s1, s2: T)) {
        byte_data, err := marshall.serialize(slice);
        defer delete(byte_data);
        fmt.printf("%v\n\n", slice);
        assert(err == .None);
        // marshalled := make([]E, len(slice));
        marshalled: []E;
        defer delete(marshalled);
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        fmt.printf("Deserialization error: %v\nMarshalled: %v\n", err, marshalled);
        assert(err == .None);
        eq_proc(slice, marshalled);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m slice\n", proc_name);
    }
    test_dyn_arrays :: proc(dyn_array: $T/[dynamic]$E, proc_name: string) {
        byte_data, err := marshall.serialize(dyn_array);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == len(dyn_array) * size_of(E));
        marshalled: T = {};
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        assert(err == .None);
        if !intrinsics.type_is_struct(E) {
            for val, idx in dyn_array do assert(val == marshalled[idx]);
        } else {
            assert(false)
        }
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m dyn_array\n", proc_name);
    }
    test_fixed_arrays :: proc(array: $T/[$N]$E, proc_name: string) {
        byte_data, err := marshall.serialize(dyn_array);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == len(dyn_array) * size_of(E));
        marshalled: T = {};
        err = marshall.deserialize(marshall.MARSHALL_ANY(&marshalled), byte_data);
        assert(err == .None);
        if !intrinsics.type_is_struct(E) {
            for val, idx in dyn_array do assert(val == marshalled[idx]);
        } else {
            assert(false)
        }
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m dyn_array\n", proc_name);
    }

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
    { // not going to work right now....
        // slice := make([][]int, 10);
        // for i in 0..<10 {
        //     slice[i] = make([]int, rand.int_max(9) + 1); // todo fix blank arrays
        //     for j in 0..<len(slice[i]) { 
        //         slice[i][j] = rand.int_max(4329832);
        //     }
        // }
        // test_slices(slice, #procedure, proc(s1, s2: [][]int) {
        //     assert(len(s1) == len(s2));
        //     for arr, i in s1 {
        //         assert(len(arr) == len(s2[i]));
        //         for val, j in arr {
        //             assert(val == s2[i][j]);
        //         }
        //     }
        // });
        // delete(slice);
    }
    {
        slice := make([]string, 10);
        for i in 0..<10 {
            characters := make([]byte, 100);
            for j in 0..<len(characters) {
                characters[j] = cast(byte)rand.float32_range(65, 90);
            }
            slice[i] = string(characters);
            delete(characters);
        }
        test_slices(slice, #procedure, proc(s1, s2: []string) {
            for val, idx in s1 {
                assert(val == s2[idx]);
            }
        });
        delete(slice);
    }
    {
        slice := make([]int, 0);
        test_slices(slice, #procedure, proc(s1, s2: []int) {
        });
        delete(slice);
    }

    {
        assert(false, "TODO dyn arrays test");
    }
    {
        assert(false, "TODO fixed size arrays test");
    }
}

test_pointers :: proc() {
    test_multi_pointers :: proc() {}
    test_pointers :: proc() {}
}

main :: proc() {

    // test arbitrary values
    test_ints();
    // todo test_floats();
    test_bools();
    test_runes();
    test_strings();
    test_arrays();

    // test structs
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