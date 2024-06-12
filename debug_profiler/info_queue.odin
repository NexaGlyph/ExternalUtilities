package debug_profiler

import "core:fmt"
import "core:mem"

import D3D11 "vendor:directx/d3d11"

/*>>>NOTE: TO DO: CONNECT THIS TO THE EX_UTILS.ODIN */

setup_info_queue :: proc(info_queue: ^D3D11.IInfoQueue) {
    // info_queue->ClearStoredMessages();
    {
        info_queue->SetBreakOnSeverity(D3D11.MESSAGE_SEVERITY.INFO, true);
        info_queue->SetBreakOnSeverity(D3D11.MESSAGE_SEVERITY.MESSAGE, true);
        info_queue->SetBreakOnSeverity(D3D11.MESSAGE_SEVERITY.WARNING, true);
        info_queue->SetBreakOnSeverity(D3D11.MESSAGE_SEVERITY.ERROR, true);
        info_queue->SetBreakOnSeverity(D3D11.MESSAGE_SEVERITY.CORRUPTION, true);
        info_queue->SetMuteDebugOutput(false);
    }
}

redirect_debug_output_file :: proc(info_queue: ^D3D11.IInfoQueue, filepath: string = "DEBUG_LAYER_OUTPUT.log") {
    // writer := file.Writer{
    //     path = filepath,
    //     mode = os.O_CREATE | os.O_WRONLY,
    // };
    // file.open_writer(&writer);
    // defer file.close_writer(&writer);

    for i in 0..<info_queue->GetNumStoredMessages() {
        message_len := uint(0);
        info_queue->GetMessage(i, nil, &message_len);
        fmt.printf("\x1b[32m%v", message_len);

        message: ^D3D11.MESSAGE;
        message_data, err := mem.alloc(auto_cast message_len);
        if err != .None do assert(false);
        message = cast(^D3D11.MESSAGE)message_data;
        defer free(message_data);

        info_queue->GetMessage(i, message, nil);

        fmt.printf("\x1b[32m%v", message);
    }

    fmt.printf("\x1b[90m");
}
