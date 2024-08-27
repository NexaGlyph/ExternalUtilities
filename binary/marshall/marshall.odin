//+build windows
package marshall

import "base:runtime"
import "base:intrinsics"

import "core:fmt"
import "core:mem"
import "core:math"
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
    ArraySizeMismatch,              // array size mismatch (happens during unmarshalling when static array size is not the same of the marshall buffer provided, also counts for enum arrays)
    InternalAllocationError,        // this is launched when either "runtime" or "mem" package return AllocationError
    StringTooLong,                  // string length exceeds limits
    ArrayTooLong,                   // array/slice/dynarray length exceeds limits
    StringBufferSizeMismatch,       // expected size of the string buffer is not divisible by 4 (used for runes)
    StructIsRawUnion,               // raw_unions cannot be saved without knowing the current type the binary represents
    UnknownError                    // unknown error
}

type_is_struct ::  proc "contextless" (t: ^runtime.Type_Info) -> bool {
	if t == nil do return false;
	s, ok := runtime.type_info_base(t).variant.(runtime.Type_Info_Struct);
	return ok && !s.is_raw_union;
} 

/**
 * @brief helper functions for data serialization
 */

/* INTEGER */
interpret_int_be_data :: proc(integer_data: $INT_T, byte_data: []byte = nil) -> []byte 
    where intrinsics.type_is_integer(INT_T) 
{
    // fmt.printf("Size: %v\nType: %v\n", size_of(INT_T), type_info_of(INT_T));
    byte_data := byte_data;
    if byte_data == nil do byte_data = make([]byte, size_of(INT_T));
    byte_index: u8 = (size_of(INT_T) - 1) * 8;
    for i in 0..<size_of(INT_T) {
        byte_data[i] = byte(integer_data >> byte_index);
        byte_index -= 8;
    }
    return byte_data;
}
interpret_int_le_data :: proc(integer_data: $INT_T, byte_data: []byte = nil) -> []byte 
    where intrinsics.type_is_integer(INT_T) && intrinsics.type_is_endian_little(INT_T)
{
    // fmt.printf("Size: %v\nType: %v\n", size_of(INT_T), type_info_of(INT_T));
    byte_data := byte_data;
    if byte_data == nil do byte_data = make([]byte, size_of(INT_T));
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

FLOAT_PRECISION :: 5;

FloatOffsetsTable :: struct($EXP, $MANTISSA: typeid) {
    exponent_shift: EXP,
    exponent_mask: MANTISSA,
    mantissa_mask: MANTISSA,
}

F16le_OFFSETS_TABLE :: FloatOffsetsTable(i8,    u16le) { 10, 0x7C00,             0x3FF};
F32le_OFFSETS_TABLE :: FloatOffsetsTable(i16le, u32le) { 23, 0x7F800000,         0x007FFFFF};
F64le_OFFSETS_TABLE :: FloatOffsetsTable(i32le, u64le) { 52, 0x7FF0000000000000, 0x000FFFFFFFFFFFFF};

F16be_OFFSETS_TABLE :: FloatOffsetsTable(i8,    u16be) { 10, 0x7C00,             0x3FF};
F32be_OFFSETS_TABLE :: FloatOffsetsTable(i16be, u32be) { 23, 0x7F800000,         0x007FFFFF};
F64be_OFFSETS_TABLE :: FloatOffsetsTable(i32be, u64be) { 52, 0x7FF0000000000000, 0x000FFFFFFFFFFFFF};

// LITTLE ENDIAN
interpret_float_data :: proc(float: any) -> ([]byte, Marshall_Error) {
    switch &float_data in float {
        case f16:   return interpret_float_le_data(cast(f16le)float_data, F16le_OFFSETS_TABLE), .None;
        case f32:   return interpret_float_le_data(cast(f32le)float_data, F32le_OFFSETS_TABLE), .None;
        case f64:   return interpret_float_le_data(cast(f64le)float_data, F64le_OFFSETS_TABLE), .None;

        case f16le: return interpret_float_le_data(float_data, F16le_OFFSETS_TABLE), .None;
        case f32le: return interpret_float_le_data(float_data, F32le_OFFSETS_TABLE), .None;
        case f64le: return interpret_float_le_data(float_data, F64le_OFFSETS_TABLE), .None;

        case f16be: return interpret_float_be_data(float_data, u16le, F16be_OFFSETS_TABLE), .None;
        case f32be: return interpret_float_be_data(float_data, u32le, F32be_OFFSETS_TABLE), .None;
        case f64be: return interpret_float_be_data(float_data, u64le, F64be_OFFSETS_TABLE), .None;
    }
    return {}, .UnknownError;
}

interpret_float_le_data :: proc(float_data: $FLOAT_T, offsets: FloatOffsetsTable($EXP, $MANTISSA)) -> []byte
    where intrinsics.type_is_float(FLOAT_T) && intrinsics.type_is_endian_little(FLOAT_T)
{
    float_data := float_data;
    float_bits := transmute(MANTISSA)float_data;
    // first bit determines +/-
    neg := cast(u8)((float_bits >> (size_of(MANTISSA) * 8 - 1)) & 1);
    if neg == 1 do float_data *= -1;
    // exponent is located on exponent mask, after the sign
    exp_bits := cast(EXP)((float_bits & offsets.exponent_mask) >> auto_cast offsets.exponent_shift);
    // multiplied by exp_bits; 10 bit long after exp_bits
    mantissa := (float_bits & offsets.mantissa_mask);

    byte_data := make([]byte, size_of(u8) + size_of(exp_bits) + size_of(mantissa));
    interpret_int_le_data(neg,      byte_data[:]);
    interpret_int_le_data(exp_bits, byte_data[size_of(neg):]);
    interpret_int_le_data(mantissa, byte_data[size_of(neg) + size_of(exp_bits):]);
    return byte_data;
}

interpret_float_be_data :: proc(float_data: $FLOAT_T, $LE_MAN: typeid, offsets: FloatOffsetsTable($EXP, $MANTISSA)) -> []byte
    where intrinsics.type_is_float(FLOAT_T) && intrinsics.type_is_endian_big(FLOAT_T)
{
    float_data := float_data;
    float_bits := transmute(MANTISSA)float_data;
    fmt.printf("BE: %b\n", float_bits);
    fmt.printf("LE: %b\n", transmute(LE_MAN)float_data);
    // // first bit determines +/-
    // neg := cast(u8)((float_bits >> (size_of(MANTISSA) * 8 - 1)) & 1);
    // if neg == 1 do float_data *= -1;
    // // exponent is located on exponent mask, after the sign
    // exp_bits := cast(EXP)((float_bits & offsets.exponent_mask) >> auto_cast offsets.exponent_shift);
    // // multiplied by exp_bits; 10 bit long after exp_bits
    // mantissa := (float_bits & offsets.mantissa_mask);

    // byte_data := make([]byte, size_of(u8) + size_of(exp_bits) + size_of(mantissa));
    // interpret_int_le_data(neg,      byte_data[:]);
    // interpret_int_le_data(exp_bits, byte_data[size_of(neg):]);
    // interpret_int_le_data(mantissa, byte_data[size_of(neg) + size_of(exp_bits):]);
    // return byte_data;
    return {};
}

// PLATFORM
interpret_float16_data :: #force_inline proc "odin" (float_data: f16) -> []byte {
    byte_data := make([]byte, size_of(f16));
    float_bits := transmute(u16)(float_data * math.pow(f16(10), cast(f16)FLOAT_PRECISION));
    for i: u8 = size_of(f16); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float32_data :: #force_inline proc "odin" (float_data: f32) -> []byte {
    byte_data := make([]byte, size_of(f32));
    float_bits := transmute(u32)(float_data * math.pow(f32(10), cast(f32)FLOAT_PRECISION));
    for i: u8 = size_of(f32); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}
interpret_float64_data :: #force_inline proc "odin" (float_data: f64) -> []byte {
    byte_data := make([]byte, size_of(f64));
    float_bits := transmute(u64)(float_data * math.pow(f64(10), cast(f64)FLOAT_PRECISION));
    for i: u8 = size_of(f64); i > 0; i -= 1 do byte_data[i] = byte(float_bits >> (8 * i));
    return byte_data;
}


/*! FLOAT */
/* STRING */
/**
 * @brief converts string to []byte array
 * @note first 4 bytes is not a character but the string length (this is useful for readings such as slice/array/dyn_array deserialization of string etc.)
 */
interpret_string :: proc(str: string) -> ([]byte, Marshall_Error) {
    // write string length as u32
    if len(str) > (1 << (size_of(u32) * 8)) do return nil, .StringTooLong;
    byte_data := make([]byte, len(str) + 4); // even though we can interpret the whole []byte buffer as "string", we should store its length for purposes of indexed type ambiguity (as an other indexable type...)
    {
        bytes := interpret_int_data(u32(len(str)));
        copy_slice(byte_data[:4], bytes);
        delete(bytes);
    }
    // fmt.printf("\x1b[33mCopying\x1b[0m... %s\n", str);
    copy_from_string(byte_data[4:], str);
    return byte_data, .None;
}
interpret_string_null_terminated :: proc(str: cstring) -> ([]byte, Marshall_Error) {
    return interpret_string(strings.clone_from_cstring(str));
}
/*! STRING */
/* ARRAY */
interpret_indexable :: proc(arr: any, count: int) -> (byte_data: []byte, err: Marshall_Error) {

    if count > 1 << (size_of(u32) * 8) do return nil, .ArrayTooLong;

    ByteData :: struct {
        data: []byte,
    }

    total_size := 0;
    for it := 0; it < count; {
        val, _, fine := reflect.iterate_array(arr, &it);
        if !fine do break;

        total_size += marshall_serialized_size(val);
    }

    byte_data = make([]byte, 8 + total_size);
    length_byte_data := interpret_int_data((u64(count) << 32) | u64(total_size + 8));
    copy_slice(byte_data[:8], length_byte_data);
    delete(length_byte_data);
    prev_pos, data_len := 8, 0;
    for it := 0; it < count; {
        val, _, fine := reflect.iterate_array(arr, &it);
        if !fine do break;

        serialized := serialize(val) or_return;
        data_len = len(serialized);
        copy_slice(byte_data[prev_pos:prev_pos + data_len], serialized);
        delete(serialized);

        prev_pos += data_len;
    }
    return;
}

interpret_enum_array :: proc(arr: any, info: runtime.Type_Info_Enumerated_Array) -> (byte_data: []byte, err: Marshall_Error) {
    total_size := 0;
    if info.is_sparse do return nil, .UnknownError;
    for it := 0; it < info.count; it += 1 {
        total_size += marshall_serialized_size(
            any { cast(rawptr)(uintptr(arr.data) + uintptr(it * info.elem_size)), info.elem.id },
        );
    }

    byte_data = make([]byte, 8 + total_size);
    length_byte_data := interpret_int_data((u64(info.count) << 32) | u64(total_size + 8));
    copy_slice(byte_data[:8], length_byte_data);
    delete(length_byte_data);
    prev_pos, data_len := 8, 0;
    for it := 0; it < info.count; it += 1 {
        serialized := serialize(
            any { cast(rawptr)(uintptr(arr.data) + uintptr(it * info.elem_size)), info.elem.id },
        ) or_return;
        data_len = len(serialized);
        copy_slice(byte_data[prev_pos:prev_pos + data_len], serialized);
        delete(serialized);

        prev_pos += data_len;
    }

    // fmt.printf("Serialized enum array: %v\n", byte_data);

    return;
}
/*! ARRAY */
/* STRUCT */
interpret_struct :: proc(base_data: any, v: runtime.Type_Info_Struct, recurrent := false) -> (byte_data: []byte, err: Marshall_Error) {

    if v.is_raw_union do return nil, .StructIsRawUnion;

    StructTempData :: []byte;

    byte_data_temp := make([dynamic]StructTempData);
    defer delete(byte_data_temp);
    byte_data_size_final := u32(0);
    for offset, index in v.offsets {
        type_info := v.types[index];
        if v.tags[index] == "NexaTag_Marshallable" || recurrent {
            byte_data: []byte = nil;
            if type_is_struct(type_info) {
                byte_data = interpret_struct(any {
                        data = cast(rawptr)(uintptr(base_data.data) + offset),
                        id = type_info.id,
                    }, 
                    runtime.type_info_base(type_info).variant.(runtime.Type_Info_Struct), 
                    true,
                ) or_return;
            } else {
                byte_data = serialize(any {
                    data = cast(rawptr)(uintptr(base_data.data) + offset),
                    id = type_info.id,
                }) or_return;
            }
            append(&byte_data_temp, byte_data);
            byte_data_size_final += u32(len(byte_data_temp[index]));
        }
    }

    byte_data = make([]byte, byte_data_size_final + size_of(u32));
    interpret_int_data(byte_data_size_final, byte_data[:size_of(u32)]);
    prev_pos := size_of(u32);
    for struct_data in byte_data_temp {
        copy_slice(byte_data[prev_pos : prev_pos + len(struct_data)], struct_data);
        prev_pos += len(struct_data);
        delete(struct_data);
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
            return nil, .InvalidType;

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
            return interpret_float_data(base_data);

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

        case runtime.Type_Info_Pointer:
            if base_data.data == nil do return nil, .None;
            return serialize(any { base_data.data, v.elem.id }); // note: is this even allowed ??

        case runtime.Type_Info_Multi_Pointer:
            if base_data.data == nil do return nil, .None;
            return serialize(any { base_data.data, v.elem.id }); // note: is this even allowed ??

        case runtime.Type_Info_Procedure:
            return nil, .InvalidType;

        case runtime.Type_Info_Array:
            return interpret_indexable(base_data, v.count);

        case runtime.Type_Info_Enumerated_Array:
            return interpret_enum_array(base_data, v);

        case runtime.Type_Info_Dynamic_Array:
            dyn_arr := cast(^runtime.Raw_Dynamic_Array)base_data.data;
            return interpret_indexable(base_data, dyn_arr.len);

        case runtime.Type_Info_Slice:
            slice := cast(^runtime.Raw_Slice)base_data.data;
            return interpret_indexable(base_data, slice.len);

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

@(private)
_marshall_serialize_float_t :: #force_inline proc "contextless" (t: ^runtime.Type_Info, v: runtime.Type_Info_Float) -> int {
    if v.endianness == .Platform {
        switch t.size {
            case size_of(f16):   return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16le) /* mantissa */;
            case size_of(f32):   return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32le) /* mantissa */;
            case size_of(f64):   return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64le) /* mantissa */;
        }
    } else if v.endianness == .Little {
        switch t.size {
            case size_of(f16le): return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16le) /* mantissa */;
            case size_of(f32le): return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32le) /* mantissa */;
            case size_of(f64le): return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64le) /* mantissa */;
        }
    } else {
        switch t.size {
            case size_of(f16be): return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16be) /* mantissa */;
            case size_of(f32be): return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32be) /* mantissa */;
            case size_of(f64be): return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64be) /* mantissa */;
        }
    }

    return -1;
}

@(private)
_marshall_serialize_ptr_t :: #force_inline proc "contextless" (t: ^runtime.Type_Info, elem: ^runtime.Type_Info) -> int {
    #partial switch vv in elem.variant {
        case runtime.Type_Info_Integer:         return t.size;
        case runtime.Type_Info_Enum:            return t.size;
        case runtime.Type_Info_Rune:            return 4;
        case runtime.Type_Info_Boolean:         return 1;

        case runtime.Type_Info_Float:           return _marshall_serialize_float_t(type_info_of(elem.id), vv);
        case runtime.Type_Info_Pointer:         return marshall_serialized_size_t(type_info_of(vv.elem.id));
        case runtime.Type_Info_Multi_Pointer:   return marshall_serialized_size_t(type_info_of(vv.elem.id));
    }

    return -1;
}

@(private)
_marshall_serialize_struct_t :: proc "contextless" (v: runtime.Type_Info_Struct, recurrent := false) -> int {
    size := 0;
    for offset, index in v.offsets {
        type_info := v.types[index];
        if v.tags[index] == "NexaTag_Marshallable" || recurrent {
            _size := -1;

            if type_is_struct(type_info) do _size = _marshall_serialize_struct_t(type_info.variant.(runtime.Type_Info_Struct), true);
            else do _size = marshall_serialized_size_t(type_info);

            if _size == -1 do return -1;

            size += _size;
        }
    }
    return size;
}

/**
 * @brief for non-indexable and supported types, one can use this function to determine the size of the binary buffer returned by 'serialize' proc on serialization of the instance of "T" type
 * @note authors aim to discard this function once every supported type (with byte size known at compile time) will have precisely the same serialized length as its "size_of(T)"
 * @return length of the []byte array; -1 if the type's size cannot be known at compile time or is not supported
 */
marshall_serialized_size_t :: proc "contextless" (t: ^runtime.Type_Info) -> int {
    #partial switch v in t.variant {
        case runtime.Type_Info_Integer:
            return t.size;

        case runtime.Type_Info_Rune:
            return t.size;

        case runtime.Type_Info_Float:
            return _marshall_serialize_float_t(t, v);
        
        case runtime.Type_Info_Boolean:
            return 1;
        
        case runtime.Type_Info_Enum:
            return t.size;

        case runtime.Type_Info_Struct:
            return _marshall_serialize_struct_t(v);

        case runtime.Type_Info_Pointer:
            return _marshall_serialize_ptr_t(t, v.elem);
        
        case runtime.Type_Info_Multi_Pointer:
            return _marshall_serialize_ptr_t(t, v.elem);
    }

    return -1;
}

/**
 * @brief calculates the size of the binary buffer that would be returned by 'serialize'
 * @return length of []byte array; -1 if id of data.id is not supported by the 'serialize' function
 */
marshall_serialized_size :: proc(data: any) -> int {
    _iterable_size :: #force_inline proc(data: any, count: int) -> int {
        byte_data_len := 0;
        for it := 0; it < count; {
            val, _, fine := reflect.iterate_array(data, &it);
            if !fine do break;
            byte_data_len += marshall_serialized_size(val);
        }
        return 8 + byte_data_len;
    }

    _struct_size :: proc(data: any, v: runtime.Type_Info_Struct, recurrent := false) -> int {
        size := size_of(u32);
        for offset, index in v.offsets {
            type_info := v.types[index];
            if v.tags[index] == "NexaTag_Marshallable" || recurrent {
                curr_field := any{
                    data = cast(rawptr)(uintptr(data.data) + offset),
                    id = type_info.id,
                };
                _size := -1;
                if type_is_struct(type_info) {
                    _size = _struct_size(
                        curr_field,
                        runtime.type_info_base(type_info).variant.(runtime.Type_Info_Struct),
                        true);
                } else {
                    _size = marshall_serialized_size(curr_field);
                }
                if _size == -1 do return _size;
                size += _size;
            }
        }
        return size;
    }

    // todo: substitute the 'constant' - known size inside the _t version of this function!
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
                case f16:   return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16le) /* mantissa */;
                case f32:   return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32le) /* mantissa */;
                case f64:   return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64le) /* mantissa */;

                case f16le: return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16le) /* mantissa */;
                case f32le: return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32le) /* mantissa */;
                case f64le: return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64le) /* mantissa */;

                case f16be: return size_of(u8) /* sign */ + size_of(i8)    /* exp */ + size_of(u16be) /* mantissa */;
                case f32be: return size_of(u8) /* sign */ + size_of(i16le) /* exp */ + size_of(u32be) /* mantissa */;
                case f64be: return size_of(u8) /* sign */ + size_of(i32le) /* exp */ + size_of(u64be) /* mantissa */;
            }

        case runtime.Type_Info_String:
            switch string_data in data {
                case string:  return 4 + len(string_data);
                case cstring: return 4 + len(string_data);
            }

        case runtime.Type_Info_Boolean:
            return 1;

        case runtime.Type_Info_Pointer:
            return marshall_serialized_size(any{ data.data, v.elem.id });

        case runtime.Type_Info_Multi_Pointer:
            return marshall_serialized_size(any{ data.data, v.elem.id }); // multi pointers cannot have (for marshall) size larger than one

        case runtime.Type_Info_Array:
            return _iterable_size(data, v.count);

        case runtime.Type_Info_Dynamic_Array:
            dyn_arr := cast(^runtime.Raw_Dynamic_Array)data.data;
            return _iterable_size(data, dyn_arr.len);

        case runtime.Type_Info_Slice:
            slice := cast(^runtime.Raw_Slice)data.data;
            return _iterable_size(data, slice.len);

        case runtime.Type_Info_Struct:
            return _struct_size(data, v);

        case runtime.Type_Info_Enum:
            return marshall_serialized_size({ data.data, v.base.id });

    }
    return -1;
}

/**
 * @brief helper functions for data deserialization
 */

/* INTEGER */ 
interpret_bytes_to_int_le_data :: proc "contextless" (val: any, bytes: []byte) -> Marshall_Error {
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
interpret_bytes_to_int_be_data :: proc "contextless" (val: any, bytes: []byte) -> Marshall_Error {
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
_interpret :: proc "contextless" ($EXP, $NEG, $MANTISSA, $OUT: typeid, bias: EXP, mantissa_max: OUT, bytes: []byte) -> OUT {
    exp: EXP;
    neg: NEG;
    mantissa: MANTISSA;
    interpret_bytes_to_int_le_data(neg,      bytes[:]);
    interpret_bytes_to_int_le_data(exp,      bytes[size_of(neg):]);
    interpret_bytes_to_int_le_data(mantissa, bytes[size_of(neg) + size_of(exp):]);
    sign: OUT = neg == 1 ? -1 : 1;
    if exp == 0 {
        // +/- zero
        if mantissa == 0 do return neg == 1 ? -0 : +0;
        // subnormal values
        else do return sign * math.pow(2, cast(OUT)(-bias + 1)) * (cast(OUT)mantissa/mantissa_max);
    }
    return sign * math.pow(2, cast(OUT)(exp - bias)) * (1 + cast(OUT)mantissa/mantissa_max);
}

interpret_bytes_to_float_le_data :: proc "contextless" (val: any, bytes: []byte) -> Marshall_Error {
    switch &float_data in val {
        case f16:
            float_data = cast(f16)(u16(bytes[1]) | u16(bytes[0]) << 8);

        case f32:
            float_data = cast(f32)(u32(bytes[3]) | u32(bytes[2]) << 8 | u32(bytes[1]) << 16 | u32(bytes[0]) << 24) / math.pow(f32(10), cast(f32)FLOAT_PRECISION);

        case f64:
            float_data = f64(
                u64(bytes[7]) << 56 | 
                u64(bytes[6]) << 48 |
                u64(bytes[5]) << 40 | 
                u64(bytes[4]) << 32 | 
                u64(bytes[3]) << 24 |
                u64(bytes[2]) << 16 |
                u64(bytes[1]) <<  8 |
                u64(bytes[0])) / math.pow(f64(10), cast(f64)FLOAT_PRECISION);

        case f16le:
            float_data = _interpret(EXP=i8, NEG=u8, MANTISSA=u16le, OUT=f16le, mantissa_max=1024 /* 1 << 10 */, bias=15, bytes=bytes);

        case f32le:
            float_data = _interpret(EXP=i16le, NEG=u8, MANTISSA=u32le, OUT=f32le, mantissa_max=8388608 /* 1 << 23 */ , bias=127, bytes=bytes);

        case f64le:
            float_data = _interpret(EXP=i32le, NEG=u8, MANTISSA=u64le, OUT=f64le, mantissa_max=1 << 52/* 1 << 52 */, bias=1023, bytes=bytes);

        case:
            return .InvalidType;

    }

    return .None;
}
interpret_bytes_to_float_be_data :: proc /*"contextless"*/ (val: any, bytes: []byte) -> Marshall_Error {
    assert(false, "dysfunctional rn");
    switch &float_data in val {
        case f16:
            float_data = cast(f16)(u16(bytes[1]) << 8 | u16(bytes[0])) / math.pow(f16(10), cast(f16)FLOAT_PRECISION);

        case f32:
            float_data = cast(f32)(u32(bytes[3]) << 24 | u32(bytes[2]) << 16 | u32(bytes[1]) << 8 | u32(bytes[0])) / math.pow(f32(10), cast(f32)FLOAT_PRECISION);

        case f64:
            float_data = f64(
                u64(bytes[7]) << 8  | 
                u64(bytes[6]) << 16 |
                u64(bytes[5]) << 24 | 
                u64(bytes[4]) << 32 | 
                u64(bytes[3]) << 40 |
                u64(bytes[2]) << 48 |
                u64(bytes[1]) << 56 |
                u64(bytes[0])) / math.pow(f64(10), cast(f64)FLOAT_PRECISION);
        
        case f16be:
            float_data = cast(f16be)_interpret(EXP=i8, NEG=u8, MANTISSA=u16le, OUT=f16le, mantissa_max=1024 /* 1 << 10 */, bias=15, bytes=bytes);

        case f32be:
            float_data = cast(f32be)(u32be(bytes[3]) << 24 | u32be(bytes[2]) << 16 | u32be(bytes[1]) << 8 | u32be(bytes[0])) / math.pow(f32be(10), cast(f32be)FLOAT_PRECISION);

        case f64be:
            float_data = f64be(
                u64be(bytes[7]) << 8  | 
                u64be(bytes[6]) << 16 |
                u64be(bytes[5]) << 24 | 
                u64be(bytes[4]) << 32 | 
                u64be(bytes[3]) << 40 |
                u64be(bytes[2]) << 48 |
                u64be(bytes[1]) << 56 |
                u64be(bytes[0])) / math.pow(f64be(10), cast(f64be)FLOAT_PRECISION);

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
    special_size: u32 = 0;
    interpret_bytes_to_int_data(special_size, data[:4]);
    if u32(len(data)) - 4 != special_size do return "", .StringBufferSizeMismatch;
    return strings.clone_from_bytes(data[4:]), .None;
}
interpret_bytes_to_cstring :: proc(data: []byte) -> (cstring, Marshall_Error) {
    string_data, err := interpret_bytes_to_string(data);
    defer delete_string(string_data);
    if err != .None do return "", err;
    return strings.clone_to_cstring(string_data), err;
}
/*! STRING */
/* ARRAY */

@(private)
_interpret_bytes_to_multi_indexable :: #force_inline proc(
    val: rawptr,
    val_offset: int,
    len: int,
    element_id: typeid,
    data: []byte,
) -> (err: Marshall_Error) {
    subarray_len, whole_size: u32 = 0, 0;
    special_size: u64 = 0;
    for i in 0..<len {
        // read length of one subarray
        interpret_bytes_to_int_data(special_size, data[whole_size : whole_size + 8]) or_return;
        // get correct values out of "special_size"
        subarray_len = u32(special_size >> 32);

        // allocate the subarray buffer
        array_byte_size := u32(special_size & 0x00000000FFFFFFFF);
        // fmt.printf("Array byte size: %v; subarray_len: %v;\n", array_byte_size, subarray_len);
        value_data_ptr := cast(^runtime.Raw_Slice)rawptr(uintptr(val) + uintptr(val_offset * i));
        err: mem.Allocator_Error;
        value_data_ptr.data, err = mem.alloc(cast(int)array_byte_size);
        value_data_ptr.len = int(subarray_len);
        // fmt.printf("Passing new slice data: %v\n", value_data_ptr);
        if err != .None do return .InternalAllocationError; // todo fix leakage if error'd

        // read the subarray
        deserialize(
            any { rawptr(value_data_ptr), element_id, },
            data[whole_size : whole_size + array_byte_size],
        ) or_return;

        whole_size += array_byte_size;
    }
    return .None;
}

@(private)
_interpret_bytes_to_strings :: #force_inline proc(
    val: rawptr,
    len: int,
    elem_size: int,
    elem_id: typeid,
    data: []byte,
) -> (err: Marshall_Error) {
    data_offset, size: u32 = 8, 0;
    for i := 0; i < len; i += 1 {
        // size of the data is first 4 bytes (of u32 type)
        deserialize(size, data[data_offset : data_offset + size_of(u32)]) or_return;
        size += 4; // size expresses rune-string length not byte-string length
        deserialize(
            any {
                data = rawptr(uintptr(val) + uintptr(i * elem_size)),
                id = elem_id,
            },
            data[data_offset : data_offset + size],
        ) or_return;
        data_offset += size;
    }
    return .None;
}

_interpret_bytes_to_indexable_default :: #force_inline proc(
    val: rawptr,
    elem_size: int,
    elem_id: typeid,
    len: int,
    data: []byte,
) -> (err: Marshall_Error) {
    byte_elem_size := marshall_serialized_size_t(type_info_of(elem_id));
    if byte_elem_size == -1 do return .UnknownError;
    for i in 0..<len {
        deserialize(
            any { rawptr(uintptr(val) + uintptr(i * elem_size)), elem_id },
            data[8 + i * byte_elem_size : 8 + (i + 1) * byte_elem_size],
        ) or_return;
    }
    return .None;
}

interpret_bytes_to_array :: proc(val: any, info: runtime.Type_Info_Array, data: []byte) -> (err: Marshall_Error) {
    if info.count > 0 {
        #partial switch v in info.elem.variant {
            case runtime.Type_Info_String:
                return _interpret_bytes_to_strings(val.data, info.count, info.elem_size, info.elem.id, data);

            case runtime.Type_Info_Array:
                return _interpret_bytes_to_multi_indexable(val.data, v.elem.size, info.count, info.elem.id, data[8:]);

            case runtime.Type_Info_Slice:
                return _interpret_bytes_to_multi_indexable(val.data, info.elem.size, info.count, info.elem.id, data[8:]);

            case runtime.Type_Info_Dynamic_Array:
                return _interpret_bytes_to_multi_indexable(val.data, info.elem.size, info.count, info.elem.id, data[8:]);

            case:
                return _interpret_bytes_to_indexable_default(val.data, info.elem_size, info.elem.id, info.count, data);
        }
    }
    return .None;
}

interpret_bytes_to_enum_array :: #force_inline proc(val: any, info: runtime.Type_Info_Enumerated_Array, data: []byte) -> (err: Marshall_Error) {
    enum_array := val.data;
    elem_size := marshall_serialized_size_t(info.elem);
    data_offset := 8;

    if elem_size == -1 do return .InvalidType;

    for index in 0..<info.count {
        element_ptr := rawptr(uintptr(enum_array) + uintptr(index * info.elem_size));

        deserialize(any { element_ptr, info.elem.id }, data[data_offset : data_offset + elem_size]) or_return;
        data_offset += elem_size;
    }

    return .None;
}

interpret_bytes_to_slice :: proc(val: any, info: runtime.Type_Info_Slice, data: []byte) -> (err: Marshall_Error) {
    slice := cast(^runtime.Raw_Slice)val.data;

    if slice.len == 0 { // slice not preallocated by the caller
        special_size: u64 = 0;
        interpret_bytes_to_int_data(special_size, data[:8]) or_return;
        slice_len := int(special_size >> 32);
        slice.len = cast(int)slice_len;
        slice_data, err := runtime.mem_alloc_bytes(info.elem.size * slice_len, info.elem.align);
        if err != .None do return .InternalAllocationError;
        slice.data = raw_data(slice_data);
    } else {
        // fmt.printf("Slice length deduced! [%v]\nSlice data: [%v]\n", slice.len, slice.data);
    }

    if slice.len == 0 do return .None;

    #partial switch v in runtime.type_info_base(info.elem).variant {
        // requires special iteration
        case runtime.Type_Info_String:
            return _interpret_bytes_to_strings(slice.data, slice.len, info.elem_size, info.elem.id, data);

        case runtime.Type_Info_Array:
            return _interpret_bytes_to_multi_indexable(slice.data, size_of(runtime.Raw_Slice), slice.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Slice:
            return _interpret_bytes_to_multi_indexable(slice.data, size_of(runtime.Raw_Slice), slice.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Dynamic_Array:
            return _interpret_bytes_to_multi_indexable(slice.data, size_of(runtime.Raw_Slice), slice.len, info.elem.id, data[8:]);
        
        case runtime.Type_Info_Struct: // not every struct has the same size.. (especially if it contains indexables/strings)
            prev_size := 8;
            for i := 0; i < slice.len; i += 1 {
                elem_size := u32(0);
                interpret_bytes_to_int_data(
                    elem_size,
                    data[prev_size : prev_size + size_of(u32)],
                ) or_return;
                elem_size += size_of(u32);
                deserialize(
                    any {
                        data = rawptr(uintptr(slice.data) + uintptr(i * info.elem_size)), // note: this offset is for the dynamic array, so it has to be precisely of the size_of(T), not the byte array offset!
                        id = info.elem.id,
                    },
                    data[prev_size : prev_size + cast(int)elem_size],
                ) or_return;
                prev_size += cast(int)elem_size;
            }
            return;

        case:
            elem_size := marshall_deserialized_size(type_info_of(info.elem.id), data[8:]) or_return;
            if elem_size == -1 do return .UnknownError; // this should not happen since here should end up only types which are arbitrary and supported
            for i := 0; i < slice.len; i += 1 {
                deserialize(
                    any {
                        data = rawptr(uintptr(slice.data) + uintptr(i * info.elem_size)), // note: this offset is for the dynamic array, so it has to be precisely of the size_of(T), not the byte array offset!
                        id = info.elem.id,
                    },
                    data[8 + i * elem_size : 8 + (i + 1) * elem_size],
                ) or_return;
            }
            return .None;
    }

    return .UnknownError;
}

interpret_bytes_to_dyn_array :: proc(val: any, info: runtime.Type_Info_Dynamic_Array, data: []byte) -> (err: Marshall_Error) {
    dyn_arr := cast(^runtime.Raw_Dynamic_Array)val.data;

    if dyn_arr.len == 0 { // dyn_arr not preallocated by the caller
        special_size: u64 = 0;
        interpret_bytes_to_int_data(special_size, data[:8]) or_return;
        dyn_arr_len := int(special_size >> 32);
        dyn_arr.len = dyn_arr_len;
        allocator := dyn_arr.allocator.data != nil ? dyn_arr.allocator : context.allocator;
        dyn_arr_data, err := runtime.mem_alloc_bytes(info.elem.size * dyn_arr_len, info.elem.align, allocator);
        if err != .None do return .InternalAllocationError;
        dyn_arr.data = raw_data(dyn_arr_data);
    } else {
        // fmt.printf("Dynamic array length deduced! [%v]\ndyn_arr data: [%v]\n", dyn_arr.len, dyn_arr.data);
    }

    if dyn_arr.len == 0 do return .None; // if it still has size of 0, then that means that array of len == 0 was serialized

    #partial switch v in info.elem.variant {
        // requires special iteration
        case runtime.Type_Info_String:
            return _interpret_bytes_to_strings(dyn_arr.data, dyn_arr.len, info.elem_size, info.elem.id, data)

        case runtime.Type_Info_Array:
            return _interpret_bytes_to_multi_indexable(dyn_arr.data, size_of(runtime.Raw_Dynamic_Array), dyn_arr.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Slice:
            return _interpret_bytes_to_multi_indexable(dyn_arr.data, size_of(runtime.Raw_Dynamic_Array), dyn_arr.len, info.elem.id, data[8:]);

        case runtime.Type_Info_Dynamic_Array:
            return _interpret_bytes_to_multi_indexable(dyn_arr.data, size_of(runtime.Raw_Dynamic_Array), dyn_arr.len, info.elem.id, data[8:]);
        
        // todo: return unsupported type for types that cannot be serialized

        // default
        case:
            elem_size := marshall_deserialized_size(type_info_of(info.elem.id), data[8:]) or_return;
            if elem_size == -1 do return .UnknownError; // this should not happen since here should end up only types which are arbitrary and supported
            for i := 0; i < dyn_arr.len; i += 1 {
                deserialize(
                    any {
                        data = rawptr(uintptr(dyn_arr.data) + uintptr(i * info.elem_size)), // note: this offset is for the dynamic array, so it has to be precisely of the size_of(T), not the byte array offset!
                        id = info.elem.id,
                    },
                    data[8 + i * elem_size : 8 + (i + 1) * elem_size],
                ) or_return;
            }
            return .None;
    }

    return .UnknownError;
}
/*! ARRAY */
/* STRUCT */

//note: the "data" param should be the pointer to the slice at beginning of the last offset
@(private)
_struct_field_size_deduction :: proc "contextless" (struct_info: runtime.Type_Info_Struct, data: []byte) -> (
    byte_offset: int, err: Marshall_Error,
) {
    bo := u32(0);
    interpret_bytes_to_int_data(bo, data) or_return;
    byte_offset = cast(int)bo + 4;
    return;
}
interpret_bytes_to_struct :: proc(val: any, v: runtime.Type_Info_Struct, data: []byte, recurrent := false) -> (err: Marshall_Error) {

    if v.is_raw_union do return .StructIsRawUnion;

    val_prev_offset: uintptr = 0;
    byte_prev_offset: int = size_of(u32);
    for offset, index in v.offsets {
        if v.tags[index] == "NexaTag_Marshallable" || recurrent {
            byte_offset: int

            // if member is also a struct, make recursive iteration
            if type_is_struct(v.types[index]) {
                // determine the byte offset of the 'data' param
                byte_offset = _struct_field_size_deduction(
                    reflect.type_info_base(v.types[index]).variant.(runtime.Type_Info_Struct),
                    data[byte_prev_offset:],
                ) or_return;
                if byte_offset < 0 do return .InvalidType;

                // fmt.printf("Struct field :: [%v/Struct]:\n\tOffset: %v\n\tOffset array: %v\n", v.types[index], byte_offset, data[byte_prev_offset : byte_prev_offset + byte_offset]);
                interpret_bytes_to_struct(
                    any {
                        data = rawptr(uintptr(val.data) + offset),
                        id = v.types[index].id,
                    },
                    runtime.type_info_base(v.types[index]).variant.(runtime.Type_Info_Struct),
                    data[byte_prev_offset : byte_prev_offset + byte_offset],
                    true,
                ) or_return;
            } else {
                // determine the byte offset of the 'data' param
                byte_offset = marshall_deserialized_size(
                    reflect.type_info_base(v.types[index]),
                    data[byte_prev_offset:],
                ) or_return;
                if byte_offset < 0 do return .InvalidType;

                // fmt.printf("Struct field :: [%v]:\n\tOffset: %v; PrevOffset: %v;\n\tOffset array: %v\n", v.types[index], byte_offset, byte_prev_offset, data[byte_prev_offset : byte_prev_offset + byte_offset]);
                deserialize(
                    any {
                        data = rawptr(uintptr(val.data) + offset),
                        id = v.types[index].id,
                    },
                    data[byte_prev_offset : byte_prev_offset + byte_offset],
                ) or_return;
            }
            val_prev_offset += offset;
            byte_prev_offset += byte_offset;
        }
    }

    return .None;
}
/*! STRUCT */

/**
 * @brief function to take any binary data and interpret it into the correct type
 * @note the only binary data that it can deserialize is the data that has been serialized by this marshall pckg in first place!
 */
deserialize :: proc(val: any, data: []byte) -> Marshall_Error {
    type_info := runtime.type_info_base(type_info_of(val.id));

    switch v in type_info.variant {
        case runtime.Type_Info_Named: 
            return .InvalidType;

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
            else do return interpret_bytes_to_float_data(val, data);

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
            if len(data) == 0 do return nil;
            return deserialize(
                any { data = val.data, id = v.elem.id, },
                data
            );

        case runtime.Type_Info_Multi_Pointer:
            if len(data) == 0 do return nil;
            return deserialize(
                any { data = val.data, id = v.elem.id, },
                data
            );

        case runtime.Type_Info_Procedure:
            return .InvalidType;

        case runtime.Type_Info_Array:
            return interpret_bytes_to_array(val, v, data);

        case runtime.Type_Info_Enumerated_Array:
            return interpret_bytes_to_enum_array(val, v, data);

        case runtime.Type_Info_Dynamic_Array:
            return interpret_bytes_to_dyn_array(val, v, data);

        case runtime.Type_Info_Slice:
            return interpret_bytes_to_slice(val, v, data);

        case runtime.Type_Info_Parameters:
            return .InvalidType;

        case runtime.Type_Info_Struct:
            return interpret_bytes_to_struct(val, v, data);

        case runtime.Type_Info_Union:
            return .InvalidType;

        case runtime.Type_Info_Enum:
            return deserialize({ val.data, v.base.id }, data);

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

marshall_deserialized_size_t :: marshall_serialized_size_t;

marshall_deserialized_size :: proc "contextless" (t: ^runtime.Type_Info, data: []byte) -> (size: int = -1, err: Marshall_Error = .InvalidType) {

    _string_size :: proc "contextless" (data: []byte) -> (size: int, err: Marshall_Error) {
        str_size := u32(0);
        interpret_bytes_to_int_data(str_size, data) or_return;
        return cast(int)str_size + 4, .None;
    }

    _iterable_size :: proc "contextless" (data: []byte) -> (size: int, err: Marshall_Error) {
        special_size := u64(0);
        interpret_bytes_to_int_data(special_size, data) or_return;
        return cast(int)(special_size & 0x00000000FFFFFFFF), .None;
    }

    _struct_size :: proc "contextless" (v: runtime.Type_Info_Struct, data: []byte, recurrent := false) -> (size: int, err: Marshall_Error) {
        for offset, index in v.offsets {
            type_info := v.types[index];
            if v.tags[index] == "NexaTag_Marshallable" || recurrent {
                _size := -1;
                if type_is_struct(type_info) {
                    _size = _struct_size(type_info.variant.(runtime.Type_Info_Struct), data[size:], true) or_return;
                } else {
                    _size = marshall_deserialized_size(type_info, data[size:]) or_return;
                }
                if _size == -1 do return -1, .InvalidType;
                size += _size;
            }
        }
        
        return;
    }

    _pointer_size :: proc "contextless" (e: ^runtime.Type_Info, data: []byte) -> (size: int, err: Marshall_Error) {
        #partial switch v in e.variant { // these types are not checked by the *_t function
            case runtime.Type_Info_String:
                return _string_size(data[:4]);
            case runtime.Type_Info_Slice:
                return _iterable_size(data[:8]);
            case runtime.Type_Info_Dynamic_Array:
                return _iterable_size(data[:8]);
        }
        return -1, .InvalidType;
    }

    // fmt.printf("Marshall deseiralized size T[%v]: %v\n", t, marshall_deserialized_size_t(t));

    // should try to grab size out of marshall_deserialized_size_t
    if size = marshall_deserialized_size_t(t); size != -1 do return size, .None;

    // check the remaining possible types (arrays/strings)
    #partial switch v in runtime.type_info_base(t).variant {
        case runtime.Type_Info_String:
            return _string_size(data[:4]);
        case runtime.Type_Info_Slice:
            return _iterable_size(data[:8]);
        case runtime.Type_Info_Dynamic_Array:
            return _iterable_size(data[:8]);
        case runtime.Type_Info_Struct:
            return _struct_size(v, data);
        case runtime.Type_Info_Pointer:
            return _pointer_size(v.elem, data);
        case runtime.Type_Info_Multi_Pointer: 
            return _pointer_size(v.elem, data);
    }
    
    return;
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
    // fmt.printf("%v\n", string(binary_data));
    binary.write_bytes(writer, binary_data);
    return;
}

marshall_read :: proc($T: typeid, path: string) -> (T, Marshall_Error) {
    reader := binary.init_reader();
    binary.load(&reader, path);
    defer binary.dump_reader(&reader);
    return marshall_read_explicit(T, &reader);
}
marshall_read_explicit :: proc($T: typeid, reader: ^binary.Reader) -> (T, Marshall_Error) {
    val: T;
    err := deserialize(val, reader.buffer);
    return val, err;
}