package indexable_test

import "core:fmt"
import "core:math/rand"

import "nexa_external:binary/marshall"

run :: proc() {
    test_slices :: proc(slice: $T/[]$E, proc_name: string, eq_proc: #type proc(s1, s2: T)) {
        byte_data, err := marshall.serialize(slice);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        deserialized: []E;
        defer delete(deserialized);
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        eq_proc(slice, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m slice\n", proc_name);
    }
    test_dyn_arrays :: proc(dyn_array: $T/[dynamic]$E, proc_name: string, eq_proc: #type proc(d1, d2: T)) {
        byte_data, err := marshall.serialize(dyn_array);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        deserialized: T = {};
        // deserialized := make(T, len(dyn_array));
        defer delete(deserialized);
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        eq_proc(dyn_array, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m dyn_array\n", proc_name);
    }
    test_fixed_arrays :: proc(array: $T/[$N]$E, proc_name: string, eq_proc: #type proc(a1, a2: [N]E)) {
        byte_data, err := marshall.serialize(array);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        deserialized: T = {};
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        eq_proc(array, deserialized);
        fmt.printf("%v\t\x1b[32mPassed...\x1b[0m fixed array\n", proc_name);
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
            slice[i] = make([]int, rand.int_max(9) + 1); // till this point, blank arrays are not checked -> avoiding it
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
        slice := make([]string, 10);
        runes := [?]byte{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };
        for i in 0..<10 {
            characters := make([]byte, 100);
            for j in 0..<len(characters) {
                characters[j] = rand.choice(runes[:]);
            }
            slice[i] = string(characters);
            fmt.printf("%v\t", slice[i]);
        }
        fmt.printf("%v\n", slice);
        test_slices(slice, #procedure, proc(s1, s2: []string) {
            for val, idx in s1 {
                fmt.assertf(val == s2[idx], "Values do not match! %s :: %s\n\ts1: %s;\n\ts2: %s\n", val, s2[idx], s1, s2);
            }
        });
        delete(slice);
    }
    // todo: fix blank
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
        }
        test_dyn_arrays(dyn_array, #procedure, proc(s1, s2: [dynamic]string) {
            for val, idx in s1 do fmt.assertf(val == s2[idx], "Values do not match! %s :: %s\n", s1, s2);
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

    // arbitrary
    {
        arr := [?]rune { '📷', '🦒', '🕵', '📮', '👺', '🔮', '🐎', '🏂', '🐒', };
        test_fixed_arrays(arr, #procedure, proc(a1, a2: [9]rune) {
            for val, idx in a1 do assert(val == a2[idx]);
        });
    }
    // indexables
    {
        rune_def := [?]rune { '📷', '🦒', '🕵', '📮', '👺', '🔮', '🐎', '🏂', '🐒', };
        arr := [7][]rune {};
        for i in 0..<7 {
            arr[i] = make([]rune, 9);
            copy(arr[i][:], rune_def[:]);
        }
        test_fixed_arrays(arr, #procedure, proc(a1, a2: [7][]rune) {
            for val, i in a1 {
                for v, j in val do assert(v == a2[i][j]);
            }
        });
    }
    // indexable string
    {
        // arr := [?]cstring {
        //     "helo",
        //     "\tfrom",
        //     "\rtesting\n",
        //     "strings!",
        // };
        // test_fixed_arrays(arr, #procedure, proc(a1, a2: [4]cstring) {
        //     for val, idx in a1 do fmt.assertf(val == a2[idx], "Failed to validate: %s :: %s", val, a2[idx]);
        // });
    }
    // blank
    {
        arr := [0]int {};
        test_fixed_arrays(arr, #procedure, proc(a1, a2: [0]int) {});
    }
    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}

