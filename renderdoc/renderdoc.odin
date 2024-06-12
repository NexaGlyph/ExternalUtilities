package renderdoc

RENDERDOC_CaptureOption :: enum {
  // Allow the application to enable vsync
  //
  // Default - enabled
  //
  // 1 - The application can enable or disable vsync at will
  // 0 - vsync is force disabled
  eRENDERDOC_Option_AllowVSync = 0,

  // Allow the application to enable fullscreen
  //
  // Default - enabled
  //
  // 1 - The application can enable or disable fullscreen at will
  // 0 - fullscreen is force disabled
  eRENDERDOC_Option_AllowFullscreen = 1,

  // Record API debugging events and messages
  //
  // Default - disabled
  //
  // 1 - Enable built-in API debugging features and records the results into
  //     the capture, which is matched up with events on replay
  // 0 - no API debugging is forcibly enabled
  eRENDERDOC_Option_APIValidation = 2,
  eRENDERDOC_Option_DebugDeviceMode = 2,    // deprecated name of this enum

  // Capture CPU callstacks for API events
  //
  // Default - disabled
  //
  // 1 - Enables capturing of callstacks
  // 0 - no callstacks are captured
  eRENDERDOC_Option_CaptureCallstacks = 3,

  // When capturing CPU callstacks, only capture them from actions.
  // This option does nothing without the above option being enabled
  //
  // Default - disabled
  //
  // 1 - Only captures callstacks for actions.
  //     Ignored if CaptureCallstacks is disabled
  // 0 - Callstacks, if enabled, are captured for every event.
  eRENDERDOC_Option_CaptureCallstacksOnlyDraws = 4,
  eRENDERDOC_Option_CaptureCallstacksOnlyActions = 4,

  // Specify a delay in seconds to wait for a debugger to attach, after
  // creating or injecting into a process, before continuing to allow it to run.
  //
  // 0 indicates no delay, and the process will run immediately after injection
  //
  // Default - 0 seconds
  //
  eRENDERDOC_Option_DelayForDebugger = 5,

  // Verify buffer access. This includes checking the memory returned by a Map() call to
  // detect any out-of-bounds modification, as well as initialising buffers with undefined contents
  // to a marker value to catch use of uninitialised memory.
  //
  // NOTE: This option is only valid for OpenGL and D3D11. Explicit APIs such as D3D12 and Vulkan do
  // not do the same kind of interception & checking and undefined contents are really undefined.
  //
  // Default - disabled
  //
  // 1 - Verify buffer access
  // 0 - No verification is performed, and overwriting bounds may cause crashes or corruption in
  //     RenderDoc.
  eRENDERDOC_Option_VerifyBufferAccess = 6,

  // The old name for eRENDERDOC_Option_VerifyBufferAccess was eRENDERDOC_Option_VerifyMapWrites.
  // This option now controls the filling of uninitialised buffers with 0xdddddddd which was
  // previously always enabled
  eRENDERDOC_Option_VerifyMapWrites = eRENDERDOC_Option_VerifyBufferAccess,

  // Hooks any system API calls that create child processes, and injects
  // RenderDoc into them recursively with the same options.
  //
  // Default - disabled
  //
  // 1 - Hooks into spawned child processes
  // 0 - Child processes are not hooked by RenderDoc
  eRENDERDOC_Option_HookIntoChildren = 7,

  // By default RenderDoc only includes resources in the final capture necessary
  // for that frame, this allows you to override that behaviour.
  //
  // Default - disabled
  //
  // 1 - all live resources at the time of capture are included in the capture
  //     and available for inspection
  // 0 - only the resources referenced by the captured frame are included
  eRENDERDOC_Option_RefAllResources = 8,

  // **NOTE**: As of RenderDoc v1.1 this option has been deprecated. Setting or
  // getting it will be ignored, to allow compatibility with older versions.
  // In v1.1 the option acts as if it's always enabled.
  //
  // By default RenderDoc skips saving initial states for resources where the
  // previous contents don't appear to be used, assuming that writes before
  // reads indicate previous contents aren't used.
  //
  // Default - disabled
  //
  // 1 - initial contents at the start of each captured frame are saved, even if
  //     they are later overwritten or cleared before being used.
  // 0 - unless a read is detected, initial contents will not be saved and will
  //     appear as black or empty data.
  eRENDERDOC_Option_SaveAllInitials = 9,

  // In APIs that allow for the recording of command lists to be replayed later,
  // RenderDoc may choose to not capture command lists before a frame capture is
  // triggered, to reduce overheads. This means any command lists recorded once
  // and replayed many times will not be available and may cause a failure to
  // capture.
  //
  // NOTE: This is only true for APIs where multithreading is difficult or
  // discouraged. Newer APIs like Vulkan and D3D12 will ignore this option
  // and always capture all command lists since the API is heavily oriented
  // around it and the overheads have been reduced by API design.
  //
  // 1 - All command lists are captured from the start of the application
  // 0 - Command lists are only captured if their recording begins during
  //     the period when a frame capture is in progress.
  eRENDERDOC_Option_CaptureAllCmdLists = 10,

  // Mute API debugging output when the API validation mode option is enabled
  //
  // Default - enabled
  //
  // 1 - Mute any API debug messages from being displayed or passed through
  // 0 - API debugging is displayed as normal
  eRENDERDOC_Option_DebugOutputMute = 11,

  // Option to allow vendor extensions to be used even when they may be
  // incompatible with RenderDoc and cause corrupted replays or crashes.
  //
  // Default - inactive
  //
  // No values are documented, this option should only be used when absolutely
  // necessary as directed by a RenderDoc developer.
  eRENDERDOC_Option_AllowUnsupportedVendorExtensions = 12,

  // Define a soft memory limit which some APIs may aim to keep overhead under where
  // possible. Anything above this limit will where possible be saved directly to disk during
  // capture.
  // This will cause increased disk space use (which may cause a capture to fail if disk space is
  // exhausted) as well as slower capture times.
  //
  // Not all memory allocations may be deferred like this so it is not a guarantee of a memory
  // limit.
  //
  // Units are in MBs, suggested values would range from 200MB to 1000MB.
  //
  // Default - 0 Megabytes
  eRENDERDOC_Option_SoftMemoryLimit = 13,
}

pRENDERDOC_SetCaptureOptionU32 :: #type proc (opt: RENDERDOC_CaptureOption, val: u32) -> i32;
pRENDERDOC_SetCaptureOptionF32 :: #type proc (opt: RENDERDOC_CaptureOption, val: f32) -> i32;

RENDERDOC_SetCaptureOptionU32  : pRENDERDOC_SetCaptureOptionU32;
RENDERDOC_SetCaptureOptionF32  : pRENDERDOC_SetCaptureOptionF32;

pRENDERDOC_GetCaptureOptionU32 :: #type proc (opt: RENDERDOC_CaptureOption) -> u32;
pRENDERDOC_GetCaptureOptionF32 :: #type proc (opt: RENDERDOC_CaptureOption) -> f32;

RENDERDOC_GetCaptureOptionU32 : pRENDERDOC_GetCaptureOptionU32;
RENDERDOC_GetCaptureOptionF32 : pRENDERDOC_GetCaptureOptionF32;

RENDERDOC_InputButton :: enum {
  // '0' - '9' matches ASCII values
  eRENDERDOC_Key_0 = 0x30,
  eRENDERDOC_Key_1 = 0x31,
  eRENDERDOC_Key_2 = 0x32,
  eRENDERDOC_Key_3 = 0x33,
  eRENDERDOC_Key_4 = 0x34,
  eRENDERDOC_Key_5 = 0x35,
  eRENDERDOC_Key_6 = 0x36,
  eRENDERDOC_Key_7 = 0x37,
  eRENDERDOC_Key_8 = 0x38,
  eRENDERDOC_Key_9 = 0x39,

  // 'A' - 'Z' matches ASCII values
  eRENDERDOC_Key_A = 0x41,
  eRENDERDOC_Key_B = 0x42,
  eRENDERDOC_Key_C = 0x43,
  eRENDERDOC_Key_D = 0x44,
  eRENDERDOC_Key_E = 0x45,
  eRENDERDOC_Key_F = 0x46,
  eRENDERDOC_Key_G = 0x47,
  eRENDERDOC_Key_H = 0x48,
  eRENDERDOC_Key_I = 0x49,
  eRENDERDOC_Key_J = 0x4A,
  eRENDERDOC_Key_K = 0x4B,
  eRENDERDOC_Key_L = 0x4C,
  eRENDERDOC_Key_M = 0x4D,
  eRENDERDOC_Key_N = 0x4E,
  eRENDERDOC_Key_O = 0x4F,
  eRENDERDOC_Key_P = 0x50,
  eRENDERDOC_Key_Q = 0x51,
  eRENDERDOC_Key_R = 0x52,
  eRENDERDOC_Key_S = 0x53,
  eRENDERDOC_Key_T = 0x54,
  eRENDERDOC_Key_U = 0x55,
  eRENDERDOC_Key_V = 0x56,
  eRENDERDOC_Key_W = 0x57,
  eRENDERDOC_Key_X = 0x58,
  eRENDERDOC_Key_Y = 0x59,
  eRENDERDOC_Key_Z = 0x5A,

  // leave the rest of the ASCII range free
  // in case we want to use it later
  eRENDERDOC_Key_NonPrintable = 0x100,

  eRENDERDOC_Key_Divide,
  eRENDERDOC_Key_Multiply,
  eRENDERDOC_Key_Subtract,
  eRENDERDOC_Key_Plus,

  eRENDERDOC_Key_F1,
  eRENDERDOC_Key_F2,
  eRENDERDOC_Key_F3,
  eRENDERDOC_Key_F4,
  eRENDERDOC_Key_F5,
  eRENDERDOC_Key_F6,
  eRENDERDOC_Key_F7,
  eRENDERDOC_Key_F8,
  eRENDERDOC_Key_F9,
  eRENDERDOC_Key_F10,
  eRENDERDOC_Key_F11,
  eRENDERDOC_Key_F12,

  eRENDERDOC_Key_Home,
  eRENDERDOC_Key_End,
  eRENDERDOC_Key_Insert,
  eRENDERDOC_Key_Delete,
  eRENDERDOC_Key_PageUp,
  eRENDERDOC_Key_PageDn,

  eRENDERDOC_Key_Backspace,
  eRENDERDOC_Key_Tab,
  eRENDERDOC_Key_PrtScrn,
  eRENDERDOC_Key_Pause,

  eRENDERDOC_Key_Max,
}

pRENDERDOC_SetFocusToggleKeys :: #type proc (keys: ^RENDERDOC_InputButton, num: i32);
pRENDERDOC_SetCaptureKeys     :: #type proc (keys: ^RENDERDOC_InputButton, num: i32);

RENDERDOC_SetFocusToggleKeys : pRENDERDOC_SetFocusToggleKeys;
RENDERDOC_SetCaptureKeys     : pRENDERDOC_SetCaptureKeys;

RENDERDOC_OverlayBits :: enum u32 {
  // This single bit controls whether the overlay is enabled or disabled globally
  eRENDERDOC_Overlay_Enabled = 0x1,

  // Show the average framerate over several seconds as well as min/max
  eRENDERDOC_Overlay_FrameRate = 0x2,

  // Show the current frame number
  eRENDERDOC_Overlay_FrameNumber = 0x4,

  // Show a list of recent captures, and how many captures have been made
  eRENDERDOC_Overlay_CaptureList = 0x8,

  // Default values for the overlay mask
  eRENDERDOC_Overlay_Default = (eRENDERDOC_Overlay_Enabled | eRENDERDOC_Overlay_FrameRate |
                                eRENDERDOC_Overlay_FrameNumber | eRENDERDOC_Overlay_CaptureList),

  // Enable all bits
  eRENDERDOC_Overlay_All = ~u32(0),

  // Disable all bits
  eRENDERDOC_Overlay_None = 0,
}

pRENDERDOC_GetOverlayBits  :: #type proc () -> u32;
pRENDERDOC_MaskOverlayBits :: #type proc (And: u32, Or: u32);

RENDERDOC_GetOverlayBits  : pRENDERDOC_GetOverlayBits;
RENDERDOC_MaskOverlayBits : pRENDERDOC_MaskOverlayBits;

pRENDERDOC_RemoveHooks :: #type proc ();
pRENDERDOC_Shutdown    :: #type proc ();

RENDERDOC_RemoveHooks : pRENDERDOC_RemoveHooks;
RENDERDOC_Shutdown    : pRENDERDOC_Shutdown;

pRENDERDOC_UnloadCrashHandler :: #type proc ();

RENDERDOC_UnloadCrashHandler : pRENDERDOC_UnloadCrashHandler;

pRENDERDOC_SetCaptureFilePathTemplate :: #type proc (pathtemplate: cstring);
pRENDERDOC_SetLogFilePathTemplate     :: #type proc (pathtemplate: cstring);

RENDERDOC_SetCaptureFilePathTemplate : pRENDERDOC_SetCaptureFilePathTemplate;
RENDERDOC_SetLogFilePathTemplate     : pRENDERDOC_SetLogFilePathTemplate;

pRENDERDOC_GetCaptureFilePathTemplate :: #type proc () -> cstring;
pRENDERDOC_GetLogFilePathTemplate     :: #type proc () -> cstring;

RENDERDOC_GetCaptureFilePathTemplate : pRENDERDOC_GetCaptureFilePathTemplate;
RENDERDOC_GetLogFilePathTemplate     : pRENDERDOC_GetLogFilePathTemplate;

pRENDERDOC_GetNumCaptures :: #type proc () -> u32;

RENDERDOC_GetNumCaptures : pRENDERDOC_GetNumCaptures;

pRENDERDOC_GetCapture :: #type proc (idx: u32, filename: cstring, pathlength: ^u32, timestamp: u64) -> u32;

RENDERDOC_GetCapture : pRENDERDOC_GetCapture;

pRENDERDOC_SetCaptureFileComments :: #type proc (filepath: cstring, comments: cstring);

RENDERDOC_SetCaptureFileComments : pRENDERDOC_SetCaptureFileComments;

pRENDERDOC_IsTargetControlConnected :: #type proc () -> u32;
pRENDERDOC_IsRemoteAccessConnected  :: #type proc () -> u32;

RENDERDOC_IsTargetControlConnected : pRENDERDOC_IsTargetControlConnected;
RENDERDOC_IsRemoteAccessConnected  : pRENDERDOC_IsRemoteAccessConnected;

pRENDERDOC_LaunchReplayUI :: #type proc (connectTargetControl: u32, cmdline: cstring) -> u32;

RENDERDOC_LaunchReplayUI : pRENDERDOC_LaunchReplayUI;

pRENDERDOC_GetAPIVersion :: #type proc (major: ^i32, minor: ^i32, patch: ^i32);

RENDERDOC_GetAPIVersion : pRENDERDOC_GetAPIVersion;

pRENDERDOC_ShowReplayUI :: #type proc () -> u32;

RENDERDOC_ShowReplayUI : pRENDERDOC_ShowReplayUI;


RENDERDOC_DevicePointer :: rawptr;
RENDERDOC_WindowHandle  :: rawptr;

pRENDERDOC_SetActiveWindow :: #type proc (device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle);

RENDERDOC_SetActiveWindow : pRENDERDOC_SetActiveWindow;

pRENDERDOC_TriggerCapture :: #type proc ();

RENDERDOC_TriggerCapture : pRENDERDOC_TriggerCapture;

pRENDERDOC_TriggerMultiFrameCapture :: #type proc (numFrames: u32);

RENDERDOC_TriggerMultiFrameCapture : pRENDERDOC_TriggerMultiFrameCapture;

pRENDERDOC_StartFrameCapture   :: #type proc (device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle);
pRENDERDOC_IsFrameCapturing    :: #type proc () -> u32;
pRENDERDOC_EndFrameCapture     :: #type proc (device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle) -> u32;
pRENDERDOC_DiscardFrameCapture :: #type proc (device: RENDERDOC_DevicePointer, wndHandle: RENDERDOC_WindowHandle) -> u32;

RENDERDOC_StartFrameCapture : pRENDERDOC_StartFrameCapture;
RENDERDOC_IsFrameCapturing : pRENDERDOC_IsFrameCapturing;
RENDERDOC_EndFrameCapture : pRENDERDOC_EndFrameCapture;
RENDERDOC_DiscardFrameCapture : pRENDERDOC_DiscardFrameCapture;

pRENDERDOC_SetCaptureTitle :: #type proc (title: cstring);

RENDERDOC_SetCaptureTitle : pRENDERDOC_SetCaptureTitle; 

RENDERDOC_Version :: enum {
    eRENDERDOC_API_Version_1_0_0 = 10000,    // RENDERDOC_API_1_0_0 = 1 00 00
    eRENDERDOC_API_Version_1_0_1 = 10001,    // RENDERDOC_API_1_0_1 = 1 00 01
    eRENDERDOC_API_Version_1_0_2 = 10002,    // RENDERDOC_API_1_0_2 = 1 00 02
    eRENDERDOC_API_Version_1_1_0 = 10100,    // RENDERDOC_API_1_1_0 = 1 01 00
    eRENDERDOC_API_Version_1_1_1 = 10101,    // RENDERDOC_API_1_1_1 = 1 01 01
    eRENDERDOC_API_Version_1_1_2 = 10102,    // RENDERDOC_API_1_1_2 = 1 01 02
    eRENDERDOC_API_Version_1_2_0 = 10200,    // RENDERDOC_API_1_2_0 = 1 02 00
    eRENDERDOC_API_Version_1_3_0 = 10300,    // RENDERDOC_API_1_3_0 = 1 03 00
    eRENDERDOC_API_Version_1_4_0 = 10400,    // RENDERDOC_API_1_4_0 = 1 04 00
    eRENDERDOC_API_Version_1_4_1 = 10401,    // RENDERDOC_API_1_4_1 = 1 04 01
    eRENDERDOC_API_Version_1_4_2 = 10402,    // RENDERDOC_API_1_4_2 = 1 04 02
    eRENDERDOC_API_Version_1_5_0 = 10500,    // RENDERDOC_API_1_5_0 = 1 05 00
    eRENDERDOC_API_Version_1_6_0 = 10600,    // RENDERDOC_API_1_6_0 = 1 06 00
}

RENDERDOC_API_1_6_0 :: struct {
  GetAPIVersion: pRENDERDOC_GetAPIVersion,

  SetCaptureOptionU32: pRENDERDOC_SetCaptureOptionU32,
  SetCaptureOptionF32: pRENDERDOC_SetCaptureOptionF32,

  GetCaptureOptionU32: pRENDERDOC_GetCaptureOptionU32,
  GetCaptureOptionF32: pRENDERDOC_GetCaptureOptionF32,

  SetFocusToggleKeys: pRENDERDOC_SetFocusToggleKeys,
  SetCaptureKeys: pRENDERDOC_SetCaptureKeys,

  GetOverlayBits: pRENDERDOC_GetOverlayBits,
  MaskOverlayBits: pRENDERDOC_MaskOverlayBits,

  // Shutdown was renamed to RemoveHooks in 1.4.1.
  // These unions allow old code to continue compiling without changes
  using x : struct #raw_union
  {
    Shutdown: pRENDERDOC_Shutdown,
    RemoveHooks: pRENDERDOC_RemoveHooks,
  },
  UnloadCrashHandler: pRENDERDOC_UnloadCrashHandler,

  // Get/SetLogFilePathTemplate was renamed to Get/SetCaptureFilePathTemplate in 1.1.2.
  // These unions allow old code to continue compiling without changes
  using y : struct #raw_union
  {
    // deprecated name
    SetLogFilePathTemplate: pRENDERDOC_SetLogFilePathTemplate,
    // current name
    SetCaptureFilePathTemplate: pRENDERDOC_SetCaptureFilePathTemplate,
  },

  using z : struct #raw_union
  {
    // deprecated name
    GetLogFilePathTemplate: pRENDERDOC_GetLogFilePathTemplate,
    // current name
    GetCaptureFilePathTemplate: pRENDERDOC_GetCaptureFilePathTemplate,
  },

  GetNumCaptures: pRENDERDOC_GetNumCaptures,
  GetCapture: pRENDERDOC_GetCapture,

  TriggerCapture: pRENDERDOC_TriggerCapture,

  // IsRemoteAccessConnected was renamed to IsTargetControlConnected in 1.1.1.
  // This union allows old code to continue compiling without changes
  using w : struct #raw_union
  {
    // deprecated name
    IsRemoteAccessConnected: pRENDERDOC_IsRemoteAccessConnected,
    // current name
    IsTargetControlConnected: pRENDERDOC_IsTargetControlConnected,
  },

  LaunchReplayUI: pRENDERDOC_LaunchReplayUI,

  SetActiveWindow: pRENDERDOC_SetActiveWindow,

  StartFrameCapture: pRENDERDOC_StartFrameCapture,
  IsFrameCapturing: pRENDERDOC_IsFrameCapturing,
  EndFrameCapture: pRENDERDOC_EndFrameCapture,

  // new function in 1.1.0
  TriggerMultiFrameCapture: pRENDERDOC_TriggerMultiFrameCapture,
  // new function in 1.2.0
  SetCaptureFileComments: pRENDERDOC_SetCaptureFileComments,
  // new function in 1.4.0
  DiscardFrameCapture: pRENDERDOC_DiscardFrameCapture,
  // new function in 1.5.0
  ShowReplayUI: pRENDERDOC_ShowReplayUI,
  // new function in 1.6.0
  SetCaptureTitle: pRENDERDOC_SetCaptureTitle,
}

RENDERDOC_API_1_0_0 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_0_1 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_0_2 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_1_0 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_1_1 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_1_2 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_2_0 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_3_0 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_4_0 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_4_1 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_4_2 :: RENDERDOC_API_1_6_0;
RENDERDOC_API_1_5_0 :: RENDERDOC_API_1_6_0;

pRENDERDOC_GetAPI :: #type proc (version: RENDERDOC_Version, outAPIPointers: ^rawptr) -> i32;

RENDERDOC_GetAPI : pRENDERDOC_GetAPI;