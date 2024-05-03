from dataclasses import dataclass
from typing import TextIO
from re import compile
from struct import pack

from primitives import *

DEBUG = True  # change as needed


class Integer:
    def __init__(self, value=0):
        self._value = int(value)

    def __repr__(self):
        return f"Integer({self._value})"

    def __add__(self, other):
        if isinstance(other, CustomInteger):
            return CustomInteger(self._value + other._value)
        return self._value + other

    def __iadd__(self, other):
        self._value += other
        return self


class Int8(Integer):
    def __init__(self, value=0):
        super().__init__(value)
        self._max_value = 2**8 - 1

    def __repr__(self):
        return f"Int8({self._value})"

    def __iadd__(self, other):
        self._value = (self._value + other) % (self._max_value + 1)
        return self


class UInt16(Integer):
    def __init__(self, value=0):
        super().__init__(value)
        self._max_value = 2**16 - 1

    def __repr__(self):
        return f"UInt16({self._value})"


@dataclass
class MappingVariableProperty:
    value: "MappingVariableArbitrary"


class MappingVariableArbitrary:
    def __init__(
        self, index: UInt16, next: list[MappingVariableProperty], name: str = ""
    ):
        self.index = index
        if DEBUG:
            self.name = name
        self.next = next

    index: UInt16
    if DEBUG:
        name: str
    next: list[MappingVariableProperty]


@dataclass
class MappingFile:
    sizes: list[int]
    properties: list[MappingVariableProperty]


class StructMember:

    def __init__(self, name: str, type: str, nbytes: int = 1) -> None:
        self.name = name
        if type in PRIMITIVES_SIZES:
            self.primitive = Primitive(
                type, PRIMITIVES_SIZES[type] * nbytes if nbytes == 1 else nbytes
            )
        else:
            self.primitive = None
            self.type = type

    name: str
    primitive: Primitive | None


def is_primitive(member: StructMember) -> bool:
    return member.primitive is not None


class Struct:

    def __init__(self, name: str) -> None:
        self.name = name
        self.members = []

    def add_member(self, member: StructMember) -> None:
        self.members.append(member)

    name: str
    members: list[StructMember]


def parse_file(file: TextIO) -> list[Struct]:

    STRUCT_DEF_BEGIN = compile(r"(\w+)\s*::\s*struct\s*{")
    STRUCT_PROP_DECL = compile(r"(\w+)\s*:\s*(\w+)(?:\[(\d+)\])?,")

    i: int = 0
    lines: list[str] = file.readlines()
    structs: list[Struct] = []
    while i < len(lines):
        if match := STRUCT_DEF_BEGIN.match(lines[i].strip()):
            i += 1
            struct = Struct(match.group(1))
            print(match.group(1))
            while match := STRUCT_PROP_DECL.match(lines[i].strip()):
                if match.group(3) is not None:
                    struct.add_member(
                        StructMember(
                            match.group(1), match.group(2), int(match.group(3))
                        )
                    )
                    print(f"\t{match.group(1)} : {match.group(2)}[{match.group(3)}]")
                else:
                    struct.add_member(StructMember(match.group(1), match.group(2)))
                    print(f"\t{match.group(1)} : {match.group(2)}")
                i += 1

            structs.append(struct)
            continue
        i += 1

    return structs


def levenshtein_distance(s1: str, s2: str) -> int:
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)

    if len(s2) == 0:
        return len(s1)

    previous_row = [i for i in range(len(s2) + 1)]
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


def create_mapping(structs: list[Struct], target: Struct) -> MappingFile:
    sizes: list[int] = []
    properties: list[MappingVariableProperty] = []

    sizes_index: int = 0

    def search_for_struct(needle: Struct) -> Struct:
        for struct in structs:
            if needle.name == struct.name:
                return struct
        raise Exception(f"Struct {needle.name} was not found!")

    def member_is_struct(needle: StructMember) -> Struct | None:
        for struct in structs:
            if needle.type == struct.name:
                return struct
        return None

    def variable_scan(member: StructMember) -> MappingVariableProperty:
        # this will ALWAYS be defined
        sizes.append(member.primitive.size)  # type: ignore[union-attr]
        return MappingVariableProperty(
            MappingVariableArbitrary(UInt16(sizes_index), [], member.name)
        )

    def variable_scan_recursive(struct: Struct) -> list[MappingVariableProperty]:
        struct_properties: list[MappingVariableProperty] = []
        for member in struct.members:
            if is_primitive(member):
                struct_properties.append(variable_scan(member))
                continue
            if (struct_ := member_is_struct(member)) is not None:
                struct_properties.append(
                    MappingVariableProperty(
                        MappingVariableArbitrary(
                            UInt16(sizes_index),
                            variable_scan_recursive(struct_),
                        ),
                    ),
                )
            else:
                raise Exception(f"{member.name} not a struct nor an arbitrary value!")

        return struct_properties

    for member in target.members:
        if is_primitive(member):
            sizes.append(member.primitive.size)  # type: ignore[union-attr]
            properties.append(
                MappingVariableProperty(
                    MappingVariableArbitrary(
                        UInt16(len(sizes) - 1),
                        [],
                        member.name,
                    )
                )
            )
        else:
            for struct in structs:
                if struct.name == member.type:
                    properties += variable_scan_recursive(struct)
                    break
            else:
                raise Exception(
                    f"The definition for the member [{member.name} : {member.type}] was not found!"
                )

    print(sizes)
    print(properties)
    return MappingFile(sizes, properties)


def open_program_in_use_type_file() -> None:
    def check_extension(file_path: str) -> str:
        if file_path.endswith(".mrtype"):
            return file_path
        return file_path + ".mrtype"

    def write_file_mapping(mapping: MappingFile, file_path: str) -> None:
        with open(file_path + ".mrmap", "wb+") as file:
            # write SIZES
            file.write(
                pack(f"<H{len(mapping.sizes)}B", len(mapping.sizes), *mapping.sizes)
            )
            # write PROPERTIES
            file.write(pack(f""))

    file_path: str = input("Name of the file with the 'program-in-use' type: ")
    with open(
        check_extension(file_path),
        "r",
        encoding="utf-8",  # Odin files may contain UTF-8 characters
    ) as file:
        structs: list[Struct] = parse_file(file)
        struct_name: str = input("Struct to parse: ").strip()

        struct_found = next((s for s in structs if s.name == struct_name), None)
        if struct_found is None:
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
            write_file_mapping(create_mapping(structs, struct_found), file_path)


if __name__ == "__main__":
    open_program_in_use_type_file()
