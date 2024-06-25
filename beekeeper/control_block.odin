//+build windows
package bkpr

import "base:intrinsics"

BKPR_AtomicInt   :: distinct int;
BKPR_AtomicBoool :: distinct bool;

/* CONTROL BLOCK */
BKPR_PointerSharedControlBlock :: struct($MEMORY: typeid) 
    where intrinsics.type_is_variant_of(BKPR_Resource, MEMORY)
{
    ref_count: BKPR_AtomicInt,
    resource: ^MEMORY,
    valid: BKPR_AtomicBoool,
}

init_control_block :: proc(resource: $MEMORY) -> ^BKPR_PointerSharedControlBlock 
    where intrinsics.type_is_variant_of(MEMORY)
{
    control_block := new(BKPR_PointerSharedControlBlock);
    intrinsics.atomic_store_explicit(&control_block^.ref_count, 1, .Relaxed);
    control_block.resource = resource;
    intrinsics.atomic_store_explicit(&control_block^.valid, true, .Relaxed);
    return control_block;
}

invalidate_control_block :: #force_inline proc(control_block: ^BKPR_PointerSharedControlBlock) {
    intrinsics.atomic_store_explicit(&control_block^.valid, false, .Relaxed);
}

add_ref :: proc(control_block: ^BKPR_PointerSharedControlBlock) {
    intrinsics.atomic_add_explicit(&control_block^.ref_count, 1, .Relaxed);
}

release_ref :: proc(control_block: ^BKPR_PointerSharedControlBlock) {
    if control_block.ref_count.fetch_sub(1) == 1 {
        invalidate_control_block(control_block);
        free(control_block.resource);
        free(control_block);
    }
}

/* SHARED PTR */

/**
 * @brief creates original BKPR_PointerShared
 * @note if you want to create new instance of BKPR_PointerShared, you have you use the VTABLE!!! (@see copy_shared)
 */
init_shared :: #force_inline proc "contextless" (resource: $RESOURCE) -> BKPR_PointerShared(RESOURCE) {
    control_block := new_control_block(&resource);
    return BKPR_PointerShared(RESOURCE){
        control_block = control_block,
    };
}

/**
 * @brief this function is going to be called when user makes explicit copy of BKPR_PointerShared
 */
@(private)
copy_shared :: #force_inline proc "contextless" (ptr: BKPR_PointerShared($RESOURCE)) -> BKPR_PointerShared(RESOURCE) {
    add_ref(ptr.control_block);
    return BKPR_PointerShared(RESOURCE) {
        control_block = ptr.control_block,
    };
}

/**
 * @brief this function is going to be called when user makes explicit dump of BKPR_PointerShared
 */
@(private)
shared_release :: #force_inline proc "contextless" (ptr: ^BKPR_PointerShared($RESOURCE)) {
    if ptr.control_block != nil {
        release_ref(ptr.control_block);
        ptr.control_block = nil;
    }
}

/**
 * @brief this function is going to be called when user requests address of the underlying memory
 */
@(private)
get_resource :: #force_inline proc "contextless" (ptr: BKPR_PointerShared($RESOURCE)) -> ^RESOURCE {
    if ptr.control_block != nil && intrinsics.atomic_load_explicit(&ptr^.control_block^.valid, .Relaxed) {
        return ptr.control_block.resource;
    }
    return nil;
}