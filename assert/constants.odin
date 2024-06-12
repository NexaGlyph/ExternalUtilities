package assert

import "core:os"
import "core:log"

import D3D11 "vendor:directx/d3d11"

S_OK :: 0x00000000;
S_FALSE :: 0x00000001;

E_INVALID_PARAM :: -2147024809;

when ODIN_DEBUG {
    ASSERT :: #force_inline proc(res: D3D11.HRESULT, err_message: string, location := #caller_location) {
        if (res == S_OK) do return;
        switch res {
            case E_INVALID_PARAM:
                log.errorf("ERROR: INVALID PARAM!\n%s", location);
                break;
            case:
                log.errorf("%v %v", res, location);
                break;
        }
        assert(res == S_OK, err_message, location);
    }
    VALIDATE :: #force_inline proc(res: D3D11.HRESULT, err_message: string, location := #caller_location) {
        if (res == S_FALSE) do return;
        switch res {
            case E_INVALID_PARAM:
                log.errorf("ERROR: INVALID PARAM!\n%s", location);
                break;
            case:
                log.errorf("%v", res, location);
                break;
        }
        assert(res == S_OK, err_message, location);
    }
}
else {
    @(disabled=true)
    ASSERT :: #force_inline proc(res: D3D11.HRESULT, err_message: string, location := #caller_location) {
        assert(res == S_OK, err_message, location);
    }
    @(disabled=true)
    VALIDATE :: #force_inline proc(res: D3D11.HRESULT, err_message: string, location := #caller_location) {}
}

CHECK_RESULT :: #force_inline proc(res: D3D11.HRESULT, location := #caller_location) {
    if res == S_OK do return;
    log.errorf("[%s]....... error: %v", res);
    os.exit(1);
}