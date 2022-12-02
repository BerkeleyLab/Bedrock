`timescale 1 ns / 1 ps

module iserdes_tb;
    localparam CLK_PERIOD = 8;    // Simulated clock period in [ns]
    localparam PATTERN=32'hf0f0f0f0;
    parameter DW=2;
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    wire [8*DW-1:0] dout;
    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    reg pass=0;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("iserdes_test.vcd");
            $dumpvars(5,iserdes_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #150000
        pass = (dout == PATTERN[8*DW-1:0]);
        $display("TIMEOUT\nFAIL");
        $stop();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            pass = (dout == PATTERN[8*DW-1:0]);
            $display("TRAP");
            if (pass) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop;
        end
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        // Look ahead mem interface
        .mem_la_read   (mem_la_read     ),
        .mem_la_write  (mem_la_write    ),
        .mem_la_addr   (mem_la_addr     ),
        .mem_la_wdata  (mem_la_wdata    ),
        .mem_la_wstrb  (mem_la_wstrb    ),
        // Packed bus
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_iserdes_ret;
    wire [32:0] packed_dbg_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_iserdes_ret | packed_dbg_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory2_pack #(
        .MEM_INIT      ("./iserdes_test32.hex"  ),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         (reset           ),
        // Look ahead interface
        .mem_la_read   (mem_la_read     ),
        .mem_la_write  (mem_la_write    ),
        .mem_la_addr   (mem_la_addr     ),
        .mem_la_wdata  (mem_la_wdata    ),
        .mem_la_wstrb  (mem_la_wstrb    ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_ret( packed_mem_ret )  //CPU < MEM
    );

    // --------------------------------------------------------------
    // Simulate adc dco clock
    // LTC2175: Max sampling rate 125MHz, 2-lanes 16-bit serialization
    // t_ser = 1/(8*fs) = 1ns
    // Operation fs = 114.574MHz
    // t_ser = 1.091ns
    // --------------------------------------------------------------
    reg clk_dco = 0;
    always begin
        clk_dco = 0; #1.091;
        clk_dco = 1; #1.091;
    end

    wire clk_dco_buf;
    wire clk_div_buf;
    dco_buf dco_buf_i (
        .clk_reset(reset),
        .dco_p  (clk_dco),
        .dco_n  (~clk_dco),
        .clk_dco_buf (clk_dco_buf),
        .clk_div_buf (clk_div_buf)
    );

    // --------------------------------------------------------------
    // Simulate adc output
    // --------------------------------------------------------------
    localparam DELAY=3;  // ADJUST ME!
    reg [DW-1:0] in_p = 0;
    wire [DW-1:0] in_n = ~in_p;

    reg [31:0] shifter = PATTERN;
    integer ix=4+DELAY; // delay, adjust with bitslip, '4' is just for frame > 8 bits
    integer j;
    always @(clk_dco) begin
        for (j=0; j<DW; j=j+1)
            in_p[j] <= shifter[ix];
        shifter <= {shifter[30:0],shifter[31]};
    end

    // --------------------------------------------------------------
    //  iserdes_pack module
    // --------------------------------------------------------------
    iserdes_pack #(
        .DW ( DW ),
        .BASE_ADDR     (8'h01)
    ) dut (
        // Hardware interface
        .clk_dco       ( clk_dco_buf ),
        .clk_div       ( clk_div_buf ),
        .in_p          ( in_p           ),
        .in_n          ( in_n           ),
        .dout          ( dout           ),

        .clk           ( mem_clk        ),
        .rst           ( reset          ),

        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ),
        .mem_packed_ret( packed_iserdes_ret)
    );

    // If the debug SFR received data, print it to the console
    //#define BASE_DBG_SFR    0x08000000
    parameter [7:0] BASE_DBG_SFR = 8'h08;
    sfr_pack #(
        .BASE_ADDR      ( BASE_DBG_SFR   ),
        .N_REGS         ( 1              )
    ) dbg (
        .clk            ( mem_clk        ),
        .rst            ( reset          ),
        .mem_packed_fwd ( packed_cpu_fwd ),
        .mem_packed_ret ( packed_dbg_ret ),
        .sfRegsOut      ( ),
        .sfRegsIn       ( 32'h0 ),
        .sfRegsWrStr    ( )
    );

    wire mem_print_hit = cpu.mu.mem_ready && cpu.mu.mem_wstrb[0] && cpu.mu.mem_addr[31:24]==BASE_DBG_SFR;
    always @(posedge mem_clk) begin
        if (mem_print_hit) begin
            $write("%c", cpu.mu.mem_wdata[7:0]);
            $fflush();
        end
    end

    // Check result
    reg [7:0] clk_div_cnt=0;
    always @(posedge clk_div_buf) clk_div_cnt <= clk_div_cnt + 1'b1;

    reg [31:0] check_data [DW-1:0];
    integer l;
    wire mem_read_stb;
    wire [7:0] lane_dout [DW-1:0];

    assign lane_dout[0] = dout[7:0];
    assign lane_dout[1] = dout[15:8];
    assign mem_read_stb = cpu.mu.mem_ready && ~|cpu.mu.mem_wstrb && cpu.mu.mem_addr[31:24]==8'h01;
    always @(posedge clk_div_buf) begin
        for (l=0; l<DW; l=l+1) begin
            check_data[l] <= {check_data[l][23:0], lane_dout[l]};
            if (mem_read_stb)
                $display("lane: %3d clk_div cc: %d, data out: 0x%x", l, clk_div_cnt, check_data[l]);
            if (check_data[l] == PATTERN) begin
                //$display("lane: %3d MATCH at clk_div cc: %d.", l,  clk_div_cnt);
                pass = 1'b1;
            end
        end
        // if (dut.bitslip)
        //     $display("clk_div cc: %d, bitslip: %b", clk_div_cnt, dut.bitslip);
    end
endmodule
