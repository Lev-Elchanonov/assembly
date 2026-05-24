CC = /usr/bin/gcc
AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -F dwarf -f elf64
LDFLAGS = -static -z noexecstack

LIBPATH = -L /lib/gcc/x86_64-linux-gnu/14 -L /lib
OBJPATH = /usr/lib
GNUPATH = /usr/lib/x86_64-linux-gnu

LIBS = -lgcc -lgcc_eh -lc -lm

PREOBJ = $(GNUPATH)/crt1.o $(GNUPATH)/crti.o
POSTOBJ = $(GNUPATH)/crtn.o

OBJDIR = build

C_MAIN = main.c
C_FILTER = sobel_c.c
ASM_FILTER = sobel_asm.asm
SIMD_FILTER = sobel_simd.asm          # ← ДОБАВИТЬ

OPT_LEVELS = O0 O1 O2 O3 Ofast

C_TARGETS = $(foreach opt,$(OPT_LEVELS),edge_detect_c_$(opt))
ASM_TARGET = edge_detect_asm
SIMD_TARGET = edge_detect_simd        # ← ДОБАВИТЬ


.PHONY: all
all: c_targets $(ASM_TARGET) $(SIMD_TARGET)    # ← ДОБАВИТЬ SIMD

.PHONY: c_targets
c_targets: $(C_TARGETS)


.PHONY: c
c: edge_detect_c_O2

.PHONY: asm
asm: $(ASM_TARGET)

.PHONY: simd
simd: $(SIMD_TARGET)


.PHONY: clean
clean:
	rm -rf $(C_TARGETS) $(ASM_TARGET) $(SIMD_TARGET) $(OBJDIR)


$(OBJDIR):
	mkdir -p $(OBJDIR)


edge_detect_c_O0: $(OBJDIR)/main_c_O0.o $(OBJDIR)/sobel_c_O0.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O1: $(OBJDIR)/main_c_O1.o $(OBJDIR)/sobel_c_O1.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O2: $(OBJDIR)/main_c_O2.o $(OBJDIR)/sobel_c_O2.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O3: $(OBJDIR)/main_c_O3.o $(OBJDIR)/sobel_c_O3.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_Ofast: $(OBJDIR)/main_c_Ofast.o $(OBJDIR)/sobel_c_Ofast.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

$(ASM_TARGET): $(OBJDIR)/main_asm.o $(OBJDIR)/sobel_asm.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

# ← ДОБАВИТЬ правило для SIMD
$(SIMD_TARGET): $(OBJDIR)/main_simd.o $(OBJDIR)/sobel_simd.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

$(OBJDIR)/main_c_O0.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O0 -c $< -o $@

$(OBJDIR)/main_c_O1.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O1 -c $< -o $@

$(OBJDIR)/main_c_O2.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O2 -c $< -o $@

$(OBJDIR)/main_c_O3.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O3 -c $< -o $@

$(OBJDIR)/main_c_Ofast.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -Ofast -c $< -o $@

$(OBJDIR)/sobel_c_O0.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O0 -c $< -o $@

$(OBJDIR)/sobel_c_O1.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O1 -c $< -o $@

$(OBJDIR)/sobel_c_O2.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O2 -c $< -o $@

$(OBJDIR)/sobel_c_O3.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O3 -c $< -o $@

$(OBJDIR)/sobel_c_Ofast.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -Ofast -c $< -o $@

$(OBJDIR)/main_asm.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O0 -DUSE_ASM -c $< -o $@

$(OBJDIR)/sobel_asm.o: $(ASM_FILTER) | $(OBJDIR)
	$(AS) $(ASFLAGS) $< -o $@


$(OBJDIR)/main_simd.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O0 -DUSE_SIMD -c $< -o $@


$(OBJDIR)/sobel_simd.o: $(SIMD_FILTER) | $(OBJDIR)
	$(AS) $(ASFLAGS) $< -o $@