AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64
LDFLAGS = -static -z noexecstack

LIBPATH = -L /lib/gcc/x86_64-linux-gnu/14 -L /lib
OBJPATH = /usr/lib
GNUPATH = /usr/lib/x86_64-linux-gnu

LIBS = -lgcc -lgcc_eh -lc -lm

PREOBJ = $(GNUPATH)/crt1.o $(GNUPATH)/crti.o
POSTOBJ = $(GNUPATH)/crtn.o

SRC = lab4.asm
OBJ = $(SRC:.asm=.o)

EXE = lab4

all: $(SRC) $(EXE)

clean:
	rm -rf $(EXE) $(OBJ)

$(EXE): $(OBJ)
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $(OBJ) $(POSTOBJ) -\( $(LIBS) -\) -o $@

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@
