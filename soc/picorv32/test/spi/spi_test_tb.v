`timescale 1 ns / 1 ns

// TODO Needs cleanup. would be better to have a sequential testbench
// based on verilog tasks, like the i2c_soft one.

module spi_test_tb;
    localparam CLK_PERIOD = 8;    // Simulated clock period in [ns]
    localparam MAX_SIM    = 84000;   // ns
    localparam N_SLAVES   = 2;
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    task bit_reverse;
        input  [31:0] inVal;
        output [31:0] outVal;
        integer i;
        begin
            for(i=0;i<=31;i=i+1)
                outVal[i] = inVal[31-i];
        end
    endtask

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //  and do some local bus reads
    //  at specific clock cycles
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=1;
    reg [31:0] rom0r;
    reg [31:0] rom1r;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("spi_test.vcd");
            $dumpvars(5,spi_test_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        // bit reverse function
        bit_reverse(ROM0, rom0r);
        $display("norm: %b   rev: %b", ROM0, rom0r );
        bit_reverse(ROM1, rom1r);
        #MAX_SIM;
        $display("TIMEOUT\nFAIL\n");
        $stop();
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire trap;
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_spi0_ret;
    wire [32:0] packed_spi1_ret;
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > DEC
        .mem_packed_ret( packed_cpu_ret )  //CPU < DEC
    );

    assign packed_cpu_ret = packed_mem_ret | packed_spi0_ret | packed_spi1_ret;
    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./spi_test32.hex"),
        .BASE_ADDR     (8'h00)
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk            ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //DEC > MEM
        .mem_packed_ret( packed_mem_ret )  //DEC < MEM
    );

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("CPU trap. Stop.");
            if (pass) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop;
        end
    end

    // --------------------------------------------------------------
    //  SPI master
    // --------------------------------------------------------------
    wire [N_SLAVES-1:0] spi_ss;
    wire [N_SLAVES-1:0] spi_sck;
    wire [N_SLAVES-1:0] spi_mosi;
    wire [N_SLAVES-1:0] spi_miso;
    spi_pack #(
        .BASE_ADDR  (8'h04)
    ) dut (
        .clk            (mem_clk        ),
        .rst            (reset          ),
        .spi_ss         (spi_ss[0]      ),
        .spi_sck        (spi_sck[0]     ),
        .spi_mosi       (spi_mosi[0]    ),
        .spi_miso       (spi_miso[0]    ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd (packed_cpu_fwd ), //DEC > URT
        .mem_packed_ret (packed_spi0_ret )  //DEC < URT
    );

    spi_pack #(
        .BASE_ADDR  (8'h05)
    ) dut1 (
        .clk            (mem_clk        ),
        .rst            (reset          ),
        .spi_ss         (spi_ss[1]      ),
        .spi_sck        (spi_sck[1]     ),
        .spi_mosi       (spi_mosi[1]    ),
        .spi_miso       (spi_miso[1]    ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd (packed_cpu_fwd ), //DEC > URT
        .mem_packed_ret (packed_spi1_ret )  //DEC < URT
    );

    // --------------------------------------------------------------
    //  SPI slave (hardware)
    // --------------------------------------------------------------
    localparam ROM0 = 32'hdeadbeaf;
    localparam ROM1 = 24'h123456;
    spi_slave #(.ID(0), .CPOL(0), .DW(32)) spi_slave0_inst (
        .ROM  (ROM0),
        .ss   (spi_ss[0]  ),
        .sck  (spi_sck[0] ),
        .mosi (spi_mosi[0]),
        .miso (spi_miso[0])
    );

    spi_slave #(.ID(1), .CPOL(1), .DW(24)) spi_slave1_inst (
        .ROM  (ROM1),
        .ss   (spi_ss[1]  ),
        .sck  (spi_sck[1] ),
        .mosi (spi_mosi[1]),
        .miso (spi_miso[1])
    );

    reg spi_start01=0;
    reg spi_start11=0;

    always @(posedge mem_clk) begin
        spi_start01 <= dut.spi_inst.trigger;
        spi_start11 <= dut1.spi_inst.trigger;
    end
    wire spi_start0 = dut.spi_inst.trigger & ~spi_start01;
    wire spi_start1 = dut1.spi_inst.trigger & ~spi_start11;

    integer time0=0;
    wire cpu_write_spi     = cpu.mem_valid & &cpu.mem_wstrb & (cpu.mem_addr[31:24]==8'h4) & spi_start0;
    wire cpu_read_spi      = cpu.mem_valid & ~|cpu.mem_wstrb & (cpu.mem_addr[31:24]==8'h4) & spi_start0;
    wire cpu_read_spi_ack0  = cpu.mem_valid & ~|cpu.mem_wstrb & (cpu.mem_addr==32'h04000000) & cpu.mem_ready;
    wire cpu_read_spi_ack1  = cpu.mem_valid & ~|cpu.mem_wstrb & (cpu.mem_addr==32'h05000000) & cpu.mem_ready;
    always @(negedge mem_clk) begin
        time0 = $time-(CLK_PERIOD)/2;
        if (cpu_write_spi)
            $display("Time: %8g ns, CPU Write  : ADDR 0x%08x DATA 0x%08x", time0, cpu.mem_addr, cpu.mem_wdata);
        if (dut.spi_inst.rdata_val)
            $display("Time: %8g ns, SPI done   : ADDR 0x%08x", time0, dut.spi_rdata);
        if (cpu_read_spi)
            $display("Time: %8g ns, CPU Reading: ADDR 0x%08x", time0, cpu.mem_addr);
        if (cpu_read_spi_ack0) begin
            $display("Time: %8g ns, CPU Readack: ADDR 0x%08x DATA 0x%08x", time0, cpu.mem_addr, cpu.mem_rdata);
            if ( dut.spi_inst.cfg_lsb_reg )
                pass &= cpu.mem_rdata == rom0r;
            else
                pass &= cpu.mem_rdata == ROM0;
        end
        if (cpu_read_spi_ack1) begin
            $display("Time: %8g ns, CPU Readack: ADDR 0x%08x DATA 0x%08x", time0, cpu.mem_addr, cpu.mem_rdata);
            if ( dut1.spi_inst.cfg_lsb_reg )
                pass &= cpu.mem_rdata == rom1r;
            else
                pass &= cpu.mem_rdata == ROM1;
        end
        if (spi_start0)
            $display("spi_start slave 0, halfperiod: %d", dut.spi_inst.cfg_sckhalfperiod[7:0]);
        if (spi_start1)
            $display("spi_start slave 1, halfperiod: %d", dut1.spi_inst.cfg_sckhalfperiod[7:0]);
        //$monitor("time: %8g ns, spi_ss: %2b, spi_miso: %2b", $time, spi_ss, spi_miso);
    end
endmodule
