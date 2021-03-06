SOURCE=source
BUILD=build
INCLUDE=include
DISK_SECTOR_COUNT=$(shell echo $$((32 * 1024)))
PART_SECTOR_COUNT=$(shell echo $$((16 * 1024)))
PART_MKDOSFS_SIZE=$(shell echo $$(($(PART_SECTOR_COUNT) / 2)))
PART_OFFSET_SECTORS=2048

nox: directories $(BUILD)/nox-disk.img

$(BUILD)/nox-disk.img: $(BUILD)/nox-fs.img $(BUILD)/mbr.bin
	
	# Empty file for the disk image
	dd if=/dev/zero of=$@ count=$(DISK_SECTOR_COUNT)
	
	# Partition it with a single 8MiB FAT12 Partition
	@echo "o\nn\np\n1\n$(PART_OFFSET_SECTORS)\n+$(PART_SECTOR_COUNT)\na\n1\nt\n1\nw" | fdisk $@
	
	# Blit in a FAT12 file system
	dd if=$(BUILD)/nox-fs.img of=$@ seek=$(PART_OFFSET_SECTORS) count=$(PART_SECTOR_COUNT) conv=notrunc

	# Blit in the MBR
	dd if=$(BUILD)/mbr.bin of=$@ bs=1 count=446 conv=notrunc

$(BUILD)/nox-fs.img: 
	mkdosfs -R $(PART_OFFSET_SECTORS) -C -n "NOX" -F 12 $@ $(PART_MKDOSFS_SIZE)

$(BUILD)/mbr.bin: $(SOURCE)/mbr.asm
	nasm $< -o $@ -f bin

$(BUILD)/boot.sys: $(SOURCE)/kloader.asm
	nasm $< -o $@ -f bin

.PHONY: clean directories
clean:
	rm -r $(BUILD)

directories:
	@mkdir -p $(BUILD)
