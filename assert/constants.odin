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

QUERY_ERROR :: #force_inline proc  (res: D3D11.HRESULT) -> (string, bool) {
    return D3D_ERR_LIST[cast(u32)res];
}

// DXGI ERROR CODES
DXGI_STATUS_OCCLUDED                                     : u32 : 0x087A0001; // The target window or output has been occluded. The application should suspend rendering operations if possible.
DXGI_STATUS_CLIPPED                                      : u32 : 0x087A0002; // Target window is clipped.
DXGI_STATUS_NO_REDIRECTION                               : u32 : 0x087A0004; // No redirection.
DXGI_STATUS_NO_DESKTOP_ACCESS                            : u32 : 0x087A0005; // No access to desktop.
DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE                 : u32 : 0x087A0006; // The graphics adapter source is already in use.
DXGI_STATUS_MODE_CHANGED                                 : u32 : 0x087A0007; // Display mode has changed.
DXGI_STATUS_MODE_CHANGE_IN_PROGRESS                      : u32 : 0x087A0008; // Display mode is changing.
DXGI_ERROR_INVALID_CALL                                  : u32 : 0x887A0001; // The application has made an erroneous API call that it had enough information to avoid.
DXGI_ERROR_NOT_FOUND                                     : u32 : 0x887A0002; // The item requested was not found.
DXGI_ERROR_MORE_DATA                                     : u32 : 0x887A0003; // The specified size of the destination buffer is too small to hold the requested data.
DXGI_ERROR_UNSUPPORTED                                   : u32 : 0x887A0004; // Unsupported.
DXGI_ERROR_DEVICE_REMOVED                                : u32 : 0x887A0005; // Hardware device removed.
DXGI_ERROR_DEVICE_HUNG                                   : u32 : 0x887A0006; // Device hung due to badly formed commands.
DXGI_ERROR_DEVICE_RESET                                  : u32 : 0x887A0007; // Device reset due to a badly formed command.
DXGI_ERROR_WAS_STILL_DRAWING                             : u32 : 0x887A000A; // Was still drawing.
DXGI_ERROR_FRAME_STATISTICS_DISJOINT                     : u32 : 0x887A000B; // The requested functionality is not supported by the device or the driver.
DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE                  : u32 : 0x887A000C; // The requested functionality is not supported by the device or the driver.
DXGI_ERROR_DRIVER_INTERNAL_ERROR                         : u32 : 0x887A0020; // An internal driver error occurred.
DXGI_ERROR_NONEXCLUSIVE                                  : u32 : 0x887A0021; // The application attempted to perform an operation on an DXGI output that is only legal after the output has been claimed for exclusive ownership.
DXGI_ERROR_NOT_CURRENTLY_AVAILABLE                       : u32 : 0x887A0022; // The requested functionality is not supported by the device or the driver.
DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED                    : u32 : 0x887A0023; // Remote desktop client disconnected.
DXGI_ERROR_REMOTE_OUTOFMEMORY                            : u32 : 0x887A0024; // Remote desktop client is out of memory.
// D3D11 ERROR CODES
D3D11_ERROR_TOO_MANY_UNIQUE_STATE_OBJECTS                : u32 : 0x887C0001; // There are too many unique state objects.
D3D11_ERROR_FILE_NOT_FOUND                               : u32 : 0x887C0002; // File not found.
D3D11_ERROR_TOO_MANY_UNIQUE_VIEW_OBJECTS                 : u32 : 0x887C0003; // There are too many unique view objects.
D3D11_ERROR_DEFERRED_CONTEXT_MAP_WITHOUT_INITIAL_DISCARD : u32 : 0x887C0004; // Deferred context requires Map-Discard usage pattern.

@(private="file")
D3D_ERR_LIST := map[u32]string {
    DXGI_STATUS_OCCLUDED                                     = "The target window or output has been occluded. The application should suspend rendering operations if possible.",
    DXGI_STATUS_CLIPPED                                      = "Target window is clipped.",
    DXGI_STATUS_NO_REDIRECTION                               = "",
    DXGI_STATUS_NO_DESKTOP_ACCESS                            = "No access to desktop.",
    DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE                 = "",
    DXGI_STATUS_MODE_CHANGED                                 = "Display mode has changed",
    DXGI_STATUS_MODE_CHANGE_IN_PROGRESS                      = "Display mode is changing",
    DXGI_ERROR_INVALID_CALL                                  = "The application has made an erroneous API call that it had enough information to avoid. This error is intended to denote that the application should be altered to avoid the error. Use of the debug version of the DXGI.DLL will provide run-time debug output with further information.",
    DXGI_ERROR_NOT_FOUND                                     = "The item requested was not found. For GetPrivateData calls, this means that the specified GUID had not been previously associated with the object.",
    DXGI_ERROR_MORE_DATA                                     = "The specified size of the destination buffer is too small to hold the requested data.",
    DXGI_ERROR_UNSUPPORTED                                   = "Unsupported.",
    DXGI_ERROR_DEVICE_REMOVED                                = "Hardware device removed.",
    DXGI_ERROR_DEVICE_HUNG                                   = "Device hung due to badly formed commands.",
    DXGI_ERROR_DEVICE_RESET                                  = "Device reset due to a badly formed commant.",
    DXGI_ERROR_WAS_STILL_DRAWING                             = "Was still drawing.",
    DXGI_ERROR_FRAME_STATISTICS_DISJOINT                     = "The requested functionality is not supported by the device or the driver.",
    DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE                  = "The requested functionality is not supported by the device or the driver.",
    DXGI_ERROR_DRIVER_INTERNAL_ERROR                         = "An internal driver error occurred.",
    DXGI_ERROR_NONEXCLUSIVE                                  = "The application attempted to perform an operation on an DXGI output that is only legal after the output has been claimed for exclusive owenership.",
    DXGI_ERROR_NOT_CURRENTLY_AVAILABLE                       = "The requested functionality is not supported by the device or the driver.",
    DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED                    = "Remote desktop client disconnected.",
    DXGI_ERROR_REMOTE_OUTOFMEMORY                            = "Remote desktop client is out of memory.",
    D3D11_ERROR_TOO_MANY_UNIQUE_STATE_OBJECTS                = "There are too many unique state objects.",
    D3D11_ERROR_FILE_NOT_FOUND                               = "File not found",
    D3D11_ERROR_TOO_MANY_UNIQUE_VIEW_OBJECTS                 = "Therea are too many unique view objects.",
    D3D11_ERROR_DEFERRED_CONTEXT_MAP_WITHOUT_INITIAL_DISCARD = "Deferred context requires Map-Discard usage pattern",
}