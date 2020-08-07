`timescale 1 ns / 1 ns

module sram_tb;
    localparam CLK_PERIOD = 13.333;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("sram.vcd");
            $dumpvars(5,sram_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #100000
        pass = 0;
        $display("TIMEOUT\nFAIL");
        $finish();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    wire [31:0] retVal = sys_inst.cpu.picorv32_core.dbg_reg_x10;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("\nTRAP,  return %08x;", retVal);
            if (retVal == 32'h00c0ffee && pass) begin
                $display("PASS");
                $finish;
            end else begin
                $display("FAIL");
                $stop;
            end
        end
        // $fflush();
    end

    wire       flash_csb;
    wire       flash_clk;
    wire [3:0] flash_dz;

    `define DEBUGREGS
    system #(
        .SYSTEM_HEX_PATH("memio32.hex")
    ) sys_inst (
        .clk        (mem_clk),
        .reset      (reset),
        .trap       (trap),

        .flash_csb  (flash_csb),
        .flash_clk  (flash_clk),
        .flash_dz   (flash_dz)
    );

    // --------------------------------------------------------------
    //  Simulated QSPI flash chip
    // --------------------------------------------------------------
    spiflash #() spiMemChip (
        .csb(flash_csb),
        .clk(flash_clk),
        .io0(flash_dz[0]), // COPI
        .io1(flash_dz[1]), // CIPO
        .io2(flash_dz[2]),
        .io3(flash_dz[3])
    );

    // --------------------------------------------------------------
    //  Pass / fail logic
    // --------------------------------------------------------------
    // intercept flash data on CPU memory bus and verify it
    reg [31:0] memTestData [0:1024];
    reg [31:0] memTestWord;
    initial begin
        $readmemh("flashdata32.hex", memTestData);
    end

    wire [31:0] cfgreg_do = sys_inst.memio_inst.mio.cfgreg_do;
    wire [23:0] flash_addr = sys_inst.memio_inst.mem_flash_addr;

    always @(posedge mem_clk) begin
        if (|sys_inst.memio_inst.mio.cfgreg_we && cfgreg_do[31]) begin
            #1
            $display("\n\nFlash Config: %08x", cfgreg_do);
        end
        if (sys_inst.memio_inst.mem_ready && flash_addr < 24'hFFFFFC) begin
            memTestWord = memTestData[flash_addr / 4];
            $write("%8x ", sys_inst.cpu.mem_rdata);
            if (memTestWord !== sys_inst.cpu.mem_rdata) begin
                $error(
                    "\nFlash Read: addr %x read %x should be %x",
                    flash_addr,
                    sys_inst.cpu.mem_rdata,
                    memTestWord
                );
                pass = 0;
            end
        end
    end


endmodule
