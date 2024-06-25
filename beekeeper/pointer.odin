//+build windows
package bkpr

import "base:intrinsics"

BKPR_PointerType :: enum u8 {
    Immutable = 0,
    Unique = 1,
    Shared = 2,
}

BKPR_Pointer :: struct($MEMORY: typeid, $VTABLE: typeid)
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    resource_ref: ^MEMORY,
    type: BKPR_PointerType,
    using vtable: VTABLE,
}

BKPR_PointerImmutable :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    using _: BKPR_Pointer(MEMORY, BKPR_PointerImmutableVTABLE(MEMORY)),
}
// since we cannot really make a "typed" type alias, we will create a blank structure for convenience of abstracting few lines of "typed" programming
// size preserved, hence the check
#assert(
    size_of(BKPR_PointerImmutable(BKPR_Texture)) == size_of(
        BKPR_Pointer(BKPR_Texture, BKPR_PointerImmutableVTABLE(BKPR_Texture))
    )
);

BKPR_PointerUnique :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    using _: BKPR_Pointer(MEMORY, BKPR_PointerUniqueVTABLE(MEMORY)),
}
#assert(
    size_of(BKPR_PointerUnique(BKPR_Texture)) == size_of(
        BKPR_Pointer(BKPR_Texture, BKPR_PointerUniqueVTABLE(BKPR_Texture))
    )
);

/**
 @note PointerShared's resource cannot be operated on ad extra
 */
BKPR_PointerShared :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    control_block: ^BKPR_PointerSharedControlBlock(MEMORY),
    type: BKPR_PointerType,
    using vtable: BKPR_PointerSharedVTABLE(MEMORY),
}
#assert(
    size_of(BKPR_PointerShared(BKPR_Texture)) == size_of(
        BKPR_Pointer(BKPR_Texture, BKPR_PointerSharedVTABLE(BKPR_Texture))
    )
);

/**
 * @brief Immmutable pointers cannot be overriden nor copied, only accessed, 
 */
BKPR_PointerImmutableVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    dump:    proc(this: ^BKPR_PointerImmutable(MEMORY)),
    address: proc(this: ^BKPR_PointerImmutable(MEMORY)) -> ^MEMORY,
}

/**
 * @brief Unique pointers are capable of "overriding" or "updating" its underlying memory, for convenience and avoidance of further unions, the update_desc of the update method
 * is going to be rawptr (this is not hapzard to the code structure since each BKPR_Resource's unique pointer implementation will deal with this in an cast to BKPR_ResourceDesc pointer)
 */
BKPR_PointerUniqueVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    dump:          proc(this: ^BKPR_PointerUnique(MEMORY)),
    address:       proc(this: ^BKPR_PointerUnique(MEMORY)) -> ^MEMORY,

    update:        proc(this: ^BKPR_PointerUnique(MEMORY), update_desc: rawptr),
}

/**
 * @brief Shared pointer have the abilities of the unqiue pointers but also can be "copied" (TODO!)
 */
BKPR_PointerSharedVTABLE :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    dump:          proc(this: ^BKPR_PointerShared(MEMORY)),
    address:       proc(this: ^BKPR_PointerShared(MEMORY)) -> ^MEMORY,

    update:        proc(this: ^BKPR_PointerShared(MEMORY), update_desc: rawptr),
    make_shared:   proc(this: ^BKPR_PointerShared(MEMORY)) -> ^MEMORY,
}