# Image

## TO DO LIST:
    1. Merge Image (v. 1) and Image (v. 2)
    2. .BMP, .PNG
    3. Normalized Image rework
    4. RawImage type inference
    5. DynamicImageBuffer (for future sprites, videos, etc.)

## STATUS (BMP, PPM, PNG):
    1. BMP reading -> No error checking, Not yet even tested
    2. BMP writing -> Mostly done, need perfomance boost (aim for: SIMD)
    3. PNG writing -> Seems to produce some sort of error when writing (otherwise ok)
    4. PNG reading -> Not done yet
    5. PPM writing -> Needs some refactoring, otherwise stable
    6. PPM reading -> Not done yet