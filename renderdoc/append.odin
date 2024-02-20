/* THIS IS PREGENERATED FILE */
/* CONTENTS OF THIS FILE SHOULD NOT BE CHANGED MANUALLY... see scripts */

package renderdoc

import "core:dynlib"

_load_instance_proc_addr :: proc(renderdoc_handler: ^RENDERDOC_HANDLER) {
	renderdoc_handler.rdoc_api.Shutdown                    = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_Shutdown");
	renderdoc_handler.rdoc_api.GetCapture                  = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetCapture");
	renderdoc_handler.rdoc_api.RemoveHooks                 = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_RemoveHooks");
	renderdoc_handler.rdoc_api.ShowReplayUI                = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_ShowReplayUI");
	renderdoc_handler.rdoc_api.GetAPIVersion               = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetAPIVersion");
	renderdoc_handler.rdoc_api.SetCaptureKeys              = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureKeys");
	renderdoc_handler.rdoc_api.GetOverlayBits              = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetOverlayBits");
	renderdoc_handler.rdoc_api.GetNumCaptures              = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetNumCaptures");
	renderdoc_handler.rdoc_api.TriggerCapture              = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_TriggerCapture");
	renderdoc_handler.rdoc_api.LaunchReplayUI              = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_LaunchReplayUI");
	renderdoc_handler.rdoc_api.MaskOverlayBits             = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_MaskOverlayBits");
	renderdoc_handler.rdoc_api.SetActiveWindow             = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetActiveWindow");
	renderdoc_handler.rdoc_api.EndFrameCapture             = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_EndFrameCapture");
	renderdoc_handler.rdoc_api.SetCaptureTitle             = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureTitle");
	renderdoc_handler.rdoc_api.IsFrameCapturing            = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_IsFrameCapturing");
	renderdoc_handler.rdoc_api.StartFrameCapture           = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_StartFrameCapture");
	renderdoc_handler.rdoc_api.SetFocusToggleKeys          = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetFocusToggleKeys");
	renderdoc_handler.rdoc_api.UnloadCrashHandler          = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_UnloadCrashHandler");
	renderdoc_handler.rdoc_api.SetCaptureOptionU32         = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureOptionU32");
	renderdoc_handler.rdoc_api.SetCaptureOptionF32         = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureOptionF32");
	renderdoc_handler.rdoc_api.GetCaptureOptionU32         = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetCaptureOptionU32");
	renderdoc_handler.rdoc_api.GetCaptureOptionF32         = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetCaptureOptionF32");
	renderdoc_handler.rdoc_api.DiscardFrameCapture         = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_DiscardFrameCapture");
	renderdoc_handler.rdoc_api.SetLogFilePathTemplate      = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetLogFilePathTemplate");
	renderdoc_handler.rdoc_api.GetLogFilePathTemplate      = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetLogFilePathTemplate");
	renderdoc_handler.rdoc_api.SetCaptureFileComments      = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureFileComments");
	renderdoc_handler.rdoc_api.IsRemoteAccessConnected     = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_IsRemoteAccessConnected");
	renderdoc_handler.rdoc_api.IsTargetControlConnected    = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_IsTargetControlConnected");
	renderdoc_handler.rdoc_api.TriggerMultiFrameCapture    = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_TriggerMultiFrameCapture");
	renderdoc_handler.rdoc_api.SetCaptureFilePathTemplate  = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_SetCaptureFilePathTemplate");
	renderdoc_handler.rdoc_api.GetCaptureFilePathTemplate  = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_GetCaptureFilePathTemplate");


 	/*-----ASSERTION LAYER-----*/
	assert(renderdoc_handler.rdoc_api.Shutdown                    != nil, "failed to bind RENDERDOC_Shutdown");
	assert(renderdoc_handler.rdoc_api.GetCapture                  != nil, "failed to bind RENDERDOC_GetCapture");
	assert(renderdoc_handler.rdoc_api.RemoveHooks                 != nil, "failed to bind RENDERDOC_RemoveHooks");
	assert(renderdoc_handler.rdoc_api.ShowReplayUI                != nil, "failed to bind RENDERDOC_ShowReplayUI");
	assert(renderdoc_handler.rdoc_api.GetAPIVersion               != nil, "failed to bind RENDERDOC_GetAPIVersion");
	assert(renderdoc_handler.rdoc_api.SetCaptureKeys              != nil, "failed to bind RENDERDOC_SetCaptureKeys");
	assert(renderdoc_handler.rdoc_api.GetOverlayBits              != nil, "failed to bind RENDERDOC_GetOverlayBits");
	assert(renderdoc_handler.rdoc_api.GetNumCaptures              != nil, "failed to bind RENDERDOC_GetNumCaptures");
	assert(renderdoc_handler.rdoc_api.TriggerCapture              != nil, "failed to bind RENDERDOC_TriggerCapture");
	assert(renderdoc_handler.rdoc_api.LaunchReplayUI              != nil, "failed to bind RENDERDOC_LaunchReplayUI");
	assert(renderdoc_handler.rdoc_api.MaskOverlayBits             != nil, "failed to bind RENDERDOC_MaskOverlayBits");
	assert(renderdoc_handler.rdoc_api.SetActiveWindow             != nil, "failed to bind RENDERDOC_SetActiveWindow");
	assert(renderdoc_handler.rdoc_api.EndFrameCapture             != nil, "failed to bind RENDERDOC_EndFrameCapture");
	assert(renderdoc_handler.rdoc_api.SetCaptureTitle             != nil, "failed to bind RENDERDOC_SetCaptureTitle");
	assert(renderdoc_handler.rdoc_api.IsFrameCapturing            != nil, "failed to bind RENDERDOC_IsFrameCapturing");
	assert(renderdoc_handler.rdoc_api.StartFrameCapture           != nil, "failed to bind RENDERDOC_StartFrameCapture");
	assert(renderdoc_handler.rdoc_api.SetFocusToggleKeys          != nil, "failed to bind RENDERDOC_SetFocusToggleKeys");
	assert(renderdoc_handler.rdoc_api.UnloadCrashHandler          != nil, "failed to bind RENDERDOC_UnloadCrashHandler");
	assert(renderdoc_handler.rdoc_api.SetCaptureOptionU32         != nil, "failed to bind RENDERDOC_SetCaptureOptionU32");
	assert(renderdoc_handler.rdoc_api.SetCaptureOptionF32         != nil, "failed to bind RENDERDOC_SetCaptureOptionF32");
	assert(renderdoc_handler.rdoc_api.GetCaptureOptionU32         != nil, "failed to bind RENDERDOC_GetCaptureOptionU32");
	assert(renderdoc_handler.rdoc_api.GetCaptureOptionF32         != nil, "failed to bind RENDERDOC_GetCaptureOptionF32");
	assert(renderdoc_handler.rdoc_api.DiscardFrameCapture         != nil, "failed to bind RENDERDOC_DiscardFrameCapture");
	assert(renderdoc_handler.rdoc_api.SetLogFilePathTemplate      != nil, "failed to bind RENDERDOC_SetLogFilePathTemplate");
	assert(renderdoc_handler.rdoc_api.GetLogFilePathTemplate      != nil, "failed to bind RENDERDOC_GetLogFilePathTemplate");
	assert(renderdoc_handler.rdoc_api.SetCaptureFileComments      != nil, "failed to bind RENDERDOC_SetCaptureFileComments");
	assert(renderdoc_handler.rdoc_api.IsRemoteAccessConnected     != nil, "failed to bind RENDERDOC_IsRemoteAccessConnected");
	assert(renderdoc_handler.rdoc_api.IsTargetControlConnected    != nil, "failed to bind RENDERDOC_IsTargetControlConnected");
	assert(renderdoc_handler.rdoc_api.TriggerMultiFrameCapture    != nil, "failed to bind RENDERDOC_TriggerMultiFrameCapture");
	assert(renderdoc_handler.rdoc_api.SetCaptureFilePathTemplate  != nil, "failed to bind RENDERDOC_SetCaptureFilePathTemplate");
	assert(renderdoc_handler.rdoc_api.GetCaptureFilePathTemplate  != nil, "failed to bind RENDERDOC_GetCaptureFilePathTemplate");
}