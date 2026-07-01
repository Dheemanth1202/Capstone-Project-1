## Reports Directory

Place synthesis and timing reports here.

### Typical report files

| File | Tool | Contents |
|------|------|----------|
| `synthesis_area.rpt`  | Yosys / Vivado | Cell count, LUT usage |
| `timing_slack.rpt`    | OpenSTA / Vivado | Critical path, slack |
| `power.rpt`           | Vivado / DC     | Dynamic & static power |

### Example Yosys synthesis command

```bash
# From Wallace_Multiplier/ root:
yosys -p "
  read_verilog rtl/half_adder.v
  read_verilog rtl/full_adder.v
  read_verilog rtl/partial_product.v
  read_verilog rtl/wallace_top.v
  synth -top wallace_top
  stat
  write_verilog reports/wallace_synth.v
" 2>&1 | tee reports/synthesis_area.rpt
```
