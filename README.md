# SVK-JTAG-VIP


## usage1

1. 例化interface和连接interface
2. 例化svk_jtag并设置virtual interface
3. 调用write_SYS_reg()/read_SYS_reg()访问系统寄存器
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

1. 例化interface和连接interface
2. 例化svk_jtag并设置virtual interface
3. 调用write_AP_reg()/read_AP_reg()访问寄存器，再系统只有DP无AP的情况下使用
```sv
svk_jtag jtag = svk_jtag::type_id::create("jtag");
jtag.vif = xxx;
jtag.trst_rst();
jtag.tms_rst();
// 通过DP访问系统寄存器(无AP)
jtag.write_AP_reg(addr, data);
jtag.read_AP_reg(addr, data);
```
