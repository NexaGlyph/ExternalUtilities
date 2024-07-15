package mixer

AudioFormatType :: enum {
	WAV,
	MP3,
}

/* WAVE FILE */
AudioFormat :: enum i16 {
	PCM_FORMAT        = 0x0001,
	IEEE_FLOAT_FORMAT = 0x0003,
	ALAW_FORMAT       = 0x0006,
	ULAW_FORMAT       = 0x0007,
}

PCM_FORMAT :: struct {
	sample_rate:     i32,
	bits_per_sample: i16,
}

IEEE_FLOAT_FORMAT :: PCM_FORMAT
ALAW_FORMAT :: PCM_FORMAT
ULAW_FORMAT :: PCM_FORMAT

AudioFormatDetails :: struct #raw_union {
	pcm:        PCM_FORMAT,
	ieee_float: IEEE_FLOAT_FORMAT,
	alaw:       ALAW_FORMAT,
	ulaw:       ULAW_FORMAT,
}

WAV_RIFF_CHUNK :: struct {
	chunk_id:   i32, // "RIFF"
	chunk_size: i32, // 4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
	format:     i32, // "WAVE"
}

WAV_FMT_SUBCHUNK :: struct {
	subchunk1_id:   i32, // "fmt"
	subchunk1_size: i32, // 16 for PCM
	audio_format:   AudioFormat, // e.g. PCM = 1
	num_channels:   i16, // Mono = 1, Stereo = 2, etc.
	format_details: AudioFormatDetails,
    using extra: struct {
        param_size: i16,
        params: rawptr,
    },
}

WAV_DATA_SUBCHUNK :: struct {
	subchunk2_id:   i32, // "data"
	subchunk2_size: i32, // size of the data section
	data:           rawptr,
}

WAV_DESC :: struct {
	chunk: WAV_RIFF_CHUNK,
	fmt:   WAV_FMT_SUBCHUNK,
	data:  WAV_DATA_SUBCHUNK,
}

/* MP3 FILE */

MP3_DESC :: struct {
	
}