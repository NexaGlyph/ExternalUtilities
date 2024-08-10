//+build windows
package demo

/**
 * 1. this should check whether the params of the functions are correct
 * 2. should check the uniqueness of the attribute (can be only one App entry)
 * 3. should check the return type
 * 4. should bind this automatically into the core.extern_main
 */
@(NexaAttr_ApplicationEntry)
extern_main :: proc() {
}

Build_Opts :: struct {
    //....
}

nexa_build :: proc(build_opts: ^Build_Opts) {
    //....
}

main :: proc() {
    nexa_build(&Build_Opts{});
}