# JTAG-VIP


## usage1

```sv
svk_jtag jtag = svk_jtag::type_id::create("jtag");
jtag.vif = xxx;
jtag.trst_rst();
jtag.tms_rst();
// 通过DAP访问系统寄存器
jtag.write_SYS_reg(base_addr, addr, data);
jtag.read_SYS_reg(base_addr, addr, data);
```

## usage2

```sv
svk_jtag jtag = svk_jtag::type_id::create("jtag");
jtag.vif = xxx;
jtag.trst_rst();
jtag.tms_rst();
// 通过DP访问系统寄存器(无AP)
jtag.write_AP_reg(addr, data);
jtag.read_AP_reg(addr, data);
```
