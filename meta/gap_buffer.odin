//+build windows
package meta

import "core:mem"

GapBuffer :: struct {
    buffer: []byte,
    gap_start: int,
    gap_end: int,
}

gap_buffer_init :: #force_inline proc(size: int) -> GapBuffer {
    return GapBuffer{
        buffer = make([]byte, size),
        gap_start = 0,
        gap_end = size,
    };
}

gap_buffer_dump :: #force_inline proc(gap: ^GapBuffer) {
    delete(gap^.buffer);
}

gap_buffer_copy :: proc(gap: ^GapBuffer, src: string) {
    raw_src := transmute(mem.Raw_String)src;
    if gap^.gap_end - gap^.gap_start < len(src) do gap_buffer_resize(gap, len(src));
    mem.copy(raw_data(gap^.buffer[gap^.gap_start:]), raw_src.data, raw_src.len);
    gap^.gap_end = gap^.gap_start + len(src);
    gap^.gap_start += len(src);
}

gap_buffer_move_gap_to :: proc "contextless" (gap: ^GapBuffer, pos: int) {
     if pos < gap^.gap_start {
        // Move gap left
        move_size := gap^.gap_start - pos;
        copy_slice(gap^.buffer[gap^.gap_end-move_size:gap^.gap_end], gap^.buffer[pos:gap^.gap_start]);
        gap^.gap_end -= move_size;
        gap^.gap_start -= move_size;
    } else if pos > gap^.gap_start {
        // Move gap right
        move_size := pos - gap^.gap_start;
        copy_slice(gap^.buffer[gap^.gap_start:gap^.gap_start+move_size], gap^.buffer[gap^.gap_end:gap^.gap_end+move_size]);
        gap^.gap_end += move_size;
        gap^.gap_start += move_size;
    }
}

gap_buffer_insert :: proc(gap: ^GapBuffer, pos: int, text: string) {

    if gap^.gap_end - gap^.gap_start < len(text) {
        gap_buffer_resize(gap, len(text));
    }

    gap_buffer_move_gap_to(gap, pos);

    raw_text := transmute(mem.Raw_String)text;
    mem.copy(raw_data(gap^.buffer[gap^.gap_start:]), raw_text.data, raw_text.len);
    gap^.gap_start += len(text);
}

gap_buffer_resize :: proc(gap: ^GapBuffer, to_add: int) {
    new_size := to_add + len(gap^.buffer);
    new_buffer := make([]byte, new_size);

    copy_slice(new_buffer, gap^.buffer[:gap^.gap_start]);
    copy_slice(new_buffer[gap^.gap_end + to_add:], gap^.buffer[gap^.gap_end:]);

    delete(gap^.buffer);
    gap^.buffer = new_buffer;
    gap^.gap_end += to_add;
}

gap_buffer_to_string :: #force_inline proc(gap: ^GapBuffer) -> string {
    str_buffer := make([]byte, len(gap^.buffer) - (gap^.gap_end - gap^.gap_start));
    copy_slice(str_buffer, gap^.buffer[:gap^.gap_start]);
    copy_slice(str_buffer[gap^.gap_start:], gap^.buffer[gap^.gap_end:]);
    return string(str_buffer);
}