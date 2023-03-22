`timescale 1ns / 1ns
module tx_8b9b(clk,data_out,word_in,word_available, frame_complete,word_read);
parameter WORD_WIDTH=8;
input clk;
// Serial data out
output reg data_out=1;
// Parallel data in & word read strobe
input [WORD_WIDTH-1:0] word_in;
input word_available;
input frame_complete;
output reg word_read=0;

reg [WORD_WIDTH-1:0] int_word=0;
reg int_frame_complete=0;
parameter IDLE  = 2'b00,TRANSMIT=2'b01,COMMIT=2'b10,COMMIT_WAIT=2'b11;
reg [1:0] state=0;
reg [2:0] bit_counter=0;//: unsigned(next_highest_power_of_two(WORD_WIDTH)-1 downto 0) := (others => '0');

always@(posedge clk) begin
	word_read <= 1'b0;
	data_out  <= 1'b1;
	case (state)
		IDLE: begin
			if (word_available)  begin
				int_word           <= word_in;
				bit_counter        <= (WORD_WIDTH-1);
				int_frame_complete <= frame_complete;
				word_read          <= 1'b1;
				data_out           <= 1'b0;
				state              <= TRANSMIT;
			end
		end

		TRANSMIT: begin

			// Copy the bits into the receive register and shift
			// More efficient than using a counter index
			bit_counter <= bit_counter - 1;
			int_word    <= {1'b0,int_word[WORD_WIDTH-1:1]};
			data_out    <= int_word[0];

			if (bit_counter == 0) begin
				state <= COMMIT;
			end
		end

		COMMIT : begin

			state    <= COMMIT_WAIT;
			data_out <= 1'b1;

			if (int_frame_complete == 1'b0) begin
				int_word           <= word_in;
				bit_counter        <= (WORD_WIDTH-1);
				int_frame_complete <= frame_complete;
				word_read          <= 1'b1;
				data_out           <= 1'b0;
				state              <= TRANSMIT;
			end
		end

		COMMIT_WAIT:

			state <= IDLE;

		default:

			state <= IDLE;

	endcase
end
endmodule
