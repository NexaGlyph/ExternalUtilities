//+build windows
package bkpr

/**
 * @brief InitFlag can be used to specify which Pool should be created and which not (memory preservance purposes)
 */
InitFlag :: enum {
    Texture,
    Text,
    Polygon,
    Line,
    Particle,
}
InitFlags :: bit_set[InitFlag]

#assert(len(InitFlag) == 5)

/**
 * @brief DumpFlag can be used to specify which Pool should be dumped (memory preservance purposes or application exit)
 */
DumpFlag :: enum {
    All = 1,

    Texture,
    Text,
    Polygon,
    Line,
    Particle,
}
DumpFlags :: bit_set[DumpFlag]

#assert(len(DumpFlag) == len(InitFlag) + 1)