SRC := $(wildcard src/*.s src/*.c)
BIN_DIR := bin
BIN := $(BIN_DIR)/server

ASM := as
ASM_FLAGS :=

CC := gcc
CC_FLAGS := -c

LD := gcc
LD_FLAGS := -nostartfiles -no-pie

OBJ := $(patsubst src/%, $(BIN_DIR)/%, $(SRC:.c=.o))
OBJ := $(OBJ:.s=.o)

.PHONY: build run clean

build: $(BIN)

$(BIN): $(OBJ) | $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $(BIN) $(OBJ)

$(BIN_DIR)/%.o: src/%.c | $(BIN_DIR)
	$(CC) $(CC_FLAGS) -o $@ $<

$(BIN_DIR)/%.o: src/%.s | $(BIN_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run: build
	./$(BIN)

clean:
	rm -rf $(BIN_DIR)
