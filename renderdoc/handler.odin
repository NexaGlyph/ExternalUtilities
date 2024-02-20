package renderdoc

import "core:dynlib"

RENDERDOC_HANDLER :: struct {
    using rdoc_api : ^RENDERDOC_API_1_1_0, // act as if it were the lowest
    renderdoc_lib : dynlib.Library
}