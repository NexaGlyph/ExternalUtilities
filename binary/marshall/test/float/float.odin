package float_test

import "base:intrinsics"

import "core:fmt"
import "core:math/rand"

import "nexa_external:binary/marshall"

run :: proc() {
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
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(val == deserialized, "\x1b[34mdeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %v :: %v", val, deserialized);
    }

    fmt.printf("\nBeginning [%s]\n", #procedure);
    fmt.printf("-----------------------------\n");

    for _ in 0..<100 do test(f16le);
    fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f16le));
    for _ in 0..<100 do test(f32le);
    fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f32le));
    for _ in 0..<100 do test(f64le);
    fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f64le));

    // for _ in 0..<100 do test(f16be);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f16be));
    // for _ in 0..<100 do test(f32be);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f32be));
    // for _ in 0..<100 do test(f64be);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f64be));

    // for _ in 0..<100 do test(f16);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f16));
    // for _ in 0..<100 do test(f32);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f32));
    // for _ in 0..<100 do test(f64);
    // fmt.printf("\t\x1b[32mPassed...\x1b[0m %v\n", type_info_of(f64));

    fmt.printf("-----------------------------\n");
    fmt.printf("Ending [%s]\n", #procedure);
}