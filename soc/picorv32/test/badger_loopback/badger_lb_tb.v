// Loopback test. Connect Ethernet out to input.
// C-program generates test-data ethernet payload, sends it through the badger.h API,
// immediately receives it back and check if the data is as expected.
`timescale 1 ns / 1 ns

module badger_lb_tb;
    localparam SYS_CLK_PERIOD = 8;  // [ns]
    localparam ETH_RX_CLK_PERIOD = 8;
    localparam LATENCY=64;
    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg sys_clk=0, eth_rx_clk=0;
    integer cc=0;
    reg rst = 1;
    always #(SYS_CLK_PERIOD / 2) sys_clk = ~sys_clk;
    always #(ETH_RX_CLK_PERIOD / 2) eth_rx_clk = ~eth_rx_clk;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("badger_lb.vcd");
            $dumpvars(10, badger_lb_tb);
        end
        repeat (10) @(posedge sys_clk);
        rst <= 0;
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    // `retVal` is the value returned from main()
    wire [31:0] retVal = cpu.picorv32_core.dbg_reg_x10;
    always @(posedge sys_clk) begin
        cc <= cc + 1;
        if (~rst && trap) begin
            $display("TRAP");
            if (retVal == 32'h1) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop;
        end
        // $fflush();
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    `define DEBUGREGS
    pico_pack cpu (
        .clk           ( sys_clk        ),
        .reset         ( rst            ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        // Packed bus
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_badger_ret;
    wire [32:0] packed_sfr_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_sfr_ret | packed_badger_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./badger_lb32.hex"),
        .BASE_ADDR     (8'h00)
    ) mem_inst (
        // Hardware interface
        .clk           ( sys_clk ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ),
        .mem_packed_ret( packed_mem_ret )
    );

    // --------------------------------------------------------------
    //  GPIO module
    // --------------------------------------------------------------
    // let the pico talk back to the test-bench
    wire [31:0] picoOut;
    wire [31:0] picoOutWr;
    sfr_pack #(
        .BASE_ADDR      ( 8'h03  ),
        .N_REGS         ( 1 )
    ) sfr_console (
        .clk            ( sys_clk  ),
        .rst            ( rst ),
        .mem_packed_fwd ( packed_cpu_fwd ),
        .mem_packed_ret ( packed_sfr_ret ),
        .sfRegsIn       ( 32'h0 ),
        .sfRegsOut      ( picoOut ),
        .sfRegsWrStr    ( picoOutWr )
    );

    // --------------------------------------------------------------
    //  DUT
    // --------------------------------------------------------------
    // reg [7:0] eth_in=0;
    // reg eth_in_s=0;
    wire [7:0] eth_out;
    wire eth_out_s;
    badger_pack #(
        .BASE_ADDR(8'h01)
    ) badger_pack_inst (
        .sys_clk       (sys_clk),
        .rst           (rst),
        .mem_packed_fwd(packed_cpu_fwd),
        .mem_packed_ret(packed_badger_ret),
        .eth_clocks_rx (eth_rx_clk),
        // Loopback output back to input
        .eth_rx_dv     (eth_out_s),
        .eth_rx_er     (1'b0),
        .eth_rx_data   (eth_out),
        .eth_clocks_gtx(),
        .eth_rst_n     (),
        .eth_tx_en     (eth_out_s),
        .eth_tx_er     (),
        .eth_tx_data   (eth_out),
        .eth_mdc       (),
        .eth_mdio      ()
    );

    // printf to terminal
    always @(posedge sys_clk)
        if(|picoOutWr[7:0])
            $write("%c", picoOut[7:0]);

endmodule
