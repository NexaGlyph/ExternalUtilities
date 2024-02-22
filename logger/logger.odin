package logger

import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"

Logger :: struct {
    using logger: log.Logger,
    file_name: string,
}

init :: proc(file_name: string = "output.log", write_modes: int = os.O_CREATE | os.O_TRUNC) -> Logger {
    handle, ok := os.open(file_name, write_modes);
    assert(ok == os.ERROR_NONE, "failed to open file!");
    return Logger{ log.create_file_logger(handle), file_name };
}

logf :: proc(logger: log.Logger, level: log.Level, fmt_str: string, args: ..any, location := #caller_location) {
    str := fmt.tprintf(fmt_str, ..args);
    logger.procedure(logger.data, level, str, logger.options, location);    
}

log_infof :: proc(logger: log.Logger, fmt_str: string, args: ..any, location := #caller_location) {
    logf(logger, .Info, fmt_str, args, location);
}

log_debugf :: proc(logger: log.Logger, fmt_str: string, args: ..any, location := #caller_location) {
    logf(logger, .Debug, fmt_str, args, location);
}

log_warnf :: proc(logger: log.Logger, fmt_str: string, args: ..any, location := #caller_location) {
    logf(logger, .Warning, fmt_str, args, location);
}

log_errorf :: proc(logger: log.Logger, fmt_str: string, args: ..any, location := #caller_location) {
    logf(logger, .Error, fmt_str, args, location);
}

log_fatalf :: proc(logger: log.Logger, fmt_str: string, args: ..any, location := #caller_location) {
    logf(logger, .Fatal, fmt_str, args, location);
}

log_customf :: proc(color: string, fmt_str: string, args: ..any, logger := context.logger, location := #caller_location) {
    assert(false, "TO DO!");
}

clearf :: proc(logger: ^Logger) {
    dump(logger);
    logger^ = init(logger.file_name, os.O_CREATE | os.O_TRUNC);
}

dump :: #force_inline proc(logger: ^Logger) {
    log.destroy_file_logger(logger);
}