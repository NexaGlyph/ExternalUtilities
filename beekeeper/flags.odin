//+build windows
package bkpr

/**
 * @brief InitFlag can be used to specify which Pool should be created and which not (memory preservance purposes)
 */
InitFlag :: enum u8 {
    Texture,
    Text,
    Polygon,
    Line,
    Particle,

    Custom1, // slot for custom pool no.1
    Custom2, // slot for custom pool no.2

    Reserved, // reserved for allocator
}
InitFlags_Proprietary :: InitFlags {.Reserved, .Texture, .Text, .Polygon, .Line, .Particle}; /* will automatically initialize All 5 non-Custom# Flags */
InitFlags :: bit_set[InitFlag]

#assert(len(InitFlag) == 8)

/**
 * @brief DumpFlag can be used to specify which Pool should be dumped (memory preservance purposes or application exit)
 */
DumpFlag :: distinct InitFlag
DumpFlags_Proprietary :: DumpFlags {.Reserved, .Texture, .Text, .Polygon, .Line, .Particle}; /* will automatically dump All 5 non-Custom# Flags */
DumpFlags_Allocator   :: DumpFlags {.Reserved}; /* will automatically dump all pools along with the allocators memory */
DumpFlags :: bit_set[DumpFlag]

#assert(len(DumpFlag) == len(InitFlag))