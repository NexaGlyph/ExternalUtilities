//+build windows
package bkpr

import "base:intrinsics"

import "core:mem"
import "core:fmt"

BKPR_PoolObjectID :: distinct u32;
BKPR_PoolObject_Uninitialized :: BKPR_PoolObjectID(0);

BKPR_PoolObject :: struct($RESOURCE: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, RESOURCE)
{
    resource: RESOURCE,
    id: BKPR_PoolObjectID,
}

BKPR_Pool :: struct($RESOURCE: typeid)
    where intrinsics.type_is_variant_of(BKPR_Resource, RESOURCE) 
{
    memory: []BKPR_PoolObject(RESOURCE),
    active_id: BKPR_PoolObjectID,
    unused: ^BKPR_PoolObject(RESOURCE),
}

/**
 * @brief initializes the BKPR_Pool using the BKPR_Allocator
 */
init_bkpr_pool :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator, size: int) {
    fmt.printf("Pool of type [%v]; requested memory of size: %v; alignment: %v\n", type_info_of(RESOURCE), size, align_of(BKPR_PoolObject(RESOURCE)));
    pool^.memory, _ = mem.make_aligned(
        []BKPR_PoolObject(RESOURCE),
        size / (size_of(BKPR_PoolObject(RESOURCE)) * align_of(BKPR_PoolObject(RESOURCE))),
        align_of(BKPR_PoolObject(RESOURCE)),
        bkpr_allocator_bare(allocator),
    );
    assert(len(pool^.memory) > 0, "Pool allocation memory failed!");
    pool^.unused = &pool^.memory[0];
    pool^.active_id = 1;
}

/**
 * @brief returns the available element from the pool's memory
 */
@(require_results)
next :: proc(pool: ^BKPR_Pool($RESOURCE)) -> (res: ^RESOURCE) {
    if pool^.unused == nil {
        fmt.println("Out of memory!");
        return nil; // out of memory
    }
    res = &pool^.unused^.resource;

    pool^.unused^.id += pool^.active_id; // TODO: make this unique to each pool!
    pool^.active_id += 1;

    _ = seek_unused(pool); // 'false' returned will not be of any use until next 'next()' call
    return;
}

/**
 * @brief will delete a resource using its pointer
 */
delete_from_bkpr_pool_by_ptr :: proc(pool: ^BKPR_Pool($RESOURCE), ptr: BKPR_Pointer(RESOURCE, $TYPE, $VTABLE)) {
    assert(false, "TODO!");
}

/**
 * @brief will delete a resource using its ID
 * >>>NOTE: WILL THE IDs BE UNIQUE ACROSS DIFFERENT POOLS ?
 */
delete_from_bkpr_pool_by_id :: proc(pool: ^BKPR_Pool($RESOURCE), ptr: BKPR_Pointer(RESOURCE, $TYPE, $VTABLE)) {
    assert(false, "TODO!");
}

delete_from_bkpr_pool :: proc { delete_from_bkpr_pool_by_ptr, delete_from_bkpr_pool_by_id }

/**
 * @brief zeroes the whole pool and resets the free pointer to the first element
 */
flush :: proc(pool: ^BKPR_Pool($RESOURCE)) {
    zero_slice(pool^.memory);
    pool^.unused = &pool^.memory[0];
}

/**
 * @brief seeks the first unitialized BKPR_PoolObject
 */
@(require_results)
seek_unused :: proc(pool: ^BKPR_Pool($RESOURCE)) -> bool {
    for val in &pool^.memory {
        if val.id == BKPR_PoolObject_Uninitialized {
            pool^.unused = &val;
            return true;
        }
    }
    pool^.unused = nil;
    return false;
}

/**
 * @brief dumps the whole Pool memory
 */
dump_bkpr_pool :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator) {
    delete_slice(pool^.memory, bkpr_allocator_bare(allocator));
}