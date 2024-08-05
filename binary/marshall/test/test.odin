//+build windows
package test

import bool_test        "bool"
import distinct_test    "distinct"
import float_test       "float"
import indexable_test   "indexable"
import int_test         "int"
import ptr_test         "ptr"
import rune_test        "rune"
import string_test      "string"
import struct_test      "struct"

main :: proc() {
    bool_test.run();
    distinct_test.run();
    float_test.run();
    indexable_test.run();
    int_test.run();
    ptr_test.run();
    rune_test.run();
    string_test.run();
    struct_test.run();
}