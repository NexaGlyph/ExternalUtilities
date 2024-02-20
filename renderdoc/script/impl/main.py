import re
import os
import sys

###
# py main.py -F ../game/VLKN/ -P _proc_addr_init  -Pf ../game/VLKN/append.odin -If vulkan.odin macros.odin instance.odin ldevice.odin pdevice.odin qfamily.odin structs.odin surface.odin swapchain.odin
###

import attribute_checker
import defs


def get_struct_functions(file_contents: str, struct_name: str, prefix: str = "") -> list:
    struct_pattern = re.compile(fr'{struct_name}\s*::\s*struct\s*{{(.*?^}})', re.DOTALL | re.MULTILINE)
    struct_match = struct_pattern.search(file_contents)

    if struct_match:
        struct_content = struct_match.group(1)
        print(struct_content)
        function_pattern = re.compile(r'([a-zA-Z_]\w*)\s*:\s*(pRENDERDOC_\w+)\s*')
        function_matches = function_pattern.findall(struct_content)
        # return [f"{func[1]} {func[0]}" for func in function_matches]
        return [f"{prefix}{func[0]}" for func in function_matches]
    else:
        return []


def get_union_functions(file_contents: str, union_name: str) -> list:
    union_pattern = re.compile(
        f"using {union_name} : struct #raw_union {{(.*?)}}", re.DOTALL
    )
    union_match = union_pattern.search(file_contents)
    if union_match:
        union_content = union_match.group(1)
        return get_struct_functions(union_content, union_name, prefix=union_name+".")
    else:
        return []


def get_proc_signatures(file_contents: str, struct_name: str) -> list:
    struct_functions = get_struct_functions(file_contents, struct_name)
    found_procs = list()
    for proc in struct_functions:
        if proc not in found_procs and proc not in defs.ODIN_PROC_EXCEPTIONS:
            found_procs.append(proc)

    union_names = re.findall(r'using (\w+) : struct #raw_union', file_contents)
    for union_name in union_names:
        found_procs += get_union_functions(file_contents, union_name)
    
    print(f"Procedures: {found_procs}")
    return sorted(found_procs, key=len)


def tabulate(lo_tablen: int, hi_tablen: int):
    return " " * (hi_tablen - lo_tablen)


def bind_all_struct_functions(
    file: int, struct_functions: list, dest_struct: str
) -> None:
    struct_functions = sorted(struct_functions, key=len)
    struct_signature = list({f"{dest_struct} :: proc(renderdoc_handler: ^RENDERDOC_HANDLER) {{\n"})
    assertion_layer = list({"\n \t/*-----ASSERTION LAYER-----*/\n"})

    hi_tablen = len(struct_functions[len(struct_functions) - 1])
    for struct_function in struct_functions:
        lo_tablen = len(struct_function)
        struct_signature.append(
            f'\trenderdoc_handler.rdoc_api.{struct_function} {tabulate(lo_tablen, hi_tablen)} = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_{struct_function}");\n'
        )
        assertion_layer.append(
            f'\tassert(renderdoc_handler.rdoc_api.{struct_function} {tabulate(lo_tablen, hi_tablen)} != nil, "failed to bind RENDERDOC_{struct_function}");\n'
        )

    for func in struct_signature:
        file.write(func)
    file.write("\n")
    for proc in assertion_layer:
        file.write(proc)
    file.write("}\n\n")


def append_proc_bindings(file: int, proc_bindings: list, dest_proc: str) -> None:
    proc_bindings = sorted(proc_bindings, key=len)
    proc_signature = list(
        {f"{dest_proc} :: proc(using renderdoc_handler: ^RENDERDOC_HANDLER) {{\n"}
    )
    assertion_layer = list({"\n \t/*-----ASSERTION LAYER-----*/\n"})

    hi_tablen = len(proc_bindings[len(proc_bindings) - 1])
    for proc_binding in proc_bindings:
        lo_tablen = len(proc_binding)
        proc_signature.append(
            f'\trenderdoc_handler.rdoc_api->{proc_binding} {tabulate(lo_tablen, hi_tablen)} = auto_cast dynlib.symbol_address(renderdoc_handler.renderdoc_lib, "RENDERDOC_{proc_binding}");\n'
        )
        assertion_layer.append(
            f'\tassert(renderdoc_handler.rdoc_api->{proc_binding} {tabulate(lo_tablen, hi_tablen)} != nil, "failed to bind RENDERDOC_{proc_binding}");\n'
        )

    for proc in proc_signature:
        file.write(proc)
    file.write("\n")
    for proc in assertion_layer:
        file.write(proc)
    file.write("}\n\n")


FULL_SCAN = False
# FULL_SCAN_DIR      = ["../../../../core"]
FULL_SCAN_DIR = ["../../renderdoc.odin"]
FULL_SCAN_PROC = "_load_instance_proc_addr_full_scan"
FULL_SCAN_PROC_DIR = "../../../append_full_scan.odin"


def main():
    if FULL_SCAN:
        buffer = str("")
        for scan_dir in FULL_SCAN_DIR:
            for root, _, files in os.walk(scan_dir):
                for file_name in files:
                    if file_name.endswith(".odin"):
                        file_path = os.path.join(root, file_name)
                        with open(file_path, "r") as file:
                            # Append each line of the file as a separate string to the list
                            buffer += file.read()

        with open(FULL_SCAN_PROC_DIR, "w") as file:
            for line in defs.ODIN_FILE_LOGO:
                file.write(line)
            file.write("package renderdoc\n\n")
            file.write('import "core:dynlib"\n\n')
            # file.write('import "renderdoc"\n\n')

            struct_name = "RENDERDOC_API_1_6_0"
            print(f"BUFFER: {buffer}")
            struct_functions = get_proc_signatures(
                file_contents=buffer, struct_name=struct_name
            )
            bind_all_struct_functions(
                file, struct_functions=struct_functions, dest_struct=struct_name
            )
            # append_proc_bindings(file, get_proc_signatures(buffer), FULL_SCAN_PROC)

    else:
        buffer = list({""})
        with open(sys.argv[1], "r") as file:
            buffer = file.readlines()
            for i in range(len(buffer)):
                buffer[i] = buffer[i].strip()

        attr_checker = attribute_checker.AttributeChecker(buffer)
        attr_checker.analyze_attribute_buffer()

        file_contents = ""
        for file in attr_checker.files():
            print(f"Opening file... {file}")
            with open(file, "r+") as file:
                file_contents += file.read()

        with open(attr_checker.proc_file(), "w") as file:
            for line in defs.ODIN_FILE_LOGO:
                file.write(line)
            file.write("package renderdoc\n\n")
            file.write('import "core:dynlib"\n\n')
            # file.write('import "renderdoc"\n\n')

            struct_name = "RENDERDOC_API_1_6_0"
            struct_functions = get_proc_signatures(
                file_contents=file_contents, struct_name=struct_name
            )
            bind_all_struct_functions(
                file, struct_functions=struct_functions, dest_struct=attr_checker.attributes[attribute_checker.AttributeType.PROC]
            )
            # append_proc_bindings(file, defs.ODIN_PROC_DEFAULT, "_proc_addr_init")
            # append_proc_bindings(file, get_proc_signatures(file_contents), attr_checker.attributes[attribute_checker.AttributeType.PROC])


if __name__ == "__main__":
    main()
