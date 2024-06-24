//+build windows
package bkpr

import "base:intrinsics"

import "core:fmt"

BKPR_PointerType :: enum u8 {
    Immutable = 0,
    Unique = 1,
    Shared = 2,
}

BKPR_Pointer :: struct($MEMORY: typeid, $VTABLE: typeid)
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY) /*&& intrinsics.type_is_subtype_of(BKPR_PointerBaseVTABLE(MEMORY), VTABLE)*/
{
    mem: ^MEMORY,
    type: BKPR_PointerType,
    using vtable: VTABLE,
}

BKPR_PointerBaseVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    address:        proc (this: ^BKPR_Pointer(MEMORY, BKPR_PointerBaseVTABLE(MEMORY))) -> ^MEMORY,
    address_of:     proc (this: ^BKPR_Pointer(MEMORY, BKPR_PointerBaseVTABLE(MEMORY))) -> ^^MEMORY,
    dump:           proc (this: ^BKPR_Pointer(MEMORY, BKPR_PointerBaseVTABLE(MEMORY))),
}
BKPR_PointerImmutableVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    #subtype base: BKPR_PointerBaseVTABLE(MEMORY),
}
BKPR_PointerUniqueVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    #subtype base: BKPR_PointerBaseVTABLE(MEMORY),
    update:        proc (this: ^BKPR_Pointer(MEMORY, BKPR_PointerUniqueVTABLE(MEMORY))),
}
BKPR_PointerSharedVTABLE :: struct($MEMORY: typeid)
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    #subtype base: BKPR_PointerBaseVTABLE(MEMORY),
    make_shared:        proc (this: ^BKPR_Pointer(MEMORY, BKPR_PointerUniqueVTABLE(MEMORY))) -> ^MEMORY,
}

address_texture :: proc(this: ^BKPR_Pointer(BKPR_Texture, BKPR_PointerBaseVTABLE(BKPR_Texture))) -> ^BKPR_Texture {
    fmt.println("Returning texture address!");
    return nil;
}
address_of_texture :: proc(this: ^BKPR_Pointer(BKPR_Texture, BKPR_PointerBaseVTABLE(BKPR_Texture))) -> ^^BKPR_Texture {
    fmt.println("Returning pointer to texture address!");
    return nil;
}
dump_texture :: proc(this: ^BKPR_Pointer(BKPR_Texture, BKPR_PointerBaseVTABLE(BKPR_Texture))) {
    fmt.println("Dumping texture!");
}