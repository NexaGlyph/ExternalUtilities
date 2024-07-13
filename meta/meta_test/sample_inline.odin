//+build windows
package test

@(NexaAttr_Inline)
function_to_inline :: proc() {
}

@(NexaAttr_Inline)
function_to_inline2 :: proc() -> int {
    return 0;
}

@(NexaAttr_Inline)
function_to_inline3 :: proc(param1: int, param2: string, param3: [dynamic]f32) {
}

@(NexaAttr_Inline)
function_to_inline4 :: proc(param1: []f32) -> Maybe(int) {
    return nil;
}