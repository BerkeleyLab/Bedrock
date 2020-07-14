`timescale 1 ns / 1 ns

module wfm_tb;
    localparam CLK_PERIOD = 10;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    reg dsp_clk=1;
    always #(4)   dsp_clk = ~dsp_clk;
    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=0;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("wfm.vcd");
            $dumpvars(5,wfm_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #15000
        pass = 0;
        $display("TIMEOUT\n");
        $display("%s\n", pass ? "PASS" : "FAIL");
        $finish();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("preliminary TRAP");
            $display("%s\n", pass ? "PASS" : "FAIL");
            $finish();
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
    wire [32:0] packed_dut_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_dut_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory2_pack #(
        .MEM_INIT      ("./wfm32.hex"  ),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        // Look ahead interface
        .mem_la_read   (mem_la_read     ),
        .mem_la_write  (mem_la_write    ),
        .mem_la_addr   (mem_la_addr     ),
        .mem_la_wdata  (mem_la_wdata    ),
        .mem_la_wstrb  (mem_la_wstrb    ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_ret( packed_mem_ret )  //CPU < MEM
    );

    reg [31:0] adc_out_data=32'hdeadbeaf;
    always @(posedge dsp_clk) begin
        adc_out_data <= ~adc_out_data;
    end
    // --------------------------------------------------------------
    //  wfm_pack module
    // --------------------------------------------------------------
    //#define BASE_WFM    0x03000000
    parameter [7:0] BASE_WFM = 8'h03;
    wfm_pack #(
        .BASE_ADDR     (BASE_WFM),
        .BASE2_ADDR    (8'h00),
        .N_CH          (2)
    ) dut (
        // Hardware interface
        .dsp_clk    (dsp_clk),
        .adc_out_data (adc_out_data),

        // PicoRV32 packed MEM Bus interface
        .clk        (mem_clk),
        .rst        (reset),
        .mem_packed_fwd( packed_cpu_fwd ),
        .mem_packed_ret( packed_dut_ret )
    );

    wire mem_read_stb;
    assign mem_read_stb = cpu.mem_ready && ~|cpu.mem_wstrb && cpu.mem_addr[31:24]==BASE_WFM;
    wire [8:0] v_addr = cpu.mem_addr[10:2];
    wire [15:0] v_rdata = cpu.mem_rdata[15:0];
    always @(posedge mem_clk) if (mem_read_stb) begin
        $display("Time: %g ns: addr: 0x%x, data : 0x%x\n", $time, v_addr, v_rdata);
        if (v_addr % 2 == 1 && v_rdata == 16'hdead) pass = 1;
    end
endmodule
