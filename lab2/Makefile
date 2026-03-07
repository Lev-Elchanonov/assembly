TARGET = main
ASM_SOURCE = main.asm
OBJ_FILE = main.o


DIR ?= 0

all: $(TARGET)

$(TARGET): $(OBJ_FILE)
	ld $< -o $@

$(OBJ_FILE): $(ASM_SOURCE)
	nasm -f elf64 -g -F dwarf -D SORT_DIRECTION=$(DIR) $< -o $@

clean:
	rm -f $(OBJ_FILE) $(TARGET)

.PHONY: all clean
