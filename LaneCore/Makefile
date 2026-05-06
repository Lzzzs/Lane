FRAMEWORKS_DIR := /Library/Developer/CommandLineTools/Library/Developer/Frameworks

SWIFT_FLAGS := -Xswiftc -F -Xswiftc $(FRAMEWORKS_DIR)
LINK_FLAGS  := -Xlinker -rpath -Xlinker $(FRAMEWORKS_DIR)
COMMON      := $(SWIFT_FLAGS) $(LINK_FLAGS)

.PHONY: build test clean

build:
	swift build $(COMMON)

test:
	swift test $(COMMON)

clean:
	swift package clean
	rm -rf .build
