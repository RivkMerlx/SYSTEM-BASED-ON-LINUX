#!/bin/bash

# ISO Creation Script for SYSTEM-BASED-ON-LINUX
# This script creates a bootable ISO image from the compiled system files

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ISO Creation Script ===${NC}"
echo ""

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed.${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Checking required tools...${NC}"
REQUIRED_TOOLS=("mkisofs" "grub-mkrescue" "xorriso")
MISSING_TOOLS=0

for tool in "${REQUIRED_TOOLS[@]}"; do
    if check_tool "$tool"; then
        echo -e "${GREEN}✓ $tool found${NC}"
    else
        echo -e "${YELLOW}⚠ $tool not found (optional: $tool)${NC}"
        ((MISSING_TOOLS++))
    fi
done

if [ $MISSING_TOOLS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Install tools with:${NC}"
    echo "  Ubuntu/Debian: sudo apt-get install xorriso grub-pc-bin mtools"
    echo "  RHEL/CentOS:   sudo yum install xorriso grub2-tools"
    echo ""
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Define paths
ISO_OUTPUT="$PROJECT_DIR/SYSTEM-BASED-ON-LINUX.iso"
ISO_TEMP_DIR="$PROJECT_DIR/.iso_temp"
BOOT_DIR="$ISO_TEMP_DIR/boot"
GRUB_DIR="$BOOT_DIR/grub"

echo ""
echo -e "${YELLOW}Project directory: $PROJECT_DIR${NC}"
echo -e "${YELLOW}ISO output: $ISO_OUTPUT${NC}"
echo ""

# Create temporary directory structure
echo -e "${YELLOW}Setting up ISO directory structure...${NC}"
mkdir -p "$GRUB_DIR"
mkdir -p "$ISO_TEMP_DIR/system"

# Copy compiled files to ISO temp directory
echo -e "${YELLOW}Copying system files...${NC}"
cp "$SCRIPT_DIR"/*.o "$ISO_TEMP_DIR/system/" 2>/dev/null || true
cp "$SCRIPT_DIR"/*.pas "$ISO_TEMP_DIR/system/" 2>/dev/null || true
cp "$SCRIPT_DIR"/boot.asm "$ISO_TEMP_DIR/system/" 2>/dev/null || true
cp "$SCRIPT_DIR"/linker.ld "$ISO_TEMP_DIR/system/" 2>/dev/null || true

# Create GRUB configuration
echo -e "${YELLOW}Creating GRUB configuration...${NC}"
cat > "$GRUB_DIR/grub.cfg" << 'EOF'
menuentry 'SYSTEM-BASED-ON-LINUX' {
    multiboot /boot/kernel
}

set timeout=5
set default=0
EOF

# Copy kernel to boot directory if it exists
if [ -f "$SCRIPT_DIR/i386-freebsd8-ppc386" ]; then
    echo -e "${YELLOW}Copying kernel...${NC}"
    cp "$SCRIPT_DIR/i386-freebsd8-ppc386" "$BOOT_DIR/kernel"
else
    echo -e "${YELLOW}⚠ Kernel file not found, ISO will not be bootable${NC}"
fi

# Create the ISO using grub-mkrescue (preferred method)
echo ""
echo -e "${BLUE}Creating ISO image...${NC}"

if command -v grub-mkrescue &> /dev/null; then
    echo -e "${YELLOW}Using grub-mkrescue (GRUB method)...${NC}"
    grub-mkrescue -o "$ISO_OUTPUT" "$ISO_TEMP_DIR" 2>&1 || {
        echo -e "${YELLOW}grub-mkrescue failed, trying xorriso...${NC}"
        xorriso -as mkisofs -R -J -c boot.cat -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table -o "$ISO_OUTPUT" "$ISO_TEMP_DIR" 2>&1 || {
            echo -e "${RED}ISO creation failed.${NC}"
            exit 1
        }
    }
elif command -v xorriso &> /dev/null; then
    echo -e "${YELLOW}Using xorriso method...${NC}"
    xorriso -as mkisofs -R -J -c boot.cat -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table -o "$ISO_OUTPUT" "$ISO_TEMP_DIR" 2>&1
elif command -v mkisofs &> /dev/null; then
    echo -e "${YELLOW}Using mkisofs method...${NC}"
    mkisofs -R -J -c boot.cat -b boot/grub/i386-pc/eltorito.img -no-emul-boot -o "$ISO_OUTPUT" "$ISO_TEMP_DIR" 2>&1
else
    echo -e "${RED}Error: No ISO creation tool found.${NC}"
    exit 1
fi

# Check if ISO was created successfully
if [ -f "$ISO_OUTPUT" ]; then
    ISO_SIZE=$(du -h "$ISO_OUTPUT" | cut -f1)
    echo -e "${GREEN}✓ ISO created successfully!${NC}"
    echo -e "${GREEN}Location: $ISO_OUTPUT${NC}"
    echo -e "${GREEN}Size: $ISO_SIZE${NC}"
    echo ""
    echo -e "${BLUE}ISO Details:${NC}"
    file "$ISO_OUTPUT"
    echo ""
else
    echo -e "${RED}✗ Failed to create ISO.${NC}"
    exit 1
fi

# Cleanup temporary directory
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$ISO_TEMP_DIR"

echo ""
echo -e "${GREEN}=== ISO Creation Complete ===${NC}"
echo ""
echo -e "${BLUE}To test the ISO:${NC}"
echo "  - QEMU: qemu-system-i386 -cdrom $ISO_OUTPUT"
echo "  - VirtualBox: Create new VM and attach ISO"
echo "  - Burn to USB: sudo dd if=$ISO_OUTPUT of=/dev/sdX bs=4M && sync"
echo "  - Mount: sudo mount -o loop $ISO_OUTPUT /mnt"
echo ""
