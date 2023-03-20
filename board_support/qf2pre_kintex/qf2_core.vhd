--Copyright (c) 2014-2017, Dr. John Alexander Jones, Iceberg Technology
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--- Redistributions of source code must retain the above copyright
--  notice, this list of conditions and the following disclaimer.

--- Redistributions in binary form must reproduce the above copyright
--  notice, this list of conditions and the following disclaimer in the
--  documentation and/or other materials provided with the distribution.

--- Neither the name Iceberg Technology nor the
--  names of contributors may be used to endorse or promote products
--  derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR
--ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;

--
-- async_to_sync_reset_shift
--
-- SRL-based reset circuit
--

entity async_to_sync_reset_shift is
  generic(
    LENGTH          : integer;
    INPUT_POLARITY  : std_logic := '1';
    OUTPUT_POLARITY : std_logic := '1'
    );
  port(
    clk    : in  std_logic;
    input  : in  std_logic;
    output : out std_logic
    );
end async_to_sync_reset_shift;

architecture behave of async_to_sync_reset_shift is
  signal shift : std_logic_vector(LENGTH-1 downto 0);
begin

  reset : process(input, clk)
  begin
    if (input = INPUT_POLARITY) then
      shift <= (others => OUTPUT_POLARITY);
    elsif (rising_edge(clk)) then
      shift <= shift(LENGTH-2 downto 0) & not(OUTPUT_POLARITY);
    end if;
  end process reset;

  -- Output the result on edge - helps to meet timing
  output <= shift(LENGTH-1) when rising_edge(clk);

end behave;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- tx_8b9b
--
-- 8b9b transmitter based on an SDR implementation
--
-- First bit is a sync bit like RS-232, then WORD_WIDTH data bits
-- If next bit is '0' then another word is present in the frame.
--
-- e.g.
-- ....1111111 [0]XXXXXXXX [0]XXXXXXXX [1] 111111.....
-- Would be a two-byte frame with a 12.5% coding overhead.
--
-- NOTE: This implementation can't stall the data stream, so the next word must
-- be available before it's needed. Therefore you either need to gate the
-- frame into the interface or have an incoming FIFO that runs faster than
-- the serializer, which is generally true.
--

entity tx_8b9b is
  generic (
    WORD_WIDTH : integer
    );
  port (
    -- Output clock rate
    clk : in std_logic;

    -- Serial data out
    data_out : out std_logic := '1';

    -- Parallel data in & word read strobe
    word_in        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    word_available : in  std_logic;
    frame_complete : in  std_logic;
    word_read      : out std_logic := '0'
    );
end entity tx_8b9b;

architecture behave of tx_8b9b is

  function rounded_down_power_of_two (VALUE : integer) return integer is
    variable temp : integer := VALUE;
    variable n    : integer := 0;
  begin
    while temp > 1 loop
      temp := temp / 2;
      n    := n + 1;
    end loop;
    return n;
  end function rounded_down_power_of_two;
  function next_highest_power_of_two (VALUE : integer) return integer is
    variable ret : integer;
  begin
    ret := rounded_down_power_of_two(VALUE);
    if (VALUE > (2**ret)) then
      ret := ret + 1;
    end if;
    -- NOT SURE IF THIS IS A GOOD IDEA IN THE GENERAL CASE?
    if (ret = 0) then
      ret := 1;
    end if;
    return ret;
  end function next_highest_power_of_two;

  signal int_word           : std_logic_vector(WORD_WIDTH-1 downto 0);
  signal int_frame_complete : std_logic;

  type TX_STATE is (
    IDLE,
    TRANSMIT,
    COMMIT,
    COMMIT_WAIT
    );

  signal state       : TX_STATE                                                   := IDLE;
  signal bit_counter : unsigned(next_highest_power_of_two(WORD_WIDTH)-1 downto 0) := (others => '0');

begin

  tx : process(clk)
  begin
    if (rising_edge(clk)) then

      word_read <= '0';
      data_out  <= '1';

      case state is
        when IDLE =>

          if (word_available = '1') then
            int_word           <= word_in;
            bit_counter        <= to_unsigned(WORD_WIDTH-1, next_highest_power_of_two(WORD_WIDTH));
            int_frame_complete <= frame_complete;
            word_read          <= '1';
            data_out           <= '0';
            state              <= TRANSMIT;
          end if;

        when TRANSMIT =>

          -- Copy the bits into the receive register and shift
          -- More efficient than using a counter index
          bit_counter <= bit_counter - 1;
          int_word    <= '0' & int_word(WORD_WIDTH-1 downto 1);
          data_out    <= int_word(0);

          if (bit_counter = 0) then
            state <= COMMIT;
          end if;

        when COMMIT =>

          state    <= COMMIT_WAIT;
          data_out <= '1';

          if (int_frame_complete = '0') then
            int_word           <= word_in;
            bit_counter        <= to_unsigned(WORD_WIDTH-1, next_highest_power_of_two(WORD_WIDTH));
            int_frame_complete <= frame_complete;
            word_read          <= '1';
            data_out           <= '0';
            state              <= TRANSMIT;
          end if;

        when COMMIT_WAIT =>

          state <= IDLE;

        when others =>

          state <= IDLE;

      end case;
    end if;
  end process tx;

end architecture behave;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

--
-- oversampling_rx_8b9b
--
-- 8b9b receiver based on an SDR ISERDES implementation
--
-- First it is sync, then 8 data, if first bit is '0' then another byte
-- is present in the frame.
--
-- e.g.
-- 1111111 [0]XXXXXXXX [0]XXXXXXXX [1]
-- Would be a two-byte frame
--

entity oversampling_rx_8b9b is
  generic (
    DEVICE     : string;
    WORD_WIDTH : integer
    );
  port (
    -- Async reset for ISERDES
    async_reset : in std_logic;

    -- Enable input
    enable : in std_logic := '1';

    -- Output clock rate
    clk : in std_logic;

    -- Receive SDR clock rate (x4)
    clk_4x        : in std_logic;
    serdes_strobe : in std_logic := '0';

    -- Serial data in
    data_in : in std_logic;

    -- Parallel data out
    word_out       : out std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
    word_write     : out std_logic                               := '0';
    frame_complete : out std_logic                               := '0'
    );
end entity oversampling_rx_8b9b;

architecture behave of oversampling_rx_8b9b is

  function rounded_down_power_of_two (VALUE : integer) return integer is
    variable temp : integer := VALUE;
    variable n    : integer := 0;
  begin
    while temp > 1 loop
      temp := temp / 2;
      n    := n + 1;
    end loop;
    return n;
  end function rounded_down_power_of_two;
  function next_highest_power_of_two (VALUE : integer) return integer is
    variable ret : integer;
  begin
    ret := rounded_down_power_of_two(VALUE);
    if (VALUE > (2**ret)) then
      ret := ret + 1;
    end if;
    -- NOT SURE IF THIS IS A GOOD IDEA IN THE GENERAL CASE?
    if (ret = 0) then
      ret := 1;
    end if;
    return ret;
  end function next_highest_power_of_two;
  component async_to_sync_reset_shift
    generic(
      LENGTH          : integer;
      INPUT_POLARITY  : std_logic := '1';
      OUTPUT_POLARITY : std_logic := '1'
      );
    port(
      clk    : in  std_logic;
      input  : in  std_logic;
      output : out std_logic
      );
  end component;

  signal int_bit, sync_reset, inv_clk_4x, n_start_detect : std_logic                    := '0';
  signal pre_int_data, r_int_data, int_data              : std_logic_vector(3 downto 0) := "1111";

  type RX_STATE is (
    IDLE,
    ONCE,
    RECEIVE,
    COMMIT
    );

  signal state                        : RX_STATE                                                   := IDLE;
  signal int_latch_point, latch_point : unsigned(1 downto 0)                                       := (others => '0');
  signal int_result                   : std_logic_vector(WORD_WIDTH-1 downto 0)                    := (others => '0');
  signal bit_counter                  : unsigned(next_highest_power_of_two(WORD_WIDTH)-1 downto 0) := (others => '0');

begin

  inv_clk_4x <= not(clk_4x);

  g_spartan_6 : if DEVICE = "SPARTAN 6" generate

    -- ISERDES2 receiver
    inst_iserdes : ISERDES2
      generic map (
        BITSLIP_ENABLE => false,
        DATA_RATE      => "SDR",
        DATA_WIDTH     => 4,
        INTERFACE_TYPE => "RETIMED",
        SERDES_MODE    => "NONE"
        )
      port map (
        ce0       => '1',
        clkdiv    => clk,
        clk0      => clk_4x,
        d         => data_in,
        rst       => async_reset,
        q4        => pre_int_data(3),   -- 0, 1, 2, 3
        q3        => pre_int_data(2),
        q2        => pre_int_data(1),
        q1        => pre_int_data(0),
        bitslip   => '0',
        cfb0      => open,
        cfb1      => open,
        clk1      => '0',
        dfb       => open,
        fabricout => open,
        incdec    => open,
        ioce      => serdes_strobe,
        shiftin   => '0',
        shiftout  => open,
        valid     => open

        );

  end generate g_spartan_6;

  g_kintex : if DEVICE = "KINTEX 7" generate

    -- ISERDESE2 receiver
    inst_iserdes : ISERDESE2
      generic map (
        DATA_RATE      => "SDR",
        DATA_WIDTH     => 4,
        INTERFACE_TYPE => "NETWORKING",
        IOBDELAY       => "NONE",
        NUM_CE         => 1
        )
      port map (
        clk          => clk_4x,
        clkb         => inv_clk_4x,
        clkdiv       => clk,
        d            => data_in,
        q4           => pre_int_data(0),
        q3           => pre_int_data(1),
        q2           => pre_int_data(2),
        q1           => pre_int_data(3),
        rst          => async_reset,
        clkdivp      => '0',
        ce1          => '1',
        ce2          => '0',
        oclk         => '0',            -- unused in non-memory applications
        oclkb        => '0',
        bitslip      => '0',
        shiftin1     => '0',
        shiftin2     => '0',
        ofb          => '0',
        dynclksel    => '0',
        dynclkdivsel => '0',
        ddly         => '0',
        o            => open
        );

  end generate g_kintex;

  -- int_data(0) is first to arrive, int_data(3) is last
  int_data <= pre_int_data when rising_edge(clk);

  -- Start is when the line goes low
  n_start_detect <= int_data(0) and int_data(1) and int_data(2) and int_data(3);

  -- Based on the start detect point we step one cycle later in time and latch
  -- there...
  int_latch_point <= "01" when int_data(0) = '0' else
                     "10" when int_data(1) = '0' else
                     "11" when int_data(2) = '0' else
                     "00";

  -- Retime to 'flatten' data into a single cycle as latch point "00" is a
  -- cycle out of time relative to the other three
  r_int_data <= int_data    when rising_edge(clk);
  int_bit    <= int_data(0) when latch_point = "00" else
                r_int_data(1) when latch_point = "01" else
                r_int_data(2) when latch_point = "10" else
                r_int_data(3);

  -- Hold the reset for the receiver after the ISERDES is reset for a
  -- few cycles to allow it to initialise
  inst_sync_reset_gen : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => clk,
      input  => async_reset,
      output => sync_reset
      );

  rx : process(clk)
  begin
    if (rising_edge(clk)) then
      if (sync_reset = '1') then

        word_write <= '0';

      else

        word_write     <= '0';
        frame_complete <= '0';

        case state is
          when IDLE =>

            -- Check for start bit
            if ((enable = '1') and (n_start_detect = '0')) then
              latch_point <= int_latch_point;
              bit_counter <= to_unsigned(WORD_WIDTH-1, next_highest_power_of_two(WORD_WIDTH));
              state       <= ONCE;
            end if;

          when ONCE =>

            state <= RECEIVE;

          when RECEIVE =>

            -- Copy the bits into the receive register and shift
            -- More efficient than using a counter index
            bit_counter <= bit_counter - 1;
            int_result  <= int_bit & int_result(WORD_WIDTH-1 downto 1);

            if (bit_counter = 0) then
              state <= COMMIT;
            end if;

          when COMMIT =>

            -- Check to see if the frame is complete
            word_out   <= int_result;
            word_write <= '1';

            -- If the 9th bit is '0' then the frame isn't complete
            bit_counter <= to_unsigned(WORD_WIDTH-1, next_highest_power_of_two(WORD_WIDTH));
            state       <= RECEIVE;

            if (int_bit = '1') then
              state          <= IDLE;
              frame_complete <= '1';
            end if;

          when others =>

            state <= IDLE;

        end case;
      end if;
    end if;
  end process rx;

end architecture behave;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unimacro;
use unimacro.vcomponents.FIFO_DUALCLOCK_MACRO;

library unisim;
use unisim.vcomponents.ibufds;
use unisim.vcomponents.obufds;

entity qf2_core is
  generic (
    CHANNEL_1_ENABLE   : boolean := false;
    CHANNEL_2_ENABLE   : boolean := false;
    CHANNEL_3_ENABLE   : boolean := false;
    CHANNEL_4_ENABLE   : boolean := false;
    MULTICAST_ENABLE   : boolean := false;
    CHANNEL_1_LOOPBACK : boolean := false;
    CHANNEL_2_LOOPBACK : boolean := false;
    CHANNEL_3_LOOPBACK : boolean := false;
    CHANNEL_4_LOOPBACK : boolean := false
    );
  port(
    -- Async reset, 50MHz, 200MHz
    async_reset, clk, clk_4x : in std_logic;

    -- Status signals to indicate data is being moved in / out of the FPGA
    -- (50MHz domain)
    transmitting, receiving : out std_logic;

    -- Differential pins connected to Spartan-6 - Kintex-7 bridge
    data_in_p, data_in_n   : in  std_logic;
    data_out_p, data_out_n : out std_logic;

    -- LED pass-through interface
    led_lpc_r, led_lpc_g, led_lpc_b : in std_logic := '0';
    led_hpc_r, led_hpc_g, led_hpc_b : in std_logic := '0';

    -- Channel 1 interface (port 50004)
    channel_1_inbound_data       : out std_logic_vector(7 downto 0);
    channel_1_inbound_available  : out std_logic;
    channel_1_inbound_frame_end  : out std_logic;
    channel_1_inbound_read       : in  std_logic                    := '1';
    channel_1_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_1_outbound_available : out std_logic;
    channel_1_outbound_frame_end : in  std_logic                    := '1';
    channel_1_outbound_write     : in  std_logic                    := '0';

    -- Channel 2 interface (port 50005)
    channel_2_inbound_data       : out std_logic_vector(7 downto 0);
    channel_2_inbound_available  : out std_logic;
    channel_2_inbound_frame_end  : out std_logic;
    channel_2_inbound_read       : in  std_logic                    := '1';
    channel_2_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_2_outbound_available : out std_logic;
    channel_2_outbound_frame_end : in  std_logic                    := '1';
    channel_2_outbound_write     : in  std_logic                    := '0';

    -- Channel 3 interface (port 50006)
    channel_3_inbound_data       : out std_logic_vector(7 downto 0);
    channel_3_inbound_available  : out std_logic;
    channel_3_inbound_frame_end  : out std_logic;
    channel_3_inbound_read       : in  std_logic                    := '1';
    channel_3_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_3_outbound_available : out std_logic;
    channel_3_outbound_frame_end : in  std_logic                    := '1';
    channel_3_outbound_write     : in  std_logic                    := '0';

    -- Channel 4 interface (port 50007)
    channel_4_inbound_data       : out std_logic_vector(7 downto 0);
    channel_4_inbound_available  : out std_logic;
    channel_4_inbound_frame_end  : out std_logic;
    channel_4_inbound_read       : in  std_logic                    := '1';
    channel_4_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_4_outbound_available : out std_logic;
    channel_4_outbound_frame_end : in  std_logic                    := '1';
    channel_4_outbound_write     : in  std_logic                    := '0';

    -- Multicast
    multicast_inbound_data       : out std_logic_vector(7 downto 0);
    multicast_inbound_available  : out std_logic;
    multicast_inbound_frame_end  : out std_logic;
    multicast_inbound_read       : in  std_logic                    := '1';
    multicast_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    multicast_outbound_available : out std_logic;
    multicast_outbound_frame_end : in  std_logic                    := '1';
    multicast_outbound_write     : in  std_logic                    := '0'
    );
end qf2_core;

architecture rtl of qf2_core is

  component tx_8b9b
    generic (
      WORD_WIDTH : integer
      );
    port (
      -- Output clock rate
      clk : in std_logic;

      -- Serial data out
      data_out : out std_logic := '1';

      -- Parallel data in & word read strobe
      word_in        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      word_available : in  std_logic;
      frame_complete : in  std_logic;
      word_read      : out std_logic := '0'
      );
  end component;
  component oversampling_rx_8b9b
    generic (
      DEVICE     : string;
      WORD_WIDTH : integer
      );
    port (
      -- Async reset for ISERDES
      async_reset : in std_logic;

      -- Enable input
      enable : in std_logic := '1';

      -- Output clock rate
      clk : in std_logic;

      -- Receive SDR clock rate (x4)
      clk_4x        : in std_logic;
      serdes_strobe : in std_logic := '0';

      -- Serial data in
      data_in : in std_logic;

      -- Parallel data out
      word_out       : out std_logic_vector(WORD_WIDTH-1 downto 0) := (others => '0');
      word_write     : out std_logic                               := '0';
      frame_complete : out std_logic                               := '0'
      );
  end component;

  -- State machine
  type type_inbound_state is (
    INIT,
    SWITCH,
    STREAM
    );
  type type_outbound_state is (
    INIT,
    SWITCH,
    STREAM
    );
  signal inbound_state                           : type_inbound_state           := INIT;
  signal outbound_state                          : type_outbound_state          := INIT;
  signal outbound_stream_select, outbound_target : std_logic_vector(3 downto 0) := "0000";
  signal inbound_stream_select                   : std_logic_vector(3 downto 0) := "1111";
  signal state_outbound_copy, state_inbound_copy : std_logic                    := '0';
  signal outbound_word_available                 : std_logic                    := '0';
  signal outbound_copy, outbound_empty           : std_logic;
  signal inbound_copy, inbound_full              : std_logic;
  signal data_in, data_out                       : std_logic;

  -- Bridge FIFO signals
  signal inbound_bridge_dout, inbound_bridge_din     : std_logic_vector(8 downto 0);
  signal inbound_bridge_empty                        : std_logic;
  signal inbound_bridge_write                        : std_logic;
  signal outbound_bridge_dout, outbound_bridge_din   : std_logic_vector(8 downto 0);
  signal outbound_bridge_empty, outbound_bridge_full : std_logic;
  signal outbound_bridge_read                        : std_logic;

  -- LED update signals
  signal led_outbound_read, led_outbound_empty : std_logic := '0';
  signal led_outbound_dout : std_logic_vector(8 downto 0);

  -- Channel FIFO signals
  signal channel_1_inbound_fifo_din, channel_1_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_1_inbound_fifo_write, channel_1_inbound_fifo_read   : std_logic;
  signal channel_1_inbound_fifo_full, channel_1_inbound_fifo_empty   : std_logic;
  signal channel_1_outbound_fifo_din, channel_1_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_1_outbound_fifo_write, channel_1_outbound_fifo_read : std_logic;
  signal channel_1_outbound_fifo_full, channel_1_outbound_fifo_empty : std_logic;

  signal channel_2_inbound_fifo_din, channel_2_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_2_inbound_fifo_write, channel_2_inbound_fifo_read   : std_logic;
  signal channel_2_inbound_fifo_full, channel_2_inbound_fifo_empty   : std_logic;
  signal channel_2_outbound_fifo_din, channel_2_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_2_outbound_fifo_write, channel_2_outbound_fifo_read : std_logic;
  signal channel_2_outbound_fifo_full, channel_2_outbound_fifo_empty : std_logic;

  signal channel_3_inbound_fifo_din, channel_3_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_3_inbound_fifo_write, channel_3_inbound_fifo_read   : std_logic;
  signal channel_3_inbound_fifo_full, channel_3_inbound_fifo_empty   : std_logic;
  signal channel_3_outbound_fifo_din, channel_3_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_3_outbound_fifo_write, channel_3_outbound_fifo_read : std_logic;
  signal channel_3_outbound_fifo_full, channel_3_outbound_fifo_empty : std_logic;

  signal channel_4_inbound_fifo_din, channel_4_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_4_inbound_fifo_write, channel_4_inbound_fifo_read   : std_logic;
  signal channel_4_inbound_fifo_full, channel_4_inbound_fifo_empty   : std_logic;
  signal channel_4_outbound_fifo_din, channel_4_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_4_outbound_fifo_write, channel_4_outbound_fifo_read : std_logic;
  signal channel_4_outbound_fifo_full, channel_4_outbound_fifo_empty : std_logic;

  signal multicast_inbound_fifo_din, multicast_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal multicast_inbound_fifo_write, multicast_inbound_fifo_read   : std_logic;
  signal multicast_inbound_fifo_full, multicast_inbound_fifo_empty   : std_logic;
  signal multicast_outbound_fifo_din, multicast_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal multicast_outbound_fifo_write, multicast_outbound_fifo_read : std_logic;
  signal multicast_outbound_fifo_full, multicast_outbound_fifo_empty : std_logic;

  -- Counters
  signal inbound_bridge_fifo_wrcount, inbound_bridge_fifo_rdcount         : std_logic_vector(11 downto 0);
  signal outbound_bridge_fifo_wrcount, outbound_bridge_fifo_rdcount       : std_logic_vector(11 downto 0);
  signal channel_1_inbound_fifo_wrcount, channel_1_inbound_fifo_rdcount   : std_logic_vector(11 downto 0);
  signal channel_1_outbound_fifo_wrcount, channel_1_outbound_fifo_rdcount : std_logic_vector(11 downto 0);
  signal channel_2_inbound_fifo_wrcount, channel_2_inbound_fifo_rdcount   : std_logic_vector(11 downto 0);
  signal channel_2_outbound_fifo_wrcount, channel_2_outbound_fifo_rdcount : std_logic_vector(11 downto 0);
  signal channel_3_inbound_fifo_wrcount, channel_3_inbound_fifo_rdcount   : std_logic_vector(11 downto 0);
  signal channel_3_outbound_fifo_wrcount, channel_3_outbound_fifo_rdcount : std_logic_vector(11 downto 0);
  signal channel_4_inbound_fifo_wrcount, channel_4_inbound_fifo_rdcount   : std_logic_vector(11 downto 0);
  signal channel_4_outbound_fifo_wrcount, channel_4_outbound_fifo_rdcount : std_logic_vector(11 downto 0);
  signal multicast_inbound_fifo_wrcount, multicast_inbound_fifo_rdcount   : std_logic_vector(11 downto 0);
  signal multicast_outbound_fifo_wrcount, multicast_outbound_fifo_rdcount : std_logic_vector(11 downto 0);

begin

  -- LVDS IOBs
  inst_data_in_ibufds : IBUFDS
    generic map (
      IOSTANDARD => "LVDS_25",
      DIFF_TERM  => true
      )
    port map (
      I  => data_in_p,
      IB => data_in_n,
      O  => data_in
      );
  inst_data_out_obufds : OBUFDS
    generic map (
      IOSTANDARD => "LVDS_25"
      )
    port map (
      O  => data_out_p,
      OB => data_out_n,
      I  => data_out
      );

  ---- TX
  inst_tx : tx_8b9b
    generic map (
      WORD_WIDTH => 8
      )
    port map (
      clk            => clk,
      data_out       => data_out,
      word_in        => outbound_bridge_dout(7 downto 0),
      word_available => outbound_word_available,
      frame_complete => outbound_bridge_dout(8),
      word_read      => outbound_bridge_read
      );

  transmitting <= (outbound_word_available and outbound_bridge_read) when rising_edge(clk);
  outbound_word_available <= not(outbound_bridge_empty);

  inst_outbound_bridge_fifo : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "7SERIES",
      ALMOST_FULL_OFFSET      => x"0080",
      ALMOST_EMPTY_OFFSET     => x"0080",
      DATA_WIDTH              => 9,
      FIFO_SIZE               => "36Kb",
      FIRST_WORD_FALL_THROUGH => true
      )
    port map (
      ALMOSTEMPTY => open,
      ALMOSTFULL  => open,
      DO          => outbound_bridge_dout,
      EMPTY       => outbound_bridge_empty,
      FULL        => outbound_bridge_full,
      RDCOUNT     => outbound_bridge_fifo_rdcount,
      RDERR       => open,
      WRCOUNT     => outbound_bridge_fifo_wrcount,
      WRERR       => open,
      DI          => outbound_bridge_din,
      RDCLK       => clk,
      RDEN        => outbound_bridge_read,
      RST         => async_reset,
      WRCLK       => clk,
      WREN        => outbound_copy
      );

  -- TX demux interface
  proc_tx_demux : process(clk)
  begin
    if (rising_edge(clk)) then

      state_outbound_copy <= '0';

      case outbound_state is

        when INIT =>

          if ((outbound_empty or outbound_bridge_full) = '0') then

            -- Map the target
            outbound_target        <= outbound_stream_select;
            outbound_stream_select <= "1111";
            state_outbound_copy    <= '1';
            outbound_state         <= SWITCH;

          else

            -- Check the next stream
            outbound_stream_select <= std_logic_vector(unsigned(outbound_stream_select) + 1);
            if (outbound_stream_select = "0101") then
              outbound_stream_select <= "0000";
            end if;

          end if;

        when SWITCH =>

          outbound_stream_select <= outbound_target;
          outbound_state         <= STREAM;

        when STREAM =>

          state_outbound_copy <= '1';

          if (outbound_copy = '1') then

            -- Finish on frame end
            if (outbound_bridge_din(8) = '1') then

              state_outbound_copy <= '0';
              outbound_state      <= INIT;

              -- Check the next stream
              outbound_stream_select <= std_logic_vector(unsigned(outbound_stream_select) + 1);
              if (outbound_stream_select = "0101") then
                outbound_stream_select <= "0000";
              end if;

            end if;

          end if;

        when others =>
          outbound_stream_select <= "1111";
          outbound_state         <= INIT;

      end case;

    end if;
  end process proc_tx_demux;

  outbound_copy <= (not(outbound_empty) and not(outbound_bridge_full)) and state_outbound_copy;

  outbound_empty <=
    channel_1_outbound_fifo_empty when outbound_stream_select = "0000" else
    channel_2_outbound_fifo_empty when outbound_stream_select = "0001" else
    channel_3_outbound_fifo_empty when outbound_stream_select = "0010" else
    channel_4_outbound_fifo_empty when outbound_stream_select = "0011" else
    multicast_outbound_fifo_empty when outbound_stream_select = "0100" else
    led_outbound_empty when outbound_stream_select = "0101" else
    '0';

  outbound_bridge_din <=
    channel_1_outbound_fifo_dout when outbound_stream_select = "0000" else
    channel_2_outbound_fifo_dout when outbound_stream_select = "0001" else
    channel_3_outbound_fifo_dout when outbound_stream_select = "0010" else
    channel_4_outbound_fifo_dout when outbound_stream_select = "0011" else
    multicast_outbound_fifo_dout when outbound_stream_select = "0100" else
    led_outbound_dout when outbound_stream_select = "0101" else
    ("00000" & outbound_target);

  channel_1_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0000" else '0';
  channel_2_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0001" else '0';
  channel_3_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0010" else '0';
  channel_4_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0011" else '0';
  multicast_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0100" else '0';
  led_outbound_read <= outbound_copy when outbound_stream_select = "0101" else '0';

  inst_led_update_proc : process(async_reset, clk)
  begin
    if ( async_reset = '1' ) then
      -- Initialize LED status on reset
      led_outbound_empty <= '0';
      led_outbound_dout <= "100" & led_hpc_b & led_hpc_g & led_hpc_r & led_lpc_b & led_lpc_g & led_lpc_r;
    elsif ( rising_edge(clk) ) then
      if ( led_outbound_empty = '0' ) then
        if ( led_outbound_read = '1' ) then
          led_outbound_empty <= '1';
        end if;
      elsif ( led_outbound_dout /= ("100" & led_hpc_b & led_hpc_g & led_hpc_r & led_lpc_b & led_lpc_g & led_lpc_r) ) then
        led_outbound_empty <= '0';
        led_outbound_dout <= ("100" & led_hpc_b & led_hpc_g & led_hpc_r & led_lpc_b & led_lpc_g & led_lpc_r);
      end if;
    end if;
  end process inst_led_update_proc;

  ------ RX
  ------ No flow control - can overflow in principle
  inst_rx : oversampling_rx_8b9b
    generic map (
      DEVICE     => "KINTEX 7",
      WORD_WIDTH => 8
      )
    port map (
      async_reset    => async_reset,
      clk            => clk,
      clk_4x         => clk_4x,
      enable         => '1',
      data_in        => data_in,
      word_out       => inbound_bridge_din(7 downto 0),
      word_write     => inbound_bridge_write,
      frame_complete => inbound_bridge_din(8)
      );

  receiving <= (inbound_bridge_write) when rising_edge(clk);

  inst_inbound_bridge_fifo : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "7SERIES",
      ALMOST_FULL_OFFSET      => x"0080",
      ALMOST_EMPTY_OFFSET     => x"0080",
      DATA_WIDTH              => 9,
      FIFO_SIZE               => "36Kb",
      FIRST_WORD_FALL_THROUGH => true
      )
    port map (
      ALMOSTEMPTY => open,
      ALMOSTFULL  => open,
      DO          => inbound_bridge_dout,
      EMPTY       => inbound_bridge_empty,
      FULL        => open,
      RDCOUNT     => inbound_bridge_fifo_rdcount,
      RDERR       => open,
      WRCOUNT     => inbound_bridge_fifo_wrcount,
      WRERR       => open,
      DI          => inbound_bridge_din,
      RDCLK       => clk,
      RDEN        => inbound_copy,
      RST         => async_reset,
      WRCLK       => clk,
      WREN        => inbound_bridge_write
      );

  -- RX demux interface
  proc_rx_demux : process(clk)
  begin
    if (rising_edge(clk)) then

      state_inbound_copy <= '0';

      case inbound_state is

        when INIT =>

          inbound_stream_select <= "1111";

          if (inbound_bridge_empty = '0') then
            state_inbound_copy <= '1';
            inbound_state      <= SWITCH;
          end if;

        when SWITCH =>

          inbound_stream_select <= inbound_bridge_dout(3 downto 0);
          inbound_state         <= STREAM;

        when STREAM =>

          state_inbound_copy <= '1';

          if (inbound_copy = '1') then

            -- Finish on frame end
            if (inbound_bridge_dout(8) = '1') then
              state_inbound_copy    <= '0';
              inbound_stream_select <= "1111";
              inbound_state         <= INIT;
            end if;

          end if;

        when others =>
          inbound_stream_select <= "1111";
          inbound_state         <= INIT;

      end case;

    end if;
  end process proc_rx_demux;

  inbound_copy <= (not(inbound_full) and not(inbound_bridge_empty)) and state_inbound_copy;

  -- Inbound FIFO mux control
  inbound_full <=
    channel_1_inbound_fifo_full when inbound_stream_select = "0000" else
    channel_2_inbound_fifo_full when inbound_stream_select = "0001" else
    channel_3_inbound_fifo_full when inbound_stream_select = "0010" else
    channel_4_inbound_fifo_full when inbound_stream_select = "0011" else
    multicast_inbound_fifo_full when inbound_stream_select = "0100" else
    '0';

  channel_1_inbound_fifo_write <= inbound_copy when inbound_stream_select = "0000" else '0';
  channel_2_inbound_fifo_write <= inbound_copy when inbound_stream_select = "0001" else '0';
  channel_3_inbound_fifo_write <= inbound_copy when inbound_stream_select = "0010" else '0';
  channel_4_inbound_fifo_write <= inbound_copy when inbound_stream_select = "0011" else '0';
  multicast_inbound_fifo_write <= inbound_copy when inbound_stream_select = "0100" else '0';

  -- Direct fanouts
  channel_1_inbound_fifo_din <= inbound_bridge_dout;
  channel_2_inbound_fifo_din <= inbound_bridge_dout;
  channel_3_inbound_fifo_din <= inbound_bridge_dout;
  channel_4_inbound_fifo_din <= inbound_bridge_dout;
  multicast_inbound_fifo_din <= inbound_bridge_dout;

  -----------------------------------------------------------------------------
  -- FIFO instances
  -----------------------------------------------------------------------------

  -- Only instantiate the FIFO if enabled
  g_channel_1 : if CHANNEL_1_ENABLE = true generate

    inst_channel_1_inbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_1_inbound_fifo_dout,
        EMPTY       => channel_1_inbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_1_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_1_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_1_inbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_1_inbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_1_inbound_fifo_write
        );

    inst_channel_1_outbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_1_outbound_fifo_dout,
        EMPTY       => channel_1_outbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_1_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_1_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_1_outbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_1_outbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_1_outbound_fifo_write
        );

    g_loopback_channel_1 : if CHANNEL_1_LOOPBACK = true generate

      channel_1_outbound_fifo_din   <= channel_1_inbound_fifo_dout;
      channel_1_inbound_fifo_read   <= not(channel_1_inbound_fifo_empty or channel_1_outbound_fifo_full);
      channel_1_outbound_fifo_write <= not(channel_1_inbound_fifo_empty or channel_1_outbound_fifo_full);

    end generate g_loopback_channel_1;

    g_n_loopback_channel_1 : if CHANNEL_1_LOOPBACK = false generate

      -- Mappings
      channel_1_inbound_fifo_read <= channel_1_inbound_read;
      channel_1_inbound_data      <= channel_1_inbound_fifo_dout(7 downto 0);
      channel_1_inbound_frame_end <= channel_1_inbound_fifo_dout(8);
      channel_1_inbound_available <= not(channel_1_inbound_fifo_empty);

      channel_1_outbound_fifo_din   <= channel_1_outbound_frame_end & channel_1_outbound_data;
      channel_1_outbound_available  <= not(channel_1_outbound_fifo_full);
      channel_1_outbound_fifo_write <= channel_1_outbound_write;

    end generate g_n_loopback_channel_1;

  end generate g_channel_1;

  g_n_channel_1 : if CHANNEL_1_ENABLE = false generate

    channel_1_inbound_fifo_dout  <= (others => '0');
    channel_1_inbound_fifo_empty <= '1';
    channel_1_inbound_fifo_full  <= '0';

    channel_1_outbound_fifo_dout  <= (others => '0');
    channel_1_outbound_fifo_empty <= '1';
    channel_1_outbound_fifo_full  <= '0';

  end generate g_n_channel_1;

  -- Only instantiate the FIFO if enabled
  g_channel_2 : if CHANNEL_2_ENABLE = true generate

    inst_channel_2_inbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_2_inbound_fifo_dout,
        EMPTY       => channel_2_inbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_2_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_2_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_2_inbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_2_inbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_2_inbound_fifo_write
        );

    inst_channel_2_outbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_2_outbound_fifo_dout,
        EMPTY       => channel_2_outbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_2_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_2_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_2_outbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_2_outbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_2_outbound_fifo_write
        );

    g_loopback_channel_2 : if CHANNEL_2_LOOPBACK = true generate

      channel_2_outbound_fifo_din   <= channel_2_inbound_fifo_dout;
      channel_2_inbound_fifo_read   <= not(channel_2_inbound_fifo_empty or channel_2_outbound_fifo_full);
      channel_2_outbound_fifo_write <= not(channel_2_inbound_fifo_empty or channel_2_outbound_fifo_full);

    end generate g_loopback_channel_2;

    g_n_loopback_channel_2 : if CHANNEL_2_LOOPBACK = false generate

      -- Mappings
      channel_2_inbound_fifo_read <= channel_2_inbound_read;
      channel_2_inbound_data      <= channel_2_inbound_fifo_dout(7 downto 0);
      channel_2_inbound_frame_end <= channel_2_inbound_fifo_dout(8);
      channel_2_inbound_available <= not(channel_2_inbound_fifo_empty);

      channel_2_outbound_fifo_din   <= channel_2_outbound_frame_end & channel_2_outbound_data;
      channel_2_outbound_available  <= not(channel_2_outbound_fifo_full);
      channel_2_outbound_fifo_write <= channel_2_outbound_write;

    end generate g_n_loopback_channel_2;

  end generate g_channel_2;

  g_n_channel_2 : if CHANNEL_2_ENABLE = false generate

    channel_2_inbound_fifo_dout  <= (others => '0');
    channel_2_inbound_fifo_empty <= '1';
    channel_2_inbound_fifo_full  <= '0';

    channel_2_outbound_fifo_dout  <= (others => '0');
    channel_2_outbound_fifo_empty <= '1';
    channel_2_outbound_fifo_full  <= '0';

  end generate g_n_channel_2;

  -- Only instantiate the FIFO if enabled
  g_channel_3 : if CHANNEL_3_ENABLE = true generate

    inst_channel_3_inbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_3_inbound_fifo_dout,
        EMPTY       => channel_3_inbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_3_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_3_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_3_inbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_3_inbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_3_inbound_fifo_write
        );

    inst_channel_3_outbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_3_outbound_fifo_dout,
        EMPTY       => channel_3_outbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_3_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_3_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_3_outbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_3_outbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_3_outbound_fifo_write
        );

    g_loopback_channel_3 : if CHANNEL_3_LOOPBACK = true generate

      channel_3_outbound_fifo_din   <= channel_3_inbound_fifo_dout;
      channel_3_inbound_fifo_read   <= not(channel_3_inbound_fifo_empty or channel_3_outbound_fifo_full);
      channel_3_outbound_fifo_write <= not(channel_3_inbound_fifo_empty or channel_3_outbound_fifo_full);

    end generate g_loopback_channel_3;

    g_n_loopback_channel_3 : if CHANNEL_3_LOOPBACK = false generate

      -- Mappings
      channel_3_inbound_fifo_read <= channel_3_inbound_read;
      channel_3_inbound_data      <= channel_3_inbound_fifo_dout(7 downto 0);
      channel_3_inbound_frame_end <= channel_3_inbound_fifo_dout(8);
      channel_3_inbound_available <= not(channel_3_inbound_fifo_empty);

      channel_3_outbound_fifo_din   <= channel_3_outbound_frame_end & channel_3_outbound_data;
      channel_3_outbound_available  <= not(channel_3_outbound_fifo_full);
      channel_3_outbound_fifo_write <= channel_3_outbound_write;

    end generate g_n_loopback_channel_3;

  end generate g_channel_3;

  g_n_channel_3 : if CHANNEL_3_ENABLE = false generate

    channel_3_inbound_fifo_dout  <= (others => '0');
    channel_3_inbound_fifo_empty <= '1';
    channel_3_inbound_fifo_full  <= '0';

    channel_3_outbound_fifo_dout  <= (others => '0');
    channel_3_outbound_fifo_empty <= '1';
    channel_3_outbound_fifo_full  <= '0';

  end generate g_n_channel_3;

  -- Only instantiate the FIFO if enabled
  g_channel_4 : if CHANNEL_4_ENABLE = true generate

    inst_channel_4_inbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_4_inbound_fifo_dout,
        EMPTY       => channel_4_inbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_4_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_4_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_4_inbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_4_inbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_4_inbound_fifo_write
        );

    inst_channel_4_outbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => channel_4_outbound_fifo_dout,
        EMPTY       => channel_4_outbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => channel_4_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_4_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_4_outbound_fifo_din,
        RDCLK       => clk,
        RDEN        => channel_4_outbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => channel_4_outbound_fifo_write
        );

    g_loopback_channel_4 : if CHANNEL_4_LOOPBACK = true generate

      channel_4_outbound_fifo_din   <= channel_4_inbound_fifo_dout;
      channel_4_inbound_fifo_read   <= not(channel_4_inbound_fifo_empty or channel_4_outbound_fifo_full);
      channel_4_outbound_fifo_write <= not(channel_4_inbound_fifo_empty or channel_4_outbound_fifo_full);

    end generate g_loopback_channel_4;

    g_n_loopback_channel_4 : if CHANNEL_4_LOOPBACK = false generate

      -- Mappings
      channel_4_inbound_fifo_read <= channel_4_inbound_read;
      channel_4_inbound_data      <= channel_4_inbound_fifo_dout(7 downto 0);
      channel_4_inbound_frame_end <= channel_4_inbound_fifo_dout(8);
      channel_4_inbound_available <= not(channel_4_inbound_fifo_empty);

      channel_4_outbound_fifo_din   <= channel_4_outbound_frame_end & channel_4_outbound_data;
      channel_4_outbound_available  <= not(channel_4_outbound_fifo_full);
      channel_4_outbound_fifo_write <= channel_4_outbound_write;

    end generate g_n_loopback_channel_4;

  end generate g_channel_4;

  g_n_channel_4 : if CHANNEL_4_ENABLE = false generate

    channel_4_inbound_fifo_dout  <= (others => '0');
    channel_4_inbound_fifo_empty <= '1';
    channel_4_inbound_fifo_full  <= '0';

    channel_4_outbound_fifo_dout  <= (others => '0');
    channel_4_outbound_fifo_empty <= '1';
    channel_4_outbound_fifo_full  <= '0';

  end generate g_n_channel_4;

  -- Only instantiate the FIFO if enabled
  g_multicast : if MULTICAST_ENABLE = true generate

    inst_multicast_inbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => multicast_inbound_fifo_dout,
        EMPTY       => multicast_inbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => multicast_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => multicast_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => multicast_inbound_fifo_din,
        RDCLK       => clk,
        RDEN        => multicast_inbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => multicast_inbound_fifo_write
        );

    inst_multicast_outbound_fifo : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "7SERIES",
        ALMOST_FULL_OFFSET      => x"0080",
        ALMOST_EMPTY_OFFSET     => x"0080",
        DATA_WIDTH              => 9,
        FIFO_SIZE               => "36Kb",
        FIRST_WORD_FALL_THROUGH => true
        )
      port map (
        ALMOSTEMPTY => open,
        ALMOSTFULL  => open,
        DO          => multicast_outbound_fifo_dout,
        EMPTY       => multicast_outbound_fifo_empty,
        FULL        => open,
        RDCOUNT     => multicast_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => multicast_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => multicast_outbound_fifo_din,
        RDCLK       => clk,
        RDEN        => multicast_outbound_fifo_read,
        RST         => async_reset,
        WRCLK       => clk,
        WREN        => multicast_outbound_fifo_write
        );

    -- Mappings
    multicast_inbound_fifo_read <= multicast_inbound_read;
    multicast_inbound_data      <= multicast_inbound_fifo_dout(7 downto 0);
    multicast_inbound_frame_end <= multicast_inbound_fifo_dout(8);
    multicast_inbound_available <= not(multicast_inbound_fifo_empty);

    multicast_outbound_fifo_din   <= multicast_outbound_frame_end & multicast_outbound_data;
    multicast_outbound_available  <= not(multicast_outbound_fifo_full);
    multicast_outbound_fifo_write <= multicast_outbound_write;

  end generate g_multicast;

  g_n_multicast : if MULTICAST_ENABLE = false generate

    multicast_inbound_fifo_dout  <= (others => '0');
    multicast_inbound_fifo_empty <= '1';
    multicast_inbound_fifo_full  <= '0';

    multicast_outbound_fifo_dout  <= (others => '0');
    multicast_outbound_fifo_empty <= '1';
    multicast_outbound_fifo_full  <= '0';

  end generate g_n_multicast;

end architecture rtl;
