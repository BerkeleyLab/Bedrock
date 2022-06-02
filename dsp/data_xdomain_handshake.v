
// 4-way handshaking Clock domain crossing for data path
// clk_out must be more than twice as fast as the gate_in rate.

// Input -> Output Latency is about 4 clk_out cycles
// Throughput is 8 (clock cycles / new input) 
// Throughput suffering in this design because of rigirous handshake
// synchronization. Do not use this module if you need to accept data
// faster than each 8 clk_in cycles.

`timescale 1ns / 1ns
module data_xdomain_handshake #(parameter width=13) (
  input clk_in, 
  input gate_in, // Must be synced to clk_in
  input [width-1:0] data_in, // Must be synced to clk_in
  input clk_out, 
  output reg busy=0, // Can be used for backpressure 
  output reg gate_out=0, // single clk_out cycle data valid flag
  output reg [width-1:0] data_out=0
);

// Registers needed for 2xFF synchronization of flags
// ASYNC_REG attribute makes sure the Xilinx Tool places
// synchronization registers close to each other 
// It also removes those registers from the timing analysis to relax the tool

reg [width-1:0] data_in_latch = 0;
reg request_clkin=0; // Request Flag in Clk In domain
reg ack_clkout=0; // Acknowledge Flag in Clk In domain
(* ASYNC_REG = "TRUE" *) reg [width-1:0] data_out_latch = 0;
(* ASYNC_REG = "TRUE" *) reg request_clkout=0; // Request Flag in Clk Out domain
(* ASYNC_REG = "TRUE" *) reg ack_clkin=0; // Acknowledge Flag in Clk Out domain
(* ASYNC_REG = "TRUE" *) reg sync0=0, sync1=0; 

// 2xFF for CDC for flags
always @(posedge clk_out) begin
    sync0 <= request_clkin;
    request_clkout <= sync0;
end
always @(posedge clk_in) begin
    sync1 <= ack_clkout;
    ack_clkin <= sync1;
end

// Sender FSM
reg [1:0] state_sender = 0;
always @(posedge clk_in) begin
    case(state_sender)
        4'h0: // Idle state
            if (gate_in) begin // Using level trigger
                data_in_latch <= data_in; // Latch the incoming data 
                request_clkin <= 1; // Assert request
                state_sender <= 4'h1;
                busy <= 1;
            end
            else begin
                busy <= 0;
                request_clkin <= 0;
            end
        4'h1: // Wait for ACK (coming from Receiver)
            if (ack_clkin) begin
                request_clkin <= 0; // Deassert request
                state_sender <= 4'h2;
            end
        4'h2: // Wait for deassertion of ACKx
            if (!ack_clkin) begin 
                state_sender <= 4'h0; // Transaction complete, go back to IDLE
                busy <= 0; 
            end  
        default: state_sender <= 4'h0;
    endcase
end

// Receiver FSM 
reg [1:0] state_receiver = 0;
always @(posedge clk_out) begin
    case(state_receiver)
        4'h0: // Idle state
          begin
            if (request_clkout) begin
                ack_clkout <= 1; // Assert Acknowledgement
                state_receiver <= 4'h1;
                data_out_latch <= data_in_latch; // Receive the data from sender
                gate_out <= 1; // Assert Data Ready 
            end
          end
        4'h1: 
        begin// Wait for deassertion of Request (coming from Sender)
            gate_out <= 0; // Deassert Data Ready 
            if (!request_clkout) begin
                ack_clkout <= 0; // Deassert Acknowledgement
                state_receiver <= 4'h0;
            end
          end
            
        default: state_receiver <= 4'h0;
    endcase
end

always @(*) data_out <= data_out_latch;

endmodule
