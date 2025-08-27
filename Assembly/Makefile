ASM_SRC = src/server.s
BIN_DIR = bin
BIN = $(BIN_DIR)/server

ASM = as
ASM_FLAGS =

LD = ld
LD_FLAGS =

.PHONY: build run clean

build: $(BIN)

$(BIN): $(BIN_DIR)/server.o | $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $(BIN) $(BIN_DIR)/server.o

$(BIN_DIR)/server.o: $(ASM_SRC) | $(BIN_DIR)
	$(ASM) $(ASM_FLAGS) -o $(BIN_DIR)/server.o $(ASM_SRC)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run: build
	./$(BIN)

clean:
	rm -rf $(BIN_DIR)
