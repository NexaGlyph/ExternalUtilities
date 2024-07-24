package rune_test

import "core:fmt"

import "nexa_external:binary/marshall"

run :: proc() {
    test :: proc(r: rune) {
        byte_data, err := marshall.serialize(r);
        defer delete(byte_data);
        fmt.assertf(err == .None, "\x1b[33mSerialization\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(len(byte_data) == size_of(r), "Failed to validate sizes: %d :: %d", len(byte_data), size_of(r));
        deserialized: rune = 0;
        err = marshall.deserialize(deserialized, byte_data);
        fmt.assertf(err == .None, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m with error: \x1b[31m%v\x1b[0m\n", err);
        fmt.assertf(r == deserialized, "\x1b[34mDeserialiation\x1b[0m \x1b[31mfailed\x1b[0m; two conflicting values: %v :: %v", r, deserialized);
        fmt.println("\t\x1b[32mPassed...\x1b[0m rune");
    }

    fmt.println("\nBeginning [RUNE]");
    fmt.println("-----------------------------");

    test('A');
    test('Z');
    test('#');
    test('😊');

    fmt.println("-----------------------------");
    fmt.println("Ending [RUNE]");
}