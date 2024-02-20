const std = @import("std");
const c = @cImport({
    @cInclude("windows.h");
});

pub fn main() void {
    const processHandle = c.OpenProcess(c.PROCESS_QUERY_INFORMATION, false, c.GetCurrentProcessId());
    if (processHandle == null) {
        std.debug.print("Failed to get process handle\n", .{});
        return;
    }

    // Get system times
    var idleTime: c.FILETIME = undefined;
    var kernelTime: c.FILETIME = undefined;
    var userTime: c.FILETIME = undefined;

    if (c.GetSystemTimes(&idleTime, &kernelTime, &userTime) == 0) {
        std.debug.print("Failed to get system times\n", .{});
        c.CloseHandle(processHandle);
        return;
    }

    // Sleep for a short duration (e.g., 500 ms)
    c.Sleep(500);

    // Get system times again
    var newIdleTime: c.FILETIME = undefined;
    var newKernelTime: c.FILETIME = undefined;
    var newUserTime: c.FILETIME = undefined;

    if (c.GetSystemTimes(&newIdleTime, &newKernelTime, &newUserTime) == 0) {
        std.debug.print("Failed to get system times\n", .{});
        c.CloseHandle(processHandle);
        return;
    }

    // Calculate CPU usage
    const idleTimeDiff = filetimeToUInt64(newIdleTime) - filetimeToUInt64(idleTime);
    const kernelTimeDiff = filetimeToUInt64(newKernelTime) - filetimeToUInt64(kernelTime);
    const userTimeDiff = filetimeToUInt64(newUserTime) - filetimeToUInt64(userTime);

    const totalUsageTime = kernelTimeDiff + userTimeDiff;
    const totalElapsedTime = idleTimeDiff + kernelTimeDiff + userTimeDiff;

    const cpuUsage = f64(totalUsageTime) / f64(totalElapsedTime) * 100.0;
    std.debug.print("CPU Usage: {}%\n", .{cpuUsage});

    // Close the process handle
    c.CloseHandle(processHandle);
}

fn filetimeToUInt64(filetime: c.FILETIME) u64 {
    return (filetime.dwHighDateTime << 32) | filetime.dwLowDateTime;
}
