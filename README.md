# RustOS_toy_project

Disclaimer: I can't look at that crappy code anymore, hence here it is - TODO list:
- [ ] Rewrite using english names (polish was required by my lecturer LOL)
- [ ] Use Rust more extensively, try to avoid `unsafe` blocks
- [ ] Write instruction on how to reproduce it from scratch

## Requirements

- Rust compiler
- Linux
- QEMU
- gdb may be useful

## Short description and a demo video

http://martyniak.tech/recent_projects.html

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

