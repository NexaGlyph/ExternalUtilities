/*
    THIS FILE CONTAINS THE "IN"PUT HANDLING OF SOUNDS (READING .wav etc.)
*/

package mixer

import "../file"

WAV_CHUNK_ID :: 0x46464952; // RIFF
WAV_FORMAT :: 0x45564157; // WAVE
WAV_SUBCHUNK_1_ID :: 0x20746D66; // fmt
WAV_SUBCHUNK_2_ID :: 0x61746164; // data

WAV_SUBCHUNK_1_SIZE_PCM :: i32(16);

read_wav :: proc(file_name: string) -> (desc: WAV_DESC, err: i32) {
	reader := file.Reader{};
	reader.path = file_name;
	file.read_from_file(&reader);

    // RIFF CHUNK
    {
        desc.chunk.chunk_id = file.read_32bits(&reader);
        when ODIN_DEBUG {
            assert(desc.chunk.chunk_id == WAV_CHUNK_ID);
        } else {
            if desc.chunk.chunk_id != WAV_CHUNK_ID do return desc, -1;
        }
    
        desc.chunk.chunk_size = file.read_32bits(&reader);
        desc.chunk.format = file.read_32bits(&reader);
        when ODIN_DEBUG {
            assert(desc.chunk.format == WAV_FORMAT);
        } else {
            if desc.chunk.format != WAV_FORMAT do return desc, -1;
        }
    }

    // SUBCHUNK 1
    {
        desc.fmt.subchunk1_id = file.read_32bits(&reader);
        when ODIN_DEBUG {
            assert(desc.fmt.subchunk1_id == WAV_SUBCHUNK_1_ID);
        } else {
            if desc.fmt.subchunk1_id != WAV_SUBCHUNK_1_ID do return desc, -1;
        }

        desc.fmt.subchunk1_size = file.read_32bits(&reader);

        // format
        {
            if desc.fmt.subchunk1_size == WAV_SUBCHUNK_1_SIZE_PCM {
                desc.fmt.audio_format = cast(AudioFormat)file.read_16bits(&reader);

                desc.fmt.num_channels = file.read_16bits(&reader);

                desc.fmt.format_details.pcm.sample_rate = file.read_32bits(&reader);
                // skip byte rate and block align since these can be calculated from the values above.
                file.skip_bits(&reader, 32 + 16);
                desc.fmt.format_details.pcm.bits_per_sample = file.read_16bits(&reader);
            }
            else {
                when ODIN_DEBUG do assert(false, "the format subchunk type is not yet supported");
                else do return desc, -1;
            }
        }
    }

    // SUNCHUNK 2
    {
        desc.data.subchunk2_id = file.read_32bits(&reader);
        when ODIN_DEBUG {
            assert(desc.data.subchunk2_id == WAV_SUBCHUNK_2_ID);
        } else {
            if desc.data.subchunk2_id != WAV_SUBCHUNK_2_ID do return desc, -1;
        }

        desc.data.subchunk2_size = file.read_32bits(&reader);
        desc.data.data = raw_data(reader.data[reader.pos:desc.data.subchunk2_size]);
    }

    return desc, 0;
}

calculate_byte_rate :: proc(format: AudioFormat, sample_rate: i32, num_channels: i16,  bits_per_sample: i16) -> i32 {
    #partial switch (format) {
        case .PCM_FORMAT:
        case .IEEE_FLOAT_FORMAT:
            return sample_rate * i32(num_channels * bits_per_sample/8);
    }
    return -1;
}

calculate_block_align :: proc(format: AudioFormat, num_channels: i16, bits_per_sample: i16) -> i16 {
    #partial switch (format) {
        case .PCM_FORMAT:
        case .IEEE_FLOAT_FORMAT:
            return num_channels * bits_per_sample / 8;
    }
    return -1;
}