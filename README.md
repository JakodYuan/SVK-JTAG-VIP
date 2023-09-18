# SVK-JTAG-VIP


## usage1

1. instantiate and connect interface
2. instantiate svk_jtag and configure virutal interface
3. call write_SYS_reg()/read_SYS_reg() access system register
```sv
svk_jtag jtag = svk_jtag::type_id::create("jtag");
jtag.vif = svk_jtag_if;
jtag.trst_rst();
jtag.tms_rst();
// access system register via DAP
jtag.write_SYS_reg(base_addr, addr, data);
jtag.read_SYS_reg(base_addr, addr, data);
```

## usage2

1. instantiate and connect interface
2. instantiate svk_jtag and configure virutal interface
3. call write_AP_reg()/read_AP_reg() access system register，used when system not have AP
```sv
svk_jtag jtag = svk_jtag::type_id::create("jtag");
jtag.vif = svk_jtag_if;
jtag.trst_rst();
jtag.tms_rst();
// access system register via DP
jtag.write_AP_reg(addr, data);
jtag.read_AP_reg(addr, data);
```
