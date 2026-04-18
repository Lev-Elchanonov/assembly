TARGET = lab4
ASM_SOURCE = lab4.asm
OBJ_FILE = lab4.o


DIR ?= 0

all: $(TARGET)

$(TARGET): $(OBJ_FILE)
	gcc -no-pie $< -lm -o $@

$(OBJ_FILE): $(ASM_SOURCE)
	nasm -f elf64 -g $< -o $@

clean:
	rm -f $(OBJ_FILE) $(TARGET)

.PHONY: all clean
