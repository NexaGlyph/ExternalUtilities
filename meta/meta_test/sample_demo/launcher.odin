//+build windows
package demo

@(private)
some_launcher_internal_function :: proc(opt: string) -> bool {
    return false;
}

@(NexaAttr_LauncherEntry)
extern_launch :: proc() {
}