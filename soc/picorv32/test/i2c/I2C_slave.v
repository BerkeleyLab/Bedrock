// File I2C_slave.vhd translated with vhd2vl v2.5 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002, 2005, 2008-2010, 2015 Larry Doolittle - LBNL
//     http://doolittle.icarus.com/~larry/vhd2vl/
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//----------------------------------------------------------
// File      : I2C_slave.vhd
//----------------------------------------------------------
// Author    : Peter Samarin <peter.samarin@gmail.com>
//----------------------------------------------------------
// Copyright (c) 2016 Peter Samarin
//----------------------------------------------------------
//----------------------------------------------------------
// no timescale needed

module I2C_slave(
inout wire scl,
inout wire sda,
input wire clk,
input wire rst,
output wire read_req,
input wire [7:0] data_to_master,
output wire data_valid,
output wire [7:0] data_from_master
);

parameter [6:0] SLAVE_ADDR = 0;
// User interface



//----------------------------------------------------------
// this assumes that system's clock is much faster than SCL
parameter [2:0]
  idle = 0,
  get_address_and_cmd = 1,
  answer_ack_start = 2,
  write = 3,
  read = 4,
  read_ack_start = 5,
  read_ack_got_rising = 6,
  read_stop = 7;
  // I2C state management
reg [2:0] state_reg = idle;
reg cmd_reg = 1'b 0;
reg [31:0] bits_processed_reg = 0;
reg continue_reg = 1'b 0;
// wire scl_reg = 1'b 1;
// wire sda_reg = 1'b 1;
reg scl_reg = 1'b 1;
reg sda_reg = 1'b 1;  // Helpers to figure out next state
reg start_reg = 1'b 0;
reg stop_reg = 1'b 0;
reg scl_rising_reg = 1'b 0;
reg scl_falling_reg = 1'b 0;  // Address and data received from master
reg [6:0] addr_reg = 0;
reg [6:0] data_reg = 0;
reg [7:0] data_from_master_reg = 0;
reg scl_prev_reg = 1'b 1;  // Slave writes on scl
wire scl_wen_reg = 1'b 0;
wire scl_o_reg = 1'b 0;
reg sda_prev_reg = 1'b 1;  // Slave writes on sda
reg sda_wen_reg = 1'b 0;
reg sda_o_reg = 1'b 0;  // User interface
reg data_valid_reg = 1'b 0;
reg read_req_reg = 1'b 0;
reg [7:0] data_to_master_reg = 0;

  always @(posedge clk) begin
    // save SCL in registers that are used for debouncing
    scl_reg <= scl;
    sda_reg <= sda;
    // Delay debounced SCL and SDA by 1 clock cycle
    scl_prev_reg <= scl_reg;
    sda_prev_reg <= sda_reg;
    // Detect rising and falling SCL
    scl_rising_reg <= 1'b 0;
    if(scl_prev_reg == 1'b 0 && scl_reg == 1'b 1) begin
      scl_rising_reg <= 1'b 1;
    end
    scl_falling_reg <= 1'b 0;
    if(scl_prev_reg == 1'b 1 && scl_reg == 1'b 0) begin
      scl_falling_reg <= 1'b 1;
    end
    // Detect I2C START condition
    start_reg <= 1'b 0;
    stop_reg <= 1'b 0;
    if(scl_reg == 1'b 1 && scl_prev_reg == 1'b 1 && sda_prev_reg == 1'b 1 && sda_reg == 1'b 0) begin
      start_reg <= 1'b 1;
      stop_reg <= 1'b 0;
    end
    // Detect I2C STOP condition
    if(scl_prev_reg == 1'b 1 && scl_reg == 1'b 1 && sda_prev_reg == 1'b 0 && sda_reg == 1'b 1) begin
      start_reg <= 1'b 0;
      stop_reg <= 1'b 1;
    end
  end

  //--------------------------------------------------------
  // I2C state machine
  //--------------------------------------------------------
  always @(posedge clk) begin
    // Default assignments
    sda_o_reg <= 1'b 0;
    sda_wen_reg <= 1'b 0;
    // User interface
    data_valid_reg <= 1'b 0;
    read_req_reg <= 1'b 0;
    case(state_reg)
    idle : begin
      if(start_reg == 1'b 1) begin
        state_reg <= get_address_and_cmd;
        bits_processed_reg <= 0;
      end
    end
    get_address_and_cmd : begin
      if(scl_rising_reg == 1'b 1) begin
        if(bits_processed_reg < 7) begin
          bits_processed_reg <= bits_processed_reg + 1;
          addr_reg[6 - bits_processed_reg] <= sda_reg;
        end
        else if(bits_processed_reg == 7) begin
          bits_processed_reg <= bits_processed_reg + 1;
          cmd_reg <= sda_reg;
        end
      end
      if(bits_processed_reg == 8 && scl_falling_reg == 1'b 1) begin
        bits_processed_reg <= 0;
        if(addr_reg == SLAVE_ADDR) begin
          // check req address
          state_reg <= answer_ack_start;
          if(cmd_reg == 1'b 1) begin
            // issue read request
            read_req_reg <= 1'b 1;
            data_to_master_reg <= data_to_master;
          end
        end
        else begin
          //assert false
          $display("I2C: target/slave address mismatch (data is being sent to another slave).");
          //  severity note;
          state_reg <= idle;
        end
      end
      //--------------------------------------------------
      // I2C acknowledge to master
      //--------------------------------------------------
    end
    answer_ack_start : begin
      sda_wen_reg <= 1'b 1;
      sda_o_reg <= 1'b 0;
      if(scl_falling_reg == 1'b 1) begin
        if(cmd_reg == 1'b 0) begin
          state_reg <= write;
        end
        else begin
          state_reg <= read;
        end
      end
      //--------------------------------------------------
      // WRITE
      //--------------------------------------------------
    end
    write : begin
      if(scl_rising_reg == 1'b 1) begin
        bits_processed_reg <= bits_processed_reg + 1;
        if(bits_processed_reg < 7) begin
          data_reg[6 - bits_processed_reg] <= sda_reg;
        end
        else begin
          data_from_master_reg <= {data_reg,sda_reg};
          data_valid_reg <= 1'b 1;
        end
      end
      if(scl_falling_reg == 1'b 1 && bits_processed_reg == 8) begin
        state_reg <= answer_ack_start;
        bits_processed_reg <= 0;
      end
      //--------------------------------------------------
      // READ: send data to master
      //--------------------------------------------------
    end
    read : begin
      sda_wen_reg <= 1'b 1;
      sda_o_reg <= data_to_master_reg[7 - bits_processed_reg];
      if(scl_falling_reg == 1'b 1) begin
        if(bits_processed_reg < 7) begin
          bits_processed_reg <= bits_processed_reg + 1;
        end
        else if(bits_processed_reg == 7) begin
          state_reg <= read_ack_start;
          bits_processed_reg <= 0;
        end
      end
      //--------------------------------------------------
      // I2C read master acknowledge
      //--------------------------------------------------
    end
    read_ack_start : begin
      sda_wen_reg <= 1'b 0;
      if(scl_rising_reg == 1'b 1) begin
        state_reg <= read_ack_got_rising;
        if(sda_reg == 1'b 1) begin
          // nack = stop read
          continue_reg <= 1'b 0;
        end
        else begin
          // ack = continue read
          continue_reg <= 1'b 1;
          read_req_reg <= 1'b 1;
          // request reg byte
          data_to_master_reg <= data_to_master;
        end
      end
    end
    read_ack_got_rising : begin
      if(scl_falling_reg == 1'b 1) begin
        if(continue_reg == 1'b 1) begin
          if(cmd_reg == 1'b 0) begin
            state_reg <= write;
          end
          else begin
            state_reg <= read;
          end
        end
        else begin
          state_reg <= read_stop;
        end
      end
      // Wait for START or STOP to get out of this state
    end
    read_stop : begin
      // Wait for START or STOP to get out of this state
    end
    default : begin
      //assert false
      $display("I2C: error: ended in an impossible state.");
      //  severity error;
      state_reg <= idle;
    end
    endcase
    //------------------------------------------------------
    // Reset counter and state on start/stop
    //------------------------------------------------------
    if(start_reg == 1'b 1) begin
      state_reg <= get_address_and_cmd;
      bits_processed_reg <= 0;
    end
    if(stop_reg == 1'b 1) begin
      state_reg <= idle;
      bits_processed_reg <= 0;
    end
    if(rst == 1'b 1) begin
      state_reg <= idle;
    end
  end

  //--------------------------------------------------------
  // I2C interface
  //--------------------------------------------------------
  assign sda = sda_wen_reg ? sda_o_reg : 1'bz;
  assign scl = scl_wen_reg ? scl_o_reg : 1'bz;
  //--------------------------------------------------------
  // User interface
  //--------------------------------------------------------
  // Master writes
  assign data_valid = data_valid_reg;
  assign data_from_master = data_from_master_reg;
  // Master reads
  assign read_req = read_req_reg;

endmodule
