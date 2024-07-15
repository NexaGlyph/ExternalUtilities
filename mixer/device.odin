package mixer

SoundDeviceAim :: enum {
	Input, // capture / record
	Output, // playback
}

SoundFormat :: enum {
	SoundFormatS8, // Signed 8 bit
	SoundFormatU8, // Unsigned 8 bit
	SoundFormatS16LE, // Signed 16 bit Little Endian
	SoundFormatU16LE, // Unsigned 16 bit Little Endian
	SoundFormatS24LE, // Signed 24 bit Little Endian using low three bytes in 32-bit word
	SoundFormatU24LE, // Unsigned 24 bit Little Endian using low three bytes in 32-bit word
	SoundFormatS32LE, // Signed 32 bit Little Endian
	SoundFormatU32LE, // Unsigned 32 bit Little Endian
	SoundFormatFloat32LE, // Float 32 bit Little Endian, Range -1.0 to 1.0
	SoundFormatFloat64LE, // Float 64 bit Little Endian, Range -1.0 to 1.0
}

// these can express number of channels (just naming convenience...)
SoundChannelTypeMono 		 :: i16(1);
SoundChannelTypeStereo 		 :: i16(2);
SoundChannelTypeStereo_1 	 :: i16(3);
SoundChannelTypeSurround_5_1 :: i16(6);
SoundChannelTypeBackSurround :: i16(7);
SoundChannelTypeSurround_7_1 :: i16(8);

///////////////
RecordConfig :: struct {}

begin_recording :: proc(using input: ^InputDevice, config: RecordConfig) {
	assert(false, "TO DO!");
}

is_recording :: proc() -> bool {
	assert(false, "TO DO!");
	return false;
}

end_recording :: proc(using input: ^InputDevice) -> Sound {
	assert(false, "TO DO!");
	return {};
}

///////////////
DeviceHandle :: struct {
	idx: i32
}
OutputDevice :: struct {
	using handle: DeviceHandle
}
InputDevice :: struct {
	using handle: DeviceHandle
}

OutputDeviceDesc :: struct {
	channels: i16
}
InputDeviceDesc :: struct {

}

DEFAULT_OUTPUT_DEVICE_DESC :: OutputDeviceDesc {
	channels = SoundChannelTypeMono
}

///////////////
DeviceConfiguraion :: struct {
	odevice: ^OutputDeviceDesc,
	idevice: ^InputDeviceDesc,
}

DeviceManager :: struct {
	input:  InputDevice,
	output: OutputDevice,
}

init_device_manager :: proc(device_configs: DeviceConfiguraion) -> DeviceManager {
	assert(false, "TO DO!");
	
	err := cast(i32)AudioDetectError.NONE;
	n_devices := u32(0);
	devices := detect_audio_devices(&n_devices, &err);
	defer free(devices);
	assert(err == auto_cast AudioDetectError.NONE);

	if device_configs.idevice != nil {
		select_idevices_custom(devices, n_devices, device_configs.idevice);
	} else {
		select_idevices_suitable(devices, n_devices);
	}
	if device_configs.odevice != nil {
		select_odevices_custom(devices, n_devices, device_configs.odevice);
	} else {
		select_odevices_suitable(devices, n_devices);
	}

    return {};
}

// selects the first suitable output device
@(private="package")
select_odevices_suitable :: #force_inline proc(devices: [^]AudioDeviceInfo, n_devices: u32) -> OutputDevice {
	assert(false, "TO DO!");
	assert(n_devices > 0);
	odevice := OutputDevice{};
	for i in 0..<n_devices {
		device := devices[i];
		if device_suitable(device) do set_output_device(&odevice, &device); break;
	}
	return odevice;
}

@(private="package")
device_suitable :: #force_inline proc(device: AudioDeviceInfo) -> bool {
	if device.supported_channel < DEFAULT_OUTPUT_DEVICE_DESC.channels do return false;
	return true;	
}

@(private="package")
set_output_device :: #force_inline proc(odevice: ^OutputDevice, device_info: ^AudioDeviceInfo) {
	assert(false, "TO DO!");
}

// selects the most suitable input device (or first one)
@(private="package")
select_idevices_suitable :: #force_inline proc(devices: [^]AudioDeviceInfo, n_devices: u32) {
	assert(false, "TO DO!");
}

// selects output device based on specification (if any)
@(private="package")
select_odevices_custom :: #force_inline proc(devices: [^]AudioDeviceInfo, n_devices: u32, odevice: ^OutputDeviceDesc) {
	assert(false, "TO DO!");
}

// selects input device based on specification (if any)
@(private="package")
select_idevices_custom :: #force_inline proc(devices: [^]AudioDeviceInfo, n_devices: u32, idevice: ^InputDeviceDesc) {
	assert(false, "TO DO!");
}

dump_device_manager :: proc(using device_manager: ^DeviceManager) {
	assert(false, "TO DO!");
}

///////////////
foreign import libaudio "external/lib/libaudio.lib"

AudioDeviceInfo :: struct {
	device_name: string,
	device_description: string,
	supported_format: SoundFormat,
    supported_channel: i16,
	output: bool,
	input: bool
}

AudioDetectError :: enum i32 {
	NONE = 0,
    NO_DEVICES = 1,
    DEVICE_INFO = 2
}

WAVE_MAPPER :: ~u32(0);

foreign libaudio {
	detect_audio_devices :: proc "cdecl" (num_devices: ^u32, err: ^i32) -> [^]AudioDeviceInfo ---
}