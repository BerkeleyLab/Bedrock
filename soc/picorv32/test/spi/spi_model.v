module spi_model #(
    parameter DW=32,
    parameter CPOL=0,
    parameter integer ID=0
) (
    input [DW-1:0] ROM,
    input ss,
    input sck,
    input mosi,
    output miso
);

reg [DW-1:0] shift=0;
reg [5:0] cnt=0;
reg [DW-1:0] rom=0;
wire sck_edge = CPOL ? ~sck : sck; // convert to CPOL=0

// send data at rising edge
always @(posedge sck_edge) if (~ss) begin
    cnt <= (cnt==DW) ? 1 : cnt + 1'b1;
    if (cnt==0) rom <= ROM;
    else rom <= {rom[DW-2:0], rom[DW-1]};
end

// sample data at falling edge
reg read=0;
always @(negedge sck_edge) if (~ss) begin
    if (cnt == 1) read = mosi;  // only response to 'read' cmd
    shift = {shift[DW-2:0], mosi};
    if (cnt == DW) begin
        $display("Time:     %g ns, spi_model_%1d got: 0x%x, '%c'", $time, ID, shift, shift);
        read = 0;
    end
end

// TODO why?
// assign miso = read ? rom[DW-1] : 0;

assign miso = rom[DW-1];
endmodule
