# Инструменты
CC = /usr/bin/gcc
AS = /usr/bin/nasm
LD = /usr/bin/ld

# Флаги
ASFLAGS = -g -f elf64
LDFLAGS = -static -z noexecstack

# Пути к библиотекам
LIBPATH = -L /lib/gcc/x86_64-linux-gnu/14 -L /lib
OBJPATH = /usr/lib
GNUPATH = /usr/lib/x86_64-linux-gnu

# Подключаемые библиотеки
LIBS = -lgcc -lgcc_eh -lc -lm

# Объектные файлы для запуска программы
PREOBJ = $(GNUPATH)/crt1.o $(GNUPATH)/crti.o
POSTOBJ = $(GNUPATH)/crtn.o

# Каталог для объектных файлов
OBJDIR = build

# Исходные файлы
C_MAIN = main.c
C_FILTER = filter_c.c
ASM_FILTER = filter_asm.asm

# Уровни оптимизации для C-версии
OPT_LEVELS = O0 O1 O2 O3 Ofast

# Формируем списки целей
C_TARGETS = $(foreach opt,$(OPT_LEVELS),edge_detect_c_$(opt))
ASM_TARGET = edge_detect_asm

# Цели по умолчанию
.PHONY: all
all: c_targets $(ASM_TARGET)

.PHONY: c_targets
c_targets: $(C_TARGETS)

# Короткие имена
.PHONY: c
c: edge_detect_c_O2

.PHONY: asm
asm: $(ASM_TARGET)

# Очистка
.PHONY: clean
clean:
	rm -rf $(C_TARGETS) $(ASM_TARGET) $(OBJDIR)

# Создание каталога для объектных файлов
$(OBJDIR):
	mkdir -p $(OBJDIR)

# Сборка C-версий с разными оптимизациями
edge_detect_c_O0: $(OBJDIR)/main_c_O0.o $(OBJDIR)/filter_c_O0.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O1: $(OBJDIR)/main_c_O1.o $(OBJDIR)/filter_c_O1.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O2: $(OBJDIR)/main_c_O2.o $(OBJDIR)/filter_c_O2.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_O3: $(OBJDIR)/main_c_O3.o $(OBJDIR)/filter_c_O3.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

edge_detect_c_Ofast: $(OBJDIR)/main_c_Ofast.o $(OBJDIR)/filter_c_Ofast.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

# Сборка ассемблерной версии (без оптимизаций, ваш рукописный код)
$(ASM_TARGET): $(OBJDIR)/main_asm.o $(OBJDIR)/filter_asm.o
	$(LD) $(LDFLAGS) $(LIBPATH) $(PREOBJ) $^ $(POSTOBJ) -\( $(LIBS) -\) -o $@

# Компиляция main.c для C-версий с разными оптимизациями
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

# Компиляция filter_c.c для C-версий с разными оптимизациями
$(OBJDIR)/filter_c_O0.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O0 -c $< -o $@

$(OBJDIR)/filter_c_O1.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O1 -c $< -o $@

$(OBJDIR)/filter_c_O2.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O2 -c $< -o $@

$(OBJDIR)/filter_c_O3.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -O3 -c $< -o $@

$(OBJDIR)/filter_c_Ofast.o: $(C_FILTER) | $(OBJDIR)
	$(CC) -Ofast -c $< -o $@

# Компиляция main.c для ассемблерной версии (без оптимизаций)
$(OBJDIR)/main_asm.o: $(C_MAIN) | $(OBJDIR)
	$(CC) -O0 -DUSE_ASM -c $< -o $@

# Ассемблирование вашего рукописного кода на NASM
$(OBJDIR)/filter_asm.o: $(ASM_FILTER) | $(OBJDIR)
	$(AS) $(ASFLAGS) $< -o $@

# Справка по использованию
.PHONY: help
help:
	@echo "=== Сборка ==="
	@echo "make all        - собрать все версии (C с оптимизациями + ASM)"
	@echo "make c          - собрать C-версию с -O2 (аналог make edge_detect_c_O2)"
	@echo "make asm        - собрать ASM-версию (аналог make edge_detect_asm)"
	@echo "make c_targets  - собрать только C-версии"
	@echo ""
	@echo "=== Доступные цели ==="
	@echo "make edge_detect_c_O0    - C без оптимизаций"
	@echo "make edge_detect_c_O1    - C с -O1"
	@echo "make edge_detect_c_O2    - C с -O2 (рекомендуется)"
	@echo "make edge_detect_c_O3    - C с -O3"
	@echo "make edge_detect_c_Ofast - C с -Ofast (максимальная)"
	@echo "make edge_detect_asm     - ASM-версия"
	@echo ""
	@echo "=== Очистка ==="
	@echo "make clean      - удалить все собранные файлы"