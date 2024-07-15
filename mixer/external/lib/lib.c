#include "../device.h"
#include <assert.h>

#define LIBAUDIO_VIRTUAL_ALLOC

AudioDeviceInfo* __cdecl detect_audio_idevices(uint32_t* num_devices, int* err) {
    *num_devices = waveInGetNumDevs();
    if (*num_devices <= 0) {
        *err = ERROR_NO_DEVICES;
        return NULL;
    }

    AudioDeviceInfo* devices = malloc(sizeof(AudioDeviceInfo) * (*num_devices));
    if (devices == NULL) {
        *err = ERROR_MEMORY_ALLOCATION;
        return NULL;
    }

    uint32_t device_index = 0;

    // Loop through both input and output devices
    for (uint32_t i = 0; i < waveInGetNumDevs(); ++i) {
        WAVEINCAPS inCaps;
        if (waveInGetDevCaps(i, &inCaps, sizeof(inCaps)) == MMSYSERR_NOERROR) {
            devices[device_index].input = TRUE;
            devices[device_index].output = FALSE;
            strncpy_s(devices[device_index].device_name, sizeof(devices[device_index].device_name), inCaps.szPname, _TRUNCATE);
            strncpy_s(devices[device_index].device_description, sizeof(devices[device_index].device_description), inCaps.szPname, _TRUNCATE);
            devices[device_index].device_name[sizeof(devices[device_index].device_name) - 1] = '\0';
            devices[device_index].device_description[sizeof(devices[device_index].device_description) - 1] = '\0';
            devices[device_index].formats = inCaps.dwFormats;
            devices[device_index].channels = inCaps.wChannels;
            devices[device_index].idx = device_index;

            // Increment the device index for the next device
            ++device_index;
        }
        else {
            *err = ERROR_DEVICE_INFO;
            free(devices);
            return NULL;
        }
    }
    
    return devices;
}

AudioDeviceInfo* __cdecl detect_audio_odevices(uint32_t* num_devices, int* err) {
    *num_devices = waveOutGetNumDevs();
    if (*num_devices <= 0) {
        *err = ERROR_NO_DEVICES;
        return NULL;
    }

    AudioDeviceInfo* devices = malloc(sizeof(AudioDeviceInfo) * (*num_devices));
    if (devices == NULL) {
        *err = ERROR_MEMORY_ALLOCATION;
        return NULL;
    }

    uint32_t device_index = 0;

    for (UINT i = 0; i < waveOutGetNumDevs(); ++i) {
        WAVEOUTCAPS outCaps;
        if (waveOutGetDevCaps(i, &outCaps, sizeof(outCaps)) == MMSYSERR_NOERROR) {
            devices[device_index].input = FALSE;
            devices[device_index].output = TRUE;
            strncpy_s(devices[device_index].device_name, sizeof(devices[device_index].device_name), outCaps.szPname, _TRUNCATE);
            strncpy_s(devices[device_index].device_description, sizeof(devices[device_index].device_description), outCaps.szPname, _TRUNCATE);
            devices[device_index].device_name[sizeof(devices[device_index].device_name) - 1] = '\0';
            devices[device_index].device_description[sizeof(devices[device_index].device_description) - 1] = '\0';
            devices[device_index].formats = outCaps.dwFormats;
            devices[device_index].channels = outCaps.wChannels;
            devices[device_index].idx = device_index;

            // Increment the device index for the next device
            ++device_index;
        }
        else {
            *err = ERROR_DEVICE_INFO;
            free(devices);
            return NULL;
        }
    }

    return devices;
}

AudioDeviceInfo* __cdecl detect_audio_devices(uint32_t* num_devices, int* err) {
    *num_devices = waveInGetNumDevs() + waveOutGetNumDevs();
    if (*num_devices <= 0) {
        *err = ERROR_NO_DEVICES;
        return NULL;
    }

    AudioDeviceInfo* devices = malloc(sizeof(AudioDeviceInfo) * (*num_devices));
    if (devices == NULL) {
        *err = ERROR_MEMORY_ALLOCATION;
        return NULL;
    }

    uint32_t device_index = 0;

    // Loop through both input and output devices
    for (uint32_t i = 0; i < waveInGetNumDevs(); ++i) {
        WAVEINCAPS inCaps;
        if (waveInGetDevCaps(i, &inCaps, sizeof(inCaps)) == MMSYSERR_NOERROR) {
            devices[device_index].input = TRUE;
            devices[device_index].output = FALSE;
            strncpy_s(devices[device_index].device_name, sizeof(devices[device_index].device_name), inCaps.szPname, _TRUNCATE);
            strncpy_s(devices[device_index].device_description, sizeof(devices[device_index].device_description), inCaps.szPname, _TRUNCATE);
            devices[device_index].device_name[sizeof(devices[device_index].device_name) - 1] = '\0';
            devices[device_index].device_description[sizeof(devices[device_index].device_description) - 1] = '\0';
            devices[device_index].formats = inCaps.dwFormats;
            devices[device_index].channels = inCaps.wChannels;
            devices[device_index].idx = device_index;

            // Increment the device index for the next device
            ++device_index;
        } else {
            *err = ERROR_DEVICE_INFO;
            free(devices);
            return NULL;
        }
    }

    for (UINT i = 0; i < waveOutGetNumDevs(); ++i) {
        WAVEOUTCAPS outCaps;
        if (waveOutGetDevCaps(i, &outCaps, sizeof(outCaps)) == MMSYSERR_NOERROR) {
            devices[device_index].input = FALSE;
            devices[device_index].output = TRUE;
            strncpy_s(devices[device_index].device_name, sizeof(devices[device_index].device_name), outCaps.szPname, _TRUNCATE);
            strncpy_s(devices[device_index].device_description, sizeof(devices[device_index].device_description), outCaps.szPname, _TRUNCATE);
            devices[device_index].device_name[sizeof(devices[device_index].device_name) - 1] = '\0';
            devices[device_index].device_description[sizeof(devices[device_index].device_description) - 1] = '\0';
            devices[device_index].formats = outCaps.dwFormats;
            devices[device_index].channels = outCaps.wChannels;
            devices[device_index].idx = device_index;

            // Increment the device index for the next device
            ++device_index;
        } else {
            *err = ERROR_DEVICE_INFO;
            free(devices);
            return NULL;
        }
    }

    return devices;
}

HWAVEOUT open_audio_odevice(OutputDeviceDescription* odesc) {
    HWAVEOUT out;
    WAVEFORMATEX wfx;

    wfx.wFormatTag = odesc->format;
    wfx.nChannels = odesc->channels;
    wfx.nSamplesPerSec = odesc->samples_per_sec;
    wfx.nAvgBytesPerSec = odesc->bytes_per_sec;
    wfx.nBlockAlign = odesc->block_align;
    wfx.wBitsPerSample = odesc->bits_per_sample;
    wfx.cbSize = odesc->byte_count;

    MMRESULT result = waveOutOpen(&out, odesc->idx, &wfx, 0, 0, WAVE_FORMAT_DIRECT);
    if (result != MMSYSERR_NOERROR) {
        return NULL;
    }

    return out;
}

HWAVEIN open_audio_idevice(InputDeviceDescription* idesc, open_audio_idevice_proc callback, uint64_t* instance) {
    HWAVEIN in;
    WAVEFORMATEX wfx = { 0 };

    wfx.wFormatTag = idesc->format;
    wfx.nChannels = idesc->channels;
    wfx.nSamplesPerSec = idesc->samples_per_sec;
    wfx.nAvgBytesPerSec = idesc->bytes_per_sec;
    wfx.nBlockAlign = idesc->block_align;
    wfx.wBitsPerSample = idesc->bits_per_sample;
    wfx.cbSize = idesc->byte_count;

    MMRESULT result = MMSYSERR_NOERROR;

    if (callback == NULL) {
        result = waveInOpen(
            &in,
            idesc->idx,
            &wfx,
            (DWORD_PTR)NULL,
            0,
            CALLBACK_FUNCTION
        );
    }
    else {
        result = waveInOpen(
            &in,
            idesc->idx,
            &wfx,
            (DWORD_PTR)callback,
            instance,
            CALLBACK_FUNCTION
        );
    }

#ifdef _DEBUG
    if (result != MMSYSERR_NOERROR)
        printf("Error: %d\n", result);
#endif
    
    return result == MMSYSERR_NOERROR ? in : INPUT_DEVICE_NULL_HANDLE;
}

int16_t* read_raw(const char* filepath, SoundDescription* sound_desc) {
    MMRESULT result;
    HMMIO mmioIn;
    MMCKINFO ckIn = { 0 };
    MMCKINFO ckInRIFF = { 0 };
    PCMWAVEFORMAT pcmFormat = { 0 };

    // Open the WAV file
    mmioIn = mmioOpenA((LPSTR)filepath, NULL, MMIO_READ | MMIO_ALLOCBUF);
    if (mmioIn == NULL) {
        // Handle error
        return NULL;
    }

    // Descend into the RIFF chunk
    ckInRIFF.fccType = mmioFOURCC('W', 'A', 'V', 'E');
    result = mmioDescend(mmioIn, &ckInRIFF, NULL, MMIO_FINDRIFF);
    if (result != MMSYSERR_NOERROR) {
        // Handle error
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Descend into the format chunk
    ckIn.ckid = mmioFOURCC('f', 'm', 't', ' ');
    result = mmioDescend(mmioIn, &ckIn, &ckInRIFF, MMIO_FINDCHUNK);
    if (result != MMSYSERR_NOERROR) {
        // Handle error
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Read the format
    result = mmioRead(mmioIn, (HPSTR)&pcmFormat, sizeof(PCMWAVEFORMAT));
    if (result != sizeof(PCMWAVEFORMAT)) {
        // Handle error
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Set the output format
    sound_desc->format          = WAVE_FORMAT_PCM;
    sound_desc->channels        = pcmFormat.wf.nChannels;
    sound_desc->samples_per_sec = pcmFormat.wf.nSamplesPerSec;
    sound_desc->bytes_per_sec   = pcmFormat.wf.nAvgBytesPerSec;
    sound_desc->block_align     = pcmFormat.wf.nBlockAlign;
    sound_desc->bits_per_sample = pcmFormat.wBitsPerSample;

    // Ascend out of the format chunk
    result = mmioAscend(mmioIn, &ckIn, 0);
    if (result != MMSYSERR_NOERROR) {
        // Handle error
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Descend into the data chunk
    ckIn.ckid = mmioFOURCC('d', 'a', 't', 'a');
    result = mmioDescend(mmioIn, &ckIn, &ckInRIFF, MMIO_FINDCHUNK);
    if (result != MMSYSERR_NOERROR) {
        // Handle error
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Allocate buffer for audio data
    uint32_t dataSize = ckIn.cksize;
#ifndef LIBAUDIO_VIRTUAL_ALLOC
    uint16_t* dataBuffer = malloc(dataSize);
#else
    uint16_t* dataBuffer = VirtualAlloc(NULL, dataSize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
#endif
    if (dataBuffer == NULL) {
        // Handle memory allocation error
        dump_sound_raw(dataBuffer);
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Read audio data into buffer
    result = mmioRead(mmioIn, (HPSTR)dataBuffer, dataSize);
    if (result != dataSize) {
        // Handle error
        dump_sound_raw(dataBuffer);
        mmioClose(mmioIn, 0);
        return NULL;
    }

    // Close the file
    mmioClose(mmioIn, 0);

    sound_desc->samples = dataSize / (sound_desc->bits_per_sample / 8);
    //sound_desc->size = CALCULATE_BUFFSIZE(sound_desc->samples / sound_desc->samples_per_sec, *sound_desc);
    sound_desc->size = dataSize;
    return dataBuffer;
}

Sound read_sound(const char* filepath) {
    assert(FALSE);
    return SOUND_NULL;
}

// https://github.com/microsoft/Windows-classic-samples/blob/main/Samples/Win7Samples/multimedia/directshow/dmo/dmodemo/wave.c
Recorder begin_rec(RecordConfig rec_config) {
    Recorder recorder = { 0 };
    recorder.buffers = RECORDER_BUFFER_NULL;
    recorder.num_buffers = (uint16_t)(0);
    recorder.buffer_sizes = NULL;

    // calculate the size of ONE chunk and their total count
    CALCULATE_BUFFSIZES_WITH_ALLOC(
        rec_config.duration,
        recorder.buffer_sizes, // array of all sizes e.g. [1024B, 1024B, 1024B, 356B]
        recorder.num_buffers, // len of the previous array (buffer_sizes)
        rec_config.idesc, recorder
    );
    recorder.buffers = malloc(sizeof(SoundChunk) * recorder.num_buffers);

    if (recorder.buffers == NULL) {
        // Indicate that the buffer failed to allocate
        free(recorder.buffer_sizes);
        recorder.buffers      = RECORDER_BUFFER_NULL;
        recorder.num_buffers  = 0;
        recorder.buffer_sizes = NULL;
        return recorder;
    }

    for (uint16_t i = 0; i < recorder.num_buffers; ++i) {
        // heap allocation (RAM) --- relatively slow
        // TODO: maybe an opt. would be to STACK (fast) allocate them 
        // SoundChunk ... make its size static (e.g. 1024B)
        // Make maximum size of Chunk array to be of 100 SoundChunk(s)
#ifndef LIBAUDIO_VIRTUAL_ALLOC
        printf("memsetting...\n");
        memset(&recorder.buffers[i], 0, sizeof(SoundChunk));
        printf("memset!\n");
        printf("mallocing...\n");
        recorder.buffers[i].lpData = malloc(recorder.buffer_sizes[i]);
        printf("malloc'd...\n");
#else
        printf("virtual mallocing...\n");
        recorder.buffers[i].lpData = VirtualAlloc(NULL, recorder.buffer_sizes[i], MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        printf("virtual malloc'd...\n");
#endif
        if (recorder.buffers[i].lpData == NULL) {
            // Handle memory allocation error
            for (int j = 0; j < i; ++j) {
#ifndef LIBAUDIO_VIRTUAL_ALLOC
                free(recorder.buffers[j].lpData);
#else
                VirtualFree(recorder.buffers[j].lpData, 0, MEM_RELEASE);
#endif
            }
            // Indicaate that the buffer failed to initialize
            free(recorder.buffers);
            free(recorder.buffer_sizes);
            recorder.buffers      = RECORDER_BUFFER_NULL;
            recorder.num_buffers  = 0;
            recorder.buffer_sizes = NULL;
            return recorder;
        }
        recorder.buffers[i].dwBufferLength = recorder.buffer_sizes[i];
        printf("preparing header...\n");
        waveInPrepareHeader(rec_config.device->in, &recorder.buffers[i], sizeof(SoundChunk));
        printf("header prepared!\n");
        printf("adding buffer...\n");
        waveInAddBuffer(rec_config.device->in, &recorder.buffers[i], sizeof(SoundChunk));
        printf("buffer added!\n");
    }

    // Start recording
    waveInStart(rec_config.device->in);

    return recorder;
}

// BOOL is_rec(InputDeviceHandle* input_device) {
//     assert(FALSE); // this function has to be rewritten!!
//     return input_device->in != NULL;
// }

MMRESULT end_rec(InputDeviceHandle* input_device, Recorder recorder, BOOL cleanup, SaveConfig save) {
    MMRESULT err = 0;
    if (input_device->in != INPUT_DEVICE_NULL_HANDLE) {
        // Stop recording
        printf("wave ...!\n");
        MMRESULT_CHECK(err, waveInStop(input_device->in))
        printf("wave stopped!\n");
        MMRESULT_CHECK(err, waveInReset(input_device->in))
        printf("wave reset!\n");

        // Save the audio recording to a file
        if (save.path != NULL) {
            MMIOINFO mmioInfo = { 0 };
            HMMIO hFile = mmioOpenA((LPSTR)save.path, &mmioInfo, save.flags);
            if (hFile != NULL) {
                MMCKINFO ckRIFF = { 0 };
                ckRIFF.fccType = mmioFOURCC('W', 'A', 'V', 'E');
                MMRESULT_CHECK(err, mmioCreateChunk(hFile, &ckRIFF, MMIO_CREATERIFF))
                printf("chunk WAVE created!\n");

                // Write the WAVE format chunk
                MMCKINFO ckFMT = { 0 };
                ckFMT.ckid = mmioFOURCC('f', 'm', 't', ' ');
                MMRESULT_CHECK(err, mmioCreateChunk(hFile, &ckFMT, 0))
                printf("chunk fmt created!\n");

                // Write the WAVEFORMAT structure
                MMIOINFO mmioinfoOut;
                mmioGetInfo(hFile, &mmioinfoOut, 0);
                mmioinfoOut.pchNext = (HPSTR)&save.format;
                mmioinfoOut.cchBuffer = sizeof(save.format);
                MMRESULT_CHECK(err, mmioSetInfo(hFile, &mmioinfoOut, 0))
                printf("waveformat set!\n");

                // Head back to the fmt
                MMRESULT_CHECK(err, mmioAscend(hFile, &ckFMT, 0))
                printf("back to the fmt chunk!\n");

                // Write the data chunk
                MMCKINFO ckData = {0};
                ckData.ckid = mmioFOURCC('d', 'a', 't', 'a');
                MMRESULT_CHECK(err, mmioCreateChunk(hFile, &ckData, 0))
                printf("dat chunk created!\n");

                // Write the recorded audio data
                for (uint16_t i = 0; i < recorder.num_buffers; ++i) {
                    mmioWrite(hFile, recorder.buffers[i].lpData, recorder.buffers[i].dwBufferLength);
                    printf("chunk written!\n");
                }

                MMRESULT_CHECK(err, mmioAscend(hFile, &ckData, 0))
                MMRESULT_CHECK(err, mmioAscend(hFile, &ckRIFF, 0))
                MMRESULT_CHECK(err, mmioClose(hFile, 0))
                printf("closed!\n");
            } else {
                // Handle file opening error
                printf("failed to open file");
                return mmioInfo.wErrorRet;
            }
        }

        // Unprepare and free the buffers
        if (cleanup) {
            SoundChunk buffer;
            memset(&buffer, 0, sizeof(SoundChunk));
            for (int i = 0; i < recorder.num_buffers; i++) {
                waveInUnprepareHeader(input_device->in, &recorder.buffers[i], sizeof(SoundChunk));
                if (recorder.buffers[i].lpData)
#ifndef LIBAUDIO_VIRTUAL_ALLOC
                    free(recorder.buffers[i].lpData);
#else
                    VirtualFree(recorder.buffers[i].lpData, 0, MEM_RELEASE);
#endif
            }

            free(recorder.buffers);
            free(recorder.buffer_sizes);
        }
    }
    return err;
}

void close_audio_odevice(OutputDeviceHandle out) {
    waveOutClose(out);
}

void close_audio_idevice(InputDeviceHandle in) {
    waveInClose(in.in);
}

//TODO: check whether this will always lunch the "IDX 0" of the AudioDevice* automatically
void play_file(const char* path, uint32_t flags) {
    PlaySound(path, NULL, flags);
}

typedef struct {
    const char* path;
    uint32_t flags;
} PlayFileExDescription;

DWORD WINAPI _play_file_ex(LPVOID param) {
    PlayFileExDescription* desc = (PlayFileExDescription*)param;
    PlaySound(desc->path, 0, desc->flags);
    return 0;
}

void play_file_ex(const char* path, uint32_t flags, double duration) {
    PlayFileExDescription desc = {
        .path   = path,
        .flags  = flags
    };
    HANDLE thread_handle = CreateThread(NULL, 0, _play_file_ex, (LPVOID)&desc, 0, NULL);
    if (thread_handle == NULL) {
        // handle thread creation error
        fprintf(stderr, "Error creating thread\n");
        return;
    }

    Sleep((DWORD)(duration * 1000));

    // terminate played sound after the "duration"
    PlaySound(NULL, NULL, flags);

    // join
    WaitForSingleObject(thread_handle, INFINITE);
    CloseHandle(thread_handle);
}

void play_raw(OutputDeviceHandle odevice, int16_t* raw, uint32_t size, uint32_t flags) {
    if (raw != NULL) {
        // ensure that the device handle is set up
        if (odevice == OUTPUT_DEVICE_NULL_HANDLE) {
            // get first suitable device
            // if (waveOutOpen(&odevice->out, WAVE_MAPPER, &format, 0, 0, WAVE_FORMAT_DIRECT) != MMSYSERR_NOERROR) {
                // Handle waveOutOpen error
            return;
            // }
        }

        // Initialize the sound buffer
        SoundChunk wave_hdr;
        ZERO_MEMORY(wave_hdr, SoundChunk);
        wave_hdr.lpData = (LPSTR)raw;
        wave_hdr.dwBufferLength = size;

        if (waveOutPrepareHeader(odevice, &wave_hdr, sizeof(SoundChunk)) != MMSYSERR_NOERROR) {
            // Handle waveOutPrepareHeader error
            return;
        }

        if (waveOutWrite(odevice, &wave_hdr, sizeof(SoundChunk)) != MMSYSERR_NOERROR) {
            // Handle waveOutWrite error
            waveOutUnprepareHeader(odevice, &wave_hdr, sizeof(SoundChunk));
            return;
        }
    }
}

void play_sound(OutputDeviceHandle odevice, Sound sound, uint32_t flags) {
    if (sound != SOUND_NULL) {
        if (odevice == OUTPUT_DEVICE_NULL_HANDLE) {
            // get first suitable device
            // if (waveOutOpen(&odevice->out, WAVE_MAPPER, &format, 0, 0, WAVE_FORMAT_DIRECT) != MMSYSERR_NOERROR) {
                // Handle waveOutOpen error
            return;
            // }
        }

        if (waveOutPrepareHeader(odevice, sound, sizeof(SoundChunk)) != MMSYSERR_NOERROR) {
            // Handle waveOutPrepareHeader error
            return;
        }

        if (waveOutWrite(odevice, sound, sizeof(SoundChunk)) != MMSYSERR_NOERROR) {
            // Handle waveOutWrite error
            waveOutUnprepareHeader(odevice, sound, sizeof(SoundChunk));
            return;
        }
    }
}

void terminate_play_file() {
    PlaySound(NULL, NULL, 0);
}

void dump_sound_raw(int16_t* raw_data) {
#ifndef LIBAUDIO_VIRTUAL_ALLOC
    free(raw_data);
#else
    VirtualFree(raw_data, 0, MEM_RELEASE);
#endif
}

void dump_sound(Sound sound) {
#ifndef LIBAUDIO_VIRTUAL_ALLOC
    free(sound->lpData);
#else
    VirtualFree(sound->lpData, 0, MEM_RELEASE);
#endif
}

void stop(OutputDeviceHandle odevice, Sound sound) {
    waveOutReset(odevice);
    waveOutUnprepareHeader(odevice, sound, sizeof(SoundChunk));
}

void stop_raw(OutputDeviceHandle odevice, int16_t* buff, uint32_t size) {
    waveOutReset(odevice);
    SoundChunk wave_hdr;
    ZERO_MEMORY(wave_hdr, SoundChunk);
    wave_hdr.lpData = (LPSTR)buff;
    wave_hdr.dwBufferLength = size;
    waveOutUnprepareHeader(odevice, &wave_hdr, sizeof(SoundChunk));
}