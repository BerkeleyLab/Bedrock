module spi_chain_pack #(
    parameter BASE_ADDR=8'h00,
    parameter [3:0] N_DEVICES=1
) (
    input  clk,
    input  rst,
    // Hardware interface
    output reg [N_DEVICES-1:0] spi_ss,
    output reg spi_sck,
    output reg spi_mosi,
    input      [N_DEVICES-1:0] spi_miso,
    // PicoRV32 packed MEM Bus interface
    input  [68:0]     mem_packed_fwd,  //DEC > URT
    output [32:0]     mem_packed_ret   //DEC < URT
);
// --------------------------------------------------------------
//  Special function register memory address offsets
// --------------------------------------------------------------
// These addresses are in bytes, so we align them to 4 byte blocks
localparam SPI_TX_REG     = 4'h0;
localparam SPI_RX_REG     = 4'h4;
localparam SPI_CONFIG     = 4'h8;
localparam BIT_CPOL       = 16;
localparam BIT_CPHA       = 17;

initial begin
    spi_ss = {N_DEVICES{1'b1}};
    spi_sck = 0;
    spi_mosi = 0;
end

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire  [3:0] addr = mem_addr[7:4];
wire  [3:0] short_addr = mem_addr[3:0];
wire        mem_ready;
reg  [31:0] mem_rdata=0;
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

wire  [7:0] mem_base_addr = mem_addr[31:24];// Which peripheral   (BASE_ADDR)
wire  [3:0] mem_reg_addr  = mem_addr[3:0];  // Which SPI register (0,4)

// ------------------------------------------------------------------------
//  Instantiate the SPI master modules, blocking IO mode
// ------------------------------------------------------------------------
reg spi_start=0;
reg [31:0] spi_wdata = 0;
wire spi_rvalid;
wire [31:0] spi_rdata;
wire spi_busy;
reg [7:0] sckhalfperiod = 8'd1;
reg [7:0] scklen = 8'd32;
reg cfg_cpol=0;
reg cfg_cpha=1;
wire spi_ss_mux;
wire spi_sck_mux;
wire spi_mosi_mux;
reg spi_miso_mux=0;
spi_engine spi_inst (
    .clk        (clk),
    .reset      (rst),
    .wdata_val  (spi_start),
    .wdata      (spi_wdata),
    .rdata      (spi_rdata),
    .rdata_val  (spi_rvalid),
    .busy       (spi_busy),
    .cfg_sckhalfperiod   (sckhalfperiod),
    .cfg_scklen (scklen),
    .cfg_cpol   (cfg_cpol),
    .cfg_cpha   (cfg_cpha),
    .SS         (spi_ss_mux),
    .SCK        (spi_sck_mux),
    .MOSI       (spi_mosi_mux),
    .MISO       (spi_miso_mux)
);

// ------------------------------------------------------------------------
//  Glue logic
// ------------------------------------------------------------------------
wire mem_write = &mem_wstrb;
wire mem_read = ~|mem_wstrb;

reg [31:0] spi_rdata_latch=0;
reg mem_read_done=0;
reg mem_write_done=0;

reg [15:0] sckhalfperiods [0:N_DEVICES-1];
reg [7:0] scklens [0:N_DEVICES-1];
reg [0:N_DEVICES-1] cfg_cpols;
reg [0:N_DEVICES-1] cfg_cphas;

always @(posedge clk) begin
    // latch spi read for cpu read
    if (spi_rvalid) spi_rdata_latch <= spi_rdata;

    mem_rdata <= 32'h00000000;
    spi_start <= 0;
    mem_write_done <= 0;
    mem_read_done <= 0;
    if ( mem_valid && ~mem_ready && mem_base_addr==BASE_ADDR) begin
        (* parallel_case *)
        case (1'b1)
            // ---------------------------------
            // --- Write to SPI, wait till done
            // ---------------------------------
            mem_write && (short_addr==SPI_TX_REG): begin
                if (spi_busy) begin
                    spi_start <= 0;
                end else begin
                    // apply configuration
                    sckhalfperiod <= sckhalfperiods[addr];
                    scklen <= scklens[addr];
                    cfg_cpol <= cfg_cpols[addr];
                    cfg_cpha <= cfg_cphas[addr];
                    spi_wdata <= mem_wdata[31:0];
                    spi_start <= 1;
                end
            end

            mem_read && (short_addr==SPI_TX_REG): begin
                $display("ffdsafadfadfasdf %g ns, 0x%8x", $time, mem_base_addr);
                mem_rdata <= spi_rdata_latch;
                mem_read_done <= 1;
            end
            // ------------------------------------
            // --- Read from SPI when data is ready
            // ------------------------------------
            mem_read && (short_addr==SPI_RX_REG): begin
                mem_rdata <= spi_rdata_latch;
                mem_read_done <= 1;
            end

            mem_write && (short_addr==SPI_CONFIG) : begin
                sckhalfperiods[addr] <= mem_wdata[7:0];
                scklens[addr] <= mem_wdata[15:8];
                cfg_cpols[addr] <= mem_wdata[BIT_CPOL];
                cfg_cphas[addr] <= mem_wdata[BIT_CPHA];
                mem_write_done <= 1;
            end

            default: begin
                mem_rdata <= 0;
                spi_start <= 0;
                mem_read_done <= 0;
                mem_write_done <= 0;
            end
        endcase
    end
end

integer ix;
initial
for (ix=0; ix<N_DEVICES; ix=ix+1) begin
    sckhalfperiods[ix] = 3;
    scklens[ix] = 32;
    cfg_cpols[ix] = 0;
    cfg_cphas[ix] = 1;
end

always @* begin
    for (ix=0; ix<N_DEVICES; ix=ix+1) begin
        spi_ss[ix]   = (addr==ix) ? spi_ss_mux : 1;
    end
    spi_sck  = spi_sck_mux;
    spi_mosi = spi_mosi_mux;
    spi_miso_mux = spi_miso[addr];
end

assign mem_ready = spi_rvalid | mem_read_done | mem_write_done;

endmodule
