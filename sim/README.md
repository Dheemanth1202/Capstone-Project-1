## Simulation Directory

Place compiled simulation binaries and log files here.

### Recommended flow (Icarus Verilog)

```bash
# From the Wallace_Multiplier/ root:

iverilog -o sim/wallace_tb \
    tb/wallace_tb.v \
    rtl/wallace_top.v \
    rtl/partial_product.v \
    rtl/full_adder.v \
    rtl/half_adder.v

vvp sim/wallace_tb | tee sim/sim_log.txt
```

Generated files after simulation:
- `sim/wallace_tb`      – compiled simulation binary
- `sim/sim_log.txt`     – console output
- `sim/wallace_wave.vcd`– waveform dump (open with GTKWave)
