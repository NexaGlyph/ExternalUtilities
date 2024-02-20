import sys
import re
from enum import Enum, auto

# from collections import namedtuple
# from typing import Any

# THOSE FUKING SHITS ARE IMMUTABLE
# Attributes = namedtuple(
#     "Attributes", # name of the struct
#     {    
#         "F",    # "FOLDER"        attribute
#         "If",   # "INCLUDE Files" attribute
#         "P"     # "PROC"          attribute
#         "Pf",   # "PROC File"     attribute
#     }
# )

class AttributeType:
    FOLDER = 0
    INCLUDE_FILE = 1
    PROC = 2
    PROC_FILE = 3

class Attribute:
    def __init__(self) -> None:
        self.attributes = [
            "",     # "FOLDER"        attribute
            list({""}), # "INCLUDE Files" attribute
            "",     # "PROC"          attribute
            "",     # "PROC File"     attribute
        ]

    def at(self, type: AttributeType, val: str | list) -> None:
        self.attributes[type] = val

    def __getitem__(self, item) -> str | list:
        return self.attributes[item]
    
    def insert(self, index, item) -> None:
        self.attributes[AttributeType.INCLUDE_FILE][index] = item
        
class AttributeChecker:

    class FeedType(Enum):
        WHITESPACE   = 0 #auto()
        LINEFEED     = 1 #auto()
        ALPHANUMERIC = 2 #auto()
        ATTRIBUTE    = 3 #auto()

    @staticmethod
    def feed(string, skip) -> bool:
        # if skip & (AttributeChecker.FeedType.WHITESPACE | AttributeChecker.FeedType.ALPHANUMERIC):
        #     return string.isspace() or string.isalnum()
        
        # if skip & AttributeChecker.FeedType.ATTRIBUTE:
        #     return string[0] != '-'
        return string[0] == skip

    def __init__(self, buffer: list = sys.argv[1:-1]) -> None:

        self.buffer = buffer
        print(f"[AttributeChecker]: Setting up buffer: {self.buffer}")

        self.attributes = Attribute()

        self.attributes_identificator = {
            "-F"  : AttributeType.FOLDER,
            "-If" : AttributeType.INCLUDE_FILE,
            "-P"  : AttributeType.PROC,
            "-Pf" : AttributeType.PROC_FILE
        }

    def assert_file_dest(self) -> None:
        folder = self.attributes[AttributeType.FOLDER]
        for index in range(len(self.attributes[AttributeType.INCLUDE_FILE])):
            file = self.attributes[AttributeType.INCLUDE_FILE][index]
            if file[0 : len(folder)] != folder:
                self.attributes.insert(index, folder + file)
                print(f"[AttributeChecker]: Destination of (If) changed to: {self.attributes[AttributeType.INCLUDE_FILE][index]}")

    def analyze_attribute_buffer(self) -> None:
        index = 0
        for i in range(len(self.buffer)):
            line = self.buffer[i]
            if line in self.attributes_identificator:
                index += 1
                print("[AttributeChecker]: Attribute FOUND\t... " + line)
                while index < len(self.buffer) and not self.feed(self.buffer[index], "-"):
                    index += 1
                identifier = self.attributes_identificator[line]
                if identifier == AttributeType.INCLUDE_FILE:
                    self.attributes.at(self.attributes_identificator[line], self.buffer[i + 1: index])
                    print(f"[AttributeChecker]: Attribe SET\t... \t{self.buffer[i + 1: index]}")
                else:
                    self.attributes.at(identifier, ''.join(self.buffer[i + 1 : index]))
                    print(f"[AttributeChecker]: Attribe SET\t... \t{self.buffer[i + 1 : index]}")
                i = index

        self.assert_file_dest()

    def files(self) -> list:
        return self.attributes[AttributeType.INCLUDE_FILE]
    
    def proc_file(self) -> str:
        return self.attributes[AttributeType.PROC_FILE]