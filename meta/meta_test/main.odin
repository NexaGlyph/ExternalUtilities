//+build windows
package test

import meta "../../meta"

main :: proc() {
    meta.check_nexa_project(
        "C:\\Programming\\Projects\\NexaGlyph\\ExternalUtilities\\meta\\meta_test\\sample_demo",
        "C:\\Programming\\Projects\\NexaGlyph\\ExternalUtilities\\meta\\meta_test\\sample_core",
        "C:\\Programming\\Projects\\NexaGlyph\\ExternalUtilities\\meta\\meta_test\\sample_external_utils",
    );
}