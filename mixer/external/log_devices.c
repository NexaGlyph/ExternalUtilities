#include <Windows.h>

#include "device.h"
#include "log_devices.h"

int log_devices(void) {
    uint32_t num_devices = 0;
    int err = ERROR_NONE;

    AudioDeviceInfo* devices = detect_audio_devices(&num_devices, &err);

    if (devices == NULL || num_devices <= 0)
        return EXIT_FAILURE;

    if (err != ERROR_NONE) {
        free(devices);
        return EXIT_FAILURE;
    }

    for (uint32_t i = 0; i < num_devices; i++)
        LOG_DEVICE(devices[i]);

    free(devices);

    return EXIT_SUCCESS;
}