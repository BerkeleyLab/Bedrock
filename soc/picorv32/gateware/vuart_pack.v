// --------------------------------------------------------------
//  virtual uart_wrap.v
// --------------------------------------------------------------
// Here we wrap the uart.v interface to the picorv32 address bus
// Makes is sinmpler to instantiate UARTS

module vuart_pack #(
    parameter BASE_ADDR=8'h00
)(
    // Hardware interface
    input       clk,

    output       s_rx_tready,
    input        s_rx_tvalid,
    input [7:0]  s_rx_tdata,

    input        s_tx_tready,
    output       s_tx_tvalid,
    output [7:0] s_tx_tdata,
    // PicoRV32 packed MEM Bus interface
    input  [68:0]     mem_packed_fwd,  //DEC > URT
    output [32:0]     mem_packed_ret   //DEC < URT
);

// --------------------------------------------------------------
//  Special function register memory address offsets
// --------------------------------------------------------------
// These addresses are in bytes, so we align them to 4 byte blocks
localparam UART_TX_REG   = 4'h0;
localparam UART_RX_REG   = 4'h8;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
reg         mem_valid_ = 0;
reg         isStalled = 0;  // high as long as a picorv32 request is processed
wire [31:0] mem_addr;
wire  [3:0] mem_short_addr = mem_addr[3:0];
reg         mem_ready=0;
reg  [31:0] mem_rdata;
munpack mu (
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
reg [7:0]   utx_tdata = 0;
reg         utx_tvalid = 0;
wire        utx_tready;
wire [7:0]  urx_tdata;
wire        urx_tvalid;
reg         urx_tready=0;

assign s_tx_tdata   = utx_tdata;
assign s_tx_tvalid  = utx_tvalid;
assign utx_tready   = s_tx_tready;

assign s_rx_tready  = urx_tready;
assign urx_tdata    = s_rx_tdata;
assign urx_tvalid   = s_rx_tvalid;

// ------------------------------------------------------------------------
//  Glue logic
// ------------------------------------------------------------------------
always @(posedge clk) begin
    // Initialize status lines operating with single clock wide pulses
    mem_ready <= 0;
    mem_rdata <= 0;
    utx_tvalid <= 0;
    urx_tready <= 0;
    if (mem_valid && !mem_valid_ && mem_addr[31:24]==BASE_ADDR || isStalled) begin
        isStalled <= 0;

        (* parallel_case *)
        case (1)
            |mem_wstrb && (mem_short_addr==UART_TX_REG): begin
                // Writing to address UART_TX_REG will make the UART transmit a byte.
                // If the uart is already transmitting something, we wait for it to finish.
                // This is done by not asserting mem_ready_i, which stalls the CPU for a while.
                // The user should check the tx_busy bit in the UART status register before
                // transmitting to avoid the stall.
                // Writing to the lowest byte starts the transmission
                if (mem_wstrb[0]) begin
                    if ( utx_tready ) begin
                        utx_tdata[7:0] <= mem_wdata[7:0];
                        utx_tvalid <= 1;
                        mem_ready <= 1;
                    end else begin
                        mem_ready <= 0;         // !!! STALL !!! (until UART is ready)
                        isStalled <= 1;
                    end
                end
            end
            !mem_wstrb && (mem_short_addr==UART_RX_REG): begin
                if ( urx_tvalid ) begin
                    mem_rdata <= urx_tdata;       // Write UART data to mem. bus
                    urx_tready <= 1;              // Acknowledge to UART that data has been read
                end else begin
                    mem_rdata <= 32'hFFFF_FF00;   // Write error flag to mem. bus
                end
                mem_ready <= 1;
            end
        endcase
    end
    mem_valid_ <= mem_valid;
end

endmodule
