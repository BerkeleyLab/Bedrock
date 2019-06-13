`timescale 1 ns / 1 ns

module bootloader_tb;
    localparam CLK_PERIOD = 10;    // Simulated clock period in [ns]
    localparam BAUD_RATE = 9216000;
    reg [15:0] prescaler=0;

    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("bootLoad.vcd");
            $dumpvars(0,bootloader_tb);
        end
        prescaler = 1000000000/CLK_PERIOD/(BAUD_RATE*8);
        $display("prescaler = %x", prescaler);
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #500000
        $display("TIMEOUT\nFAIL");
        $stop();
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
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_urt0_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_urt0_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./bootLoad32.hex"),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > MEM
        .mem_packed_ret( packed_mem_ret )  //CPU < MEM
    );

    // --------------------------------------------------------------
    //  UART0 (part of picorv)
    // --------------------------------------------------------------
    wire uart_rx0, uart_tx0;
    uart_fifo_pack #(
        .DATA_WIDTH  ( 8 ),
        .BASE_ADDR   ( 8'h02 )
    ) uart_inst0 (
        // Hardware interface
        .clk         ( mem_clk    ),
        .rst         ( reset      ),
        .rxd         ( uart_rx0   ),
        .txd         ( uart_tx0   ),
        .irq_rx_valid( ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ),  //CPU > URT
        .mem_packed_ret( packed_urt0_ret )  //CPU < URT
    );

    // ------------------------------------------------------------------------
    //  UART RX (part of tb)
    // ------------------------------------------------------------------------
    wire [7:0] urx_tdata0;
    wire       urx_tvalid0;
    reg        urx_tready0 = 0;
    uart_rx #(
        .DATA_WIDTH(8)              // We transmit / receive 8 bit words + 1 start and stop bit
    ) uart_tb_rx (
        .prescale( prescaler ),
        .clk ( mem_clk       ),
        .rst ( reset         ),     // UART expects an active high reset
        // axi output
        .output_axis_tdata(  urx_tdata0 ),
        .output_axis_tvalid( urx_tvalid0 ),
        .input_axis_tready( urx_tready0 ),
        // uart pins
        .rxd( uart_tx0 )
    );

    // ------------------------------------------------------------------------
    //  UART TX (part of tb)
    // ------------------------------------------------------------------------
    reg [7:0]  utx_tdata0 = 0;
    reg        utx_tvalid0 = 0;
    wire       utx_tready0;
    uart_tx #(
        .DATA_WIDTH(8)              // We transmit / receive 8 bit words + 1 start and stop bit
    ) uart_tb_tx (
        .prescale( prescaler ),
        .clk ( mem_clk       ),
        .rst ( reset         ),     // UART expects an active high reset
        // axi output
        .input_axis_tdata(  utx_tdata0  ),
        .input_axis_tvalid( utx_tvalid0 ),
        .output_axis_tready( utx_tready0 ),
        // uart pins
        .txd( uart_rx0 )
    );

    integer i, progLen=0;
    reg  [31:0] _startup_adr_arr[0:0];
    wire [31:0] _startup_adr = _startup_adr_arr[0];
    reg  [ 7:0] hexData      [0:255];

    //--------------------
    // The test sequence
    //--------------------
    initial begin
        // to get the value of _startup_adr, this is run from the makefile:
        // riscv32-unknown-elf-objdump -t bootLoad.elf | grep _startup_adr | sed "s/\s.*$//"  > _startup_adr.hex
        $readmemh("_startup_adr.hex", _startup_adr_arr);
        // read bootloader + userprogram hex file
        $readmemh("bootLoad8.hex", hexData);
        // find length of user program
        while( hexData[_startup_adr+progLen] !== 8'hxx ) progLen=progLen+1;
        $display("User prog starting from %x (%x bytes)", _startup_adr, progLen);
        wait( !reset );
        $display("---------------------");
        $display(" Testing bootloading");
        $display("---------------------");
        // Sync sequence: ok go
        uart_read_task("o");
        uart_read_task("o");
        uart_read_task("k");
        uart_read_task("\n");
        uart_write_task("g");
        uart_read_task("o");
        uart_read_task("\n");
        // Send number of bytes
        uart_write_task( progLen[31:24] );
        uart_write_task( progLen[23:16] );
        uart_write_task( progLen[15: 8] );
        uart_write_task( progLen[ 7: 0] );
        $write("\n");
        // Send data bytes
        for(i=0; i<progLen; i=i+1) begin
            uart_write_task( hexData[_startup_adr+i] );
        end
        $write("\n");
        // Read back data bytes
        for(i=0; i<progLen; i=i+1) begin
            uart_read_task( hexData[_startup_adr+i] );
        end
        $write("\n");
        // The user program starts talking
        uart_read_task("!");
        uart_read_task("!");
        uart_read_task("!");
        //-------------------
        // Test timeout
        //-------------------
        $display("\n<reset>");
        @ (posedge mem_clk);
        reset <= 1;
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        $display("---------------------");
        $display(" Testing timeout");
        $display("---------------------");
        // Sync sequence: ok
        uart_read_task("o");
        uart_read_task("o");
        uart_read_task("k");
        uart_read_task("\n");
        // The user program should start talking after the timeout
        uart_read_task("!");
        uart_read_task("!");
        uart_read_task("!");
        $write("\n");
        #500
        if (pass) begin
            $display("PASS");
            $finish;
        end
        $display("FAIL");
        $stop;
    end

    // --------------------------------------------------------------
    //  blocking uart rx tx helpers
    // --------------------------------------------------------------
    task uart_write_task;
        input [7:0] data;
        begin
            wait( utx_tready0 && !utx_tvalid0 );
            @ (posedge mem_clk);
            utx_tvalid0 <= 1;
            utx_tdata0  <= data;
            $write("W%x ", data); $fflush();
            // $write("%c", data); $fflush();
            @ (posedge mem_clk);
            utx_tvalid0 <= 0;
        end
    endtask

    task uart_read_task;
        input [7:0] expectVal;
        begin
            wait( urx_tvalid0 && !urx_tready0 );
            @ (posedge mem_clk);
            if( urx_tdata0 === expectVal ) begin
                $write("R%x ", urx_tdata0); $fflush();
                // $write("%c", urx_tdata0); $fflush();
            end else begin
                $write("R<%2x!=%2x> ", expectVal, urx_tdata0); $fflush();
                pass = 0;
            end
            urx_tready0 <= 1;
            @ (posedge mem_clk);
            urx_tready0 <= 0;
        end
    endtask
    always @(posedge mem_clk) begin
        if (cpu.mem_ready && cpu.mem_addr == 32'h2000008)
            if (cpu.mem_rdata != 32'hffffff00)
                $display("RX: %x", cpu.mem_rdata[7:0]);
    end

endmodule
