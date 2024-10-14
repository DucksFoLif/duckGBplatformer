# Makefile for building a Game Boy ROM

# Define the source file
SOURCE_FILE := duck.asm

# Define the object file
OBJECT_FILE := duck.o

# Define the ROM file
ROM_FILE := duckgame.gb

# Assemble the source code
$(OBJECT_FILE): $(SOURCE_FILE)
	rgbasm -o $(OBJECT_FILE) $(SOURCE_FILE)

# Link the object file
$(ROM_FILE): $(OBJECT_FILE)
	rgblink -o $(ROM_FILE) $(OBJECT_FILE)

# Fix the ROM
.PHONY: fix
fix: $(ROM_FILE)
	rgbfix -v -p 0xFF $(ROM_FILE)

# Clean up intermediate files
.PHONY: clean
clean:
	rm -f $(OBJECT_FILE)

# Clean up all generated files
.PHONY: distclean
distclean: clean
	rm -f $(ROM_FILE)
