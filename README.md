# Wallace Tree Multiplier (8×8)

A fully structural, gate-level 8×8 unsigned Wallace Tree multiplier written in
Verilog-2001.

## Directory Structure

```
Wallace_Multiplier/
│
├── rtl/
│   ├── wallace_top.v       # Top-level Wallace Tree multiplier
│   ├── partial_product.v   # 8×8 partial-product generator
│   ├── full_adder.v        # 1-bit full adder  (structural)
│   └── half_adder.v        # 1-bit half adder  (structural)
│
├── tb/
│   └── wallace_tb.v        # Self-checking testbench
│
├── sim/                    # Simulation binaries & waveform dumps
│   └── README.md
│
└── reports/                # Synthesis & timing reports
    └── README.md
```

## Architecture

```
A[7:0] ──┐
          ├──► Partial Products (8 rows × 8 bits)
B[7:0] ──┘
              │
              ▼
         Stage 1: FA/HA compressors  (8 rows → ~5 rows per column)
              │
              ▼
         Stage 2: FA/HA compressors  (→ ~4 rows)
              │
              ▼
         Stage 3: FA/HA compressors  (→ 3 rows)
              │
              ▼
         Stage 4: FA/HA compressors  (→ 2 rows: sum_vec + carry_vec)
              │
              ▼
         16-bit Carry-Propagate Adder
              │
              ▼
         product[15:0]
```

## Quick Start

### Icarus Verilog

```bash
# Compile
iverilog -o sim/wallace_tb \
    tb/wallace_tb.v \
    rtl/wallace_top.v \
    rtl/partial_product.v \
    rtl/full_adder.v \
    rtl/half_adder.v

# Run simulation
vvp sim/wallace_tb | tee sim/sim_log.txt

# View waveforms (optional)
gtkwave sim/wallace_wave.vcd
```

### ModelSim / Questa

```tcl
vlib work
vmap work work
vlog rtl/half_adder.v rtl/full_adder.v rtl/partial_product.v rtl/wallace_top.v
vlog tb/wallace_tb.v
vsim -novopt wallace_tb
run -all
```

## Test Coverage

| Test Suite            | Vectors |
|-----------------------|---------|
| Directed corner cases |      18 |
| Exhaustive sweep      |  65 536 |
| Pseudo-random         |     500 |
| **Total**             | **66 054** |

## Module Summary

| Module             | Description                                   |
|--------------------|-----------------------------------------------|
| `half_adder`       | 1-bit HA: sum = A⊕B, cout = A·B              |
| `full_adder`       | 1-bit FA: sum = A⊕B⊕Cin, cout = majority     |
| `partial_product`  | Generates pp[0..7] = A & {8{B[i]}}           |
| `wallace_top`      | 4-stage Wallace tree + final CPA adder        |
| `wallace_tb`       | Self-checking testbench with pass/fail report |
