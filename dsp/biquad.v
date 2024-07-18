// Biquad IIR filter
//
// y(t) = u(t)*b0 + u(t-1)*b1 + u(t-2)*b2 + y(t-1)*(-a1) + y(t-2)*(-a2)
//
// Minimizes latency by computing all but u(t)*b0 at end of previous sample.
//
// Minimizes resource consumption by using internal
// DSP registers for between-sample storage.
//
// Writing a coefficient holds the filter in reset until address 7 is written.
// This allows usage of a consistent set of coefficients.
//
module biquad #(
    parameter DATA_WIDTH        = 28,
    parameter DATA_COUNT        = 1,
    parameter COEFFICIENT_WIDTH = 25,
    parameter DEBUG             = "false"
) (
    input                         sysClk,
    input                         sysCoefficientStrobe,
    input                   [2:0] sysCoefficientAddress,
    input [COEFFICIENT_WIDTH-1:0] sysCoefficientValue,

    input                                                         dataClk,
    (*mark_debug=DEBUG*) input      [(DATA_COUNT*DATA_WIDTH)-1:0] S_TDATA,
    (*mark_debug=DEBUG*) input                                    S_TVALID,
    (*mark_debug=DEBUG*) output reg                               S_TREADY,
    (*mark_debug=DEBUG*) output reg [(DATA_COUNT*DATA_WIDTH)-1:0] M_TDATA,
    (*mark_debug=DEBUG*) output reg                               M_TVALID,
    (*mark_debug=DEBUG*) input                                    M_TREADY
);

localparam MAC_WIDEN = 4;
localparam MAC_WIDTH = DATA_WIDTH + COEFFICIENT_WIDTH + MAC_WIDEN;

// Coefficient dual-port RAM 0:b0, 1:b1, 2:b2, 3:-a2, 4:-a1
// Coefficient range [-2,2) -- i.e. two bits to the left of the binary point
reg [COEFFICIENT_WIDTH-1:0] coefficientRAM [0:4], coefficientRAMq;
reg sysReset = 1;
always @(posedge sysClk) begin
    if (sysCoefficientStrobe) begin
        if (sysCoefficientAddress <= 4) begin
            coefficientRAM[sysCoefficientAddress] <= sysCoefficientValue;
            sysReset <= 1;
        end else if (sysCoefficientAddress == 7) begin
            sysReset <= 0;
        end
    end
end

// I/O history
(*mark_debug=DEBUG*) reg [(DATA_COUNT*DATA_WIDTH)-1:0] u, uOld = 0, yOld = 0;

// MAC parameter input multiplexer
reg [2:0] state = 0;
wire [(DATA_COUNT*DATA_WIDTH)-1:0] parameterMux = (state == 1) ? u :
                                                  (state == 2) ? u :
                                                  (state == 3) ? uOld :
                                                  (state == 4) ? yOld : M_TDATA;

// Move sysReset to our clock domain
wire reset;
reg_tech_cdc reset_cdc(.I(sysReset), .C(dataClk), .O(reset));

// Computation state machine
reg enMAC = 0, ldMAC = 0;

always @(posedge dataClk) begin
    coefficientRAMq <= coefficientRAM[state];
end

always @(posedge dataClk) begin
    if (reset) begin
        state <= 0;
        u <= 0;
        uOld <= 0;
        yOld <= 0;
        S_TREADY <= 0;
        M_TVALID <= 0;
    end
    else begin
        case (state)
        0: begin
            if (S_TVALID && S_TREADY) begin
                u <= S_TDATA;
                S_TREADY <= 0;
                enMAC <= 1;
                state <= 1;
            end
            else begin
                S_TREADY <= 1;
            end
        end
        1: begin // MAC inputs: u(t), b0
                 // Multiplier inputs: y(t-1), -a1
                 // Accumulator input: y(t-2)*-a2
                 // Clip input: u(t-2)*b2 + u(t-1)*b1
                 // M_TDATA: u(t-1)*b1
            state <= 2;
        end
        2: begin // MAC inputs: u(t-1), b1 for next cycle
                 // Multiplier inputs: u(t), b0
                 // Accumulator inputx: y(t-1)*-a1
                 // Clip input: y(t-2)*-a2 + u(t-2)*b2 + u(t-1)*b1
                 // M_TDATA: u(t-2)*b2 + u(t-1)*b1
            ldMAC <= 1;
            state <= 3;
        end
        3: begin // MAC inputs: u(t-2), b2 for next cycle
                 // Multiplier inputs: u(t-1), b1 for next cycle
                 // Accumulator input: u(t)*b0
                 // Clip input: y(t-1)*a1 + y(t-2)*-a2 + u(t-2)*b2 + u(t-1)*b1
                 // M_TDATA: y(t-2)*-a2 + u(t-2)*b2 + u(t-1)*b1
                 // sload = 1
            ldMAC <= 0;
            uOld <= u;
            state <= 4;
        end
        4: begin // MAC inputs: y(t-2), -a2 for next cycle
                 // Multiplier inputs: u(t-2), b2 for next cycle
                 // Accumulator input: u(t-1)*b1 for next cycle
                 // Clip input: u(t)*b0+y(t-1)*a1+y(t-2)*-a2+u(t-2)*b2+u(t-1)*b1
                 // M_TDATA: y(t-1)*a1+y(t-2)*-a2+u(t-2)*b2+u(t-1)*b1
                 // sload_reg = 1
            M_TVALID <= 1;
            state <= 5;
        end
        5: begin // MAC inputs: y(t-1), -a1 for next cycle
                 // Multiplier inputs: y(t-2), -a2 for next cycle
                 // Accumulator input: u(t-2), b2 for next cycle
                 // Clip input: u(t-1)*b1 for next cycle
                 // M_TDATA: u(t)*b0+y(t-1)*a1+y(t-2)*-a2+u(t-2)*b2+u(t-1)*b1
                 // M_TVALID = 1
            enMAC <= 0;
            yOld <= M_TDATA;
            if (M_TREADY) begin
                M_TVALID <= 0;
                S_TREADY <= 1;
                state <= 0;
            end
        end
        default: begin
            enMAC <= 0;
            ldMAC <= 0;
            S_TREADY <= 0;
            M_TVALID <= 0;
            state <= 0;
        end
        endcase
    end
end

///////////////////////////////////////////////////////////////////////////////
// Per-lane computation
genvar i;
generate
for (i = 0 ; i < DATA_COUNT ; i = i + 1) begin
    // Instantiate multiply-accumulate module
    // Module doesn't provide a reset port so fake one by enabling
    // the module in 'load' mode with coefficients all 0.
    wire [MAC_WIDTH-1:0] accum_out;
    macc # (.SIZEA(DATA_WIDTH),
            .SIZEB(COEFFICIENT_WIDTH),
            .SIZEOUT(MAC_WIDTH))
      macc_i (
        .clk(dataClk),
        .ce(reset || enMAC),
        .sload(reset || ldMAC),
        .a(reset ? {DATA_WIDTH{1'b0}} : parameterMux[i*DATA_WIDTH+:DATA_WIDTH]),
        .b(coefficientRAMq),
        .accum_out(accum_out));

    // Clip accumulated result
    // The '-2' on the input width and input bit selection accounts
    // for the fact that the coefficient range is [-2,2).
    wire [DATA_WIDTH-1:0] accum_out_clipped;
    reduceWidth #(.IWIDTH(MAC_WIDTH-(COEFFICIENT_WIDTH-2)),
                  .OWIDTH(DATA_WIDTH))
      clipMAC (.I(accum_out[MAC_WIDTH-1:COEFFICIENT_WIDTH-2]),
               .O(accum_out_clipped));
    always @(posedge dataClk) begin
        M_TDATA[i*DATA_WIDTH+:DATA_WIDTH] <= accum_out_clipped;
    end
end
endgenerate
endmodule

///////////////////////////////////////////////////////////////////////////////
// Multiply-accumulate unit
// Template from Vivado
module macc #(
    parameter SIZEA   = 25,
              SIZEB   = 28,
              SIZEOUT = 55
) (
    input clk,
    input ce,
    input sload,
    input signed    [SIZEA-1:0] a,
    input signed    [SIZEB-1:0] b,
    output signed [SIZEOUT-1:0] accum_out
);

// Declare registers for intermediate values
reg signed       [SIZEA-1:0] a_reg;
reg signed       [SIZEB-1:0] b_reg;
reg                          sload_reg;
reg signed [SIZEA+SIZEB-1:0] mult_reg;
reg signed     [SIZEOUT-1:0] adder_out, old_result;

always @(sload_reg or adder_out)
begin
 if (sload_reg)
    old_result <= 0;
 else
  // 'sload' is now and opens the accumulation loop.
  // The accumulator takes the next multiplier output
  // in the same cycle.
    old_result <= adder_out;
end

always @(posedge clk)
 if (ce)
  begin
    a_reg     <= a;
    b_reg     <= b;
    mult_reg  <= a_reg * b_reg;
    sload_reg <= sload;
    // Store accumulation result into a register
    adder_out <= old_result + mult_reg;
 end

// Output accumulation result
assign accum_out = adder_out;

endmodule
