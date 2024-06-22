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
    mem: ^MEMORY,
    type: BKPR_PointerType,
    using vtable: VTABLE,
}

BKPR_PointerImmutableVTABLE :: struct {}
BKPR_PointerUniqueVTABLE :: struct {}
BKPR_PointerSharedVTABLE :: struct {}