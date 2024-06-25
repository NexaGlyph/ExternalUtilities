//+build windows
package bkpr

import "base:intrinsics"

import "core:mem"
import "core:fmt"

BKPR_PoolObjectID :: distinct u32;
BKPR_POOLOBJECT_UNINITIALIZED :: BKPR_PoolObjectID(0);

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
@(require_results)
init_bkpr_pool :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator, pool_size: BKPR_PoolSizeDescription) -> BKPR_AllocatorError {
    fmt.printf("Pool of type [%v]; requested memory of size: %vB; alignment: %v\n", type_info_of(RESOURCE), pool_size.len * mem.align_forward_int(pool_size.byte_size, pool_size.alignment), pool_size.alignment);

    pool_data := mem.alloc_bytes(
        pool_size.len * pool_size.byte_size,
        pool_size.alignment,
        bkpr_allocator_bare(allocator)
    ) or_return;
	pool^.memory = transmute([]BKPR_PoolObject(RESOURCE))mem.Raw_Slice{raw_data(pool_data), pool_size.len};
    assert(len(pool^.memory) == pool_size.len);

    pool^.unused = &pool^.memory[0];
    pool^.active_id = 1;

    return .None;
}

/**
 * @brief returns the available element from the pool's memory
 */
@(require_results)
next :: proc(pool: ^BKPR_Pool($RESOURCE)) -> (res: ^RESOURCE) {
    if pool^.unused == nil {
        when BKPR_DEBUG_TRACKER_ENABLED do fmt.println("Out of memory!");
        return nil; // out of memory
    }
    res = &pool^.unused^.resource;

    // if "unusued" points to an object that has non-zero id value, it must have been initialized previously and deleted
    // in that case, the id is going to be left unchanged
    if pool^.unused^.id == BKPR_POOLOBJECT_UNINITIALIZED {
        pool^.unused^.id = pool^.active_id; // TODO: make this unique to each pool!
        pool^.active_id += 1;
    } else {
        fmt.printf("ID NOT INCRMEENTED\n");
    }

    _ = seek_unused(pool); // 'false' returned will not be of any use until next 'next()' call
    return;
}

@(require_results)
query_id :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), ptr: BKPR_Pointer(RESOURCE, $VTABLE)) -> BKPR_PoolObjectID 
    where intrinsics.type_is_variant_of(BKPR_Resource, RESOURCE) 
{
    for obj in &pool^.memory {
        if ptr.resource_ref == &obj.resource do return obj.id;
    }
    return BKPR_POOLOBJECT_UNINITIALIZED;
}

/**
 * @brief will delete a resource using its pointer
 */
delete_from_bkpr_pool_by_ptr :: proc(pool: ^BKPR_Pool($RESOURCE), ptr: ^BKPR_Pointer(RESOURCE, $VTABLE)) 
    where intrinsics.type_is_variant_of(BKPR_Resource, RESOURCE) 
{
    for obj in &pool^.memory {
        if ptr.resource_ref == &obj.resource {
            pool^.unused = &obj;
            when BKPR_DEBUG_TRACKER_ENABLED do fmt.printf("Object deleting [id: %v]...\n", pool^.unused^.id);
            return;
        }
    }
}

/**
 * @brief will delete a resource using its ID
 * @note it is assumed that this call is going to be used with Custom pools or at least when MANUAL resource dump occurs (this function does not "dump" the underlying RESOURCE memory if necessary...)
 */
delete_from_bkpr_pool_by_id :: proc(pool: ^BKPR_Pool($RESOURCE), id: BKPR_PoolObjectID) {
    for obj in &pool^.memory {
        if id == obj.id {
            pool^.unused = &obj;
            when BKPR_DEBUG_TRACKER_ENABLED do fmt.printf("Object deleting [id: %v]...\n", pool^.unused^.id);
            return;
        }
    }
}

/**
 * @brief function will make a copy of the instance into the pool^.unused pointer but give it a new id, returning nil if the pool is full
 */
@(require_results)
copy_by_instance :: proc(pool: ^BKPR_Pool($RESOURCE), instance: ^RESOURCE) -> ^RESOURCE {
    if pool^.unusued == nil do return nil;
    
    mem.copy(pool^.unusued, instance, size_of(instance));
    pool^.unused^.id = pool^.active_id;
    pool^.active_id += 1;
    _ = seek_unused(pool);
}

/**
 * @brief function will scan for a resource with the id provided, returning nil if it does not
 * @note this function should be used only in case the id is generally known or that custom pools are incorporated into the project
 */
@(require_results)
copy_by_id :: proc(pool: ^BKPR_Pool($RESOURCE), id: BKPR_PoolObjectID) -> ^RESOURCE {
    assert(false, "TODO");
}

delete_from_bkpr_pool :: proc { delete_from_bkpr_pool_by_ptr, delete_from_bkpr_pool_by_id }

/**
 * @brief zeroes the whole pool and resets the free pointer to the first element
 */
when BKPR_DEBUG_TRACKER_ENABLED {

flush :: proc(pool: ^BKPR_Pool($RESOURCE), tracker: ^BKPR_AllocatorTracker) {
    assert(false, "TODO!");
}

} else {

flush :: proc(pool: ^BKPR_Pool($RESOURCE)) {
    mem.zero_slice(pool^.memory);
    pool^.unused = &pool^.memory[0];
}

} //! BKPR_DEBUG_TRACKER_ENABLED

/**
 * @brief seeks the first unitialized BKPR_PoolObject
 */
@(require_results)
seek_unused :: proc(pool: ^BKPR_Pool($RESOURCE)) -> bool {
    for val in &pool^.memory {
        if val.id == BKPR_POOLOBJECT_UNINITIALIZED {
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
@(require_results)
dump_bkpr_pool :: #force_inline proc(pool: ^BKPR_Pool($RESOURCE), allocator: ^BKPR_Allocator) -> BKPR_AllocatorError {
    return mem.delete_slice(pool^.memory, bkpr_allocator_bare(allocator));
}