/***********************************************************
 *  Copyright (C) 2023 by JakodYuan (JakodYuan@outlook.com).
 *  All right reserved.
************************************************************/
`ifndef SVK_JTAG_IF__SV
`define SVK_JTAG_IF__SV

interface svk_jtag_if();

    logic trstn;
    logic tck;
    logic tms;
    logic tdi;
    logic tdo;

    clocking mst_cb@(posedge tck);
        default input #0.1ns output #0.1ns;

        output   trstn;
        output   tck;
        output   tms;
        output   tdi;
        input    tdo;
    endclocking

    task reset(int cycle_num=5);
        mst_cb.trstn <= 0;
        mst_cb.tms   <= 0;
        mst_cb.tdi   <= 0;
        for(int i=0; i<cycle_num; ++i)
            @(mst_cb);
        
        mst_cb.trstn <= 1;
        @(mst_cb);
    endtask

    task drive_jtag(logic tms_t, logic tdi_t, output logic tdo_t);
        mst_cb.tms <= tms_t;
        mst_cb.tdi <= tdi_t;
        tdo_t      <= mst_cb.tdo;
        @(mst_cb);
    endtask

    initial begin
        trstn = 0;
        tdi   = 0;
        tms   = 1;
    end

endinterface

typedef virtual svk_jtag_if svk_jtag_vif;

`endif
