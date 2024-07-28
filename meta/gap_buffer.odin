//+build windows
package meta

import "core:unicode/utf8"

GapBuffer :: struct {
    buffer: []rune,
    gap_start: int,
    gap_end: int,
}

gap_buffer_init :: #force_inline proc(size: int) -> GapBuffer {
    return GapBuffer{
        buffer = make([]rune, size),
        gap_start = 0,
        gap_end = size,
    };
}

/** @note this call should not be executed if you have called the 'gap_buffer_to_string'! (invalidates the string buffer) */
gap_buffer_dump :: #force_inline proc(gap: ^GapBuffer) {
    delete(gap^.buffer);
}

gap_buffer_move_gap_to :: proc "contextless" (gap: ^GapBuffer, pos: int) {
    if pos < gap^.gap_start {
        for i := pos; i < gap^.gap_start; i += 1 {
            gap^.buffer[gap^.gap_end - 1] = gap^.buffer[i];
            gap^.gap_end -= 1;
        }
    } else if pos > gap^.gap_start {
        for i := gap^.gap_end; i < pos; i += 1 {
            gap^.buffer[gap^.gap_start] = gap^.buffer[i];
            gap^.gap_start += 1;
        }
    }
    gap^.gap_start = pos;
    gap^.gap_end = pos + (gap^.gap_end - gap^.gap_start);
}

gap_buffer_insert :: proc "contextless" (gap: ^GapBuffer, pos: int, text: string) {
    gap_buffer_move_gap_to(gap, pos);
    for i in text {
        gap^.buffer[gap^.gap_start] = i;
        gap^.gap_start += 1;
    }
}

gap_buffer_to_string :: #force_inline proc(gap: ^GapBuffer) -> string {
    return utf8.runes_to_string(gap^.buffer);
}