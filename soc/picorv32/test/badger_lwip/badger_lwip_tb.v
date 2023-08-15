// Use verilator to generate an executable which is an hardware emulator of the picorv32 SOC.
// Then use it to run and debug the lwip stack on picorv32
`timescale 1 ns / 1 ns

// top level ports are accessed from badger_lwip_sim.cpp
module badger_lwip_tb(
    // GMII Tx port
    input vgmii_tx_clk,
    output [7:0] vgmii_txd,
    output vgmii_tx_en,
    output vgmii_tx_er,

    // GMII Rx port
    input vgmii_rx_clk,
    input [7:0] vgmii_rxd,
    input vgmii_rx_er,
    input vgmii_rx_dv,

    output in_use  // not used ;)
);
    localparam LATENCY=64;
    //------------------------------------------------------------------------
    //  Wire up clocks, reset and handle cpu trap
    //------------------------------------------------------------------------
    wire eth_rx_clk = vgmii_rx_clk;
    wire sys_clk = vgmii_rx_clk;

    // assign in_use = badger_pack_inst.rtefi_blob_inst.in_use;
    // the above line makes the emulator insert sleep() cycles
    // when the eth-interface is not in use
    assign in_use = 1; // emulation at full steam

    integer cc=0;
    reg rst = 1;
    wire trap;
    // `retVal` is the value returned from main() in the firmware code
    wire [31:0] retVal = cpu.picorv32_core.dbg_reg_x10;

    always @(posedge sys_clk) begin
        cc <= cc + 1;
        if (cc > 10)
            rst <= 0;
        // Catch the picorv trap signal to end simulation
        if (~rst && trap) begin
            $display("TRAP");
            // Make sim. fail when firmware returns != 1
            if (retVal == 32'h1) begin
                $display("PASS");
                $finish;
            end else begin
                $display("FAIL");
                $stop(0);
            end
        end
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
        .MEM_INIT      ("./badger_lwip32.hex"),
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
    reg [7:0] eth_in=0;
    reg eth_in_s=0;
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
        .eth_rx_dv     (vgmii_rx_dv),
        .eth_rx_er     (vgmii_rx_er),
        .eth_rx_data   (vgmii_rxd),
        .eth_clocks_gtx(),
        .eth_rst_n     (),
        .eth_tx_en     (vgmii_tx_en),
        .eth_tx_er     (vgmii_tx_er),
        .eth_tx_data   (vgmii_txd),
        .eth_mdc       (),
        .eth_mdio      ()
    );

    // printf to terminal
    always @(posedge sys_clk)
        if(|picoOutWr[7:0])
            $write("%c", picoOut[7:0]);

endmodule
