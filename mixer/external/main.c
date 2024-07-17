#include <stdio.h>
#include <Windows.h>

#define LIBAUDIO_VIRTUAL_ALLOC
#include "device.h"

// test headers here
#define TEST_ENABLE
//#define PLAY_TEST_ENABLE
//#define INPUT_TEST_ENABLE

#include "log_devices.h"
#include "play.h"

// note this will be only convenient for the user 
// to hold all the necessary data together
// (not a job of the library itself...)
typedef struct {
    InputDeviceHandle       ihandle;
    InputDeviceDescription  idesc; 
} InputDevice;

typedef struct {
    OutputDeviceHandle        ohandle;
    OutputDeviceDescription   odesc; 
} OutputDevice;

#ifdef TEST_ENABLE
    #undef LOG_TEST_ENABLE
    #ifdef LOG_TEST_ENABLE
    int main(void) {
        return log_devices();
    }
    #endif
    //#undef PLAY_TEST_ENABLE
    #ifdef PLAY_TEST_ENABLE
    int main(void) {
        return play_test(OUTPUT_DEVICE_NULL_HANDLE);
    }
    #endif
    #ifdef INPUT_TEST_ENABLE
    int main(void) {
        return input_test(INPUT_DEVICE_NULL_HANDLE, OUTPUT_DEVICE_NULL_HANDLE);
    }
    #endif
#else
int main(void) {
    UINT num_devices = 0;
    int err = ERROR_NONE;

    AudioDeviceInfo* devices = detect_audio_devices(&num_devices, &err);

    if (devices == NULL || num_devices <= 0 || err != ERROR_NONE)
        return EXIT_FAILURE;

    OutputDevice odevice = { 0 };
    // create output device
    {
        odevice.odesc.idx = 0; // basically the first functional
        odevice.odesc.format = WAVE_FORMAT_PCM;
        odevice.odesc.channels = 2;
        odevice.odesc.samples_per_sec = 44100;
        odevice.odesc.bits_per_sample = 16;
        odevice.odesc.byte_count = 0;
        CALCULATE_OUTPUT_DEVICE_VALUES(odevice.odesc);

        odevice.ohandle = open_audio_odevice(&odevice.odesc);

        if (odevice.ohandle == OUTPUT_DEVICE_NULL_HANDLE) {
            return EXIT_FAILURE;
        }
        else {
            printf("Output device was successfully initialized!\n");
        }
    }

    InputDeviceHandle idevice = { 0 };
    idevice.idx = 0;
    // create the input device
    InputDeviceDescription idesc = {
        .idx = idevice.idx, // basically the first functional
        .format = WAVE_FORMAT_PCM,
        .channels = 2,
        .samples_per_sec = 44100,
        .bits_per_sample = 16,
        .byte_count = 0
    };
    CALCULATE_INPUT_DEVICE_VALUES(idesc);
    {
        idevice.in = open_audio_idevice(&idesc, CALLBACK_NULL, NULL);

        if (idevice.in == INPUT_DEVICE_NULL_HANDLE) {
            return EXIT_FAILURE;
        }
        else {
            printf("Input device was successfully initialized!\n");
        }
    }

    // record sound from input device
    // save it
    // close input device
    {
        RecordConfig rec_config = {
            .device       = &idevice,
            .duration     = 5, // seconds
            .idesc        = idesc
        };

        Recorder recorder = begin_rec(rec_config);

#ifdef _DEBUG
        if (recorder.buffers == RECORDER_BUFFER_NULL) {
            return EXIT_FAILURE;
        }
        else {
            printf("Recorder was set on!");
        }
#endif
        
        printf("ready to sleep for sound input...\n");
        Sleep((rec_config.duration) * 1000); // 5 seconds

        SaveConfig save = {
            .format = WAVE_FORMAT_PCM,
            .path = "recording1.wav",
            .flags = MMIO_CREATE | MMIO_WRITE
        };

        MMRESULT rec_err = 0;
        if ((rec_err = end_rec(&idevice, recorder, FALSE, save)) != 0) {
            printf("end rec\t ERROR: %d\n", rec_err);
            wchar_t buf[256];
            FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, rec_err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                buf, (sizeof(buf) / sizeof(wchar_t)), NULL);
            printf("%ls", buf);
            LocalFree(buf);
            return EXIT_FAILURE;
        }

        close_audio_idevice(idevice.in);

        play_sound(odevice.ohandle, recorder.buffers, 0);
        
        for (uint16_t i = 0; i < recorder.num_buffers; i++)
            dump_sound(&recorder.buffers[i]);

        //>>>NOTE: FORGOT TO FREE
//        size_t size = CALCULATE_BUFFSIZE(500, odevice.odesc);
//#ifndef LIBAUDIO_VIRTUAL_ALLOC
//        int16_t* raw_sound = calloc(1, sizeof(int16_t) * size);
//#else
//        int16_t* raw_sound = VirtualAlloc(NULL, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
//#endif
//        generate_sine_wave(raw_sound, 5.0);
//        play_raw(odevice.ohandle, raw_sound, (uint32_t)size, PLAYSOUND_LOOP_BIT);
//        dump_sound_raw(raw_sound);
    }

    // play recorder sound to output device
    // close output device
    {
        play_file("C:\\Programovanie\\Codin\\mixer\\mixer\\external\\s1.wav", 0);
        Sleep(50000);
        terminate_play_file();
        close_audio_odevice(odevice.ohandle);
    }

    return EXIT_SUCCESS;
}
#endif