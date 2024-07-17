#ifndef DEVICE_H
#define DEVICE_H

#include <Windows.h>
#include <mmsystem.h>
#include <memory.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

// Structure to hold device information
typedef struct {
    char        device_name[MAXPNAMELEN];
    char        device_description[MAXPNAMELEN];
    uint32_t    formats;
    uint16_t    channels;
    BOOL        input;
    BOOL        output;
    uint32_t    idx;
} AudioDeviceInfo;

typedef struct {
    // custom values
    uint32_t    idx;        // device index
    
    // format values (to be set)
    uint16_t    format;            // format type
    uint16_t    channels;          // number of channels (i.e., mono, stereo...)
    uint32_t    samples_per_sec;   // sample rate
    uint16_t    bits_per_sample;   // number of bits per sample of mono data
    uint16_t    byte_count;        // count in bytes of the size of extra information
    
    // format values (to be calculated)
    uint32_t    bytes_per_sec;     // for buffer estimation
    uint16_t    block_align;       // block size of data

} OutputDeviceDescription, InputDeviceDescription;

#define CALCULATE_OUTPUT_DEVICE_VALUES(odev)                                \
    do {                                                                    \
        (odev).bytes_per_sec = (odev).samples_per_sec * (odev).channels *   \
                               ((odev).bits_per_sample / 8);               \
        (odev).block_align = (odev).channels * ((odev).bits_per_sample / 8); \
    } while (0)

#define CALCULATE_INPUT_DEVICE_VALUES(idev)                                \
    do {                                                                   \
        (idev).bytes_per_sec = (idev).samples_per_sec * (idev).channels *   \
                               ((idev).bits_per_sample / 8);               \
        (idev).block_align = (idev).channels * ((idev).bits_per_sample / 8); \
    } while (0)

typedef HWAVEOUT OutputDeviceHandle;

#define OUTPUT_DEVICE_NULL_HANDLE NULL

typedef struct {
    uint32_t idx;
    HWAVEIN  in;
} InputDeviceHandle;

#define INPUT_DEVICE_NULL_HANDLE NULL

typedef struct {
    InputDeviceDescription  idesc;
    InputDeviceHandle*      device;
    uint32_t                duration; // Complete duration of the recording sequence
} RecordConfig;

typedef WAVEHDR SoundChunk;
typedef WAVEHDR* Sound;

typedef struct {
    uint16_t    format;            // format type
    uint16_t    channels;          // number of channels (i.e., mono, stereo...)
    uint32_t    samples;           // number of samples
    uint32_t    samples_per_sec;   // sample rate
    uint16_t    bits_per_sample;   // number of bits per sample of mono data
    uint16_t    byte_count;        // count in bytes of the size of extra information
    uint32_t    bytes_per_sec;     // for buffer estimation
    uint16_t    block_align;       // block size of data
    uint32_t    size;              // size (in bytes) of the whole sound
} SoundDescription;

#define SOUND_NULL NULL

typedef struct {
    Sound           buffers;
    uint32_t*       buffer_sizes;   // Size of each buffer
    uint16_t        num_buffers;    // Number of buffers
} Recorder;

#define MAX_BUFFER_SIZE 1000000 // the maximum size of one Chunk

#define RECORDER_BUFFER_NULL NULL

typedef struct {
    uint16_t    format;  // format type
    const char* path;    // path to the save file
    uint32_t    flags;   // flags for opening the file
} SaveConfig;

enum AudioDetectError {
    NONE,
    NO_DEVICES,
    DEVICE_INFO,
    MEMORY_ALLOCATION
};

#define ERROR_NONE              NONE
#define ERROR_NO_DEVICES        NO_DEVICES
#define ERROR_DEVICE_INFO       DEVICE_INFO
#define ERROR_MEMORY_ALLOCATION MEMORY_ALLOCATION

// just raw adaption of the SND_* flags
// useful when parsing for odin lang
enum PlaySoundFlag {
    SYNC_FLG        = 0x0000,
    ASYNC_FLG       = 0x0001,
    NODEFAULT_FLG   = 0x0002,
    MEMORY_FLG      = 0x0004,
    LOOP_FLG        = 0x0008,
    NOSTOP_FLG      = 0x0010,

    NOWAIT_FLG      = 0x00002000L,
    FILENAME_FLG    = 0x00020000L
};

#define PLAYSOUND_SYNC      SYNC_FLG
#define PLAYSOUND_ASYNC     ASYNC_FLG
#define PLAYSOUND_NODEFAULT NODEFAULT_FLG
#define PLAYSOUND_MEMORY    MEMORY_FLG
#define PLAYSOUND_LOOP      LOOP_FLG
#define PLAYSOUND_NOSTOP    NOSTOP_FLG
#define PLAYSOUND_NOWAIT    NOWAIT_FLG
#define PLAYSOUND_FILENAME  FILENAME_FLG

// custom adaptation of PlaySoundFlag for easier use 
enum PlaySoundFlags {
    DEFAULT  = PLAYSOUND_SYNC,
    LOOP     = PLAYSOUND_LOOP,
    ASYNC_EX = PLAYSOUND_NOSTOP | PLAYSOUND_ASYNC
};

#define PLAYSOUND_DEFAULT_BIT  DEFAULT
#define PLAYSOUND_LOOP_BIT     LOOP
#define PLAYSOUND_ASYNC_EX_BIT ASYNC_EX

// Function to retrieve audio device information
/**
 * @param audio_device_type will be used to determine the searched type of device (Input = 1, Output = 2, Both = 4) 
 */
AudioDeviceInfo* __cdecl detect_audio_devices(uint32_t* num_devices, int* err);
AudioDeviceInfo* __cdecl detect_audio_idevices(uint32_t* num_devices, int* err);
AudioDeviceInfo* __cdecl detect_audio_odevices(uint32_t* num_devices, int* err);

// Macro to log information about the device of type AudioDeviceInfo
#define LOG_DEVICE(device_info) \
    do { \
       if ((device_info).output) \
            printf("Output audio device: %s\n", (device_info).device_name); \
       else \
            printf("Input audio device: %s\n", (device_info).device_name); \
       printf("\tdevice index... %d\n", (device_info).idx); \
       switch((device_info).formats) { \
            case WAVE_INVALIDFORMAT: \
                printf("\tdevice format... invalid\n"); \
                break; \
            case WAVE_FORMAT_1M08: \
                printf("\tdevice format... 11.025kHz, Mono, 8 bits \n");\
                break; \
            case WAVE_FORMAT_1S08: \
                printf("\tdevice format... 11.025kHz, Stereo 8 bits \n");\
                break; \
            case WAVE_FORMAT_1M16: \
                printf("\tdevice format... 11.025kHz, Mono, 16 bits \n");\
                break; \
            case WAVE_FORMAT_1S16: \
                printf("\tdevice format... 11.025kHz, Stereo, 16 bits \n");\
                break; \
            case WAVE_FORMAT_2M08: \
                printf("\tdevice format... 22.05kHz, Mono, 8 bits \n");\
                break; \
            case WAVE_FORMAT_2S08: \
                printf("\tdevice format... 22.05kHz, Stereo, 8 bits \n");\
                break; \
            case WAVE_FORMAT_2M16: \
                printf("\tdevice format... 22.05kHz, Mono, 16 bits \n");\
                break; \
            case WAVE_FORMAT_2S16: \
                printf("\tdevice format... 22.05kHz, Stereo, 16 bits \n");\
                break; \
            case WAVE_FORMAT_44M08: \
                printf("\tdevice format... 44.1kHz, Mono, 8 bits \n");\
                break; \
            case WAVE_FORMAT_44S08: \
                printf("\tdevice format... 44.1kHz, Stereo, 8 bits \n");\
                break; \
            case WAVE_FORMAT_44M16: \
                printf("\tdevice format... 44.1kHz, Mono, 16 bits \n");\
                break; \
            case WAVE_FORMAT_44S16: \
                printf("\tdevice format... 44.1kHz, Stereo, 16 bits \n");\
                break; \
            case WAVE_FORMAT_48M08: \
                printf("\tdevice format... 48kHz, Mono, 8 bits \n");\
                break; \
            case WAVE_FORMAT_48S08: \
                printf("\tdevice format... 48kHz, Stereo, 8 bits \n");\
                break; \
            case WAVE_FORMAT_48M16: \
                printf("\tdevice format... 48kHz, Mono, 16 bits \n");\
                break; \
            case WAVE_FORMAT_48S16: \
                printf("\tdevice format... 48kHz, Stereo, 16 bits \n");\
                break; \
            case WAVE_FORMAT_96M08: \
                printf("\tdevice format... 96kHz, Mono, 8 bits \n");\
                break; \
            case WAVE_FORMAT_96S08: \
                printf("\tdevice format... 96kHz, Stereo, 8 bits \n");\
                break; \
            case WAVE_FORMAT_96M16: \
                printf("\tdevice format... 96kHz, Mono, 16 bits \n");\
                break; \
            case WAVE_FORMAT_96S16: \
                printf("\tdevice format... 96kHz, Stereo, 16 bits \n");\
                break; \
            default: \
                printf("\tnot identified??\n\tnumber: %d", (device_info).formats); \
                break; \
       }  \
       printf("\tdevice channels... %d\n", (device_info).channels); \
    } while(0)

#define LOG_SOUND_DESC(sound_desc) \
    do { \
        printf("format: %u\n", (sound_desc).format); \
        printf("channels: %u\n", (sound_desc).channels); \
        printf("samples: %u\n", (sound_desc).samples); \
        printf("samples per second: %u\n", (sound_desc).samples_per_sec); \
        printf("bits per sample: %u\n", (sound_desc).bits_per_sample); \
        printf("byte count: %u\n", (sound_desc).byte_count); \
        printf("bytes per second: %u\n", (sound_desc).bytes_per_sec); \
        printf("block alignment: %u\n", (sound_desc).block_align); \
        printf("size (in bytes): %u\n", (sound_desc).size); \
    } while (0)

// Signature of the optional proc for the audio device
typedef void (CALLBACK *open_audio_idevice_proc)(HWAVEOUT, uint32_t, uint32_t*, uint32_t*, uint32_t*);

// Function to open audio (output) device
HWAVEOUT __cdecl open_audio_odevice(OutputDeviceDescription* odesc);
// Function to open audio (input) device
HWAVEIN  __cdecl open_audio_idevice(InputDeviceDescription* idesc, open_audio_idevice_proc callback, uint64_t* instance);
// Functions to get the minimum requirements for the audio device
AudioDeviceInfo __cdecl get_audio_req_file(const char* filepath);
AudioDeviceInfo __cdecl get_audio_req_raw(int16_t* raw_data);

int16_t* __cdecl read_raw(const char* filepath, SoundDescription * sound_desc);
Sound    __cdecl read_sound(const char* filepath);

// Function to play sound
// You can use these with OUTPUT_DEVICE_NULL_HANDLE to just "fast play"
void  __cdecl play_raw(OutputDeviceHandle odevice, int16_t* raw_data, uint32_t size, uint32_t flags);
void  __cdecl play_file(const char* path, uint32_t flags);
void  __cdecl play_file_ex(const char* path, uint32_t flags, double duration);
void  __cdecl play_sound(OutputDeviceHandle odevice, Sound sound, uint32_t flags); 

// Function to terminate playing sound by play_file func
void __cdecl terminate_play_file();

// Function to delete sound tracks
void __cdecl dump_sound_raw(int16_t* raw_data);
void __cdecl dump_sound(Sound sound);

// Function to stop playing from odevice (and also "unprepare" the SoundChunk(s))
void __cdecl stop(OutputDeviceHandle odevice, Sound sound);
void __cdecl stop_raw(OutputDeviceHandle odevice, int16_t* buff, uint32_t size);

// Function to record sound
Recorder __cdecl begin_rec(RecordConfig rec_config);
// Function to check whether recording is on
BOOL     __cdecl is_rec(InputDeviceHandle* input_device);
// Function to end recording sound
MMRESULT __cdecl end_rec(InputDeviceHandle* input_device, Recorder recorder, BOOL cleanup, SaveConfig save);

// Function to close audio (output) device
void __cdecl close_audio_odevice(OutputDeviceHandle out);
// Function to close audio (input) device
void __cdecl close_audio_idevice(InputDeviceHandle  in);

// Utility macros
#define MMRESULT_CHECK(err, x) \
    if ((err = x) != 0) \
        return err;

#define ZERO_MEMORY(val, type) \
    memset(&val, 0, sizeof(type));

#define CALCULATE_BUFFSIZES_WITH_ALLOC(duration, buffer_sizes, num_buffers, DeviceFormat, return_if_failed) \
    do { \
        uint32_t sz = (duration) * (DeviceFormat).channels * \
            ((DeviceFormat).bits_per_sample/8) * (DeviceFormat).samples_per_sec; \
        float ratio = ((float)sz) / MAX_BUFFER_SIZE; \
        num_buffers = ceil(ratio); \
        buffer_sizes = malloc(sizeof(uint32_t) * num_buffers); \
        if (buffer_sizes == NULL) { \
            return return_if_failed; \
        } \
        memset(buffer_sizes, MAX_BUFFER_SIZE, (num_buffers-1) * sizeof(uint32_t)); \
        buffer_sizes[num_buffers-1] = (uint32_t)((ratio - num_buffers) * MAX_BUFFER_SIZE); \
    } while (0)

#define CALCULATE_BUFFSIZE(duration, DeviceFormat) \
        (duration) * (DeviceFormat).channels \
        * ((DeviceFormat).bits_per_sample/8) * (DeviceFormat).samples_per_sec

#endif // DEVICE_H
