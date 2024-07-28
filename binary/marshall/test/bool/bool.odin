package bool_test

import "core:fmt"

import "nexa_external:binary/marshall"

run :: proc() {
    test :: proc(b: bool) {
        byte_data, err := marshall.serialize(b);
        defer delete(byte_data);
        assert(err == .None);
        assert(len(byte_data) == size_of(b))
        deserialized := !b;
        err = marshall.deserialize(deserialized, byte_data);
        assert(err == .None);
        assert(b == deserialized);
        fmt.printf("\t\x1b[32mPassed...\x1b[0m bool\n");    
    }

    fmt.println("\nBeginning [BOOL]");
    fmt.println("-----------------------------");

    test(false);
    test(true);

    fmt.println("-----------------------------");
    fmt.println("Ending [BOOL]");
}