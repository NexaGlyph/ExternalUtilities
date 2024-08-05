package ptr_test

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"

import "nexa_external:binary/marshall"

run :: proc() {
    test_ptr :: proc(val: $T/^$E) 
        where intrinsics.type_is_pointer(T)
    {
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        ti := type_info_of(T);
        fmt.assertf(
            len(byte_data) == marshall.marshall_serialized_size_t(ti),
            "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m; sizes do not match: %v[byte_data] :: %v[size_of(%v)]\n", 
            len(byte_data), marshall.marshall_serialized_size_t(ti), ti,
        );
        deserialized := new(E);
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(val^ == deserialized^, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %v :: %v", val, deserialized);
        fmt.printf("\x1b[32m\tPassed...\x1b[0m pointer\n");
    }

    test_multi_ptr :: proc(val: $T) 
        where intrinsics.type_is_multi_pointer(T)
    {
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(
            len(byte_data) == marshall.marshall_serialized_size(val),
            "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m; sizes do not match: %v[byte_data] :: %v[size_of(%v)]\n", 
            len(byte_data), marshall.marshall_serialized_size(val), type_info_of(T)
        );
        deserialized := make_multi_pointer(T, 1);
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(val[0] == deserialized[0], "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %v :: %v", val, deserialized);
        fmt.printf("\x1b[32m\tPassed...\x1b[0m multi-pointer\n");
    }

    fmt.println("\nBeginning [PTR]");
    fmt.println("-----------------------------");
    // pointers
    {
        my_float_ptr := new(f32le);
        my_float_ptr^ = cast(f32le)rand.float32();
        test_ptr(my_float_ptr);
        free(my_float_ptr);
    }
    // multi pointers
    {
        my_float_ptr := make_multi_pointer([^]f32le, 1); // cannot deduce the size by marshall, can only be of size 1
        my_float_ptr[0] = cast(f32le)rand.float32();
        test_multi_ptr(my_float_ptr);
        free(my_float_ptr);
    }
    fmt.println("-----------------------------");
    fmt.println("Ending [PTR]");
}