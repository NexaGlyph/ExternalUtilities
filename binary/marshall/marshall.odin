//+build windows
package marshall

import "base:runtime"
import "base:intrinsics"

import "core:fmt"
import "core:mem"
import "core:math"
import "core:unicode/utf8"
import "core:reflect"
import "core:strings"

import binary "../"

Marshall_Error :: enum {
    None,                // no error

    InvalidType,         // unsupported type for marshalling/unmarshalling
    TypeMismatch,        // type mismatch during unmarshalling
    OutOfMemory,         // not enough memory for buffers
    BufferOverflow,      // buffer is not large enough
    WriteError,          // error during writing
    ReadError,           // error during reading
    InvalidEndianness,   // unsupported endianness
    ArraySizeMismatch,   // array size mismatch
    StringTooLong,       // string length exceeds limits
    StringBufferSizeMismatch, // expected size of the string buffer is not divisible by 4 (used for runes)
    UnknownError         // unknown error
}

/**
 * @brief helper functions for data serialization
 */

/* INTEGER */
interpret_int_be_data :: proc(integer_data: $INT_T) -> []byte 
    where intrinsics.type_is_integer(INT_T) 
{
    // fmt.printf("Size: %v\nType: %v\n", size_of(INT_T), type_info_of(INT_T));
    byte_data := make([]byte, size_of(INT_T));
    byte_index: u8 = (size_of(INT_T) - 1) * 8;
    for i in 0..<size_of(INT_T) {
        byte_data[i] = byte(integer_data >> byte_index);
        byte_index -= 8;
    }
    return byte_data;
}
interpret_int_le_data :: proc(integer_data: $INT_T) -> []byte 
    where intrinsics.type_is_integer(INT_T) 
{
    // fmt.printf("Size: %v\nType: %v\n", size_of(INT_T), type_info_of(INT_T));
    byte_data := make([]byte, size_of(INT_T));
    byte_index: u8 = 0;
    for i in 0..<size_of(INT_T) {
        byte_data[i] = byte(integer_data >> byte_index);
        byte_index += 8;
    }
    return byte_data;
}
when ODIN_ENDIAN == .Big {
    interpret_int_data :: interpret_int_be_data;
} else {
    interpret_int_data :: interpret_int_le_data;
}
/*! INTEGER */
/* FLOAT */
FLOAT_PRECISION :: 5; // signifies how many digits after 0 are going to be written
interpret_float_le_data   :: proc { interpret_float16_le_data, interpret_float32_le_data, interpret_float64_le_data }
interpret_float16_le_data :: proc(float_data: f16le) -> []byte {
    byte_data := make([]byte, size_of(f16le));
    float_bits := transmute(u16le)(float_data * math.pow(f16le(10), FLOAT_PRECISION));
    for i: u8 = 0; i < size_of(f16le); i += 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float32_le_data :: proc(float_data: f32le) -> []byte {
    byte_data := make([]byte, size_of(f32le));
    float_bits := transmute(u32le)(float_data * math.pow(f32le(10), FLOAT_PRECISION));
    for i: u8 = 0; i < size_of(f32le); i += 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float64_le_data :: proc(float_data: f64le) -> []byte {
    byte_data := make([]byte, size_of(f64le));
    float_bits := transmute(u64le)(float_data * math.pow(f64le(10), FLOAT_PRECISION));
    for i: u8 = 0; i < size_of(f64le); i += 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}

interpret_float_be_data   :: proc { interpret_float16_be_data, interpret_float32_be_data, interpret_float64_be_data }
interpret_float16_be_data :: proc(float_data: f16be) -> []byte {
    byte_data := make([]byte, size_of(f16be));
    float_bits := transmute(u16be)(float_data * math.pow(f16be(10), FLOAT_PRECISION));
    for i: u8 = size_of(f16be); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float32_be_data :: proc(float_data: f32be) -> []byte {
    byte_data := make([]byte, size_of(f32be));
    float_bits := transmute(u32be)(float_data * math.pow(f32be(10), FLOAT_PRECISION));
    for i: u8 = size_of(f32be); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float64_be_data :: proc(float_data: f64be) -> []byte {
    byte_data := make([]byte, size_of(f64be));
    float_bits := transmute(u64be)(float_data * math.pow(f64be(10), FLOAT_PRECISION));
    for i: u8 = size_of(f64be); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
when ODIN_ENDIAN == .Big {
    interpret_float_data :: interpret_float_be_data;
} else {
    interpret_float_data :: interpret_float_le_data;
}
/*! FLOAT */
/* STRING */
/**
 * @brief this function assumes that strings contain utf-8 characters by default and does not care about "padding" or some special compressions so each character is of size "size_of(rune)" (which is 4 bytes...)
 * @note first 4 bytes is not a character but the string length (this is useful for RW I/O)
 */
interpret_string :: proc(str: string) -> ([]byte, Marshall_Error) {
    // write string length as u32
    if len(str) > (1 << (size_of(u32) * 8)) do return nil, .StringTooLong;
    byte_data := make([]byte, 4 + len(str) * 4);
    {
        bytes := interpret_int_data(u32(len(str)));
        copy_slice(byte_data[:4], bytes);
        delete(bytes);
    }
    for character, index in str {
        int_data := interpret_int_data(cast(i32)character);
        copy_slice(byte_data[(index + 1) * 4 : (index + 2) * 4], int_data);
        delete(int_data);
    }
    return byte_data, .None;
}
interpret_string_null_terminated :: proc(str: cstring) -> ([]byte, Marshall_Error) {
    return interpret_string(strings.clone_from_cstring(str));
}
/*! STRING */
/* ARRAY */
interpret_array :: proc(arr: any, v: runtime.Type_Info_Array) -> (byte_data: []byte, err: Marshall_Error) {
    byte_data_temp := make([dynamic][^]byte);
    element_size: u32 = 0;
    byte_data_len: u32 = 0;
    for it := 0; it < v.count; {
        val, idx, fine := reflect.iterate_array(arr, &it);
        if !fine do break;

        byte_array := serialize(val) or_return;
        defer delete(byte_array);

        append(&byte_data_temp, intrinsics.alloca(len(byte_array), align_of(byte)));
        mem.copy(byte_data_temp[idx], raw_data(byte_array), len(byte_array));

        element_size = u32(len(byte_array));
        byte_data_len += element_size;
    }

    byte_data = make([]byte, byte_data_len);
    prev_pos: u32 = 0;
    for data in byte_data_temp {
        mem.copy(raw_data(byte_data[prev_pos:prev_pos + element_size]), data, int(element_size));
        prev_pos += element_size;
    }
    return;
}

interpret_slice :: proc() {

}
/*! ARRAY */
/* STRUCT */
interpret_struct :: proc(base_data: any, v: runtime.Type_Info_Struct) -> (byte_data: []byte, err: Marshall_Error) {

    StructTempData :: struct {
        data: [^]byte,
        offset: int,
    }

    byte_data_temp := make_dynamic_array_len([dynamic]StructTempData, len(v.offsets));
    byte_data_size_final := u32(0);
    for offset, index in v.offsets {
        if v.tags[index] == "NexaTag_Marshallable" {
            byte_array := serialize(uintptr(base_data.data) + offset) or_return;
            defer delete(byte_array);
            append(&byte_data_temp, StructTempData{ 
                data = intrinsics.alloca(len(byte_array), align_of(byte)),
                offset = int(offset),
            });
            mem.copy(byte_data_temp[index].data, raw_data(byte_array), len(byte_array));
            byte_data_size_final += u32(len(byte_array));
        }
    }
    byte_data = make([]byte, byte_data_size_final);
    prev_pos := 0;
    for struct_data in byte_data_temp {
        mem.copy(raw_data(byte_data[prev_pos:prev_pos + struct_data.offset]), struct_data.data, struct_data.offset);
        prev_pos += struct_data.offset;
    }
    return;
}
/*! STRUCT */


/**
 * @brief function that takes any data and returns its binary form
 */
serialize :: proc(data: any) -> ([]byte, Marshall_Error) {
    type_info := runtime.type_info_base(type_info_of(data.id));
	base_data := any{data.data, type_info.id}

    if reflect.is_struct(type_info) {
        fmt.println("Type is struct!");
        return nil, .None;
    } else {
        switch v in type_info.variant {
            case runtime.Type_Info_Named: 
                return nil, .UnknownError;

            case runtime.Type_Info_Integer:
                switch integer_data in base_data {
                    case i8:      return interpret_int_data(integer_data), .None;
                    case i16:     return interpret_int_data(integer_data), .None;
                    case i32:     return interpret_int_data(integer_data), .None;
                    case i64:     return interpret_int_data(integer_data), .None;
                    case int:     return interpret_int_data(integer_data), .None;
                    case u8:      return interpret_int_data(integer_data), .None;
                    case u16:     return interpret_int_data(integer_data), .None;
                    case u32:     return interpret_int_data(integer_data), .None;
                    case u64:     return interpret_int_data(integer_data), .None;
                    case uint:    return interpret_int_data(integer_data), .None;

                    case i16le:   return interpret_int_le_data(integer_data), .None;
                    case i32le:   return interpret_int_le_data(integer_data), .None;
                    case i64le:   return interpret_int_le_data(integer_data), .None;
                    case u16le:   return interpret_int_le_data(integer_data), .None;
                    case u32le:   return interpret_int_le_data(integer_data), .None;
                    case u64le:   return interpret_int_le_data(integer_data), .None;

                    case i16be:   return interpret_int_be_data(integer_data), .None;
                    case i32be:   return interpret_int_be_data(integer_data), .None;
                    case i64be:   return interpret_int_be_data(integer_data), .None;
                    case u16be:   return interpret_int_be_data(integer_data), .None;
                    case u32be:   return interpret_int_be_data(integer_data), .None;
                    case u64be:   return interpret_int_be_data(integer_data), .None;

                    case i128:    return nil, .InvalidType;
                    case u128:    return nil, .InvalidType;
                    case u128le:  return nil, .InvalidType;
                    case u128be:  return nil, .InvalidType;
                    case uintptr: return nil, .InvalidType;
                }

            case runtime.Type_Info_Rune:
                return interpret_int_data(cast(i32)base_data.(rune)), .None;

            case runtime.Type_Info_Float:
                switch float_data in base_data {
                    // case f16: return interpret_float_data(float_data), .None;
                    // case f32: return interpret_float_data(float_data), .None;
                    // case f64: return interpret_float_data(float_data), .None;

                    case f16le: return interpret_float_le_data(float_data), .None;
                    case f32le: return interpret_float_le_data(float_data), .None;
                    case f64le: return interpret_float_le_data(float_data), .None;

                    case f16be: return interpret_float_be_data(float_data), .None;
                    case f32be: return interpret_float_be_data(float_data), .None;
                    case f64be: return interpret_float_be_data(float_data), .None;
                }

            case runtime.Type_Info_Complex: // todo
                return nil, .InvalidType;

            case runtime.Type_Info_Quaternion: // todo
                return nil, .InvalidType;

            case runtime.Type_Info_String:
                switch string_data in base_data {
                    case string:  return interpret_string(string_data);
                    case cstring: return interpret_string_null_terminated(string_data);
                }

            case runtime.Type_Info_Boolean:
                // we are going to treat boolean as just u8(0) or u8(1)
                return interpret_int_data(base_data.(bool) == true ? u8(1) : u8(0)), .None;

            case runtime.Type_Info_Any:
                fmt.println("\x1b[32mIf you wanted to write 'any', you may try to set 'forced' to true\x1b[0m");
                return nil, .InvalidType;

            case runtime.Type_Info_Type_Id:
                return nil, .InvalidType;

            case runtime.Type_Info_Pointer: // todo
                return serialize(base_data.data);

            case runtime.Type_Info_Multi_Pointer: // todo
                return nil, .InvalidType;

            case runtime.Type_Info_Procedure:
                return nil, .InvalidType;

            case runtime.Type_Info_Array:
                if v.count > 0 do return interpret_array(base_data, v);

            case runtime.Type_Info_Enumerated_Array: // todo
                return nil, .InvalidType;

            case runtime.Type_Info_Dynamic_Array: // todo
                dyn_arr := cast(^runtime.Raw_Dynamic_Array)base_data.data;
                if dyn_arr.len > 0 do return interpret_array(base_data, {
                    v.elem,
                    v.elem_size,
                    dyn_arr.len,
                });

            case runtime.Type_Info_Slice: // todo
                slice := cast(^runtime.Raw_Slice)base_data.data;
                if slice.len > 0 do return interpret_array(base_data, {
                    v.elem,
                    v.elem_size,
                    slice.len,
                });

            case runtime.Type_Info_Parameters:
                return nil, .InvalidType;

            case runtime.Type_Info_Struct:
                return interpret_struct(base_data, v);

            case runtime.Type_Info_Union:
                return nil, .InvalidType;

            case runtime.Type_Info_Enum: // todo
                return serialize({ base_data.data, v.base.id });

            case runtime.Type_Info_Map:
                return nil, .InvalidType;

            case runtime.Type_Info_Bit_Set:
                return nil, .InvalidType;

            case runtime.Type_Info_Simd_Vector:
                return nil, .InvalidType;

            case runtime.Type_Info_Relative_Pointer:
                return nil, .InvalidType;

            case runtime.Type_Info_Relative_Multi_Pointer:
                return nil, .InvalidType;

            case runtime.Type_Info_Matrix:
                return nil, .InvalidType;

            case runtime.Type_Info_Soa_Pointer:
                return nil, .InvalidType;
        }
    }
    return nil, .UnknownError;
}


/**
 * @brief helper functions for data serialization
 */

/* INTEGER */ 
interpret_bytes_to_int_le_data :: proc(val: any, bytes: []byte) -> Marshall_Error {
    switch integer_data in val {
        case ^i8:
            data := cast(^i8)val.data; // todo overflow check
            data^ = i8(bytes[0]);

        case ^i16:
            data := cast(^i16)val.data;
            data^ = i16(bytes[1]) << 8 | i16(bytes[0]);

        case ^i32:
            data := cast(^i32)val.data;
            data^ = i32(bytes[3]) << 24 | i32(bytes[2]) << 16 | i32(bytes[1]) << 8 | i32(bytes[0]);

        case ^i64:
            data := cast(^i64)val.data;
            data^ = (
                i64(bytes[7]) << 56 | 
                i64(bytes[6]) << 48 |
                i64(bytes[5]) << 40 | 
                i64(bytes[4]) << 32 | 
                i64(bytes[3]) << 24 |
                i64(bytes[2]) << 16 |
                i64(bytes[1]) <<  8 |
                i64(bytes[0]));

        case ^i16le:
            data := cast(^i16le)val.data;
            data^ = i16le(bytes[1]) << 8 | i16le(bytes[0]);

        case ^i32le:
            data := cast(^i32le)val.data;
            data^ = i32le(bytes[3]) << 24 | i32le(bytes[2]) << 16 | i32le(bytes[1]) << 8 | i32le(bytes[0]);

        case ^i64le:
            data := cast(^i64le)val.data;
            data^ = (
                i64le(bytes[7]) << 56 | 
                i64le(bytes[6]) << 48 |
                i64le(bytes[5]) << 40 | 
                i64le(bytes[4]) << 32 | 
                i64le(bytes[3]) << 24 |
                i64le(bytes[2]) << 16 |
                i64le(bytes[1]) <<  8 |
                i64le(bytes[0]));

        case ^int:
            data := cast(^int)val.data;
            data^ = (
                int(bytes[7]) << 56 | 
                int(bytes[6]) << 48 |
                int(bytes[5]) << 40 | 
                int(bytes[4]) << 32 | 
                int(bytes[3]) << 24 |
                int(bytes[2]) << 16 |
                int(bytes[1]) <<  8 |
                int(bytes[0]));

        case ^u8:
            data := cast(^u8)val.data; // todo overflow check
            data^ = bytes[0];

        case ^u16:
            data := cast(^u16)val.data;
            data^ = u16(bytes[1]) << 8 | u16(bytes[0]);

        case ^u32:
            data := cast(^u32)val.data;
            data^ = u32(bytes[3]) << 24 | u32(bytes[2]) << 16 | u32(bytes[1]) << 8 | u32(bytes[0]);

        case ^u64:
            data := cast(^u64)val.data;
            data^ = (
                u64(bytes[7]) << 56 | 
                u64(bytes[6]) << 48 |
                u64(bytes[5]) << 40 | 
                u64(bytes[4]) << 32 | 
                u64(bytes[3]) << 24 |
                u64(bytes[2]) << 16 |
                u64(bytes[1]) <<  8 |
                u64(bytes[0]));

        case ^u16le:
            data := cast(^u16le)val.data;
            data^ = u16le(bytes[1]) << 8 | u16le(bytes[0]);

        case ^u32le:
            data := cast(^u32le)val.data;
            data^ = u32le(bytes[3]) << 24 | u32le(bytes[2]) << 16 | u32le(bytes[1]) << 8 | u32le(bytes[0]);

        case ^u64le:
            data := cast(^u64le)val.data;
            data^ = (
                u64le(bytes[7]) << 56 | 
                u64le(bytes[6]) << 48 |
                u64le(bytes[5]) << 40 | 
                u64le(bytes[4]) << 32 | 
                u64le(bytes[3]) << 24 |
                u64le(bytes[2]) << 16 |
                u64le(bytes[1]) <<  8 |
                u64le(bytes[0]));

        case ^uint:
            data := cast(^uint)val.data;
            data^ = (
                uint(bytes[7]) << 56 | 
                uint(bytes[6]) << 48 |
                uint(bytes[5]) << 40 | 
                uint(bytes[4]) << 32 | 
                uint(bytes[3]) << 24 |
                uint(bytes[2]) << 16 |
                uint(bytes[1]) <<  8 |
                uint(bytes[0]));


        case:
            return .InvalidType;
    }

    return .None;
}
interpret_bytes_to_int_be_data :: proc(val: any, bytes: []byte) -> Marshall_Error {
    switch integer_data in val {
        case ^i16be:
            data := cast(^i16be)val.data;
            data^ = i16be(bytes[1]) | i16be(bytes[0]) << 8;

        case ^i32be:
            data := cast(^i32be)val.data;
            data^ = i32be(bytes[3]) | i32be(bytes[2]) << 8 | i32be(bytes[1]) << 16 | i32be(bytes[0]) << 24;

        case ^i64be:
            data := cast(^i64be)val.data;
            data^ = (
                i64be(bytes[7])       | 
                i64be(bytes[6]) << 8  |
                i64be(bytes[5]) << 16 | 
                i64be(bytes[4]) << 24 | 
                i64be(bytes[3]) << 32 |
                i64be(bytes[2]) << 40 |
                i64be(bytes[1]) << 48 |
                i64be(bytes[0]) << 56);

        case ^int:
            data := cast(^int)val.data;
            data^ = (
                int(bytes[7])       | 
                int(bytes[6]) << 8  |
                int(bytes[5]) << 16 | 
                int(bytes[4]) << 24 | 
                int(bytes[3]) << 32 |
                int(bytes[2]) << 40 |
                int(bytes[1]) << 48 |
                int(bytes[0]) << 56);

        case ^u16be:
            data := cast(^u16be)val.data;
            data^ = u16be(bytes[1]) | u16be(bytes[0]) >> 8;

        case ^u32be:
            data := cast(^u32be)val.data;
            data^ = u32be(bytes[3]) | u32be(bytes[2]) >> 8 | u32be(bytes[1]) >> 16 | u32be(bytes[0]) >> 24;

        case ^u64be:
            data := cast(^u64be)val.data;
            data^ = (
                u64be(bytes[7])       | 
                u64be(bytes[6]) << 8  |
                u64be(bytes[5]) << 16 | 
                u64be(bytes[4]) << 24 | 
                u64be(bytes[3]) << 32 |
                u64be(bytes[2]) << 40 |
                u64be(bytes[1]) << 48 |
                u64be(bytes[0]) << 56);

        case ^uint:
            data := cast(^uint)val.data;
            data^ = (
                uint(bytes[7])       | 
                uint(bytes[6]) << 8  |
                uint(bytes[5]) << 16 | 
                uint(bytes[4]) << 24 | 
                uint(bytes[3]) << 32 |
                uint(bytes[2]) << 40 |
                uint(bytes[1]) << 48 |
                uint(bytes[0]) << 56);

        case:
            return .InvalidType;
    }

    return .None;
}
when ODIN_ENDIAN == .Big {
    interpret_bytes_to_int_data :: interpret_bytes_to_int_be_data;
} else {
    interpret_bytes_to_int_data :: interpret_bytes_to_int_le_data;
}
/*! INTEGER */ 
/* FLOAT */
interpret_bytes_to_float_le_data :: proc(val: any, bytes: []byte) -> Marshall_Error {
    switch float_data in val {
        case ^f16le:
            data := cast(^f16le)val.data;
            data^ = cast(f16le)(u16le(bytes[1]) | u16le(bytes[0]) << 8);

        case ^f32le:
            data := cast(^f32le)val.data;
            data^ = cast(f32le)(u32le(bytes[3]) | u32le(bytes[2]) << 8 | u32le(bytes[1]) << 16 | u32le(bytes[0]) << 24) / math.pow(f32le(10), FLOAT_PRECISION);

        case ^f64le:
            data := cast(^f64le)val.data;
            data^ = f64le(
                u64le(bytes[7]) << 56 | 
                u64le(bytes[6]) << 48 |
                u64le(bytes[5]) << 40 | 
                u64le(bytes[4]) << 32 | 
                u64le(bytes[3]) << 24 |
                u64le(bytes[2]) << 16 |
                u64le(bytes[1]) <<  8 |
                u64le(bytes[0])) / math.pow(f64le(10), FLOAT_PRECISION);

        case:
            return .InvalidType;

    }

    return .None;
}
interpret_bytes_to_float_be_data :: proc(val: any, bytes: []byte) -> Marshall_Error {
    switch float_data in val {
        case ^f16be:
            data := cast(^f16be)val.data;
            data^ = cast(f16be)(u16be(bytes[1]) << 8 | u16be(bytes[0])) / math.pow(f16be(10), FLOAT_PRECISION);

        case ^f32be:
            data := cast(^f32be)val.data;
            data^ = cast(f32be)(u32be(bytes[3]) << 24 | u32be(bytes[2]) << 16 | u32be(bytes[1]) << 8 | u32be(bytes[0])) / math.pow(f32be(10), FLOAT_PRECISION);

        case ^f64be:
            data := cast(^f64be)val.data;
            data^ = f64be(
                u64be(bytes[7]) << 8  | 
                u64be(bytes[6]) << 16 |
                u64be(bytes[5]) << 24 | 
                u64be(bytes[4]) << 32 | 
                u64be(bytes[3]) << 40 |
                u64be(bytes[2]) << 48 |
                u64be(bytes[1]) << 56 |
                u64be(bytes[0])) / math.pow(f64be(10), FLOAT_PRECISION);

        case:
            return .InvalidType;
    }
    return .None;
}
when ODIN_ENDIAN == .Big {
    interpret_bytes_to_float_data :: interpret_bytes_to_int_be_data;
} else {
    interpret_bytes_to_float_data :: interpret_bytes_to_int_le_data;
}
/*! FLOAT */
/* STRING */
/**
 * @note this functions assumes that the first 4 bytes of the 'data' param is string's length!
 */
interpret_bytes_to_string :: proc(data: []byte) -> (string, Marshall_Error) {
    if len(data) % 4 != 0 do return "", .StringBufferSizeMismatch;
    characters_len: u32 = 0;
    interpret_bytes_to_int_data(
        any { &characters_len, typeid_of(^u32) },
        data[:4],
    );
    characters := make([]i32, characters_len);
    for i := 4; i < len(data); i += 4 {
        // fmt.printf("[%v:%v] :: %v\n", i, i + 4, data[i : i + 4]);
        interpret_bytes_to_int_data(
            any { &characters[(i - 1) / 4], typeid_of(^i32) },
            data[i : i + 4],
        );
    }
    // fmt.printf("[%v:%v] :: %v\n", len(data) - 4, len(data), data[len(data) - 4 : len(data)]);
    // fmt.printf("%v\n", characters);

    byte_count := 0
	for chr in characters {
		_, chr_w := utf8.encode_rune(cast(rune)chr);
		byte_count += chr_w;
	}

	bytes := make([]byte, byte_count);
	offset := 0;
	for r in characters {
		b, chr_width := utf8.encode_rune(cast(rune)r);
		copy(bytes[offset:], b[:chr_width]);
		offset += chr_width;
	}
    return string(bytes), .None;
}
interpret_bytes_to_cstring :: proc(data: []byte) -> (cstring, Marshall_Error) {
    string_data, err := interpret_bytes_to_string(data);
    if err != .None do return "", err;
    return strings.clone_to_cstring(string_data), err;
}
/*! STRING */

MARSHALL_ANY :: #force_inline proc(variable: $T) -> any 
    where intrinsics.type_is_pointer(T)
{
    return any {
        data = variable,
        id = typeid_of(T),
    };
}

/**
 * @brief function to take any binary data and interpret it into the correct type
 * @note the only binary data that it can deserialize is the data that has been serialized by this marshall pckg in first place!
 */
deserialize :: proc(val: any, data: []byte) -> Marshall_Error {
    type_info := runtime.type_info_base(type_info_of(val.id));

    #partial switch vp in type_info.variant {
        case runtime.Type_Info_Pointer: // type has to be pointer (in order to be able to write inside it)
            switch v in vp.elem.variant {
                case runtime.Type_Info_Named: 
                    return .UnknownError;
                case runtime.Type_Info_Integer:
                    if v.endianness == .Big do return interpret_bytes_to_int_be_data(val, data);
                    else if v.endianness == .Little do return interpret_bytes_to_int_le_data(val, data);
                    else do return interpret_bytes_to_int_data(val, data);
                case runtime.Type_Info_Rune:
                    return interpret_bytes_to_int_data(
                        any {
                            val.data,
                            typeid_of(^i32),
                        }, data
                    );
                case runtime.Type_Info_Float:
                    if v.endianness == .Big do return interpret_bytes_to_float_be_data(val, data);
                    else if v.endianness == .Little do return interpret_bytes_to_float_le_data(val, data);
                    else do return interpret_bytes_to_int_data(val, data);
                case runtime.Type_Info_Complex: // todo
                    return .InvalidType;
                case runtime.Type_Info_Quaternion: // todo
                    return .InvalidType;
                case runtime.Type_Info_String:
                    switch _ in val {
                        case ^string:
                            err: Marshall_Error;
                            string_data := cast(^string)val.data;
                            string_data^, err = interpret_bytes_to_string(data);
                            return err;
                        case ^cstring:
                            err: Marshall_Error;
                            string_data := cast(^cstring)val.data;
                            string_data^, err = interpret_bytes_to_cstring(data);
                            return err;
                    }
                case runtime.Type_Info_Boolean:
                    value_data := cast(^bool)val.data;
                    if data[0] == 1 do value_data^ = true;
                    else if data[0] == 0 do value_data^ = false;
                    else do return .TypeMismatch; // cannot be a boolean
                    return .None;
                case runtime.Type_Info_Any:
                    return .InvalidType;
                case runtime.Type_Info_Type_Id:
                    return .InvalidType;
                case runtime.Type_Info_Pointer:
                    return .InvalidType;
                case runtime.Type_Info_Multi_Pointer:
                    return .InvalidType;
                case runtime.Type_Info_Procedure:
                    return .InvalidType;
                case runtime.Type_Info_Array:
                    return .InvalidType;
                case runtime.Type_Info_Enumerated_Array:
                    return .InvalidType;
                case runtime.Type_Info_Dynamic_Array:
                    return .InvalidType;
                case runtime.Type_Info_Slice:
                    return .InvalidType;
                case runtime.Type_Info_Parameters:
                    return .InvalidType;
                case runtime.Type_Info_Struct:
                    return .InvalidType;
                case runtime.Type_Info_Union:
                    return .InvalidType;
                case runtime.Type_Info_Enum:
                    return .InvalidType;
                case runtime.Type_Info_Map:
                    return .InvalidType;
                case runtime.Type_Info_Bit_Set:
                    return .InvalidType;
                case runtime.Type_Info_Simd_Vector:
                    return .InvalidType;
                case runtime.Type_Info_Relative_Pointer:
                    return .InvalidType;
                case runtime.Type_Info_Relative_Multi_Pointer:
                    return .InvalidType;
                case runtime.Type_Info_Matrix:
                    return .InvalidType;
                case runtime.Type_Info_Soa_Pointer:
                    return .InvalidType;
            }

        case:
            return .UnknownError;
    }
    return .UnknownError;
}
/**
 * @brief this functions writes binary data of any type "T" such that it creates binary.Writer and its contents using the marshall_write_explicit
 */
marshall_write :: #force_inline proc(data: $T) -> Marshall_Error {
    writer := binary.init_writer();
    return marshall_write_explicit(data, writer);
    binary.dump_writer(&writer);
}
/**
 * @brief this functions writes binary data of any type "T" using binary.Writer, type reflection ensures that pointers and arrays/multi-pointers are written correctly
 */
marshall_write_explicit :: proc(data: $T, writer: binary.Writer) -> Marshall_Error {
    binary_data, err := serialize(data); // automatically assume "hideous" types
    assert(err == .None, "Failed to serialize data!");
    binary.write_bytes(&writer, binary_data);
    assert(false, "TODO");
    return .None;
}

marshall_read :: proc($T: typeid) -> (T, Marshall_Error) {
    assert(false, "TODO");
    return nil, .None;
}
marshall_read_explicit :: proc($T: typeid, reader: binary.Reader) -> (T, Marshall_Error) {
    assert(false, "TODO");
    return nil, .None;
}