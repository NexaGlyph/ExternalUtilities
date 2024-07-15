#include "input.h"

int input_test(InputDeviceHandle* idevice, OutputDeviceHandle* odevice) {

	BOOL should_close_idevice, should_close_odevice = FALSE;
	InputDeviceDescription idesc = { 0 };
	int err = ERROR_NONE;
	if (idevice == INPUT_DEVICE_NULL_HANDLE) {
		should_close_idevice = TRUE;

		uint32_t num_devices = 0;
		AudioDeviceInfo* devices = detect_audio_devices(&num_devices, &err);
		if (err) {
			printf("[INPUT_TEST]: Failed to query audio devices!\nError: %d", err);
			return EXIT_FAILURE;
		}

		idesc.idx = 0;
		idesc.format = WAVE_FORMAT_PCM;
		idesc.channels = 2;
		idesc.samples_per_sec = 44100;
		idesc.bits_per_sample = 16;
		idesc.byte_count = 0;
		CALCULATE_INPUT_DEVICE_VALUES(idesc);
		idevice = &(InputDeviceHandle) {
			.idx = 0,
			.in = open_audio_idevice(&idesc, NULL, NULL)
		};

		if (idevice->in == INPUT_DEVICE_NULL_HANDLE) {
			printf("Failed to initialize input device!\n");
			return EXIT_FAILURE;
		}
		else {
			printf("Input device was successfully initialized!\n");
			LOG_DEVICE(devices[idesc.idx]);
		}
	}

	OutputDeviceDescription odesc = { 0 };
	err = ERROR_NONE;
	if (odevice == OUTPUT_DEVICE_NULL_HANDLE) {
		should_close_odevice = TRUE;
		// initialize device
		//		get the device info
		uint32_t num_devices = 0;
		AudioDeviceInfo* devices = detect_audio_devices(&num_devices, &err);
		if (err != ERROR_NONE) {
			return EXIT_FAILURE;
		}
		//		pick the device
		odesc.idx = 0; // basically the first functional
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

	err = ERROR_NONE;
	printf("[INPUT_TEST]: Record test (5s) ...\n");
	
	RecordConfig rec_config = {
		.duration = 5,
		.idesc = idesc,
		.device = idevice
	};
	Recorder rec = begin_rec(rec_config);
	Sleep(5000);
	if ((err = end_rec(&idevice, rec, FALSE, (SaveConfig) {
		.path = NULL
	})) != MMSYSERR_NOERROR)
	{
		printf("Scheisse... %d\n", err);
		return EXIT_FAILURE;
	}
	
	printf("[INPUT_TEST]: Record stopped   ...\n");
	printf("[INPUT_TEST]: Playing record   ...\n");
	
	play_sound(odevice, rec.buffers, PLAYSOUND_DEFAULT_BIT);
	Sleep(5000);

	printf("[INPUT_TEST]: Playing stopped  ...\n");
	
	stop(odevice, rec.buffers);
	dump_sound(rec.buffers);
	
	printf("[INPUT_TEST]: End\n");

	if (should_close_idevice)
		close_audio_idevice(*idevice);

	if (should_close_odevice)
		close_audio_odevice(odevice);

	return EXIT_SUCCESS;
}