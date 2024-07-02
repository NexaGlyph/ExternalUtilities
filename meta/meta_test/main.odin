//+build windows
package test

main :: proc() {
    res := Resource{};
    res = Atlas{};
    accept_resource_any(res);
}