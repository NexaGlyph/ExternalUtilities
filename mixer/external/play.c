#include <stdlib.h>
#include <assert.h>

#include "device.h"
// test header
#include "play.h"

//#define PLAY_RAW_TEST

#define SAMPLE_RATE 44100
#define AMPLITUDE	0.5
#define FREQUENCY	440.0
#define PI			3.14159

void generate_sine_wave(int16_t* buffer, double duration) {
	size_t num_samples = (size_t)(duration * SAMPLE_RATE);

	for (size_t i = 0; i < num_samples; ++i) {
		double time = (double)i / SAMPLE_RATE;
		double value = sin(2.0 * PI * FREQUENCY * time);

		// Scale and convert to 16-bit PCM
		buffer[i] = (int16_t)(AMPLITUDE * value * INT16_MAX);
	}
}

int play_test(OutputDeviceHandle* odevice) {

	BOOL should_close_odevice = FALSE;
	OutputDeviceDescription odesc = { 0 };
	if (odevice == OUTPUT_DEVICE_NULL_HANDLE) {
		should_close_odevice = TRUE;
		// initialize device
		//		get the device info
		uint32_t num_devices = 0;
		int err = ERROR_NONE;
		AudioDeviceInfo* devices = detect_audio_odevices(&num_devices, &err);
		if (err != ERROR_NONE) {
			return EXIT_FAILURE;
		}
		
		//		pick the device
		odesc.idx = 0; // basically the first functional -- should be the default
		odesc.format = WAVE_FORMAT_PCM;
		odesc.channels = 2;
		odesc.samples_per_sec = 44100;
		odesc.bits_per_sample = 16;
		odesc.byte_count = 0;
		CALCULATE_OUTPUT_DEVICE_VALUES(odesc);

		odevice = open_audio_odevice(&odesc);

		if (odevice == OUTPUT_DEVICE_NULL_HANDLE) {
			printf("Failed to initialize output device!\n");
			return EXIT_FAILURE;
		}
		else {
			printf("Output device was successfully initialized!\n");
			LOG_DEVICE(devices[odesc.idx]);
		}
	}
#ifdef PLAY_RAW_TEST



	printf("[PLAY_TEST]: raw (5s)...\n");
	{
		// generate the raw data
		size_t size = CALCULATE_BUFFSIZE(5, odesc);
#ifndef LIBAUDIO_VIRTUAL_ALLOC
		int16_t* raw_sound = calloc(1, sizeof(int16_t) * size);
#else
		int16_t* raw_sound = VirtualAlloc(NULL, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
#endif
		generate_sine_wave(raw_sound, 5.0);
		// play the raw data
		play_raw(odevice, NULL, 0, PLAYSOUND_DEFAULT_BIT);
		Sleep(5000);
		// stop the sound
		stop_raw(odevice, raw_sound, (uint32_t)size);
		// dump the raw data
		dump_sound_raw(raw_sound);
	}
	printf("[PLAY_TEST]: raw END\n");
#endif // PLAY_RAW_TEST
	printf("[PLAY_TEST]: file (5s) ...\n");
	{
		play_file("s1.wav", PLAYSOUND_ASYNC);
		Sleep(1000);
		play_file("s1.wav", PLAYSOUND_ASYNC);
		Sleep(5000);
		terminate_play_file();
	}
	printf("[PLAY_TEST]: file END\n");

	printf("waiting (5s) ...\n");
	Sleep(5000);

	printf("[PLAY_TEST]: raw read (5s) ...\n");
	{
		// generate the sound
		SoundDescription sound_desc = { 0 };
		int16_t* buff = read_raw("s1.wav", &sound_desc);
		LOG_SOUND_DESC(sound_desc);
		if (buff == SOUND_NULL) {
			return EXIT_FAILURE;
		}
		// play the sound
		play_raw(odevice, buff, sound_desc.size, PLAYSOUND_DEFAULT_BIT);
		Sleep(5000);
		// stop the sound
		stop_raw(odevice, buff, sound_desc.size);
		// dump the sound
		dump_sound_raw(buff);
	}
	printf("[PLAY_TEST]: raw read END\n");

	if (should_close_odevice)
		close_audio_odevice(odevice);

	return EXIT_SUCCESS;
}