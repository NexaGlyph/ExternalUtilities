package logger

import "core:os"
import "core:fmt"
import "core:strings"

BLACK   :: "\033[30m"
RED     :: "\033[31m"
GREEN   :: "\033[32m"
YELLOW  :: "\033[33m"
ORANGE  :: "\033[38;5;208m"
BLUE    :: "\033[34m"
MAGENTA :: "\033[35m"
CYAN    :: "\033[36m"
WHITE   :: "\033[37m"
RESET   :: "\033[0m"

log_custom :: proc(color: string, fmt_str: string, args: ..any, logger := context.logger, location := #caller_location) {

    builder := strings.Builder{};
    defer strings.builder_destroy(&builder);
    strings.builder_init(&builder);
    formatted := fmt.sbprintf(&builder, fmt_str, ..args);
    fmt.printf("%s[CUSTOM]: %s%s\n", color, RESET, formatted);

}