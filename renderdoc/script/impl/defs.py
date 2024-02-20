import re

PREFFIX = "RENDERDOC_"

ODIN_PROC_PATTERN = re.compile(r'pRENDERDOC_\.(\w+)\(')

ODIN_PROC_DEFAULT = list(
    {
        "CreateInstance",
        "EnumerateInstanceVersion",
        "EnumerateInstanceLayerProperties",
        "EnumerateInstanceExtensionProperties"
    }
)

ODIN_PROC_EXCEPTIONS = set(
    list ({
        "MAKE_VERSION",
        "load_proc_addresses_global",
        "load_proc_addresses_instance",
        "load_proc_addresses_device",
        "load_proc_addresses_device_vtable",
        "load_proc_addresses_custom",
        "DestroyDebugUtilsMessengerEXT"
    }) + ODIN_PROC_DEFAULT
)

ODIN_FILE_LOGO = list({
    "/* THIS IS PREGENERATED FILE */\n"
    "/* CONTENTS OF THIS FILE SHOULD NOT BE CHANGED MANUALLY... see scripts */\n\n"
})

class ODIN_PROC_TYPE:
    NIL = "nil"
    INSTANCE = "instance"