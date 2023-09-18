`ifndef SVK_JTAG__SV
`define SVK_JTAG__SV

`ifndef SVK_JTAG_DATA_WIDTH
`define SVK_JTAG_DATA_WIDTH 1024
`endif

`ifndef SVK_JTAG_ADDR_WIDTH
`define SVK_JTAG_ADDR_WIDTH 128
`endif

// usage1
// svk_jtag jtag = svk_jtag::type_id::create("jtag");
// jtag.vif = xxx;
// jtag.trst_rst();
// jtag.tms_rst();
// 通过DAP访问系统寄存器
// jtag.write_SYS_reg(base_addr, addr, data);
// jtag.read_SYS_reg(base_addr, addr, data);

// usage2
// svk_jtag jtag = svk_jtag::type_id::create("jtag");
// jtag.vif = xxx;
// jtag.trst_rst();
// jtag.tms_rst();
// 通过DP访问系统寄存器(无AP)
// jtag.write_AP_reg(addr, data);
// jtag.read_AP_reg(addr, data);

class svk_jtag  extends uvm_object;
    `uvm_object_utils(svk_jtag)

    virtual svk_jtag_if vif;

    local svk_jtag me;

    bit [31:0] CSW_addr = 32'h0000_0D00;
    bit [31:0] TAR_addr = 32'h0000_0D04;
    bit [31:0] DRW_addr = 32'h0000_0D0C;
    bit [31:0] CSW_data = 32'h3000_0002;
    //bit [31:0] CSW_data = 32'h1000_0002;

    extern function new(string name="svk_jtag");
    extern task ir_scan(input  int                                width,
                        input  logic [`SVK_JTAG_DATA_WIDTH-1:0]   tdi,
                        output logic [`SVK_JTAG_ADDR_WIDTH-1:0]   tdo);

    extern task dr_scan(input  int                                width,
                        input  logic [`SVK_JTAG_DATA_WIDTH-1:0]   tdi,
                        output logic [`SVK_JTAG_ADDR_WIDTH-1:0]   tdo);

    extern task drive_idle();
    extern task tms_rst(int cycle_num=5);
    extern task trst_rst(int cycle_num=5);

    extern task read_DP_reg(input  logic [1:0]  addr,
                            output logic [31:0] data);

    extern task write_DP_reg(input logic [1:0]  addr,
                             input logic [31:0] data);

    extern task read_AP_reg(input  logic [31:0] addr,
                            output logic [31:0] data);

    extern task write_AP_reg(input logic [31:0] addr,
                             input logic [31:0] data);

    extern task read_SYS_reg(input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] ap_base_addr,
                             input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] addr,
                             output logic [`SVK_JTAG_DATA_WIDTH-1:0] data);

    extern task write_SYS_reg(input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] ap_base_addr,
                              input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] addr,
                              input  logic [`SVK_JTAG_DATA_WIDTH-1:0] data);

endclass

function svk_jtag::new(string name="svk_jtag");
    super.new(name);
endfunction


task svk_jtag::ir_scan(input  int                                width,
                       input  logic [`SVK_JTAG_DATA_WIDTH-1:0]   tdi,
                       output logic [`SVK_JTAG_ADDR_WIDTH-1:0]   tdo);
    logic tmp;

    tdo = 0;
    vif.drive_jtag(1, 0, tmp); // run-test/idle -> select DR-scan
    vif.drive_jtag(1, 0, tmp); // select DR-scan -> select IR-scan
    vif.drive_jtag(0, 0, tmp); // select IR-scan -> capture-IR
    vif.drive_jtag(0, 0, tmp); // capture-IR -> shift IR

    for(int i = 0; i < width-1; ++i) begin // shift IR
        vif.drive_jtag(0, tdi[i], tdo[i]); // 第一个tdo[0]不是有效数据
    end

    vif.drive_jtag(1, tdi[width-1], tdo[width-1]); // shift IR -> exit1-IR
    vif.drive_jtag(1, 0, tdo[width]); // exit1-IR->updata-IR  这个是最后一个有效数据
    vif.drive_jtag(0, 0, tmp); // updata-IR -> run-test/idle

endtask

task svk_jtag::dr_scan(input  int                                width,
                       input  logic [`SVK_JTAG_DATA_WIDTH-1:0]   tdi,
                       output logic [`SVK_JTAG_ADDR_WIDTH-1:0]   tdo);
    logic tmp;

    tdo = 0;
    vif.drive_jtag(1, 0, tmp); // run-test/idle -> select DR-scan
    vif.drive_jtag(0, 0, tmp); // select DR-scan -> capture-DR
    vif.drive_jtag(0, 0, tmp); // capture-DR -> shift DR

    for(int i = 0; i < width-1; ++i) begin // shift DR
        vif.drive_jtag(0, tdi[i], tdo[i]); // 第一个tdo[0]不是有效数据
    end

    vif.drive_jtag(1, tdi[width-1], tdo[width-1]); // shift DR -> exit1-DR
    vif.drive_jtag(1, 0, tdo[width]); // exit1-DR->updata-DR  这个是最后一个有效数据
    vif.drive_jtag(0, 0, tmp); // updata-DR -> run-test/idle

endtask

task svk_jtag::drive_idle();
    logic tmp;

    vif.drive_jtag(1, 0, tmp); // run-test/idle -> run-test/idle
endtask

task svk_jtag::tms_rst(int cycle_num=5);
    logic tmp;
    for(int i = 0; i < cycle_num; ++i)
        vif.drive_jtag(1, 0, tmp); // xxx -> Test-Logic-Reset

    vif.drive_jtag(0, 0, tmp); // Test-Logic-Reset -> run-test/idle
endtask


task svk_jtag::trst_rst(int cycle_num=5);
    vif.reset(cycle_num);
endtask




task svk_jtag::read_DP_reg(input  logic [1:0]  addr,
                           output logic [31:0] data);
    bit [34:0] tdi;
    bit [35:0] tdo;

    forever begin
        ir_scan(4, 'ha, tdo);   // select DPACC register
        tdi[34:3] = 'h0;
        tdi[2:1]  = addr;
        tdi[0]    = 1'b1;
        dr_scan(35, tdi, tdo);
        tdo >>= 1;
        if(tdo[2:0] != 1) break; // ACK = 'b001 -> WAIT
    end
    data = tdo[34:3];
endtask

task svk_jtag::write_DP_reg(input logic [1:0]  addr,
                            input logic [31:0] data);
    bit [34:0] tdi;
    bit [35:0] tdo;

    forever begin
        ir_scan(4, 'ha, tdo);   // select DPACC register
        tdi[34:3] = data;
        tdi[2:1]  = addr;
        tdi[0]    = 1'b0;
        dr_scan(35, tdi, tdo);
        tdo >>= 1;
        if(tdo[2:0] != 1) break; // ACK = 'b001 -> WAIT
    end

endtask


task svk_jtag::read_AP_reg(input  logic [31:0] addr,
                           output logic [31:0] data);
    bit [34:0] tdi;
    bit [35:0] tdo;

    write_DP_reg(2'b10, {addr[31:4], 4'b0}); // write DP.SELECT

    forever begin
        ir_scan(4, 'hb, tdo);   // select DPACC register
        tdi[34:3] = 'h0;
        tdi[2:1]  = addr[3:2];
        tdi[0]    = 1'b1;
        dr_scan(35, tdi, tdo);
        tdo >>= 1;
        if(tdo[2:0] != 1) break; // ACK = 'b001 -> WAIT
    end
    data = tdo[34:3];
endtask

task svk_jtag::write_AP_reg(input logic [31:0] addr,
                            input logic [31:0] data);
    bit [34:0] tdi;
    bit [35:0] tdo;

    write_DP_reg(2'b10, {addr[31:4], 4'b0}); // write DP.SELECT

    forever begin
        ir_scan(4, 'hb, tdo);   // select DPACC register
        tdi[34:3] = data;
        tdi[2:1]  = addr[3:2];
        tdi[0]    = 1'b0;
        dr_scan(35, tdi, tdo);
        tdo >>= 1;
        if(tdo[2:0] != 1) break; // ACK = 'b001 -> WAIT
    end

endtask


task svk_jtag::write_SYS_reg(input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] ap_base_addr,
                             input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] addr,
                             input  logic [`SVK_JTAG_DATA_WIDTH-1:0] data);
    bit [31:0] CSW_addr_tmp;
    bit [31:0] TAR_addr_tmp;
    bit [31:0] DRW_addr_tmp;

    CSW_addr_tmp = ap_base_addr + CSW_addr;
    TAR_addr_tmp = ap_base_addr + TAR_addr;
    DRW_addr_tmp = ap_base_addr + DRW_addr;

    // write AP.CSW
    write_AP_reg(CSW_addr_tmp, CSW_data);

    // write AP.TAR
    write_AP_reg(TAR_addr_tmp, addr);

    // write AP.DRW
    write_AP_reg(DRW_addr_tmp, data);

endtask

task svk_jtag::read_SYS_reg(input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] ap_base_addr,
                            input  logic [`SVK_JTAG_ADDR_WIDTH-1:0] addr,
                            output logic [`SVK_JTAG_DATA_WIDTH-1:0] data);

    bit [31:0] CSW_addr_tmp;
    bit [31:0] TAR_addr_tmp;
    bit [31:0] DRW_addr_tmp;

    CSW_addr_tmp = ap_base_addr + CSW_addr;
    TAR_addr_tmp = ap_base_addr + TAR_addr;
    DRW_addr_tmp = ap_base_addr + DRW_addr;

    // write AP.CSW
    write_AP_reg(CSW_addr_tmp, CSW_data);

    // write AP.TAR
    write_AP_reg(TAR_addr_tmp, addr);

    // read AP.DRW
    read_AP_reg(DRW_addr_tmp, data);

    // read DP.RBUFF
    read_DP_reg(2'b11, data);

endtask

`endif