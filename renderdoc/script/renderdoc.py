import os
import re

# CONSTANTS
RENDERDOC_PATH = "C:/renderdoc-1.x/renderdoc-1.x"
HEADERS = list(
    [  # define a list of headers to compile, NOTE: MAYBE IN THE FUTURE MAKE A CONFIG FILE ?
        {
            "rel_path": "renderdoc/api/app",
            "header_file": "renderdoc_app.h",
            "dest_file": "renderdoc.odin",
        }
    ]
)


TYPEDEF_PATTERN = re.compile(r"typedef\s+(.*?)(\w+)\s*(\(.*?\))?\s*;")
ENUM_PATTERN = re.compile(r"(typedef\s+)?enum\s+(\w+)\s*{([^}]*)}\s*;")
FUNCTION_PATTERN = re.compile(r"(\w+)\s+(\w+)\s*\(([^)]*)\)\s*;")
VARIABLE_PATTERN = re.compile(r"(\w+)\s+(\w+)\s*;")
DEFINE_PATTERN = re.compile(r"#define\s+(\w+)\s+(.+)")


def preprocess_content(content, macros):
    lines = content.split("\n")
    preprocessed_lines = []

    for line in lines:
        define_match = DEFINE_PATTERN.match(line)
        if define_match:
            macro_name, macro_value = define_match.groups()
            macros[macro_name] = macro_value.strip()
        else:
            for macro_name, macro_value in macros.items():
                line = line.replace(macro_name, macro_value)
            preprocessed_lines.append(line)

    return "\n".join(preprocessed_lines)


def format_enum(enum_name, enum_values):
    values_str = ", ".join(enum_values)
    return f"{enum_name} :: enum {{ {values_str} }}"


def format_typedef(type_alias, original_type):
    return f"{type_alias} :: {original_type}"


def format_function(func_name, return_type, params):
    params_str = ", ".join([f"{name}: {data_type}" for name, data_type in params])
    return f"{func_name} :: proc({params_str}) -> {return_type}"


def write_to_dest_file(header, typedefs, enums, functions, variables):
    try:
        with open(header["dest_file"], "w+t") as file:
            for type_name, type_alias in typedefs.items():
                if type_name in enums:
                    file.write(format_enum(type_alias, enums[type_name]) + "\n")
                else:
                    file.write(format_typedef(type_alias, type_name) + "\n")

            for enum_name, enum_values in enums.items():
                file.write(format_enum(enum_name, enum_values) + "\n")

            for func_name, func_info in functions.items():
                return_type = func_info["return_type"]
                params = func_info["params"]
                file.write(format_function(func_name, return_type, params) + "\n")
    except:
        print(f"failed to open or create {header['dest_file']}")


def display_results(typedefs, enums, functions, variables):
    print("Typedefs:", typedefs)
    print("Enums:", enums)
    print("Functions:", functions)
    print("Variables:", variables)


def parse_content(content: list):
    typedefs = enums = functions = variables = dict()

    for line in content.split("\n"):
        typedef_match = TYPEDEF_PATTERN.match(line)
        enum_match = ENUM_PATTERN.match(line)
        function_match = FUNCTION_PATTERN.match(line)
        # variable_match = VARIABLE_PATTERN.match(line)

        if typedef_match:
            original_type, type_name, func_ptr_signature = typedef_match.groups()
            if func_ptr_signature:
                functions[type_name] = {"return_type": original_type, "params": []}
            else:
                typedefs[type_name] = original_type
        elif enum_match:
            typedef_keyword, enum_name, enum_values = enum_match.groups()
            if not typedef_keyword:
                values = [val.strip() for val in enum_values.split(",")]
                enums[enum_name] = values
        elif function_match:
            return_type, func_name, params = function_match.groups()
            param_list = [
                (name.strip(), data_type.strip())
                for name, data_type in (param.split(":") for param in params.split(","))
            ]
            functions[func_name] = {"return_type": return_type, "params": param_list}

    return typedefs, enums, functions, variables


def parse_file(header: dict):
    try:
        with open(
            RENDERDOC_PATH + "/" + header["rel_path"] + "/" + header["header_file"],
            "r",
        ) as file:
            macros = {}
            preprocessed_content = preprocess_content(file.read(), macros)
            print(preprocessed_content)
            typedefs, enums, functions, variables = parse_content(preprocessed_content)
            write_to_dest_file(header, typedefs, enums, functions, variables)
    except:
        print(f"could not open {header['header_file']}")
        os._exit(1)


def main():
    if os.path.exists(RENDERDOC_PATH):
        for header in HEADERS:
            parse_file(header)
    else:
        print("failed to open the renderdoc folder!")
        os._exit(1)


if __name__ == "__main__":
    main()
