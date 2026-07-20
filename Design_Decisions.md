# Design Decisions

## Overview

This document explains the key architectural and implementation decisions made while developing the Control-Flow Integrity (CFI) Finite State Machine (FSM) for the Linux Foundation (LFX) Mentorship Coding Challenge.

The objective was not only to satisfy the functional requirements of the challenge but also to produce a clean, synthesizable, and easily extensible RTL implementation that resembles real hardware design practices.

---

# 1. Moore FSM Architecture

The FSM was implemented as a **Moore finite state machine**, where the current state is stored in a sequential register and the next state is computed using combinational logic.

### Rationale

- Separates sequential and combinational logic.
- Improves readability and maintainability.
- Matches common RTL design practices used in processor control logic.
- Easily synthesizable on FPGA and ASIC flows.

---

# 2. Three-State Design

The FSM contains only three states:

- **IDLE**
- **CHECK**
- **ERROR**

### Rationale

The coding challenge explicitly specifies three states. Each state corresponds to a distinct stage of the simplified CFI verification process.

| State | Purpose |
|--------|----------|
| IDLE | Accept incoming commands and program the secure label. |
| CHECK | Verify the landing pad label. |
| ERROR | Permanently indicate a control-flow integrity violation. |

This minimal state machine captures the essential behavior of a hardware-assisted CFI mechanism while remaining simple and easy to verify.

---

# 3. Label Register Update Policy

The internal label register is updated **only when a SET command is received while the FSM is in the IDLE state.**

```systemverilog
if (state == IDLE && cmd == SET)
    label <= data;
```

### Rationale

Although the specification states that the label should be stored upon receiving a SET command in the IDLE state, updating the label on every cycle while remaining in IDLE would overwrite previously stored secure labels with unrelated packet data.

Restricting updates to explicit SET commands ensures that:

- Only authorized packets modify the secure label.
- Subsequent JUMP and LPAD commands cannot accidentally overwrite stored information.
- The stored label remains stable throughout the verification process.

---

# 4. Sticky ERROR State

Once the FSM enters the ERROR state, it remains there indefinitely.

### Rationale

A control-flow integrity violation represents a critical security event.

Allowing the FSM to leave the ERROR state without a reset could permit execution to continue after an attack has already been detected.

Implementing a sticky ERROR state reflects common hardware security practices, where fault conditions require explicit recovery mechanisms.

---

# 5. Command Decoding

The incoming packet is divided into two fields.

| Bits | Description |
|------|-------------|
| [31:24] | Command |
| [23:0] | Data |

Three command values are recognized:

| Command | Encoding |
|----------|----------|
| SET | 0x01 |
| JUMP | 0x02 |
| LPAD | 0x03 |

### Rationale

Separating command and data fields simplifies decoding and closely resembles packet formats commonly used in hardware interfaces.

---

# 6. Sequential and Combinational Separation

The implementation separates state storage from next-state logic.

Sequential Logic:

- State register
- Label register

Combinational Logic:

- Command decoding
- Next-state computation

### Rationale

This separation

- avoids unintended latches,
- simplifies debugging,
- follows standard RTL coding guidelines,
- improves synthesis results.

---

# 7. Security-Oriented Behavior

The FSM intentionally performs only a single comparison inside the CHECK state.

```
Received Label == Stored Label ?
```

If the comparison succeeds:

```
CHECK → IDLE
```

Otherwise:

```
CHECK → ERROR
```

### Rationale

This directly models the simplified landing pad verification described in the coding challenge and mirrors the concept of hardware-assisted landing pad validation used in the RISC-V CFI ISA extension.


---

# 8. Coding Style

The implementation follows common SystemVerilog RTL design practices.

Design choices include:

- `logic` data types
- `typedef enum` for state encoding
- `always_ff` for sequential logic
- `always_comb` for combinational logic
- Named local parameters for command encoding

### Rationale

These constructs improve readability, reduce coding errors, and align with IEEE SystemVerilog recommendations.

---

# Conclusion

The implementation prioritizes correctness, readability, synthesizability, and extensibility. While intentionally simplified for the coding challenge, the architectural decisions closely follow standard RTL design practices and provide a solid foundation for future integration into a complete RISC-V processor supporting the Control-Flow Integrity ISA extensions.