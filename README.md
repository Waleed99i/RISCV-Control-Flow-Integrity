# RISC-V Control-Flow Integrity 

[![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![LFX Mentorship](https://img.shields.io/badge/LFX-Mentorship-0A5FFF.svg)](https://lfx.linuxfoundation.org/tools/mentorship/)
[![RISC-V](https://img.shields.io/badge/Architecture-RISC--V-red.svg)](https://riscv.org/)
[![Security](https://img.shields.io/badge/Focus-Control--Flow%20Integrity-green.svg)](https://github.com/riscv/riscv-cfi)
[![RTL](https://img.shields.io/badge/Design-RTL-orange.svg)](https://en.wikipedia.org/wiki/Register-transfer_level)
[![FSM](https://img.shields.io/badge/Design-Finite%20State%20Machine-purple.svg)](https://en.wikipedia.org/wiki/Finite-state_machine)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Target Core: Sargantana](https://img.shields.io/badge/Target-Sargantana_Core-lightgrey.svg)](https://github.com/bsc-loca/sargantana)

---

This repository contains my **SystemVerilog** solution for the **Linux Foundation (LFX) Mentorship** coding challenge:

> **Implementation of the RISC-V ISA Extensions for Control-Flow Integrity (CFI)**

The challenge models a simplified hardware implementation of the **Landing Pad** mechanism proposed in the RISC-V Control-Flow Integrity (CFI) ISA extensions.

---

## Challenge Overview

A 32-bit packet is received every clock cycle.

| Bits | Description |
|------|-------------|
| **[31:24]** | Command |
| **[23:0]** | Data |

Supported commands:

| Command | Value |
|---------|------:|
| SET | `0x01` |
| JUMP | `0x02` |
| LPAD | `0x03` |

---

## FSM States

- **IDLE**
  - Stores the incoming label on `SET`
  - Moves to `CHECK` on `JUMP`

- **CHECK**
  - Waits for an `LPAD`
  - Compares the received label with the stored label
  - Returns to `IDLE` if they match
  - Otherwise transitions to `ERROR`

- **ERROR**
  - Terminal state
  - Remains in `ERROR` permanently

---


## Reference

- **RISC-V Control-Flow Integrity (CFI) Extension**
- **Sargantana RISC-V Core**

---

## License

Released under the **MIT License**.