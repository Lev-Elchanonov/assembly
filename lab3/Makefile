TARGET = main
ASM_SOURCE = main.asm
OBJ_FILE = main.o


DIR ?= 0

all: $(TARGET)

$(TARGET): $(OBJ_FILE)
	ld $< -o $@

$(OBJ_FILE): $(ASM_SOURCE)
	nasm -f elf64 -g -F dwarf $< -o $@

clean:
	rm -f $(OBJ_FILE) $(TARGET)

.PHONY: all clean
