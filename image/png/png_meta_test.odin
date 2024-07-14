package png_

import "core:fmt"
import "core:image"
import "core:image/png"

main :: proc() {
    img, err := png.load("bgr8.png", image.Options{.return_metadata});

	if err != nil {
		fmt.printf("Trying to read PNG file %v returned %v\n", "bgr8.png", err)
    } else {
        fmt.println("Eyo wut");
    }
}