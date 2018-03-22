# RustOS_toy_project

## Requirements

- Rust compiler
- Linux
- QEMU
- gdb may be useful

## Short description and a demo video

http://martyniak.me/recent_projects.html

## How to run

Ready-to-use ISO is inside ```build/``` directory
```bash
qemu-system-x86_64 -cdrom os-x86_64.iso
```

## How to compile

See the Makefile
```bash
make iso
```

