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

Marshall_Error :: enum u8 {
    None,                           // no error

    InvalidType,                    // unsupported type for marshalling/unmarshalling
    TypeMismatch,                   // type mismatch during unmarshalling
    OutOfMemory,                    // not enough memory for buffers
    BufferOverflow,                 // buffer is not large enough
    WriteError,                     // error during writing
    ReadError,                      // error during reading
    InvalidEndianness,              // unsupported endianness
    ArraySizeMismatch,              // array size mismatch (happens during unmarshalling when static array size is not the same of the marshall buffer provided)
    InternalAllocationError,        // this is launched when either "runtime" or "mem" package return AllocationError
    StringTooLong,                  // string length exceeds limits
    ArrayTooLong,                   // array/slice/dynarray length exceeds limits
    StringBufferSizeMismatch,       // expected size of the string buffer is not divisible by 4 (used for runes)
    IndexableAmbiguous,
    UnknownError                    // unknown error
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

    if v.count > 1 << (size_of(u32) * 8) do return nil, .ArrayTooLong;

    ByteData :: struct {
        data: [^]byte,
        size: int,
    }

    byte_data_temp := make([dynamic]ByteData);
    byte_data_len: int = 0;
    for it := 0; it < v.count; {
        val, idx, fine := reflect.iterate_array(arr, &it);
        if !fine do break;

        serialized := serialize(val) or_return;
        defer delete(serialized);

        append(
            &byte_data_temp, 
            ByteData {
                data = intrinsics.alloca(len(serialized), align_of(byte)),
                size = len(serialized),
            },
        );
        byte_data := &byte_data_temp[it - 1];
        mem.copy(byte_data^.data, raw_data(serialized), byte_data^.size);

        byte_data_len += byte_data^.size;

    }

    // first 8 bytes: [(4 bytes)=(num of elements); (4 bytes)=(num of bytes)]
    byte_data = make([]byte, 8 + byte_data_len);
    length_byte_data := interpret_int_data((u64(v.count) << 32) | u64(byte_data_len + 8));
    // fmt.printf("Special size: %v\n", (u64(v.count) << 32) | u64(byte_data_len + 8));
    // fmt.printf("Special size buffer: %v\n", length_byte_data);
    copy_slice(byte_data[:8], length_byte_data);
    delete(length_byte_data);
    prev_pos := 8;
    for data in byte_data_temp {
        mem.copy(raw_data(byte_data[prev_pos:prev_pos + data.size]), data.data, int(data.size));
        prev_pos += data.size;
    }
    return;
}
/*! ARRAY */
/* STRUCT */
interpret_struct :: proc(base_data: any, v: runtime.Type_Info_Struct) -> (byte_data: []byte, err: Marshall_Error) {

    StructTempData :: struct {
        offset: int,
        data: []byte,
    }

    //todo: optimize with using "marshall_serialize_size" instead of this dynamic allocation
    //todo: not every offset for every type is accurate! (indexable types)
    byte_data_temp := make_dynamic_array_len([dynamic]StructTempData, len(v.offsets));
    defer delete(byte_data_temp);
    byte_data_size_final := u32(0);
    for offset, index in v.offsets {
        // note: leave this "NexaTag_Marshallable" later, when "meta" package will be supported...
        // if v.tags[index] == "NexaTag_Marshallable" {
            fmt.println("Before serialize");
            byte_array, s_err := serialize(any {
                data = cast(rawptr)(uintptr(base_data.data) + offset),
                id = v.types[index].id,
            });
            fmt.printf("%v; %v\n", s_err, v.types[index]);
            fmt.println("After serialize");
            append(&byte_data_temp, StructTempData { offset = int(offset), data = byte_array });
            fmt.printf("\t%v :: %v\n", byte_data_temp[index].data, byte_array);
            byte_data_size_final += u32(len(byte_array));
        // }
    }
    byte_data = make([]byte, byte_data_size_final);
    prev_pos := 0;
    for struct_data in byte_data_temp {
        copy_slice(byte_data[prev_pos : prev_pos + len(struct_data.data)], struct_data.data);
        prev_pos += len(struct_data.data);
        delete(struct_data.data);
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

    switch v in type_info.variant {
        case runtime.Type_Info_Named: 
            return nil, .UnknownError;

        case runtime.Type_Info_Integer:
            switch integer_data in base_data {
                case i8:      return interpret_int_data(integer_data), .None;
                case i16:     return interpret_int_data(integer_data), .None;
                case i32:     return interpret_int_data(integer_data), .None;
                case i64:     return interpret_int_data(integer_data), .None;
                case int: {
                    data := interpret_int_data(integer_data);
                    // fmt.printf("Interpreted data [%v] into [%v]\n", integer_data, data);
                    return data, .None;
                }
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
            return nil, .InvalidType;

        case runtime.Type_Info_Type_Id:
            return nil, .InvalidType;

        case runtime.Type_Info_Pointer: // todo
            return serialize(base_data.data);

        case runtime.Type_Info_Multi_Pointer: // todo, do not forget to write its size
            return nil, .InvalidType;

        case runtime.Type_Info_Procedure:
            return nil, .InvalidType;

        case runtime.Type_Info_Array:
            return interpret_array(base_data, v);

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

        // case runtime.Type_Info_Bit_Field:
        //     return nil, .InvalidType;
    }
    return nil, .UnknownError;
}

/**
 * @brief calculates the size of the binary buffer that would be returned by 'serialize'
 * @return length of []byte array; -1 if id of data.id is not supported by the 'serialize' function
 */
marshall_serialized_size :: proc(data: any) -> int {

    iterable_size :: #force_inline proc(data: any, count: int) -> int {
        byte_data_len := 0;
        for it := 0; it < count; {
            val, idx, fine := reflect.iterate_array(data, &it);
            if !fine do break;
            byte_data_len += marshall_serialized_size(val);
        }
        return 8 + byte_data_len;
    }

    type_info := runtime.type_info_base(type_info_of(data.id));
    #partial switch v in type_info.variant {
        case runtime.Type_Info_Integer:
            switch integer_data in data {
                case i8:      return 1;
                case i16:     return 2;
                case i32:     return 4;
                case i64:     return 8;
                case int:     return 8;
                case u8:      return 1;
                case u16:     return 2;
                case u32:     return 4;
                case u64:     return 8;
                case uint:    return 8;

                case i16le:   return 2;
                case i32le:   return 4;
                case i64le:   return 8;
                case u16le:   return 2;
                case u32le:   return 4;
                case u64le:   return 8;

                case i16be:   return 2;
                case i32be:   return 4;
                case i64be:   return 8;
                case u16be:   return 2;
                case u32be:   return 4;
                case u64be:   return 8;
            }

        case runtime.Type_Info_Rune:
            return 4;

        case runtime.Type_Info_Float:
            switch float_data in data {
                // case f16: return interpret_float_data(float_data), .None;
                // case f32: return interpret_float_data(float_data), .None;
                // case f64: return interpret_float_data(float_data), .None;

                case f16le: return 2;
                case f32le: return 4;
                case f64le: return 8;

                case f16be: return 2;
                case f32be: return 4;
                case f64be: return 8;
            }

        case runtime.Type_Info_String:
            switch string_data in data {
                case string:  return 4 * (len(string_data) + 1);
                case cstring: return 4 * (len(string_data) + 1);
            }

        case runtime.Type_Info_Boolean:
            return 1;

        case runtime.Type_Info_Pointer:
            return marshall_serialized_size(data.data);

        case runtime.Type_Info_Array:
            return iterable_size(data, v.count);

        case runtime.Type_Info_Dynamic_Array:
            dyn_arr := cast(^runtime.Raw_Dynamic_Array)data.data;
            return iterable_size(data, dyn_arr.len);

        case runtime.Type_Info_Slice:
            slice := cast(^runtime.Raw_Slice)data.data;
            return iterable_size(data, slice.len);

        case runtime.Type_Info_Struct:
            assert(false, "todo");

        case runtime.Type_Info_Enum:
            return marshall_serialized_size({ data.data, v.base.id });

    }
    return -1;
}

/**
 * @brief helper functions for data serialization
 */

/* INTEGER */ 
interpret_bytes_to_int_le_data :: proc(val: any, bytes: []byte) -> Marshall_Error {
    switch &data in val {
        case i8:
            data = i8(bytes[0]); // todo buffer overflow

        case i16:
            data = i16(bytes[1]) << 8 | i16(bytes[0]);

        case i32:
            data = i32(bytes[3]) << 24 | i32(bytes[2]) << 16 | i32(bytes[1]) << 8 | i32(bytes[0]);

        case i64:
            data = (
                i64(bytes[7]) << 56 | 
                i64(bytes[6]) << 48 |
                i64(bytes[5]) << 40 | 
                i64(bytes[4]) << 32 | 
                i64(bytes[3]) << 24 |
                i64(bytes[2]) << 16 |
                i64(bytes[1]) <<  8 |
                i64(bytes[0]));

        case i16le:
            data = i16le(bytes[1]) << 8 | i16le(bytes[0]);

        case i32le:
            data = i32le(bytes[3]) << 24 | i32le(bytes[2]) << 16 | i32le(bytes[1]) << 8 | i32le(bytes[0]);

        case i64le:
            data = (
                i64le(bytes[7]) << 56 | 
                i64le(bytes[6]) << 48 |
                i64le(bytes[5]) << 40 | 
                i64le(bytes[4]) << 32 | 
                i64le(bytes[3]) << 24 |
                i64le(bytes[2]) << 16 |
                i64le(bytes[1]) <<  8 |
                i64le(bytes[0]));

        case int:
            data = (
                int(bytes[7]) << 56 | 
                int(bytes[6]) << 48 |
                int(bytes[5]) << 40 | 
                int(bytes[4]) << 32 | 
                int(bytes[3]) << 24 |
                int(bytes[2]) << 16 |
                int(bytes[1]) <<  8 |
                int(bytes[0]));
            // fmt.printf("Interpreting byte data: %v; as: %v\n", bytes, data);

        case u8:
            data = bytes[0];

        case u16:
            data = u16(bytes[1]) << 8 | u16(bytes[0]);

        case u32:
            data = u32(bytes[3]) << 24 | u32(bytes[2]) << 16 | u32(bytes[1]) << 8 | u32(bytes[0]);

        case u64:
            data = (
                u64(bytes[7]) << 56 | 
                u64(bytes[6]) << 48 |
                u64(bytes[5]) << 40 | 
                u64(bytes[4]) << 32 | 
                u64(bytes[3]) << 24 |
                u64(bytes[2]) << 16 |
                u64(bytes[1]) <<  8 |
                u64(bytes[0]));

        case u16le:
            data = u16le(bytes[1]) << 8 | u16le(bytes[0]);

        case u32le:
            data = u32le(bytes[3]) << 24 | u32le(bytes[2]) << 16 | u32le(bytes[1]) << 8 | u32le(bytes[0]);

        case u64le:
            data = (
                u64le(bytes[7]) << 56 | 
                u64le(bytes[6]) << 48 |
                u64le(bytes[5]) << 40 | 
                u64le(bytes[4]) << 32 | 
                u64le(bytes[3]) << 24 |
                u64le(bytes[2]) << 16 |
                u64le(bytes[1]) <<  8 |
                u64le(bytes[0]));

        case uint:
            data = (
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
    switch &data in val {
        case i16be:
            data = i16be(bytes[1]) | i16be(bytes[0]) << 8;

        case i32be:
            data = i32be(bytes[3]) | i32be(bytes[2]) << 8 | i32be(bytes[1]) << 16 | i32be(bytes[0]) << 24;

        case i64be:
            data = (
                i64be(bytes[7])       | 
                i64be(bytes[6]) << 8  |
                i64be(bytes[5]) << 16 | 
                i64be(bytes[4]) << 24 | 
                i64be(bytes[3]) << 32 |
                i64be(bytes[2]) << 40 |
                i64be(bytes[1]) << 48 |
                i64be(bytes[0]) << 56);

        case int:
            data = (
                int(bytes[7])       | 
                int(bytes[6]) << 8  |
                int(bytes[5]) << 16 | 
                int(bytes[4]) << 24 | 
                int(bytes[3]) << 32 |
                int(bytes[2]) << 40 |
                int(bytes[1]) << 48 |
                int(bytes[0]) << 56);

        case u16be:
            data = u16be(bytes[1]) | u16be(bytes[0]) >> 8;

        case u32be:
            data = u32be(bytes[3]) | u32be(bytes[2]) >> 8 | u32be(bytes[1]) >> 16 | u32be(bytes[0]) >> 24;

        case u64be:
            data = (
                u64be(bytes[7])       | 
                u64be(bytes[6]) << 8  |
                u64be(bytes[5]) << 16 | 
                u64be(bytes[4]) << 24 | 
                u64be(bytes[3]) << 32 |
                u64be(bytes[2]) << 40 |
                u64be(bytes[1]) << 48 |
                u64be(bytes[0]) << 56);

        case uint:
            data = (
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
    special_size: u32 = 0;
    fmt.printf("Bytes_to_string:: %v\n", data);
    interpret_bytes_to_int_data(special_size, data[:8]);
    characters := make([]i32, cast(int)special_size);
    for i := 0; i < len(data) - 4; i += 4 {
        // fmt.printf("[%v:%v] :: %v\n", i, i + 4, data[i + 4 : i + 8]);
        interpret_bytes_to_int_data(characters[i / 4], data[i + 4 : i + 8]);
    }
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
/* ARRAY */

@(private)
_interpret_bytes_to_array_with_indexable_slice :: #force_inline proc(
    val: any, 
    count: u32,
    element_id: typeid,
    data: []byte) -> (err: Marshall_Error) 
{
    subarray_len, whole_size: u32 = 0, 0;
    special_size: u64 = 0;
    for i: u32 = 0; i < count; i += 1 {
        // read length of one subarray
        interpret_bytes_to_int_data(special_size, data[whole_size : whole_size + 8]) or_return;
        // get correct values out of "special_size"
        subarray_len = u32(special_size >> 32);

        // allocate the subarray buffer
        array_byte_size := u32(special_size & 0x00000000FFFFFFFF);
        // fmt.printf("Array byte size: %v; subarray_len: %v;\n", array_byte_size, subarray_len);
        value_data_ptr := cast(^runtime.Raw_Slice)rawptr(uintptr(val.data) + uintptr(whole_size));
        err: mem.Allocator_Error;
        value_data_ptr.data, err = mem.alloc(cast(int)array_byte_size);
        value_data_ptr.len = int(subarray_len);
        fmt.printf("Passing new slice data: %v\n", value_data_ptr);
        if err != .None do return .InternalAllocationError; // todo fix leakage if error'd

        // read the subarray
        fmt.printf("\x1b[30mPassing a subarray of size: %v\x1b[0m\n", array_byte_size);
        deserialize(
            any { rawptr(value_data_ptr), element_id, },
            data[whole_size : whole_size + array_byte_size],
        ) or_return;

        whole_size += array_byte_size;
        fmt.printf("Whole size update: %v\n", whole_size);
    }
    return .None;
}

@(private)
_interpret_bytes_to_array_with_indexable_elements :: #force_inline proc(
    val: any, 
    count: u32,
    element_id: typeid,
    data: []byte) -> (err: Marshall_Error) 
{
    assert(false, "NOT IMPLEMENTED!");
    return .UnknownError;
}

interpret_bytes_to_array :: proc(val: any, info: runtime.Type_Info_Array, data: []byte) -> (err: Marshall_Error) {
    if info.count > 0 {
        #partial switch v in info.elem.variant {
            // for indexable types, check first 4 bytes
            case runtime.Type_Info_String:
                fmt.printf("Type: %v\n", info.elem.id)
                return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)info.count, info.elem.id, data);

            case runtime.Type_Info_Array:
                fmt.printf("Type: %v\n", info.elem.id)
                return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)info.count, info.elem.id, data);

            case runtime.Type_Info_Slice:
                fmt.printf("Type: %v\n", info.elem.id)
                return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)info.count, info.elem.id, data);

            case runtime.Type_Info_Dynamic_Array:
                fmt.printf("Type: %v\n", info.elem.id)
                return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)info.count, info.elem.id, data);

            case:
                fmt.printf("Type: %v\n", info.elem.id)
                for i in 0..<info.count {
                    deserialize(
                        any { rawptr(uintptr(val.data) + uintptr(i * info.elem_size)), info.elem.id },
                        data[8 + i * info.elem_size : 8 + (i + 1) * info.elem_size],
                    ) or_return;
                }
                return .None;
        }
    }
    return .ArraySizeMismatch;
}

interpret_bytes_to_enum_array :: #force_inline proc(val: any, info: runtime.Type_Info_Enumerated_Array, data: []byte) -> (err: Marshall_Error) {
    return interpret_bytes_to_array(
        val, 
        {
            elem = info.elem,
            elem_size = info.elem_size,
            count = info.count,
        }, 
        data,
    );
}

interpret_bytes_to_slice :: proc(val: any, info: runtime.Type_Info_Slice, data: []byte) -> (err: Marshall_Error) {
    slice := cast(^runtime.Raw_Slice)val.data;

    if slice.len == 0 { // slice not preallocated by the caller
        special_size: u64 = 0;
        interpret_bytes_to_int_data(special_size, data[:8]) or_return;
        slice_len := int(special_size >> 32);
        array_byte_size := int(special_size & 0x00000000FFFFFFFF);
        if slice_len == 0 do return .ArraySizeMismatch;
        slice.len = cast(int)slice_len;
        slice_data, err := runtime.mem_alloc_bytes(array_byte_size, info.elem.align);
        if err != .None do return .InternalAllocationError;
        slice.data = raw_data(slice_data);
    } else {
        fmt.printf("Slice length deduced! [%v]\nSlice data: [%v]\n", slice.len, slice.data);
    }

    #partial switch v in info.elem.variant {
        case runtime.Type_Info_Array:
            fmt.printf("Type: %v\n", info.elem.id)
            return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)slice.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Slice:
            fmt.printf("Type: %v\n", info.elem.id)
            return _interpret_bytes_to_array_with_indexable_slice(val, cast(u32)slice.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Dynamic_Array:
            fmt.printf("Type: %v\n", info.elem.id)
            return _interpret_bytes_to_array_with_indexable_elements(val, cast(u32)slice.len, info.elem.id, data[8:]);

        case:
            // fmt.printf("Slice len: %d; Slice data: %v\n", slice.len, data);
            for i := 0; i < slice.len; i += 1 {
                // fmt.printf("\tIteration: %d\n", i);
                deserialize(
                    any {
                        data = rawptr(uintptr(slice.data) + uintptr(i * info.elem_size)),
                        id = info.elem.id,
                    },
                    data[8 + i * info.elem_size : 8 + (i + 1) * info.elem_size],
                ) or_return;
            }
            return .None;
    }

    return .UnknownError;
}
interpret_bytes_to_dyn_array :: proc(val: any, info: runtime.Type_Info_Dynamic_Array, data: []byte) -> (err: Marshall_Error) {
    dyn_array := cast(^runtime.Raw_Dynamic_Array)val.data;
    if dyn_array.len == 0 { // dyn_array not preallocated by the user
        dyn_array.len = len(data) / info.elem_size;
        dyn_array.cap = dyn_array.len;
        dyn_array_data, err := runtime.mem_alloc_bytes(dyn_array.len, info.elem.align);
        if err != .None do return .InternalAllocationError;
        dyn_array.data = raw_data(dyn_array_data);
        dyn_array.allocator = context.allocator;
    }
    for i in 0..<dyn_array.len {
        deserialize(
            any {
                data = rawptr(uintptr(dyn_array.data) + uintptr(i * info.elem_size)),
                id = info.elem.id,
            },
            data[i * info.elem_size : (i + 1) * info.elem_size],
        ) or_return;
    }
    return .None;
}
/*! ARRAY */
/* STRUCT */
interpret_bytes_to_struct :: proc(val: any, v: runtime.Type_Info_Struct, data: []byte) -> (err: Marshall_Error) {

    prev_offset: uintptr = 0;
    for offset, index in v.offsets {
        deserialize(
            any {
                data = rawptr(uintptr(val.data) + offset),
                id = v.types[index].id,
            },
            data[prev_offset : prev_offset + offset],
        );

        prev_offset += offset;
    }

    return;
}
/*! STRUCT */

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

    switch v in type_info.variant {
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
                    typeid_of(i32),
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
            switch &string_data in val {
                case string:
                    err: Marshall_Error;
                    string_data, err = interpret_bytes_to_string(data);
                    return err;
                case cstring:
                    err: Marshall_Error;
                    string_data, err = interpret_bytes_to_cstring(data);
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
            return deserialize(
                any { data = val.data, id = v.elem.id, },
                data
            );

        case runtime.Type_Info_Multi_Pointer:
            return .InvalidType;

        case runtime.Type_Info_Procedure:
            return .InvalidType;

        case runtime.Type_Info_Array:
            fmt.println("hellope array");
            return interpret_bytes_to_array(val, v, data);

        case runtime.Type_Info_Enumerated_Array:
            fmt.println("hellope enum array");
            return interpret_bytes_to_enum_array(val, v, data);

        case runtime.Type_Info_Dynamic_Array:
            fmt.println("hellope dyn array");
            return interpret_bytes_to_dyn_array(val, v, data);

        case runtime.Type_Info_Slice:
            fmt.println("hellope slice");
            return interpret_bytes_to_slice(val, v, data);

        case runtime.Type_Info_Parameters:
            return .InvalidType;

        case runtime.Type_Info_Struct: //todo
            // note: have to account for "pointers" as members of the struct (in case of recursive calling of the 'deserialize' proc...)
            return interpret_bytes_to_struct(val, v, data);

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

        // case runtime.Type_Info_Bit_Field:
        //     return .InvalidType;
    }
    return .UnknownError;
}
/**
 * @brief this functions writes binary data of any type "T" such that it creates binary.Writer and its contents using the marshall_write_explicit
 */
marshall_write :: #force_inline proc(data: $T, path: string) -> Marshall_Error {
    writer := binary.init_writer(path);
    defer binary.dump_writer(&writer);
    return marshall_write_explicit(data, &writer);
}
/**
 * @brief this functions writes binary data of any type "T" using binary.Writer, type reflection ensures that pointers and arrays/multi-pointers are written correctly
 */
marshall_write_explicit :: proc(data: $T, writer: ^binary.Writer) -> (err: Marshall_Error) {
    binary_data := serialize(data) or_return; // automatically assume "hideous" types
    defer delete(binary_data);
    fmt.printf("%v\n", binary_data);
    binary.write_bytes(writer, binary_data);
    return;
}

marshall_read :: proc($T: typeid, path: string) -> (T, Marshall_Error) {
    reader := binary.init_reader();
    binary.load(&reader, path);
    defer binary.dump_reader(&reader);
    return marshall_read_explicit(T, reader);
}
marshall_read_explicit :: proc($T: typeid, reader: binary.Reader) -> (T, Marshall_Error) {
    val: T;
    err := deserialize(val, reader.buffer);
    return val, err;
}