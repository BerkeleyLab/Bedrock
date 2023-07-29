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
        $finish(0);
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    wire [31:0] retVal = sys_inst.cpu.picorv32_core.dbg_reg_x10;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("TRAP,  return %08x;", retVal);
            if (retVal == 32'h04030201) begin
                $display("PASS");
                $finish;
            end else begin
                $display("FAIL");
                $stop(0);
            end
        end
        // $fflush();
    end

    wire [31:0] gpio_z = 32'h0;
    wire [ 7:0] ram_data_z;
    wire [23:0] ram_address;
    wire        ram_nce;
    wire        ram_noe;
    wire        ram_nwe;

    `define DEBUGREGS
    system #(
        .SYSTEM_HEX_PATH("sram32.hex")
    ) sys_inst (
        .clk        (mem_clk),
        .reset      (reset),
        .trap       (trap),

        .gpio_z     (gpio_z),
        .uart_tx0   (),
        .uart_rx0   (1'b1),


        // SRAM Hardware interface
        .ram_data_z  (ram_data_z),
        .ram_address (ram_address),
        .ram_nce     (ram_nce),
        .ram_noe     (ram_noe),
        .ram_nwe     (ram_nwe)
    );

    sram_model sram_model_inst (
        .we_n(ram_nwe),
        .ce_n(ram_nce),
        .oe_n(ram_noe),
        .addr(ram_address[18:0]),
        .data(ram_data_z)
    );

endmodule
