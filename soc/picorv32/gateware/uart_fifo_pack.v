module uart_fifo_pack #(
    parameter [31:0] DATA_WIDTH = 8,
    parameter BASE_ADDR=8'h00,
    parameter [31:0] AW_TX=8,
    parameter [31:0] AW_RX=8
)(
    // Hardware interface
    input  clk,
    input  rst,
    input  rxd,
    output txd,
    // Interrupt signals
    output        irq_rx_valid,    // Set when a byte is received. Cleared when the byte is read from UART_RX_REG
    output        tx_busy,         // High when transmission in progress
    output [15:0] prescale_out,    // output uprescale value
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);

// --------------------------------------------------------------
//  Special function register memory address offsets
// --------------------------------------------------------------
// These addresses are in bytes, so we align them to 4 byte blocks
localparam UART_TX_REG   = 4'h0;
localparam UART_STATUS   = 4'h4;
localparam UART_RX_REG   = 4'h8;
localparam UART_BAUDRATE = 4'hC;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire  [3:0] mem_short_addr = mem_addr[3:0];
reg  [31:0] mem_rdata = 0;

reg mem_ready = 0;
reg mem_ready_ = 0;
wire ready_sum = mem_ready || mem_ready_;

munpack mu (
    .clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),

    .mem_wdata ( mem_wdata    ),
    .mem_wstrb ( mem_wstrb    ),
    .mem_valid ( mem_valid    ),
    .mem_addr  ( mem_addr     ),
    .mem_ready ( mem_ready    ),
    .mem_rdata ( mem_rdata    )
);

// ------------------------------------------------------------------------
//  Instantiate the two UART modules for RX and TX
// ------------------------------------------------------------------------
wire [3:0]  uart_status;

reg  [15:0] uprescale = 1;
assign prescale_out = uprescale;

reg [31:0] utx_tdata = 0;   // set deliberately to 32 bit (and not DATA_WIDTH-1) ...
reg utx_tvalid = 0;         // ... so that the mem_wstrb checking simplifies
reg utx_tlast = 0;
wire utx_tready;

wire [DATA_WIDTH-1:0] urx_tdata;
wire urx_tvalid;
reg urx_tready = 0;

uart_stream #(
    .DW(DATA_WIDTH),
    .AW_TX(AW_TX),
    .AW_RX(AW_RX),
    .USE_SHORTFIFO(0)
) stream (
    .clk        (clk),
    .rst        (rst),
    .uprescale  (uprescale),
    .uart_status(uart_status),
    .utx_tdata  (utx_tdata[DATA_WIDTH-1:0]),
    .utx_tvalid (utx_tvalid),
    .utx_tready (utx_tready),
    .utx_tlast  (utx_tlast),
    .urx_tdata  (urx_tdata[DATA_WIDTH-1:0]),
    .urx_tvalid (urx_tvalid),
    .urx_tready (urx_tready),
    .txd        (txd),
    .rxd        (rxd)
);

assign irq_rx_valid = urx_tvalid;
assign tx_busy = uart_status[0];

// ------------------------------------------------------------------------
//  Glue logic
// ------------------------------------------------------------------------
always @(posedge clk) begin
    // Initialize status lines operating with single clock wide pulses
    mem_ready <= 0;
    mem_rdata <= 32'h00000000;
    utx_tvalid <= 0;
    urx_tready <= 0;
    if (mem_valid && !ready_sum && mem_addr[31:16]=={BASE_ADDR, 8'h00}) begin
        mem_ready <= 1; // acknowledge by default if base_addr matches

        // -----------------------------
        // --- Write to UART output  ---
        // -----------------------------
        if (|mem_wstrb && (mem_short_addr==UART_TX_REG)) begin
            // Writing to address UART_TX_REG will make the UART transmit a byte.
            // If the uart is already transmitting something, we wait for it to finish.
            // This is done by not asserting mem_ready_i, which stalls the CPU for a while.
            // The user should check the tx_busy bit in the UART status register before
            // transmitting to avoid the stall.
            if (mem_wstrb[3]) utx_tdata[31:24] <= mem_wdata[31:24];
            if (mem_wstrb[2]) utx_tdata[23:16] <= mem_wdata[23:16];
            if (mem_wstrb[1]) utx_tdata[15: 8] <= mem_wdata[15: 8];

            // Writing to the lowest byte starts the transmission
            if (mem_wstrb[0]) begin
                if (utx_tready) begin
                    utx_tdata[7:0] <= mem_wdata[7:0];
                    utx_tvalid <= 1;
                end else begin
                    mem_ready <= 0;  // !!! STALL !!! (until UART is ready)
                end
            end
        end
        // -------------------------------
        // --- Write to UART0 baudrate ---
        // -------------------------------
        if (|mem_wstrb && (mem_short_addr==UART_BAUDRATE)) begin
            if (mem_wstrb[0]) uprescale[ 7:0] <= mem_wdata[ 7:0];
            if (mem_wstrb[1]) uprescale[15:8] <= mem_wdata[15:8];
`ifndef YOSYS
            $display("new UART prescale value = 0x%04x", mem_wdata);
`endif
        end
        // -------------
        // --- Reads ---
        // -------------
        if (!mem_wstrb) begin
            if (mem_short_addr == UART_STATUS) begin
                // Read from UART0 status register
                mem_rdata <= uart_status;
            end else if (mem_short_addr == UART_RX_REG) begin
                // Read from RX UART0 data register
                if (urx_tvalid) begin
                    mem_rdata <= urx_tdata;  // Write UART data to mem. bus
                    urx_tready <= 1;  // Acknowledge to FIFO that data has been read
                end else begin
                    mem_rdata <= 32'hFFFF_FF00;   // Write error flag to mem. bus
                end
            end
        end
    end
    mem_ready_ <= mem_ready;
end


`ifdef FORMAL
    // formal rules for the picorv32 bus
    f_pack_peripheral #(
        .BASE_ADDR (BASE_ADDR),
        .BASE2_ADDR(8'h0),
        .F_MAX_STALL_CYCLES(32'd2)
    ) fpp (
        .clk(clk),
        .rst(rst),
        .mem_packed_fwd(mem_packed_fwd),
        .mem_packed_ret(mem_packed_ret),
        .f_past_valid()
    );

    always @(posedge clk) begin
        // without this line, sby will figure out how to write a large value
        // to the prescale reg and then timeout on the UART stall :p
        assume(uprescale == 1);

        // Run it in cover mode and see how sby will figure out how to clock
        // 0x12 into the UART by driving the RX line and then read it over
        // the picorv bus. Very impressive.
        cover(mem_rdata == 32'h00000012);
    end
`endif
endmodule
