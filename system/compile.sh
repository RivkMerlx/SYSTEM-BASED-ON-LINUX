#!/bin/bash

# Pascal Compilation Script for SYSTEM-BASED-ON-LINUX
# This script compiles all .pas files in the system folder

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if fpc (Free Pascal Compiler) is installed
if ! command -v fpc &> /dev/null; then
    echo -e "${RED}Error: Free Pascal Compiler (fpc) is not installed.${NC}"
    echo "Install it with: sudo apt-get install fp-compiler (on Ubuntu/Debian)"
    exit 1
fi

echo -e "${YELLOW}=== Pascal Compilation Script ===${NC}"
echo "Compiler: $(fpc -v)"
echo ""

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Find all .pas files
PAS_FILES=(*.pas)

if [ ${#PAS_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No .pas files found in $SCRIPT_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Found ${#PAS_FILES[@]} Pascal file(s) to compile:${NC}"
for file in "${PAS_FILES[@]}"; do
    echo "  - $file"
done
echo ""

# Compile each .pas file
COMPILED=0
FAILED=0

for pas_file in "${PAS_FILES[@]}"; do
    output_file="${pas_file%.pas}"
    
    echo -e "${YELLOW}Compiling: $pas_file${NC}"
    
    if fpc "$pas_file" -o"$output_file" 2>&1; then
        echo -e "${GREEN}✓ Successfully compiled: $output_file${NC}"
        ((COMPILED++))
    else
        echo -e "${RED}✗ Failed to compile: $pas_file${NC}"
        ((FAILED++))
    fi
    echo ""
done

# Summary
echo -e "${YELLOW}=== Compilation Summary ===${NC}"
echo -e "Compiled: ${GREEN}$COMPILED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All files compiled successfully!${NC}"
    exit 0
else
    echo -e "${RED}Some files failed to compile.${NC}"
    exit 1
fi
