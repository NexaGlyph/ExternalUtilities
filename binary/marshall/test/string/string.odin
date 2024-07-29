package string_test

import "core:fmt"

import "nexa_external:binary/marshall"

run :: proc() {
    test_string :: proc(str: string) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(len(str) == (len(byte_data) - 4), "Failed to validate sizes: %d :: %d", len(str), len(byte_data));
        deserialized: string = "";
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(str == deserialized, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %s :: %s", str, deserialized);
        fmt.println("\t\x1b[32mPassed...\x1b[0m string");
    }

    test_cstring :: proc(str: cstring) {
        byte_data, err := marshall.serialize(str);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(len(str) == (len(byte_data) - 4), "Failed to validate sizes: %d :: %d", len(str), len(byte_data));
        deserialized: cstring = "";
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(str == deserialized, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %s :: %s", str, deserialized);
        fmt.println("\t\x1b[32mPassed...\x1b[0m cstring");
    }

    fmt.println("\nBeginning [STRING]");
    fmt.println("-----------------------------");

    test_string("Some String");
    test_string("d4wad8wa48c48sa87 23qe12\n\t\r");

    test_cstring("Some String");
    test_cstring("d4wad8wa48c48sa87 23qe12\n\t\r");

    fmt.println("-----------------------------\n");
    fmt.println("Ending [STRING]\n");
}