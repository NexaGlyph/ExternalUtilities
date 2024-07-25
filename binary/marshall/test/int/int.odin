package int_test

import "base:intrinsics"

import "core:fmt"
import "core:math/rand"

import "nexa_external:binary/marshall"

run :: proc() {
    test :: proc($T: typeid) 
        where intrinsics.type_is_integer(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        _test(val);
    }
    test_s :: proc($T: typeid) 
        where intrinsics.type_is_integer(T)
    {
        val: T = cast(T)(rand.float64() * (1 << size_of(T)));
        val *= -1;
        _test(val);
    }
    _test :: proc(val: $T) 
        where intrinsics.type_is_integer(T)
    {
        byte_data, err := marshall.serialize(val);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(size_of(val) == len(byte_data), "Failed to validate sizes: %d :: %d", size_of(val) == len(byte_data));
        deserialized: T = 0;
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(val == deserialized, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %v :: %v", val, deserialized);
        fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(T));
    }

    fmt.println("\nBeginning [INT_TEST]");
    fmt.println("-----------------------------");
    test_s(i16le);
    test_s(i32le);
    test_s(i64le);
    test_s(i16be);
    test_s(i32be);
    test_s(i64be);
    test_s(i8);
    test_s(i16);
    test_s(i32);
    test_s(i64);
    test_s(int); // same as i64...

    test(u16le);
    test(u32le);
    test(u64le);
    test(u16be);
    test(u32be);
    test(u64be);
    test(u8);
    test(u16);
    test(u32);
    test(u64);
    test(uint); // same as u64...
    fmt.println("-----------------------------");
    fmt.println("Ending [INT_TEST]");
}

