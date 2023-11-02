`timescale 1 ns / 1 ns

module lb_bridge_tb;
    localparam CLK_PERIOD = 8;    // Simulated clock period in [ns]
    localparam READ_DELAY = 3;
    localparam MAX_SIM    = 30000;   // ns
    localparam LB_ADW     = 20;
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;
    wire lb_clk = mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //  and do some local bus reads
    //  at specific clock cycles
    //------------------------------------------------------------------------
    reg reset = 1;
    integer collisions=0;
    integer w_retries=0;
    integer r_retries=0;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("lb_bridge.vcd");
            $dumpvars(5,lb_bridge_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #MAX_SIM;
        $display("TIMEOUT\nFAIL");
        $stop(0);
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    wire trap;
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > DEC
        .mem_packed_ret( packed_cpu_ret )  //CPU < DEC
    );

    // --------------------------------------------------------------
    //  Instantiate the external address decoder and multiplexer
    // --------------------------------------------------------------
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_bridge_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_bridge_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./lb_bridge32.hex")
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk            ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //DEC > MEM
        .mem_packed_ret( packed_mem_ret )  //DEC < MEM
    );

    wire collision;
    wire busy;

    wire lbo_write, lbo_read;
    wire [LB_ADW-1:0] lbo_addr;
    wire [31:0] lbo_wdata;
    wire [31:0] lbo_rdata;
    wire lbo_rvalid;
    lb_bridge #(
        .BASE_ADDR     ( 8'h04           ),
        .ADW           ( LB_ADW          ),
        .READ_DELAY    ( READ_DELAY      )
    ) bridge (
        // PicoRV32 packed MEM Bus interface
        .clk           ( mem_clk         ),
        .mem_packed_fwd( packed_cpu_fwd  ), //DEC > MEM
        .mem_packed_ret( packed_bridge_ret ), //DEC < MEM
        .busy          ( busy            ),
        .lb_write      ( lbo_write       ),
        .lb_read       ( lbo_read        ),
        .lb_addr       ( lbo_addr        ),
        .lb_wdata      ( lbo_wdata       ),
        .lb_rdata      ( lbo_rdata       ),
        .lb_rvalid     ( lbo_rvalid      )
    );

    reg dbg_w_retry1=0, dbg_r_retry1=0;
    wire dbg_w_retry = busy & bridge.mem_write;
    wire dbg_r_retry = busy & bridge.mem_read;
    always @(posedge mem_clk) begin
        dbg_w_retry1 <= dbg_w_retry;
        dbg_r_retry1 <= dbg_r_retry;
    end
    wire dbg_w_retry_rise = dbg_w_retry & ~dbg_w_retry1;
    wire dbg_r_retry_rise = dbg_r_retry & ~dbg_r_retry1;

    reg lb1_write=0, lb1_read=0;
    reg [LB_ADW-1:0] lb1_addr=0;
    reg [31:0] lb1_wdata=0;
    wire [31:0] lb1_rdata;
    wire lb1_rvalid;

    wire lb_merge_write, lb_merge_read;
    wire [LB_ADW-1:0] lb_merge_addr;
    wire [31:0] lb_merge_wdata;
    wire [31:0] lb_merge_rdata;
    wire lb_merge_rvalid;
    lb_merge #(.ADW(LB_ADW), .READ_DELAY(READ_DELAY)) merge(
        .clk(lb_clk),
        .collision  (collision  ),
        .busy       (busy),
        .lb_write_a (lbo_write  ),
        .lb_read_a  (lbo_read   ),
        .lb_wdata_a (lbo_wdata  ),
        .lb_addr_a  (lbo_addr[LB_ADW-1:0]   ),
        .lb_rdata_a (lbo_rdata),
        .lb_rvalid_a(lbo_rvalid  ),

        .lb_write_b (lb1_write   ),
        .lb_read_b  (lb1_read    ),
        .lb_wdata_b (lb1_wdata   ),
        .lb_addr_b  (lb1_addr[LB_ADW-1:0]    ),
        .lb_rdata_b (lb1_rdata   ),
        .lb_rvalid_b(lb1_rvalid  ),

        .lb_merge_write  (lb_merge_write   ),
        .lb_merge_read   (lb_merge_read    ),
        .lb_merge_wdata  (lb_merge_wdata   ),
        .lb_merge_addr   (lb_merge_addr    ),
        .lb_merge_rdata  (lb_merge_rdata   ),
        .lb_merge_rvalid (lb_merge_rvalid  )
    );
    assign lb_merge_rdata = lb_merge_rvalid ? $random : 32'hx;

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    reg pass = 1'b0;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("%8d collisions. Expected %8d.", collisions, 0);
            $display("%8d write retries. Expected %8d.", w_retries, 2);
            $display("%8d read retries. Expected %8d.", r_retries, 3);
            pass = (collisions == 0) && (w_retries == 2) && (r_retries == 3);
            if (pass) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop(0);
        end
    end

    wire cpu_la_write = cpu.mem_la_write && (cpu.mem_la_addr[31:24]==8'h04);
    wire cpu_la_read = cpu.mem_la_read && (cpu.mem_la_addr[31:24]==8'h04);
    initial begin
        #500;
        // write through
        lb1_write_task( 20'h20000, 32'hfaceface );
        // collision
        @ (posedge cpu_la_write); // simulate both write. w_retry
        lb1_write_task( 20'h30000, 32'hdeadbeaf );
        @ (posedge cpu_la_read);  // simulate both read, LB first. r_retry
        lb1_read_task ( 20'h00020, lb1_rdata);
        @ (posedge bridge.mem_read); // simulate both read, CPU first. r_retry
        # (2*CLK_PERIOD);
        lb1_read_task ( 20'h00030, lb1_rdata);

        @ (posedge cpu_la_write);  // simulate LB read while CPU write. w_retry
        lb1_read_task ( 20'h00040, lb1_rdata);
        @ (posedge bridge.mem_read); // simulate LB write while CPU read. r_retry
        lb1_write_task( 20'h00050, 32'hfaceface );
    end

    // --------------------------------------------------------------
    //  debug functions
    // --------------------------------------------------------------
    task lb1_write_task;
        input [LB_ADW-1:0] addr;
        input [31:0] data;
        begin
            @ (posedge lb_clk);
            lb1_addr  <= addr;
            lb1_wdata <= data;
            lb1_write <= 1'b1;
            @ (posedge lb_clk);
            lb1_write = 1'b0;
        end
    endtask
    // master read task
    task lb1_read_task;
        input [LB_ADW-1:0] addr;
        input [31:0] rdata;
        begin
            @ (posedge lb_clk);
            lb1_addr <= addr;
            lb1_read <= 1'b1;
            @ (posedge lb1_rvalid);
            @ (posedge lb_clk);
            lb1_read <= 1'b0;
            // $display("time: %g Read ack: ADDR 0x%x DATA 0x%x", $time, addr, lb1_rdata);
        end
    endtask

    // 4 + READ_DELAY due to mem_gateway timing
    lb_reading #(.READ_DELAY(4+READ_DELAY)) reading_lb1 (
        .clk        (lb_clk),
        .reset      (1'b0),
        .lb_read    (lb1_read),
        .lb_rvalid  (lb1_rvalid)
    );

    integer time0=0;
    always @(negedge lb_clk) begin
        time0 = $time-(CLK_PERIOD)/2;
        if (bridge.mem_write)
            $display("Time: %8g CPU Write  : ADDR 0x%08x DATA 0x%08x %c",
                      time0, lbo_addr, lbo_wdata, lbo_wdata & 16'hff);
        if (lb1_write)
            $display("Time: %8g LB  Write  : ADDR 0x%08x DATA 0x%08x", time0, lb1_addr, lb1_wdata);
        if (collision) begin
            $display("Time: %8g === Collision. ===", time0);
            collisions <= collisions + 1;
        end
        if (dbg_w_retry_rise) begin
            $display("Time: %8g === CPU write retry ===", time0);
            w_retries <= w_retries + 1;
        end
        if (dbg_r_retry_rise) begin
            $display("Time: %8g === CPU read retry ===", time0);
            r_retries <= r_retries + 1;
        end
        if (bridge.mem_read)
            $display("Time: %8g CPU Reading: ADDR 0x%08x", time0, cpu.mem_addr);
        if (bridge.lb_rvalid)
            $display("Time: %8g CPU Readack: ADDR 0x%08x DATA 0x%08x", time0, bridge.mem_addr, bridge.lb_rdata);
        if (lb1_read)
            $display("Time: %8g LB  Read   : ADDR 0x%08x", time0, lb1_addr);
        if (lb1_rvalid)
            $display("Time: %8g LB  Readack: ADDR 0x%08x DATA 0x%08x", time0, lb1_addr, lb1_rdata);
    end
endmodule
