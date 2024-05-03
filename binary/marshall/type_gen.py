from dataclasses import dataclass
from typing import TextIO

DEBUG = True  # change as needed

type UInt = int

@dataclass
class MappingVariableProperty:
    value: "MappingVariableArbitrary"


@dataclass
class MappingVariableArbitrary:
    index: UInt
    if DEBUG:
        name: str
    next: list[MappingVariableProperty]


@dataclass
class MappingFile:
    sizes: list[int]
    properties: list[MappingVariableProperty]


class Struct:

    def __eq__(self, __value: object) -> bool:
        assert False
        if type(__value) == str:
            return __value == self.name
        return __value.name == self.name

    name: str


def write_file_mapping(file_buffer: MappingFile) -> None:
    def check_extension(file_path: str) -> str:
        if file_path.endswith("mr"):
            return file_path
        return file_path + "mr"

    with open(check_extension(input("Name of the file to write to: ")), "wb+") as file:
        file.write()


def parse_file(file: TextIO) -> list[Struct]:
    for line in file:
        pass
    return list()


def levenshtein_distance(s1: str, s2: str) -> int:
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)

    if len(s2) == 0:
        return len(s1)

    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    return previous_row[-1]


def fuzzy_match(struct: str, structs: list[str]) -> str | None:
    distances = [
        (_struct, levenshtein_distance(struct, _struct)) for _struct in structs
    ]
    matches = sorted(distances, key=lambda x: x[1])
    return matches[0][0] if matches else None


def open_program_in_use_type_file() -> MappingFile:
    def check_extension(file_path: str) -> str:
        if file_path.endswith(".mrtype"):
            return file_path
        return file_path + ".mrtype"

    with open(
        check_extension(input("Name of the file with the 'program-in-use' type: ")),
        "r",
        encoding="utf-8",  # Odin files may contain UTF-8 characters
    ) as file:
        structs: list[Struct] = parse_file(file)
        struct_name: str = input("Struct to parse: ").strip()

        if struct_name not in structs:
            if (
                res := fuzzy_match(struct_name, [struct.name for struct in structs])
            ) is not None:
                raise Exception(
                    f"Failed to find the desired struct wit the name {struct_name}! Did you mean {res}"
                )
            else:
                raise Exception(
                    f"Failed to find the desired struct with the name {struct_name}!"
                )
        else:
            create_mapping()


if __name__ == "__main__":
    open_program_in_use_type_file()
