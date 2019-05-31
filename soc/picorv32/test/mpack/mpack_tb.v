`timescale 1 ns / 1 ps

module mem_pack_unpack_tb;

    reg clk=0;
    always #5 begin
        clk = ~clk;
    end

    // Test data to be packed
    reg [31:0] mem_wdata = 32'hAFFEC0FE;
    reg [ 3:0] mem_wstrb = 3;
    reg        mem_valid = 1;
    reg [31:0] mem_addr  = 32'hDEADBEEF;
    reg        mem_ready = 1;
    reg [31:0] mem_rdata = 32'h47114712;

    // What comes out of unpack
    wire [31:0] mem_wdata_ret;
    wire [ 3:0] mem_wstrb_ret;
    wire        mem_valid_ret;
    wire [31:0] mem_addr_ret;
    wire        mem_ready_ret;
    wire [31:0] mem_rdata_ret;

    // Packed data
    wire [68:0] packed_fwd;
    wire [32:0] packed_ret;

    mpack mp (
        .mem_wdata ( mem_wdata      ),
        .mem_wstrb ( mem_wstrb      ),
        .mem_valid ( mem_valid      ),
        .mem_addr  ( mem_addr       ),
        .mem_ready ( mem_ready_ret  ),
        .mem_rdata ( mem_rdata_ret  ),

        .mem_packed_fwd( packed_fwd ),
        .mem_packed_ret( packed_ret )
    );

    munpack mu (
        .mem_packed_fwd( packed_fwd ),
        .mem_packed_ret( packed_ret ),

        .mem_wdata ( mem_wdata_ret  ),
        .mem_wstrb ( mem_wstrb_ret  ),
        .mem_valid ( mem_valid_ret  ),
        .mem_addr  ( mem_addr_ret   ),
        .mem_ready ( mem_ready      ),
        .mem_rdata ( mem_rdata      )
    );

    integer pass = 1;
    initial begin
        repeat (1) @(posedge clk);

        $write("\n");
        $write("packed_fwd %24x\n", packed_fwd);
        $write("packed_ret %24x\n", packed_ret);
        $write("\n");
        $write("mem_wdata_ret %8x %8x\n", mem_wdata, mem_wdata_ret);
        $write("mem_wstrb_ret %8x %8x\n", mem_wstrb, mem_wstrb_ret);
        $write("mem_valid_ret %8x %8x\n", mem_valid, mem_valid_ret);
        $write("mem_addr_ret  %8x %8x\n", mem_addr,  mem_addr_ret);
        $write("mem_ready_ret %8x %8x\n", mem_ready, mem_ready_ret);
        $write("mem_rdata_ret %8x %8x\n", mem_rdata, mem_rdata_ret);
        $write("\n");
        $fflush();

        pass &= (mem_wdata === mem_wdata_ret);
        pass &= (mem_wstrb === mem_wstrb_ret);
        pass &= (mem_valid === mem_valid_ret);
        pass &= (mem_addr  === mem_addr_ret );
        pass &= (mem_ready === mem_ready_ret);
        pass &= (mem_rdata === mem_rdata_ret);

        if (pass) begin
            $display("PASS");
            $finish;
        end
        $display("FAIL");
        $stop;
    end

endmodule
