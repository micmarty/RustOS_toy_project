#	SCIEZKI I NAZWY DO PLIKOW
architektura ?= x86_64
kernel := build/kernel-$(architektura).bin
iso := build/os-$(architektura).iso

skrypt_linkera := src/arch/$(architektura)/linker.ld
grub_cfg := src/arch/$(architektura)/grub.cfg
asm_pliki_zrodlowe := $(wildcard src/arch/$(architektura)/*.asm)
#	przeprowadza kompilacje asm do .o zamieniając odpowiednio nazwy rozszerzen
asm_pliki_po_kompilacji := $(patsubst src/arch/$(architektura)/%.asm, \
	build/arch/$(architektura)/%.o, $(asm_pliki_zrodlowe))

#dodane przy instalacji rusta
target ?= $(architektura)-unknown-linux-gnu
rust_os := target/$(target)/debug/libchrust_os.a
#-------------------------------------------------------------------------------
#	OPCJE MAKE
.PHONY: all clean run iso

#	buduje sam kernel
all: $(kernel)

#	usuwa wygenerowane przez siebie pliki
clean:
	@rm -r build

#	odpala stworzone iso w emulatorze. -s -> nasluchuje polaczenia gdb
run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso) -s

debug: $(iso)
	@qemu-system-x86_64 -cdrom $(iso) -s -S #freeze na starcie

gdb:
    @rust-os-gdb/bin/rust-gdb "build/kernel-x86_64.bin" -ex "target remote :1234"

#	generuje obraz iso
iso: $(iso)

#	aby zbudowac obraz, musimy skompilowac najpierw kernel i zaladowac/przeniesc
#	grub_cfg w odpowienie miejsce wg standardu GRUBa
#	usuwa pliki tymczasowe
$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles
	@rm -r build/isofiles

#	budowa jadra: linkuje multiboota jako naglowek i inne asmowe z kernelem z flaga --nmagic
$(kernel): cargo $(rust_os) $(asm_pliki_po_kompilacji) $(skrypt_linkera)
	@ld -n --gc-sections -T $(skrypt_linkera) -o $(kernel) $(asm_pliki_po_kompilacji) $(rust_os)

cargo:
	@cargo build --target $(target)

#	kompilacja asm do formatu elf64 wywolana z linii 10
#	mkdir jest potrzebny zeby miec gdzie wsadzic pliki o
build/arch/$(architektura)/%.o: src/arch/$(architektura)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
