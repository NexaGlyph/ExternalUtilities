import os

if __name__ == "__main__":
    file_buffer = [file for file in os.listdir("./") if file.endswith(".odin")]

    with open("beekeeper.odin", "w+", encoding="utf-8") as file_to_write:
        with open(file_buffer[0], "r", encoding="utf-8") as file_to_copy:
            print("".join(file_to_copy.readlines()), file=file_to_write)

    for file in file_buffer[1:]:
        with open("beekeeper.odin", "a", encoding="utf-8") as file_to_write:
            with open(file, "r", encoding="utf-8") as file_to_copy:
                print("".join(file_to_copy.readlines()), file=file_to_write)