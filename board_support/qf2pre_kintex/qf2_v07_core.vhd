-- Copyright (c) 2014-2020, Dr. John Alexander Jones, Iceberg Technology
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

-- Redistributions of source code must retain the above copyright
-- notice, this list of conditions and the following disclaimer.

-- Redistributions in binary form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.

-- Neither the name Iceberg Technology nor the
-- names of contributors may be used to endorse or promote products
-- derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--
-- definitions
--
-- Package definitions required for the below code
--

library ieee;
use ieee.std_logic_1164.all;

package definitions is
constant link_trainer_kernel_CORE_DATA_WIDTH : integer := 8;
constant link_trainer_kernel_STACK_DEPTH : integer := 5;
constant link_trainer_kernel_FIFO_DEPTH : integer := 0;
constant link_trainer_kernel_PRAM_DEPTH : integer := 112;
constant link_trainer_kernel_C_MAX : integer := 108;
constant link_trainer_kernel_RA_MAX : integer := 7;
constant link_trainer_kernel_RB_MAX : integer := 7;
constant link_trainer_kernel_RC_MAX : integer := 7;
constant link_trainer_kernel_RD_MAX : integer := 0;
constant link_trainer_kernel_PI_MAX : integer := 1;
constant link_trainer_kernel_PO_MAX : integer := 7;
constant link_trainer_kernel_RA_INDIRECTION : std_logic := '0';
constant link_trainer_kernel_RB_INDIRECTION : std_logic := '0';
constant link_trainer_kernel_RC_INDIRECTION : std_logic := '0';
constant link_trainer_kernel_RD_INDIRECTION : std_logic := '0';
constant link_trainer_kernel_PRAM_ADDRESS_WIDTH : integer := 7;
constant link_trainer_kernel_RRAM_ADDRESS_WIDTH : integer := 3;
constant link_trainer_kernel_PORT_ADDRESS_WIDTH : integer := 3;
constant link_trainer_kernel_PRAM_DATA_WIDTH : integer := 23;
constant link_trainer_kernel_RRAM_DEPTH : integer := 7;
constant link_trainer_kernel_PORT_DEPTH : integer := 7;
constant link_trainer_kernel_C_ORIGIN : integer := 4;
constant link_trainer_kernel_C_WIDTH : integer := 7;
constant link_trainer_kernel_RA_ORIGIN : integer := 11;
constant link_trainer_kernel_RA_WIDTH : integer := 3;
constant link_trainer_kernel_RB_ORIGIN : integer := 14;
constant link_trainer_kernel_RB_WIDTH : integer := 3;
constant link_trainer_kernel_RC_ORIGIN : integer := 17;
constant link_trainer_kernel_RC_WIDTH : integer := 3;
constant link_trainer_kernel_RD_ORIGIN : integer := 20;
constant link_trainer_kernel_RD_WIDTH : integer := 0;
constant link_trainer_kernel_PI_ORIGIN : integer := 20;
constant link_trainer_kernel_PI_WIDTH : integer := 0;
constant link_trainer_kernel_PO_ORIGIN : integer := 20;
constant link_trainer_kernel_PO_WIDTH : integer := 3;
constant link_trainer_kernel_NUM_OPCODES : integer := 15;
constant link_trainer_kernel_OPCODE_WIDTH : integer := 4;
constant link_trainer_kernel_RA_INDIRECTION_ORIGIN : integer := 23;
constant link_trainer_kernel_RB_INDIRECTION_ORIGIN : integer := 23;
constant link_trainer_kernel_RC_INDIRECTION_ORIGIN : integer := 23;
constant link_trainer_kernel_RD_INDIRECTION_ORIGIN : integer := 23;
constant link_trainer_kernel_STACK_DATA_WIDTH : integer := 8;
constant link_trainer_kernel_FIFO_DATA_WIDTH : integer := 0;
constant link_trainer_kernel_PORT_DATA_WIDTH : integer := 8;
type type_link_trainer_kernel_port_array is array (integer range link_trainer_kernel_PORT_DEPTH-1 downto 0) of std_logic_vector(link_trainer_kernel_PORT_DATA_WIDTH-1 downto 0);
type type_link_trainer_kernel_rram_array is array (integer range link_trainer_kernel_RRAM_DEPTH-1 downto 0) of std_logic_vector(link_trainer_kernel_CORE_DATA_WIDTH-1 downto 0);
component link_trainer_kernel
 port (
    prog_data_in : in std_logic_vector(link_trainer_kernel_PRAM_DATA_WIDTH-1 downto 0);
    prog_data_out : out std_logic_vector(link_trainer_kernel_PRAM_DATA_WIDTH-1 downto 0);
    prog_address_in : in std_logic_vector(link_trainer_kernel_PRAM_ADDRESS_WIDTH-1 downto 0);
    port_in : in type_link_trainer_kernel_port_array;
    port_in_strobe : out std_logic_vector(link_trainer_kernel_PORT_DEPTH-1 downto 0);
    port_out : out type_link_trainer_kernel_port_array;
    port_out_strobe : out std_logic_vector(link_trainer_kernel_PORT_DEPTH-1 downto 0);
    clk, sync_reset, prog_write : in std_logic
  );
end component;
  component dp_ram
    GENERIC (
      ADDRESS_WIDTH : integer;
      DATA_WIDTH : integer;
      DEPTH : integer;
      INIT : string
      );
    PORT (
      -- main clock
      clk : in std_logic;

      -- master control for reloading the program memory from
      -- and external control interface at runtime
      master_read_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      master_write : in std_logic;
      master_write_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      master_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      master_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
    
      -- read / write strobes and addresses
      slave_read_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      slave_write : in std_logic;
      slave_write_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      slave_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      slave_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component;
  component lifo
    GENERIC (
      DATA_WIDTH : integer;
      DEPTH : integer
      );
    PORT (
      -- main clock
      clk : in std_logic;

      -- push & pop, data input and output
      push : in std_logic;
      pop : in std_logic;
      data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component;
  component op_add
    generic (
      RWIDTH : integer
      );
    PORT (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      rb : in std_logic_vector(RWIDTH-1 downto 0);
      rc : out std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;
  component op_call
    generic (
      CWIDTH : integer;
      SWIDTH : integer;
      AWIDTH : integer
      );
    port (
      c : in std_logic_vector(CWIDTH-1 downto 0);
      ai : in std_logic_vector(AWIDTH-1 downto 0);
      ao : out std_logic_vector(AWIDTH-1 downto 0);
      sto : out std_logic_vector(SWIDTH-1 downto 0)
      );
  end component;
  component op_dbrnz
    generic (
      CWIDTH : integer;
      RWIDTH : integer;
      AWIDTH : integer
      );
    port (
      c : in std_logic_vector(CWIDTH-1 downto 0);
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      ai : in std_logic_vector(AWIDTH-1 downto 0);
      ao : out std_logic_vector(AWIDTH-1 downto 0)
      );
  end component;
  component op_dbrz
    generic (
      CWIDTH : integer;
      RWIDTH : integer;
      AWIDTH : integer
      );
    port (
      c : in std_logic_vector(CWIDTH-1 downto 0);
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      ai : in std_logic_vector(AWIDTH-1 downto 0);
      ao : out std_logic_vector(AWIDTH-1 downto 0)
      );
  end component;
  component op_djmp
    generic (
      CWIDTH : integer;
      AWIDTH : integer
      );
    port (
      c : in std_logic_vector(CWIDTH-1 downto 0);
      ao : out std_logic_vector(AWIDTH-1 downto 0)
      );
  end component;
  component op_in
    generic (
      PWIDTH : integer;
      RWIDTH : integer
      );
    port (
      rc : out std_logic_vector(RWIDTH-1 downto 0);
      pi : in std_logic_vector(PWIDTH-1 downto 0)
      );
  end component;
  component op_ld
    generic (
      CWIDTH : integer;
      RWIDTH : integer
      );
    port (
      c : in std_logic_vector(CWIDTH-1 downto 0);
      rc : out std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;
  component op_mov
    generic (
      RWIDTH : integer
      );
    PORT (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      rc : out std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;  
  component op_out
    generic (
      PWIDTH : integer;
      RWIDTH : integer
      );
    port (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      po : out std_logic_vector(PWIDTH-1 downto 0)
      );
  end component;
  component op_pop
    generic (
      RWIDTH : integer;
      SWIDTH : integer
      );
    port (
      rc : out std_logic_vector(RWIDTH-1 downto 0);
      sti : in std_logic_vector(SWIDTH-1 downto 0)
      );
  end component;
  component op_push
    generic (
      RWIDTH : integer;
      SWIDTH : integer
      );
    port (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      sto : out std_logic_vector(SWIDTH-1 downto 0)
      );
  end component;
  component op_ret
    generic (
      SWIDTH : integer;
      AWIDTH : integer
      );
    port (
      ao : out std_logic_vector(AWIDTH-1 downto 0);
      sti : in std_logic_vector(SWIDTH-1 downto 0)
      );
  end component;
  component op_shr
    generic (
      RWIDTH : integer
      );
    port (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      rc : out std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;
  component op_sub
    generic (
      RWIDTH : integer
      );
    PORT (
      ra : in std_logic_vector(RWIDTH-1 downto 0);
      rb : in std_logic_vector(RWIDTH-1 downto 0);
      rc : out std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;
  component op_test_unsigned_gt
    generic (
      RWIDTH : integer
      );
    port (
      ra : in  std_logic_vector(RWIDTH-1 downto 0);
      rb : in  std_logic_vector(RWIDTH-1 downto 0);
      rc : out  std_logic_vector(RWIDTH-1 downto 0)
      );
  end component;
  end definitions;

--
-- dp_ram
--
  
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY dp_ram IS
  GENERIC (
    ADDRESS_WIDTH : integer;
    DATA_WIDTH : integer;
    DEPTH : integer;
    INIT : string
    );
  PORT (
    -- main clock
    clk : in std_logic;

    -- master control for reloading the program memory from
    -- and external control interface at runtime
    master_read_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    master_write : in std_logic;
    master_write_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    master_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    master_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    -- read / write strobes and addresses
    slave_read_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    slave_write : in std_logic;
    slave_write_address : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    slave_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
    );
END ENTITY dp_ram;

architecture rtl OF dp_ram is 

  type type_ram_array is array (integer range DEPTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  
  function dp_ram_init_null (A : integer; B : integer) return type_ram_array is
    variable RES : type_ram_array;
  begin
    for I in A-1 downto 0 loop
      for J in B-1 downto 0 loop
        RES(I)(J) := '0';
      end loop;
    end loop;
    return RES;
  end dp_ram_init_null;

  function string_to_slv(s : string) return std_logic_vector is
    variable ret_slv : std_logic_vector(s'length-1 downto 0);
  begin
    for i in 1 to s'length loop
      if s(i) = '0' then
        ret_slv(i-1) := '0';
      elsif s(i) = '1' then
        ret_slv(i-1) := '1';
      else
        --catch bad characters
        ret_slv(i-1) := 'X';
      end if;
    end loop;
    return ret_slv;
  end string_to_slv;

  function dp_ram_init (A : integer; B : integer; INIT : string) return type_ram_array is
    variable RES : type_ram_array;
    variable slv : std_logic_vector(A*B-1 downto 0);
  begin
    if INIT'length = 0 then
      RES := dp_ram_init_null(A,B);
    else
      slv := string_to_slv(INIT);
      for I in A-1 downto 0 loop
        for J in B-1 downto 0 loop
          RES(I)(J) := slv(I*B+(B-1-J));
        end loop;
      end loop;
    end if;
    return RES;
  end dp_ram_init;

  -- define the ram array
  signal int_ram_array : type_ram_array := dp_ram_init(DEPTH,DATA_WIDTH, INIT);

  -- control signals for the ram
  -- split read, interlocked write
  signal int_write : std_logic;
  signal int_write_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal int_write_data : std_logic_vector(DATA_WIDTH-1 downto 0);

BEGIN

    -- slave read
  slave_data_out <= int_ram_array(to_integer(unsigned(slave_read_address))) when rising_edge(clk);
  
  -- master read
  master_data_out <= int_ram_array(to_integer(unsigned(master_read_address))) when rising_edge(clk);

  -- interlocked write (master_write must keep at '0' if slave is not halted)
  int_write <= slave_write or master_write;
  int_write_address <= master_write_address when master_write = '1'
                       else slave_write_address;
  int_write_data <= master_data_in when master_write = '1'
                    else slave_data_in;

  write_process : process(clk)
  begin
    if rising_edge(clk) then
      if int_write = '1' then
        int_ram_array(to_integer(unsigned(int_write_address))) <= int_write_data;
      end if;
    end if;
  end process write_process;

END ARCHITECTURE rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lifo is
  generic (
    DATA_WIDTH : integer;
    DEPTH      : integer
    );
  port (
    -- clock
    clk : in std_logic;

    -- push & pop, data input and output
    push     : in  std_logic;
    pop      : in  std_logic;
    data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity lifo;

architecture rtl of lifo is

  -- lifo shift array
  signal lifo_array : std_logic_vector((DEPTH * DATA_WIDTH) - 1 downto 0) := (others => '0');
  
begin

  data_out <= lifo_array(DATA_WIDTH-1 downto 0);

  shift_process : process(clk)
  begin
    if rising_edge(clk) then
      if push = '1' then
        lifo_array <= lifo_array(((DEPTH-1) * DATA_WIDTH) - 1 downto 0) & data_in;
      elsif pop = '1' then
        lifo_array <= std_logic_vector(to_unsigned(0, DATA_WIDTH)) & lifo_array((DEPTH * DATA_WIDTH) - 1 downto DATA_WIDTH);
      end if;
    end if;
  end process shift_process;

end architecture rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_add IS
  generic (
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    rb : in std_logic_vector(RWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_add;

ARCHITECTURE rtl OF op_add is   
  signal int_q : std_logic_vector(RWIDTH downto 0);
  signal int_d_a : std_logic_vector(RWIDTH downto 0);
  signal int_d_b : std_logic_vector(RWIDTH downto 0);
BEGIN

  int_d_a <= '0' & ra;
  int_d_b <= '0' & rb;
  
  -- add a to b and assign to q
  int_q <= std_logic_vector(unsigned(int_d_a) + unsigned(int_d_b));

  -- output result
  rc <= int_q(RWIDTH-1 downto 0);
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_call IS
  generic (
    CWIDTH : integer;
    SWIDTH : integer;
    AWIDTH : integer
    );
  PORT (
    c : in std_logic_vector(CWIDTH-1 downto 0);
    ai : in std_logic_vector(AWIDTH-1 downto 0);
    ao : out std_logic_vector(AWIDTH-1 downto 0);
    sto : out std_logic_vector(SWIDTH-1 downto 0)
    );
END ENTITY op_call;

ARCHITECTURE rtl OF op_call is   
BEGIN

  glt1: if CWIDTH > AWIDTH generate
    ao <= c(AWIDTH-1 downto 0);
  end generate glt1;
  geq1: if CWIDTH = AWIDTH generate
    ao <= c;
  end generate geq1;
  ggt1: if CWIDTH < AWIDTH generate
    ao <= std_logic_vector(to_unsigned(0, AWIDTH-CWIDTH)) & c;
  end generate ggt1;

  glt2: if SWIDTH > AWIDTH generate
    sto <= std_logic_vector(to_unsigned(0, SWIDTH-AWIDTH)) & ai;
  end generate glt2;
  geq2: if SWIDTH = AWIDTH generate
    sto <= ai;
  end generate geq2;
  ggt2: if SWIDTH < AWIDTH generate
    sto <= ai(SWIDTH-1 downto 0);
  end generate ggt2;

END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_dbrnz IS
  generic (
    RWIDTH : integer;
    CWIDTH : integer;
    AWIDTH : integer
    );
  PORT (
    c : in std_logic_vector(CWIDTH-1 downto 0);
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    ai : in std_logic_vector(AWIDTH-1 downto 0);
    ao : out std_logic_vector(AWIDTH-1 downto 0)
    );
END ENTITY op_dbrnz;

ARCHITECTURE rtl OF op_dbrnz is
  signal condition : std_logic;
BEGIN

  condition <= '1' when ra /= std_logic_vector(to_unsigned(0, RWIDTH)) else '0';

  glt: if CWIDTH < AWIDTH generate
    ao <= std_logic_vector(to_unsigned(0, AWIDTH-CWIDTH)) & c when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate glt;
  geq: if CWIDTH = AWIDTH generate
    ao <= c when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate geq;
  ggt: if CWIDTH > AWIDTH generate
    ao <= c(AWIDTH-1 downto 0) when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate ggt;

END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_dbrz IS
  generic (
    CWIDTH : integer;
    RWIDTH : integer;
    AWIDTH : integer
    );
  PORT (
    c : in std_logic_vector(CWIDTH-1 downto 0);
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    ai : in std_logic_vector(AWIDTH-1 downto 0);
    ao : out std_logic_vector(AWIDTH-1 downto 0)
    );
END ENTITY op_dbrz;

ARCHITECTURE rtl OF op_dbrz is
  signal condition : std_logic;
BEGIN

  condition <= '1' when ra = std_logic_vector(to_unsigned(0, RWIDTH)) else '0';

  glt: if CWIDTH < AWIDTH generate
    ao <= std_logic_vector(to_unsigned(0, AWIDTH-CWIDTH)) & c when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate glt;
  geq: if CWIDTH = AWIDTH generate
    ao <= c when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate geq;
  ggt: if CWIDTH > AWIDTH generate
    ao <= c(AWIDTH-1 downto 0) when condition = '1' else std_logic_vector(unsigned(ai)+1);
  end generate ggt;

END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_djmp IS
  generic (
    CWIDTH : integer;
    AWIDTH : integer
    );
  PORT (
    c : in std_logic_vector(CWIDTH-1 downto 0);
    ao : out std_logic_vector(AWIDTH-1 downto 0)
    );
END ENTITY op_djmp;

ARCHITECTURE rtl OF op_djmp is   
BEGIN
  glt: if CWIDTH < AWIDTH generate
    ao <= std_logic_vector(to_unsigned(0, AWIDTH-CWIDTH)) & c;
  end generate glt;
  geq: if CWIDTH = AWIDTH generate
    ao <= c;
  end generate geq;
  ggt: if CWIDTH > AWIDTH generate
    ao <= c(AWIDTH-1 downto 0);
  end generate ggt;
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_in IS
  generic (
    PWIDTH : integer;
    RWIDTH : integer
    );
  PORT (
    rc : out std_logic_vector(RWIDTH-1 downto 0);
    pi : in std_logic_vector(PWIDTH-1 downto 0)
    );
END ENTITY op_in;

ARCHITECTURE rtl OF op_in is   
BEGIN

  glt: if PWIDTH < RWIDTH generate
    rc <= std_logic_vector(to_unsigned(0, RWIDTH-PWIDTH)) & pi;
  end generate glt;
  geq: if PWIDTH = RWIDTH generate
    rc <= pi;
  end generate geq;
  ggt: if PWIDTH > RWIDTH generate
    rc <= pi(RWIDTH-1 downto 0);
  end generate ggt;

END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_ld IS
  generic (
    CWIDTH : integer;
    RWIDTH : integer
    );
  PORT (
    c : in std_logic_vector(CWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_ld;

ARCHITECTURE rtl OF op_ld is   
BEGIN

  glt: if CWIDTH < RWIDTH generate
    rc <= std_logic_vector(to_unsigned(0, RWIDTH-CWIDTH)) & c;
  end generate glt;
  geq: if CWIDTH = RWIDTH generate
    rc <= c;
  end generate geq;
  ggt: if CWIDTH > RWIDTH generate
    rc <= c(RWIDTH-1 downto 0);
  end generate ggt;
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY op_mov IS
  generic (
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_mov;

ARCHITECTURE rtl OF op_mov is   
BEGIN

  rc <= ra;
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_out IS
  generic (
    PWIDTH : integer;
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    po : out std_logic_vector(PWIDTH-1 downto 0)
    );
END ENTITY op_out;

ARCHITECTURE rtl OF op_out is   
BEGIN

  glt: if PWIDTH > RWIDTH generate
    po <= std_logic_vector(to_unsigned(0, PWIDTH-RWIDTH)) & ra;
  end generate glt;
  geq: if PWIDTH = RWIDTH generate
    po <= ra;
  end generate geq;
  ggt: if PWIDTH < RWIDTH generate
    po <= ra(PWIDTH-1 downto 0);
  end generate ggt;
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_pop IS
  generic (
    SWIDTH : integer;
    RWIDTH : integer
    );
  PORT (
    rc : out std_logic_vector(RWIDTH-1 downto 0);
    sti : in std_logic_vector(SWIDTH-1 downto 0)
    );
END ENTITY op_pop;

ARCHITECTURE rtl OF op_pop is   
BEGIN
  glt: if RWIDTH > SWIDTH generate
    rc <= std_logic_vector(to_unsigned(0, RWIDTH-SWIDTH)) & sti;
  end generate glt;
  geq: if SWIDTH = RWIDTH generate
    rc <= sti;
  end generate geq;
  ggt: if RWIDTH < SWIDTH generate
    rc <= sti(RWIDTH-1 downto 0);
  end generate ggt;
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_push IS
  generic (
    RWIDTH : integer;
    SWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    sto : out std_logic_vector(SWIDTH-1 downto 0)
    );
END ENTITY op_push;

ARCHITECTURE rtl OF op_push is   
BEGIN

  glt2: if SWIDTH > RWIDTH generate
    sto <= std_logic_vector(to_unsigned(0, SWIDTH-RWIDTH)) & ra;
  end generate glt2;
  geq2: if SWIDTH = RWIDTH generate
    sto <= ra;
  end generate geq2;
  ggt2: if SWIDTH < RWIDTH generate
    sto <= ra(SWIDTH-1 downto 0);
  end generate ggt2;

END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_ret IS
  generic (
    SWIDTH : integer;
    AWIDTH : integer
    );
  PORT (
    ao : out std_logic_vector(AWIDTH-1 downto 0);
    sti : in std_logic_vector(SWIDTH-1 downto 0)
    );
END ENTITY op_ret;

ARCHITECTURE rtl OF op_ret is   
BEGIN
  glt: if AWIDTH > SWIDTH generate
    ao <= std_logic_vector(unsigned(std_logic_vector(to_unsigned(0, AWIDTH-SWIDTH)) & sti) + 1);
  end generate glt;
  geq: if SWIDTH = AWIDTH generate
    ao <= std_logic_vector(unsigned(sti) + 1);
  end generate geq;
  ggt: if AWIDTH < SWIDTH generate
    ao <= std_logic_vector(unsigned(sti(AWIDTH-1 downto 0)) + 1);
  end generate ggt;
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_shr IS
  generic (
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_shr;

ARCHITECTURE rtl OF op_shr is   
BEGIN

  -- rotate bits
  rc(RWIDTH-2 downto 0) <= ra(RWIDTH-1 downto 1);
  rc(RWIDTH-1) <= '0';
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY op_sub IS
  generic (
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    rb : in std_logic_vector(RWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_sub;

ARCHITECTURE rtl OF op_sub is   
  signal int_q : std_logic_vector(RWIDTH downto 0);
  signal int_d_a : std_logic_vector(RWIDTH downto 0);
  signal int_d_b : std_logic_vector(RWIDTH downto 0);
BEGIN

  int_d_a <= '0' & ra;
  int_d_b <= '0' & rb;
  
  -- add a to b and assign to q
  int_q <= std_logic_vector(unsigned(int_d_b) - unsigned(int_d_a));

  -- output result
  rc <= int_q(RWIDTH-1 downto 0);
  
END ARCHITECTURE rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY op_test_unsigned_gt IS
  generic (
    RWIDTH : integer
    );
  PORT (
    ra : in std_logic_vector(RWIDTH-1 downto 0);
    rb : in std_logic_vector(RWIDTH-1 downto 0);
    rc : out std_logic_vector(RWIDTH-1 downto 0)
    );
END ENTITY op_test_unsigned_gt;

ARCHITECTURE rtl OF op_test_unsigned_gt is
BEGIN

  -- unsigned greater than flag
  rc(RWIDTH-1 downto 1) <= (others => '0');
  rc(0) <= '1' when unsigned(rb) > unsigned(ra) else '0';
  
END ARCHITECTURE rtl;

--
-- async_to_sync_reset_shift
--
-- SRL-based reset circuit
--

library ieee;
use ieee.std_logic_1164.all;

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

architecture rtl of async_to_sync_reset_shift is
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

end rtl;

--
-- link_trainer_kernel
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library qf2_pre;
use qf2_pre.definitions.all;
entity link_trainer_kernel is
  port (
    prog_data_in : in std_logic_vector(22 downto 0);
    prog_data_out : out std_logic_vector(22 downto 0);
    prog_address_in : in std_logic_vector(6 downto 0);
    port_in : in type_link_trainer_kernel_port_array;
    port_in_strobe : out std_logic_vector(6 downto 0);
    port_out : out type_link_trainer_kernel_port_array;
    port_out_strobe : out std_logic_vector(6 downto 0);
    clk, sync_reset, prog_write : in std_logic
);
end entity link_trainer_kernel;
architecture v1 of link_trainer_kernel is
constant CORE_DATA_WIDTH : integer := link_trainer_kernel_CORE_DATA_WIDTH;
constant STACK_DATA_WIDTH : integer := link_trainer_kernel_STACK_DATA_WIDTH;
constant FIFO_DATA_WIDTH : integer := link_trainer_kernel_FIFO_DATA_WIDTH;
constant PORT_DATA_WIDTH : integer := link_trainer_kernel_PORT_DATA_WIDTH;
constant STACK_DEPTH : integer := link_trainer_kernel_STACK_DEPTH;
constant FIFO_DEPTH : integer := link_trainer_kernel_FIFO_DEPTH;
constant PRAM_DEPTH : integer := link_trainer_kernel_PRAM_DEPTH;
constant C_MAX : integer := link_trainer_kernel_C_MAX;
constant RA_MAX : integer := link_trainer_kernel_RA_MAX;
constant RB_MAX : integer := link_trainer_kernel_RB_MAX;
constant RC_MAX : integer := link_trainer_kernel_RC_MAX;
constant RD_MAX : integer := link_trainer_kernel_RD_MAX;
constant PI_MAX : integer := link_trainer_kernel_PI_MAX;
constant PO_MAX : integer := link_trainer_kernel_PO_MAX;
constant RA_INDIRECTION : std_logic := link_trainer_kernel_RA_INDIRECTION;
constant RB_INDIRECTION : std_logic := link_trainer_kernel_RB_INDIRECTION;
constant RC_INDIRECTION : std_logic := link_trainer_kernel_RC_INDIRECTION;
constant RD_INDIRECTION : std_logic := link_trainer_kernel_RD_INDIRECTION;
constant PRAM_ADDRESS_WIDTH : integer := link_trainer_kernel_PRAM_ADDRESS_WIDTH;
constant RRAM_ADDRESS_WIDTH : integer := link_trainer_kernel_RRAM_ADDRESS_WIDTH;
constant PORT_ADDRESS_WIDTH : integer := link_trainer_kernel_PORT_ADDRESS_WIDTH;
constant PRAM_DATA_WIDTH : integer := link_trainer_kernel_PRAM_DATA_WIDTH;
constant RRAM_DEPTH : integer := link_trainer_kernel_RRAM_DEPTH;
constant PORT_DEPTH : integer := link_trainer_kernel_PORT_DEPTH;
constant C_ORIGIN : integer := link_trainer_kernel_C_ORIGIN;
constant C_WIDTH : integer := link_trainer_kernel_C_WIDTH;
constant RA_ORIGIN : integer := link_trainer_kernel_RA_ORIGIN;
constant RA_WIDTH : integer := link_trainer_kernel_RA_WIDTH;
constant RB_ORIGIN : integer := link_trainer_kernel_RB_ORIGIN;
constant RB_WIDTH : integer := link_trainer_kernel_RB_WIDTH;
constant RC_ORIGIN : integer := link_trainer_kernel_RC_ORIGIN;
constant RC_WIDTH : integer := link_trainer_kernel_RC_WIDTH;
constant RD_ORIGIN : integer := link_trainer_kernel_RD_ORIGIN;
constant RD_WIDTH : integer := link_trainer_kernel_RD_WIDTH;
constant PI_ORIGIN : integer := link_trainer_kernel_PI_ORIGIN;
constant PI_WIDTH : integer := link_trainer_kernel_PI_WIDTH;
constant PO_ORIGIN : integer := link_trainer_kernel_PO_ORIGIN;
constant PO_WIDTH : integer := link_trainer_kernel_PO_WIDTH;
constant RA_INDIRECTION_ORIGIN : integer := link_trainer_kernel_RA_INDIRECTION_ORIGIN;
constant RB_INDIRECTION_ORIGIN : integer := link_trainer_kernel_RB_INDIRECTION_ORIGIN;
constant RC_INDIRECTION_ORIGIN : integer := link_trainer_kernel_RC_INDIRECTION_ORIGIN;
constant RD_INDIRECTION_ORIGIN : integer := link_trainer_kernel_RD_INDIRECTION_ORIGIN;
constant NUM_OPCODES : integer := link_trainer_kernel_NUM_OPCODES;
constant OPCODE_WIDTH : integer := link_trainer_kernel_OPCODE_WIDTH;
signal po_unlatched : std_logic_vector(PORT_DATA_WIDTH-1 downto 0) := (others => '0');
signal po_latched : std_logic_vector(PORT_DATA_WIDTH-1 downto 0) := (others => '0');
signal po_mux : std_logic_vector(PORT_DATA_WIDTH-1 downto 0) := (others => '0');
signal po_write : std_logic := '0';
signal po_write_pulse : std_logic := '0';
signal pi_read : std_logic := '0';
signal pi_read_pulse : std_logic := '0';
signal pi : std_logic_vector(PORT_DATA_WIDTH-1 downto 0) := (others => '0');
signal ra : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rb : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_unlatched : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_latched : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_write : std_logic := '0';
signal rc_write_pulse : std_logic := '0';
signal rd : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rd_unlatched : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rd_latched : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rd_write : std_logic := '0';
signal rd_write_pulse : std_logic := '0';
signal opcode_finish : std_logic := '0';
signal opcode_start : std_logic := '0';
signal ai : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal pram_prefetch_data : std_logic_vector(PRAM_DATA_WIDTH-1 downto 0) := (others => '0');
signal int_prog_data_out : std_logic_vector(PRAM_DATA_WIDTH-1 downto 0) := (others => '0');
signal pram_master_read_address : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal ra_rc_cache_address_match : std_logic := '0';
signal ra_rd_cache_address_match : std_logic := '0';
signal rb_rc_cache_address_match : std_logic := '0';
signal rb_rd_cache_address_match : std_logic := '0';
signal rc_cache_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rd_cache_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rc_cache_data : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rd_cache_data : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal ra_from_rram : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rb_from_rram : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal pram_address : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal pram_address_inc : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal pram_address_delayed : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal next_pram_address : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal pram_data : std_logic_vector(PRAM_DATA_WIDTH-1 downto 0) := (others => '0');
type processor_state is (
PRAM_ALIGN,
OPCODE_WITH_LOOKAHEAD,
OPCODE_WITH_INDIRECT_READ,
OPCODE_WITH_INDIRECT_WRITE
);
signal current_state, next_state : processor_state;
signal pram_alignment_required, indirect_read_required, indirect_write_required : std_logic;
signal do_indirect_read, do_indirect_write, ao_op_valid : std_logic;
signal ao_op : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0);
signal do_ra_indirect_delay, do_rb_indirect_delay : std_logic;
signal ra_indirect, rb_indirect, rc_indirect, rd_indirect : std_logic := '0';
signal do_ra_indirect, do_rb_indirect, do_rc_indirect, do_rd_indirect : std_logic := '0';
signal delayed_write : std_logic := '0';
signal write_latch : std_logic := '0';
signal fifo_push : std_logic := '0';
signal fifo_push_mux : std_logic := '0';
signal fifo_pop : std_logic := '0';
signal fifo_pop_mux : std_logic := '0';
signal st_push : std_logic := '0';
signal st_push_mux : std_logic := '0';
signal st_pop : std_logic := '0';
signal st_pop_mux : std_logic := '0';
signal ti : std_logic := '0';
signal gnd : std_logic := '0';
signal gnd_pram_address : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal gnd_pram_data : std_logic_vector(PRAM_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_add : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal ao_op_call : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal sto_op_call : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal ao_op_dbrnz : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal ao_op_dbrz : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal ao_op_djmp : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rc_op_in : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_ld : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_mov : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal po_op_out : std_logic_vector(PORT_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_pop : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal sto_op_push : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal ao_op_ret : std_logic_vector(PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rc_op_shr : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_sub : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal rc_op_test_unsigned_gt : std_logic_vector(CORE_DATA_WIDTH-1 downto 0) := (others => '0');
signal ra_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rb_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rc_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal rd_address : std_logic_vector(RRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal po_address : std_logic_vector(PO_WIDTH-1 downto 0) := (others => '0');
signal sto : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal sto_latched : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal sto_unlatched : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal sti : std_logic_vector(STACK_DATA_WIDTH-1 downto 0) := (others => '0');
signal opcode : std_logic_vector(OPCODE_WIDTH-1 downto 0) := (others => '0');
signal c : std_logic_vector(C_WIDTH-1 downto 0) := (others => '0');
constant OPCODE_add : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(0, OPCODE_WIDTH));
constant OPCODE_call : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, OPCODE_WIDTH));
constant OPCODE_dbrnz : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(2, OPCODE_WIDTH));
constant OPCODE_dbrz : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(3, OPCODE_WIDTH));
constant OPCODE_djmp : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(4, OPCODE_WIDTH));
constant OPCODE_in : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(5, OPCODE_WIDTH));
constant OPCODE_ld : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(6, OPCODE_WIDTH));
constant OPCODE_mov : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(7, OPCODE_WIDTH));
constant OPCODE_out : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(8, OPCODE_WIDTH));
constant OPCODE_pop : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(9, OPCODE_WIDTH));
constant OPCODE_push : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(10, OPCODE_WIDTH));
constant OPCODE_ret : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(11, OPCODE_WIDTH));
constant OPCODE_shr : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(12, OPCODE_WIDTH));
constant OPCODE_sub : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(13, OPCODE_WIDTH));
constant OPCODE_test_unsigned_gt : std_logic_vector(OPCODE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(14, OPCODE_WIDTH));
begin
opcode <= pram_data(OPCODE_WIDTH-1 downto 0);
c <= pram_data(C_WIDTH-1+C_ORIGIN downto C_ORIGIN);
pi <= port_in(0);
port_in_strobes : process(clk)
begin
  if ( rising_edge(clk) ) then
    port_in_strobe <= (others => '0');
    if ( pi_read_pulse = '1' ) then
      port_in_strobe(0) <= '1';
    end if;
  end if;
end process port_in_strobes;
po_address <= pram_data(PO_WIDTH-1+PO_ORIGIN downto PO_ORIGIN);
port_out_strobes : process(clk)
begin
  if ( rising_edge(clk) ) then
    port_out_strobe <= (others => '0');
    if ( po_write_pulse = '1' ) then
      port_out_strobe(to_integer(unsigned(po_address))) <= '1';
      port_out(to_integer(unsigned(po_address))) <= po_mux;
    end if;
  end if;
end process port_out_strobes;
po_mux <= po_unlatched when delayed_write = '0' else po_latched;
ra_address <= pram_prefetch_data(RA_WIDTH-1+RA_ORIGIN downto RA_ORIGIN);
rb_address <= pram_prefetch_data(RB_WIDTH-1+RB_ORIGIN downto RB_ORIGIN);
rc_address <= pram_data(RC_WIDTH-1+RC_ORIGIN downto RC_ORIGIN);
pram_inst : dp_ram
  generic map (
    ADDRESS_WIDTH => PRAM_ADDRESS_WIDTH,
    DATA_WIDTH    => PRAM_DATA_WIDTH,
    DEPTH         => PRAM_DEPTH,
    INIT          => b"00000000000000000000110000000000000000000010000100000000000000000100001100000000000000001000100000000000000000010001010000000000000000100000001000000000111110110000101000000000000001100001100000000000000011000001100000000000000110000100000000000000001100010000000100000000100000000000000010100110001000000000000010010000100000000000000000000011011000000000000000001000000000110010000000011010000010000000000010011000000000000100000001101000000000000001100100110000000000100101110001100000000000000000010110000010010000000000011010010000000100000000100000000000000000011000100000000101110000000011010000010111000000000110100000000000100000001110000000000000001111100110000110001010000000011100010000011000000000111000101000000000000001100100000001010000000100000011000000000000000110011000000110000000010000000000000000010100010000000000000000000010110110000000000000000010000000000000000000001011000000000001000000000000000000000101010101100100001010000000000000011101000000010100000001000000110000000000000001110110000001100000000100000000000000000101000100000000000110100010100110000000000000100000011000000001100000000001101000000000000011100100110000001011100000000110100000101110000000001101000000000001000000011100000000000001000101001100001100010100000000111000100000110000000001110000000000001000101010010000000010100000001000101000000110000000010000000000000000011101011000000010100000000000000000000100000000000000000000000000000000000110000000100000000111110110000001000001000000011100000000000011001100001100000100000000111110110000000000001000000011010000000000001001100010000000000010000000000011010000000011000000010000110000001000000000100000000010001100000000000000001000000000001001100000000000010000000110100000000000000000001100001000000000000000010000000000000001010011000100000000000000001000110000000000000000000010000000000000000000000010100000000000000000000010000000000000101000001000000010000000001010011000000000000111001010011000000000000000001001100000000000000000000100000000000000000000000110000000000000000000010000000000000001100111000100000000000000000010110000000000000000000010000000000000000000000011000000000000000000001000000000000000110011100010000000000000000001011000000100100000000001101000000000000000000001010000000000001010100001000000000000000000010110000000000000000000010110000000000000000000011000000000000000000001011000000000000000000010100000000000010000000101000000000000000001010110000001000000000000101100000000000010000000110100000000000011010110010000001000000000000010010000000000000000000100100000000000000000001011")
  port map (
    clk => clk,
    master_read_address => pram_master_read_address,
    master_write_address => prog_address_in,
    master_write => prog_write,
    master_data_in => prog_data_in,
    master_data_out => int_prog_data_out,
    slave_write => gnd,
    slave_write_address => gnd_pram_address,
    slave_data_in => gnd_pram_data,
    slave_data_out => pram_data,
    slave_read_address => pram_address
);
pram_master_read_address <= prog_address_in when sync_reset = '1' else next_pram_address;
pram_prefetch_data <= int_prog_data_out;
prog_data_out <= int_prog_data_out;
rram_inst : dp_ram
  generic map (
    ADDRESS_WIDTH => RRAM_ADDRESS_WIDTH,
    DATA_WIDTH    => CORE_DATA_WIDTH,
    DEPTH         => RRAM_DEPTH,
    INIT          => "")
  port map (
    clk => clk,
    master_read_address => ra_address,
    master_write_address => rc_address,
    master_write => rc_write_pulse,
    master_data_in => rc,
    master_data_out => ra_from_rram,
    slave_write => rd_write_pulse,
    slave_write_address => rd_address,
    slave_data_in => rd,
    slave_data_out => rb_from_rram,
    slave_read_address => rb_address
);
stack_inst : lifo
generic map (
  DATA_WIDTH    => STACK_DATA_WIDTH,
  DEPTH         => STACK_DEPTH
)
port map (
  clk => clk,
  push => st_push,
  pop => st_pop,
  data_in => sto,
  data_out => sti
);
cache_process : process(clk)
begin
if ( rising_edge(clk) ) then
if ( rc_write_pulse = '1' ) then
rc_cache_data <= rc;
rc_cache_address <= rc_address;
end if;
if ( rd_write_pulse = '1' ) then
rd_cache_data <= rd;
rd_cache_address <= rd_address;
end if;
end if;
end process cache_process;
ra <= ra_from_rram when (do_ra_indirect_delay = '1') else
rc_cache_data when (ra_rc_cache_address_match = '1') else
rd_cache_data when (ra_rd_cache_address_match = '1') else
ra_from_rram;
rb <= rb_from_rram when (do_rb_indirect_delay = '1') else
rc_cache_data when (rb_rc_cache_address_match = '1') else
rd_cache_data when (rb_rd_cache_address_match = '1') else
rb_from_rram;
clk_state : process(clk)
begin
if (rising_edge(clk)) then
if (sync_reset = '1') then
current_state <= PRAM_ALIGN;
opcode_start   <= '0';
write_latch    <= '0';
do_ra_indirect <= '0';
do_rb_indirect <= '0';
do_rc_indirect <= '0';
do_rd_indirect <= '0';
pram_address <= (others => '0');
else
opcode_start <= '0';
write_latch <= '0';
do_ra_indirect <= '0';
do_rb_indirect <= '0';
do_rc_indirect <= '0';
do_rd_indirect <= '0';
current_state <= next_state;
case next_state is
when PRAM_ALIGN =>
pram_address <= next_pram_address;
when OPCODE_WITH_LOOKAHEAD =>
if ((indirect_read_required or indirect_write_required) = '0') then
opcode_start  <= '1';
pram_address <= next_pram_address;
write_latch   <= '1';
end if;
if (indirect_read_required = '1') then
do_ra_indirect <= ra_indirect;
do_rb_indirect <= rb_indirect;
elsif (indirect_write_required = '1') then
do_rc_indirect <= rc_indirect;
do_rd_indirect <= rd_indirect;
end if;
when OPCODE_WITH_INDIRECT_READ =>
if (indirect_write_required = '0') then
opcode_start  <= '1';
pram_address  <= next_pram_address;
write_latch <= '1';
end if;
if (indirect_write_required = '1') then
do_rc_indirect <= rc_indirect;
do_rd_indirect <= rd_indirect;
end if;
when OPCODE_WITH_INDIRECT_WRITE =>
if (indirect_write_required = '0') then
opcode_start  <= '1';
pram_address <= next_pram_address;
write_latch <= '1';
end if;
when others => null;
end case;
end if;
end if;
end process clk_state;
next_state_process : process(current_state, do_indirect_read, do_indirect_write, pram_alignment_required)
begin
case current_state is
when PRAM_ALIGN =>
next_state <= OPCODE_WITH_LOOKAHEAD;
when OPCODE_WITH_LOOKAHEAD =>
if (do_indirect_read = '1') then
next_state <= OPCODE_WITH_INDIRECT_READ;
elsif (do_indirect_write = '1') then
next_state <= OPCODE_WITH_INDIRECT_WRITE;
elsif (pram_alignment_required = '1') then
next_state <= PRAM_ALIGN;
else
next_state <= OPCODE_WITH_LOOKAHEAD;
end if;
when OPCODE_WITH_INDIRECT_READ =>
if (do_indirect_write = '1') then
next_state <= OPCODE_WITH_INDIRECT_WRITE;
elsif (pram_alignment_required = '1') then
next_state <= PRAM_ALIGN;
else
next_state <= OPCODE_WITH_LOOKAHEAD;
end if;
when OPCODE_WITH_INDIRECT_WRITE =>
if (pram_alignment_required = '1') then
next_state <= PRAM_ALIGN;
else
next_state <= OPCODE_WITH_LOOKAHEAD;
end if;
when others => null;
end case;
 end process next_state_process;
indirect_read_required  <= '1' when (ra_indirect or rb_indirect) = '1' else '0';
indirect_write_required <= '1' when (rc_indirect or rd_indirect) = '1' else '0';
do_indirect_read <= '1' when (do_ra_indirect or do_rb_indirect) = '1' else '0';
do_indirect_write <= '1' when (do_rc_indirect or do_rd_indirect) = '1' else '0';
do_ra_indirect_delay <= do_ra_indirect when rising_edge(clk);
do_rb_indirect_delay <= do_rb_indirect when rising_edge(clk);
pram_address_delayed <= pram_address when rising_edge(clk);
ti <= opcode_start;
add_inst : op_add
generic map (
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  rb => rb,
  rc => rc_op_add
);
call_inst : op_call
generic map (
  CWIDTH => C_WIDTH,
  SWIDTH => STACK_DATA_WIDTH,
  AWIDTH => PRAM_ADDRESS_WIDTH
) port map (
  c => c,
  ai => pram_address_delayed,
  ao => ao_op_call,
  sto => sto_op_call
);
dbrnz_inst : op_dbrnz
generic map (
  CWIDTH => C_WIDTH,
  RWIDTH => CORE_DATA_WIDTH,
  AWIDTH => PRAM_ADDRESS_WIDTH
) port map (
  c => c,
  ra => ra,
  ai => pram_address_delayed,
  ao => ao_op_dbrnz
);
dbrz_inst : op_dbrz
generic map (
  CWIDTH => C_WIDTH,
  RWIDTH => CORE_DATA_WIDTH,
  AWIDTH => PRAM_ADDRESS_WIDTH
) port map (
  c => c,
  ra => ra,
  ai => pram_address_delayed,
  ao => ao_op_dbrz
);
djmp_inst : op_djmp
generic map (
  CWIDTH => C_WIDTH,
  AWIDTH => PRAM_ADDRESS_WIDTH
) port map (
  c => c,
  ao => ao_op_djmp
);
in_inst : op_in
generic map (
  PWIDTH => PORT_DATA_WIDTH,
  RWIDTH => CORE_DATA_WIDTH
) port map (
  pi => pi,
  rc => rc_op_in
);
ld_inst : op_ld
generic map (
  CWIDTH => C_WIDTH,
  RWIDTH => CORE_DATA_WIDTH
) port map (
  c => c,
  rc => rc_op_ld
);
mov_inst : op_mov
generic map (
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  rc => rc_op_mov
);
out_inst : op_out
generic map (
  PWIDTH => PORT_DATA_WIDTH,
  RWIDTH => CORE_DATA_WIDTH
) port map (
  po => po_op_out,
  ra => ra
);
pop_inst : op_pop
generic map (
  SWIDTH => STACK_DATA_WIDTH,
  RWIDTH => CORE_DATA_WIDTH
) port map (
  rc => rc_op_pop,
  sti => sti
);
push_inst : op_push
generic map (
  SWIDTH => STACK_DATA_WIDTH,
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  sto => sto_op_push
);
ret_inst : op_ret
generic map (
  SWIDTH => STACK_DATA_WIDTH,
  AWIDTH => PRAM_ADDRESS_WIDTH
) port map (
  ao => ao_op_ret,
  sti => sti
);
shr_inst : op_shr
generic map (
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  rc => rc_op_shr
);
sub_inst : op_sub
generic map (
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  rb => rb,
  rc => rc_op_sub
);
test_unsigned_gt_inst : op_test_unsigned_gt
generic map (
  RWIDTH => CORE_DATA_WIDTH
) port map (
  ra => ra,
  rb => rb,
  rc => rc_op_test_unsigned_gt
);
rc <= rc_unlatched when delayed_write = '0' else rc_latched;
rc_latch_process : process(clk)
begin
  if ( rising_edge(clk) ) then
    if ( write_latch = '1' ) then
      rc_latched <= rc_unlatched;
    end if;
  end if;
end process rc_latch_process;
rc_unlatched <= rc_op_add when (opcode = OPCODE_add) else
rc_op_in when (opcode = OPCODE_in) else
rc_op_ld when (opcode = OPCODE_ld) else
rc_op_mov when (opcode = OPCODE_mov) else
rc_op_pop when (opcode = OPCODE_pop) else
rc_op_shr when (opcode = OPCODE_shr) else
rc_op_sub when (opcode = OPCODE_sub) else
rc_op_test_unsigned_gt when (opcode = OPCODE_test_unsigned_gt) else
(others => '0');
rd <= rd_unlatched when delayed_write = '0' else rd_latched;
rd_latch_process : process(clk)
begin
  if ( rising_edge(clk) ) then
    if ( write_latch = '1' ) then
      rd_latched <= rd_unlatched;
    end if;
  end if;
end process rd_latch_process;
rd_unlatched <= (others => '0');
rc_write_pulse <= rc_write and opcode_finish;
rc_write <= '1' when (opcode = OPCODE_add) else
'1' when (opcode = OPCODE_in) else
'1' when (opcode = OPCODE_ld) else
'1' when (opcode = OPCODE_mov) else
'1' when (opcode = OPCODE_pop) else
'1' when (opcode = OPCODE_shr) else
'1' when (opcode = OPCODE_sub) else
'1' when (opcode = OPCODE_test_unsigned_gt) else
'0';
rd_write_pulse <= rd_write and opcode_finish;
rd_write <= '0';
pi_read_pulse <= pi_read and opcode_start;
pi_read <= '1' when (opcode = OPCODE_in) else
'0';
po_latch_process : process(clk)
begin
  if ( rising_edge(clk) ) then
    if ( write_latch = '1' ) then
      po_latched <= po_unlatched;
    end if;
  end if;
end process po_latch_process;
po_unlatched <= po_op_out when (opcode = OPCODE_out) else
(others => '0');
po_write_pulse <= po_write and opcode_finish;
po_write <= '1' when (opcode = OPCODE_out) else
'0';
sto_latch_process : process(clk)
begin
  if ( rising_edge(clk) ) then
    if ( write_latch = '1' ) then
      sto_latched <= sto_unlatched;
    end if;
  end if;
end process sto_latch_process;
sto <= sto_unlatched when delayed_write = '0' else sto_latched;
sto_unlatched <= sto_op_call when (opcode = OPCODE_call) else
sto_op_push when (opcode = OPCODE_push) else
(others => '0');
st_push <= st_push_mux and opcode_finish;
st_push_mux <= '1' when (opcode = OPCODE_call) else
'1' when (opcode = OPCODE_push) else
'0';
st_pop <= st_pop_mux and opcode_start;
st_pop_mux <= '1' when (opcode = OPCODE_pop) else
'1' when (opcode = OPCODE_ret) else
'0';
ra_rc_cache_address_match <= '1' when (rc_cache_address = pram_data(RA_WIDTH-1+RA_ORIGIN downto RA_ORIGIN)) else '0';
rb_rc_cache_address_match <= '1' when (rc_cache_address = pram_data(RB_WIDTH-1+RB_ORIGIN downto RB_ORIGIN)) else '0';
next_pram_address <= ao_op when ((ao_op_valid and opcode_finish) = '1') else pram_address_inc;
pram_address_inc <= std_logic_vector(unsigned(pram_address)+1) when (pram_address /= std_logic_vector(to_unsigned(PRAM_DEPTH-1, PRAM_ADDRESS_WIDTH))) else (others => '0');
ao_op_valid <= pram_alignment_required;
ao_op <= ao_op_call when (opcode = OPCODE_call) else
ao_op_dbrnz when (opcode = OPCODE_dbrnz) else
ao_op_dbrz when (opcode = OPCODE_dbrz) else
ao_op_djmp when (opcode = OPCODE_djmp) else
ao_op_ret when (opcode = OPCODE_ret) else
(others => '0');
pram_alignment_required <='1' when (opcode = OPCODE_call) else
'1' when (opcode = OPCODE_dbrnz) else
'1' when (opcode = OPCODE_dbrz) else
'1' when (opcode = OPCODE_djmp) else
'1' when (opcode = OPCODE_ret) else
'0';
opcode_finish <= opcode_start;
end architecture v1;

--
-- link_trainer
--
-- Receiver link trainer
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library qf2_pre;
use qf2_pre.definitions.all;

entity link_trainer is
  port (
    clk : in std_logic;
    sync_reset : in  std_logic;
    rx_bitslip : out std_logic;
    rx_delay : out std_logic_vector(4 downto 0);
    rx_disparity_error : in std_logic;
    rx_crc_error : in std_logic;
    rx_code_error : in std_logic;
    rx_locked : out std_logic;
    rx_delay_start : out std_logic_vector(7 downto 0);
    rx_delay_end : out std_logic_vector(7 downto 0);
    rx_delay_last_start : out std_logic_vector(7 downto 0);
    rx_delay_last_end : out std_logic_vector(7 downto 0);
    rx_scan_bits : out std_logic_vector(31 downto 0)
    );
end entity link_trainer;

architecture rtl of link_trainer is

  signal gnd_prog_data_in    : std_logic_vector(link_trainer_kernel_PRAM_DATA_WIDTH-1 downto 0)    := (others => '0');
  signal gnd_prog_address_in : std_logic_vector(link_trainer_kernel_PRAM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
  signal gnd                 : std_logic                                                             := '0';

  signal port_in         : type_link_trainer_kernel_port_array;
  signal port_out        : type_link_trainer_kernel_port_array;
  signal port_in_strobe  : std_logic_vector(link_trainer_kernel_PORT_DEPTH-1 downto 0);
  signal port_out_strobe : std_logic_vector(link_trainer_kernel_PORT_DEPTH-1 downto 0);

  signal rx_crc_error_latch, rx_code_error_latch, rx_disparity_error_latch, rx_error_latch_clear : std_logic := '0';
  signal int_rx_scan_bits : std_logic_vector(31 downto 0) := (others => '0');
  
begin

  -- 8-bit kernel
  link_trainer_kernel_inst : link_trainer_kernel
    port map (
      clk             => clk,
      sync_reset      => sync_reset,
      port_in         => port_in,
      port_in_strobe  => port_in_strobe,
      port_out        => port_out,
      port_out_strobe => port_out_strobe,
      prog_data_in    => gnd_prog_data_in,
      prog_data_out   => open,
      prog_address_in => gnd_prog_address_in,
      prog_write      => gnd
      );

  -- Latch the errors to make sure we don't miss them
  rx_error_latch_proc : process(clk)
  begin
    if rising_edge(clk) then
      if ( rx_crc_error = '1' ) then
        rx_crc_error_latch <= '1';
      end if;
      if ( rx_disparity_error = '1' ) then
        rx_disparity_error_latch <= '1';
      end if;
      if ( rx_code_error = '1' ) then
        rx_code_error_latch <= '1';
      end if;
      if rx_error_latch_clear = '1' then
        rx_crc_error_latch <= '0';
        rx_code_error_latch <= '0';
        rx_disparity_error_latch <= '0';
      end if;
    end if;
  end process rx_error_latch_proc;
  
  -- Input ports
  port_in(0) <= "00000" & rx_crc_error_latch & rx_disparity_error_latch & rx_code_error_latch;

  -- Output ports
  rx_error_latch_clear <= port_out(0)(0);
  rx_bitslip <= port_out(0)(1) and port_out_strobe(0); -- Single cycle
  rx_locked <= port_out(0)(2);
  rx_delay <= port_out(1)(4 downto 0);
  rx_delay_start <= port_out(2);
  rx_delay_end <= port_out(3);
  rx_delay_last_start <= port_out(4);
  rx_delay_last_end <= port_out(5);

  rx_scan_bits_proc : process(clk)
  begin
    if rising_edge(clk) then
      if port_out_strobe(6) = '1' then
        int_rx_scan_bits <= int_rx_scan_bits(30 downto 0) & port_out(6)(0);
      end if;
    end if;
  end process rx_scan_bits_proc;
  rx_scan_bits <= int_rx_scan_bits;
  
end architecture rtl;

--
-- ROM-based 8b10b encoder
--
-- Always starts with a negative disparity and simply carries on from wherever
-- it was before. Relies on the decoder to match the running disparity, easy
-- using at least two standard commas in a row such as K28.5 which toggles the
-- running disparity to invert every cycle.
--
-- Providing an abnormal data byte with is_k high will deliberately generate an
-- invalid 10b code of "0000000000", which will trigger an error on the receiver.
--
-- Inputs and outputs are intentionally registered.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encode_8b10b is
  port(
    clk      : in  std_logic;
    is_k     : in  std_logic;                     -- Is K character
    data_in  : in  std_logic_vector(7 downto 0);  -- Data byte
    data_out : out std_logic_vector(9 downto 0)
    );
end encode_8b10b;

architecture rtl of encode_8b10b is

  -- '0' == negative running disparity, '1' == positive
  signal running_disparity : std_logic := '0';

  -- 10b code for every permutation of running_disparity, is_k and data_in
  -- Output is 10b code, extra bit indicates if that code will alter the disparity
  type type_code_table is array (integer range 0 to 1023) of std_logic_vector(10 downto 0);
  constant code_table : type_code_table := (
    "01001110100",
    "00111010100",
    "01011010100",
    "11100011011",
    "01101010100",
    "11010011011",
    "10110011011",
    "11110001011",
    "01110010100",
    "11001011011",
    "10101011011",
    "11101001011",
    "10011011011",
    "11011001011",
    "10111001011",
    "00101110100",
    "00110110100",
    "11000111011",
    "10100111011",
    "11100101011",
    "10010111011",
    "11010101011",
    "10110101011",
    "01110100100",
    "01100110100",
    "11001101011",
    "10101101011",
    "01101100100",
    "10011101011",
    "01011100100",
    "00111100100",
    "01010110100",
    "11001111001",
    "10111011001",
    "11011011001",
    "01100011001",
    "11101011001",
    "01010011001",
    "00110011001",
    "01110001001",
    "11110011001",
    "01001011001",
    "00101011001",
    "01101001001",
    "00011011001",
    "01011001001",
    "00111001001",
    "10101111001",
    "10110111001",
    "01000111001",
    "00100111001",
    "01100101001",
    "00010111001",
    "01010101001",
    "00110101001",
    "11110101001",
    "11100111001",
    "01001101001",
    "00101101001",
    "11101101001",
    "00011101001",
    "11011101001",
    "10111101001",
    "11010111001",
    "11001110101",
    "10111010101",
    "11011010101",
    "01100010101",
    "11101010101",
    "01010010101",
    "00110010101",
    "01110000101",
    "11110010101",
    "01001010101",
    "00101010101",
    "01101000101",
    "00011010101",
    "01011000101",
    "00111000101",
    "10101110101",
    "10110110101",
    "01000110101",
    "00100110101",
    "01100100101",
    "00010110101",
    "01010100101",
    "00110100101",
    "11110100101",
    "11100110101",
    "01001100101",
    "00101100101",
    "11101100101",
    "00011100101",
    "11011100101",
    "10111100101",
    "11010110101",
    "11001110011",
    "10111010011",
    "11011010011",
    "01100011100",
    "11101010011",
    "01010011100",
    "00110011100",
    "01110001100",
    "11110010011",
    "01001011100",
    "00101011100",
    "01101001100",
    "00011011100",
    "01011001100",
    "00111001100",
    "10101110011",
    "10110110011",
    "01000111100",
    "00100111100",
    "01100101100",
    "00010111100",
    "01010101100",
    "00110101100",
    "11110100011",
    "11100110011",
    "01001101100",
    "00101101100",
    "11101100011",
    "00011101100",
    "11011100011",
    "10111100011",
    "11010110011",
    "01001110010",
    "00111010010",
    "01011010010",
    "11100011101",
    "01101010010",
    "11010011101",
    "10110011101",
    "11110001101",
    "01110010010",
    "11001011101",
    "10101011101",
    "11101001101",
    "10011011101",
    "11011001101",
    "10111001101",
    "00101110010",
    "00110110010",
    "11000111101",
    "10100111101",
    "11100101101",
    "10010111101",
    "11010101101",
    "10110101101",
    "01110100010",
    "01100110010",
    "11001101101",
    "10101101101",
    "01101100010",
    "10011101101",
    "01011100010",
    "00111100010",
    "01010110010",
    "11001111010",
    "10111011010",
    "11011011010",
    "01100011010",
    "11101011010",
    "01010011010",
    "00110011010",
    "01110001010",
    "11110011010",
    "01001011010",
    "00101011010",
    "01101001010",
    "00011011010",
    "01011001010",
    "00111001010",
    "10101111010",
    "10110111010",
    "01000111010",
    "00100111010",
    "01100101010",
    "00010111010",
    "01010101010",
    "00110101010",
    "11110101010",
    "11100111010",
    "01001101010",
    "00101101010",
    "11101101010",
    "00011101010",
    "11011101010",
    "10111101010",
    "11010111010",
    "11001110110",
    "10111010110",
    "11011010110",
    "01100010110",
    "11101010110",
    "01010010110",
    "00110010110",
    "01110000110",
    "11110010110",
    "01001010110",
    "00101010110",
    "01101000110",
    "00011010110",
    "01011000110",
    "00111000110",
    "10101110110",
    "10110110110",
    "01000110110",
    "00100110110",
    "01100100110",
    "00010110110",
    "01010100110",
    "00110100110",
    "11110100110",
    "11100110110",
    "01001100110",
    "00101100110",
    "11101100110",
    "00011100110",
    "11011100110",
    "10111100110",
    "11010110110",
    "01001110001",
    "00111010001",
    "01011010001",
    "11100011110",
    "01101010001",
    "11010011110",
    "10110011110",
    "11110001110",
    "01110010001",
    "11001011110",
    "10101011110",
    "11101001110",
    "10011011110",
    "11011001110",
    "10111001110",
    "00101110001",
    "00110110001",
    "11000110111",
    "10100110111",
    "11100101110",
    "10010110111",
    "11010101110",
    "10110101110",
    "01110100001",
    "01100110001",
    "11001101110",
    "10101101110",
    "01101100001",
    "10011101110",
    "01011100001",
    "00111100001",
    "01010110001",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00011110100",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "10011111001",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "10011110101",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "10011110011",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00011110010",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "10011111010",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "10011110110",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "01110101000",
    "00000000000",
    "00000000000",
    "00000000000",
    "01101101000",
    "00011111000",
    "01011101000",
    "00111101000",
    "00000000000",
    "00110001011",
    "01000101011",
    "00100101011",
    "11100010100",
    "00010101011",
    "11010010100",
    "10110010100",
    "10001110100",
    "00001101011",
    "11001010100",
    "10101010100",
    "11101000100",
    "10011010100",
    "11011000100",
    "10111000100",
    "01010001011",
    "01001001011",
    "11000110100",
    "10100110100",
    "11100100100",
    "10010110100",
    "11010100100",
    "10110100100",
    "00001011011",
    "00011001011",
    "11001100100",
    "10101100100",
    "00010011011",
    "10011100100",
    "00100011011",
    "01000011011",
    "00101001011",
    "10110001001",
    "11000101001",
    "10100101001",
    "01100011001",
    "10010101001",
    "01010011001",
    "00110011001",
    "00001111001",
    "10001101001",
    "01001011001",
    "00101011001",
    "01101001001",
    "00011011001",
    "01011001001",
    "00111001001",
    "11010001001",
    "11001001001",
    "01000111001",
    "00100111001",
    "01100101001",
    "00010111001",
    "01010101001",
    "00110101001",
    "10001011001",
    "10011001001",
    "01001101001",
    "00101101001",
    "10010011001",
    "00011101001",
    "10100011001",
    "11000011001",
    "10101001001",
    "10110000101",
    "11000100101",
    "10100100101",
    "01100010101",
    "10010100101",
    "01010010101",
    "00110010101",
    "00001110101",
    "10001100101",
    "01001010101",
    "00101010101",
    "01101000101",
    "00011010101",
    "01011000101",
    "00111000101",
    "11010000101",
    "11001000101",
    "01000110101",
    "00100110101",
    "01100100101",
    "00010110101",
    "01010100101",
    "00110100101",
    "10001010101",
    "10011000101",
    "01001100101",
    "00101100101",
    "10010010101",
    "00011100101",
    "10100010101",
    "11000010101",
    "10101000101",
    "10110001100",
    "11000101100",
    "10100101100",
    "01100010011",
    "10010101100",
    "01010010011",
    "00110010011",
    "00001110011",
    "10001101100",
    "01001010011",
    "00101010011",
    "01101000011",
    "00011010011",
    "01011000011",
    "00111000011",
    "11010001100",
    "11001001100",
    "01000110011",
    "00100110011",
    "01100100011",
    "00010110011",
    "01010100011",
    "00110100011",
    "10001011100",
    "10011001100",
    "01001100011",
    "00101100011",
    "10010011100",
    "00011100011",
    "10100011100",
    "11000011100",
    "10101001100",
    "00110001101",
    "01000101101",
    "00100101101",
    "11100010010",
    "00010101101",
    "11010010010",
    "10110010010",
    "10001110010",
    "00001101101",
    "11001010010",
    "10101010010",
    "11101000010",
    "10011010010",
    "11011000010",
    "10111000010",
    "01010001101",
    "01001001101",
    "11000110010",
    "10100110010",
    "11100100010",
    "10010110010",
    "11010100010",
    "10110100010",
    "00001011101",
    "00011001101",
    "11001100010",
    "10101100010",
    "00010011101",
    "10011100010",
    "00100011101",
    "01000011101",
    "00101001101",
    "10110001010",
    "11000101010",
    "10100101010",
    "01100011010",
    "10010101010",
    "01010011010",
    "00110011010",
    "00001111010",
    "10001101010",
    "01001011010",
    "00101011010",
    "01101001010",
    "00011011010",
    "01011001010",
    "00111001010",
    "11010001010",
    "11001001010",
    "01000111010",
    "00100111010",
    "01100101010",
    "00010111010",
    "01010101010",
    "00110101010",
    "10001011010",
    "10011001010",
    "01001101010",
    "00101101010",
    "10010011010",
    "00011101010",
    "10100011010",
    "11000011010",
    "10101001010",
    "10110000110",
    "11000100110",
    "10100100110",
    "01100010110",
    "10010100110",
    "01010010110",
    "00110010110",
    "00001110110",
    "10001100110",
    "01001010110",
    "00101010110",
    "01101000110",
    "00011010110",
    "01011000110",
    "00111000110",
    "11010000110",
    "11001000110",
    "01000110110",
    "00100110110",
    "01100100110",
    "00010110110",
    "01010100110",
    "00110100110",
    "10001010110",
    "10011000110",
    "01001100110",
    "00101100110",
    "10010010110",
    "00011100110",
    "10100010110",
    "11000010110",
    "10101000110",
    "00110001110",
    "01000101110",
    "00100101110",
    "11100010001",
    "00010101110",
    "11010010001",
    "10110010001",
    "10001110001",
    "00001101110",
    "11001010001",
    "10101010001",
    "11101001000",
    "10011010001",
    "11011001000",
    "10111001000",
    "01010001110",
    "01001001110",
    "11000110001",
    "10100110001",
    "11100100001",
    "10010110001",
    "11010100001",
    "10110100001",
    "00001011110",
    "00011001110",
    "11001100001",
    "10101100001",
    "00010011110",
    "10011100001",
    "00100011110",
    "01000011110",
    "00101001110",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "01100001011",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "11100000110",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "11100001010",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "11100001100",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "01100001101",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "11100000101",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "11100001001",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00000000000",
    "00001010111",
    "00000000000",
    "00000000000",
    "00000000000",
    "00010010111",
    "01100000111",
    "00100010111",
    "01000010111",
    "00000000000"
    );

  signal code_index : integer range 1023 downto 0 := 0;
  signal code_vector : std_logic_vector(9 downto 0) := (others => '0');
  signal result, r_result : std_logic_vector(10 downto 0) := (others => '0');

  signal r_data_in : std_logic_vector(7 downto 0) := (others => '0');
  signal r_is_k : std_logic := '0';
  
begin

  -- Register inputs
  r_data_in <= data_in when rising_edge(clk);
  r_is_k <= is_k when rising_edge(clk);
  
  -- XOR output disparity change flag with running disparity
  running_disparity <= code_vector(9) xor result(10) when rising_edge(clk);

  -- Build code and register index
  code_vector <= (running_disparity & r_is_k & r_data_in);
  result <= code_table(to_integer(unsigned(code_vector)));

  -- Register output
  r_result <= result when rising_edge(clk);

  -- Pass out code minus running disparity
  data_out <= r_result(9 downto 0);
  
end rtl;

--
-- ROM-based 8b10b decoder
--
-- Always starts with a negative disparity and simply carries on from wherever
-- it was before. Does not require a reset by assuming that synchronization of
-- the receiver requires at least two K codes with opposite disparities. One of
-- them will match the receiver and it will continue tracking from then onward.
--
-- Somewhat wasteful use of a BRAM, but could be optimised quite easily at the
-- cost of increased logic complexity.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode_8b10b is
  port(
    clk             : in  std_logic;
    data_in         : in  std_logic_vector(9 downto 0);
    data_out        : out std_logic_vector(7 downto 0);
    is_k            : out std_logic;
    code_error      : out std_logic;
    disparity_error : out std_logic
    );
end decode_8b10b;

architecture rtl of decode_8b10b is

  -- '0' == negative running disparity, '1' == positive
  signal int_disparity_error, running_disparity : std_logic := '0';

  -- code error, disparity, has disparity, is k, data [8] = 12 bits
  type type_code_table is array (integer range 0 to 1023) of std_logic_vector(11 downto 0);
  constant code_table : type_code_table := (
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001010111",
    "011011010111",
    "000111110111",
    "100000000000",
    "011000110111",
    "011010110111",
    "000000010111",
    "011001110111",
    "000010010111",
    "000011110111",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001001000",
    "011011001000",
    "100000000000",
    "100000000000",
    "011000101000",
    "011010101000",
    "000000001000",
    "011001101000",
    "000010001000",
    "000011101000",
    "100000000000",
    "100000000000",
    "011011100111",
    "011010000111",
    "000001100111",
    "011000000111",
    "000001000111",
    "000011000111",
    "100000000000",
    "100000000000",
    "000000100111",
    "000010100111",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001011011",
    "011011011011",
    "000111111011",
    "100000000000",
    "011000111011",
    "011010111011",
    "000000011011",
    "011001111011",
    "000010011011",
    "000011111011",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001000100",
    "011011000100",
    "100000000000",
    "100000000000",
    "011000100100",
    "011010100100",
    "000000000100",
    "011001100100",
    "000010000100",
    "000011100100",
    "100000000000",
    "100000000000",
    "011011110100",
    "011010010100",
    "000001110100",
    "011000010100",
    "000001010100",
    "000011010100",
    "001011110100",
    "100000000000",
    "000000110100",
    "000010110100",
    "001000010100",
    "000001110100",
    "001010010100",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001011000",
    "011011011000",
    "100000000000",
    "100000000000",
    "011000111000",
    "011010111000",
    "000000011000",
    "011001111000",
    "000010011000",
    "000011111000",
    "100000000000",
    "100000000000",
    "011011101100",
    "011010001100",
    "000001101100",
    "011000001100",
    "000001001100",
    "000011001100",
    "100000000000",
    "100000000000",
    "000000101100",
    "000010101100",
    "001000001100",
    "000001101100",
    "001010001100",
    "001011101100",
    "100000000000",
    "100000000000",
    "011011111100",
    "011010011100",
    "000001111100",
    "011000011100",
    "000001011100",
    "000011011100",
    "100000000000",
    "100000000000",
    "000000111100",
    "000010111100",
    "001000011100",
    "000001111100",
    "001010011100",
    "001011111100",
    "100000000000",
    "100000000000",
    "100000000000",
    "000110011100",
    "001101111100",
    "000100011100",
    "001101011100",
    "001111011100",
    "100000000000",
    "000111111100",
    "001100111100",
    "001110111100",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001011101",
    "011011011101",
    "000111111101",
    "100000000000",
    "011000111101",
    "011010111101",
    "000000011101",
    "011001111101",
    "000010011101",
    "000011111101",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001000010",
    "011011000010",
    "100000000000",
    "100000000000",
    "011000100010",
    "011010100010",
    "000000000010",
    "011001100010",
    "000010000010",
    "000011100010",
    "100000000000",
    "100000000000",
    "011011110010",
    "011010010010",
    "000001110010",
    "011000010010",
    "000001010010",
    "000011010010",
    "001011110010",
    "100000000000",
    "000000110010",
    "000010110010",
    "001000010010",
    "000001110010",
    "001010010010",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001011111",
    "011011011111",
    "100000000000",
    "100000000000",
    "011000111111",
    "011010111111",
    "000000011111",
    "011001111111",
    "000010011111",
    "000011111111",
    "100000000000",
    "100000000000",
    "011011101010",
    "011010001010",
    "000001101010",
    "011000001010",
    "000001001010",
    "000011001010",
    "100000000000",
    "100000000000",
    "000000101010",
    "000010101010",
    "001000001010",
    "000001101010",
    "001010001010",
    "001011101010",
    "100000000000",
    "100000000000",
    "011011111010",
    "011010011010",
    "000001111010",
    "011000011010",
    "000001011010",
    "000011011010",
    "100000000000",
    "100000000000",
    "000000111010",
    "000010111010",
    "001000011010",
    "000001111010",
    "001010011010",
    "001011111010",
    "100000000000",
    "100000000000",
    "000011101111",
    "000010001111",
    "001001101111",
    "000000001111",
    "001001001111",
    "001011001111",
    "100000000000",
    "100000000000",
    "001000101111",
    "001010101111",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001000000",
    "011011000000",
    "100000000000",
    "100000000000",
    "011000100000",
    "011010100000",
    "000000000000",
    "011001100000",
    "000010000000",
    "000011100000",
    "100000000000",
    "100000000000",
    "011011100110",
    "011010000110",
    "000001100110",
    "011000000110",
    "000001000110",
    "000011000110",
    "100000000000",
    "100000000000",
    "000000100110",
    "000010100110",
    "001000000110",
    "000001100110",
    "001010000110",
    "001011100110",
    "100000000000",
    "100000000000",
    "011011110110",
    "011010010110",
    "000001110110",
    "011000010110",
    "000001010110",
    "000011010110",
    "100000000000",
    "100000000000",
    "000000110110",
    "000010110110",
    "001000010110",
    "000001110110",
    "001010010110",
    "001011110110",
    "100000000000",
    "100000000000",
    "000011110000",
    "000010010000",
    "001001110000",
    "000000010000",
    "001001010000",
    "001011010000",
    "100000000000",
    "100000000000",
    "001000110000",
    "001010110000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011010001110",
    "000001101110",
    "011000001110",
    "000001001110",
    "000011001110",
    "100000000000",
    "011011101110",
    "000000101110",
    "000010101110",
    "001000001110",
    "000001101110",
    "001010001110",
    "001011101110",
    "100000000000",
    "100000000000",
    "000011100001",
    "000010000001",
    "001001100001",
    "000000000001",
    "001001000001",
    "001011000001",
    "100000000000",
    "100000000000",
    "001000100001",
    "001010100001",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "000011111110",
    "000010011110",
    "001001111110",
    "000000011110",
    "001001011110",
    "001011011110",
    "100000000000",
    "000111111110",
    "001000111110",
    "001010111110",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001011110",
    "011011011110",
    "000111111110",
    "100000000000",
    "011000111110",
    "011010111110",
    "000000011110",
    "011001111110",
    "000010011110",
    "000011111110",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001000001",
    "011011000001",
    "100000000000",
    "100000000000",
    "011000100001",
    "011010100001",
    "000000000001",
    "011001100001",
    "000010000001",
    "000011100001",
    "100000000000",
    "100000000000",
    "011011110001",
    "011010010001",
    "000001110001",
    "011000010001",
    "000001010001",
    "000011010001",
    "001011110001",
    "100000000000",
    "000000110001",
    "000010110001",
    "001000010001",
    "000001110001",
    "001010010001",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001010000",
    "011011010000",
    "100000000000",
    "100000000000",
    "011000110000",
    "011010110000",
    "000000010000",
    "011001110000",
    "000010010000",
    "000011110000",
    "100000000000",
    "100000000000",
    "011011101001",
    "011010001001",
    "000001101001",
    "011000001001",
    "000001001001",
    "000011001001",
    "100000000000",
    "100000000000",
    "000000101001",
    "000010101001",
    "001000001001",
    "000001101001",
    "001010001001",
    "001011101001",
    "100000000000",
    "100000000000",
    "011011111001",
    "011010011001",
    "000001111001",
    "011000011001",
    "000001011001",
    "000011011001",
    "100000000000",
    "100000000000",
    "000000111001",
    "000010111001",
    "001000011001",
    "000001111001",
    "001010011001",
    "001011111001",
    "100000000000",
    "100000000000",
    "000011100000",
    "000010000000",
    "001001100000",
    "000000000000",
    "001001000000",
    "001011000000",
    "100000000000",
    "100000000000",
    "001000100000",
    "001010100000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011001001111",
    "011011001111",
    "100000000000",
    "100000000000",
    "011000101111",
    "011010101111",
    "000000001111",
    "011001101111",
    "000010001111",
    "000011101111",
    "100000000000",
    "100000000000",
    "011011100101",
    "011010000101",
    "000001100101",
    "011000000101",
    "000001000101",
    "000011000101",
    "100000000000",
    "100000000000",
    "000000100101",
    "000010100101",
    "001000000101",
    "000001100101",
    "001010000101",
    "001011100101",
    "100000000000",
    "100000000000",
    "011011110101",
    "011010010101",
    "000001110101",
    "011000010101",
    "000001010101",
    "000011010101",
    "100000000000",
    "100000000000",
    "000000110101",
    "000010110101",
    "001000010101",
    "000001110101",
    "001010010101",
    "001011110101",
    "100000000000",
    "100000000000",
    "000011111111",
    "000010011111",
    "001001111111",
    "000000011111",
    "001001011111",
    "001011011111",
    "100000000000",
    "100000000000",
    "001000111111",
    "001010111111",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011010001101",
    "000001101101",
    "011000001101",
    "000001001101",
    "000011001101",
    "100000000000",
    "011011101101",
    "000000101101",
    "000010101101",
    "001000001101",
    "000001101101",
    "001010001101",
    "001011101101",
    "100000000000",
    "100000000000",
    "000011100010",
    "000010000010",
    "001001100010",
    "000000000010",
    "001001000010",
    "001011000010",
    "100000000000",
    "100000000000",
    "001000100010",
    "001010100010",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "000011111101",
    "000010011101",
    "001001111101",
    "000000011101",
    "001001011101",
    "001011011101",
    "100000000000",
    "000111111101",
    "001000111101",
    "001010111101",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011110111100",
    "011100111100",
    "000111111100",
    "100000000000",
    "011111011100",
    "011101011100",
    "000100011100",
    "011101111100",
    "000110011100",
    "100000000000",
    "100000000000",
    "100000000000",
    "011011100011",
    "011010000011",
    "000001100011",
    "011000000011",
    "000001000011",
    "000011000011",
    "100000000000",
    "100000000000",
    "000000100011",
    "000010100011",
    "001000000011",
    "000001100011",
    "001010000011",
    "001011100011",
    "100000000000",
    "100000000000",
    "011011110011",
    "011010010011",
    "000001110011",
    "011000010011",
    "000001010011",
    "000011010011",
    "100000000000",
    "100000000000",
    "000000110011",
    "000010110011",
    "001000010011",
    "000001110011",
    "001010010011",
    "001011110011",
    "100000000000",
    "100000000000",
    "000011111000",
    "000010011000",
    "001001111000",
    "000000011000",
    "001001011000",
    "001011011000",
    "100000000000",
    "100000000000",
    "001000111000",
    "001010111000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "011010001011",
    "000001101011",
    "011000001011",
    "000001001011",
    "000011001011",
    "100000000000",
    "011011101011",
    "000000101011",
    "000010101011",
    "001000001011",
    "000001101011",
    "001010001011",
    "001011101011",
    "100000000000",
    "100000000000",
    "000011100100",
    "000010000100",
    "001001100100",
    "000000000100",
    "001001000100",
    "001011000100",
    "100000000000",
    "100000000000",
    "001000100100",
    "001010100100",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "000011111011",
    "000010011011",
    "001001111011",
    "000000011011",
    "001001011011",
    "001011011011",
    "100000000000",
    "000111111011",
    "001000111011",
    "001010111011",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "000001000111",
    "000011000111",
    "100000000000",
    "100000000000",
    "000000100111",
    "000010100111",
    "001000000111",
    "000001100111",
    "001010000111",
    "001011100111",
    "100000000000",
    "100000000000",
    "000011101000",
    "000010001000",
    "001001101000",
    "000000001000",
    "001001001000",
    "001011001000",
    "100000000000",
    "100000000000",
    "001000101000",
    "001010101000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "000011110111",
    "000010010111",
    "001001110111",
    "000000010111",
    "001001010111",
    "001011010111",
    "100000000000",
    "000111110111",
    "001000110111",
    "001010110111",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000",
    "100000000000"
    );

  signal code_index                      : integer range 1023 downto 0   := 0;
  signal code_vector                     : std_logic_vector(9 downto 0)  := (others => '0');
  signal result, r_result                : std_logic_vector(11 downto 0) := (others => '0');
  signal r_code_error, r_disparity_error : std_logic                     := '0';
  signal r_data_in : std_logic_vector(9 downto 0) := (others => '0');
  
begin

  -- Register the input
  r_data_in         <= data_in                when rising_edge(clk);

  -- Look up the 10b code in the table
  result <= code_table(to_integer(unsigned(r_data_in)));

  -- Disparity check
  -- Disparity error if the received code has an overall disparity that matches
  -- the previous value for the running disparity
  int_disparity_error <= '1' when ((running_disparity /= result(10)) and (result(9) = '1')) else
                         '0';

  -- Invert running disparity if the received code has overall disparity and
  -- there isn't a running disparity error
  disparity_proc : process(clk)
  begin
    if ( rising_edge(clk) ) then
      if ( result(9) = '1' and (running_disparity = result(10)) ) then
        running_disparity <= not(running_disparity);
      end if;
    end if;
  end process disparity_proc;

  r_disparity_error <= int_disparity_error when rising_edge(clk);
  r_result          <= result              when rising_edge(clk);
  r_code_error      <= result(11)          when rising_edge(clk);

  data_out        <= r_result(7 downto 0);
  is_k            <= r_result(8);
  disparity_error <= r_disparity_error;
  code_error      <= r_code_error;
  
end rtl;

-- base
--
-- Base clocking and reset circuits
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;

entity base is
  port (

    -- Reset signal output to rest of system
    async_reset : out std_logic;

    -- Reference 50MHz clock from Spartan-6
    clk_sys_p, clk_sys_n : in std_logic;

    -- System clock reference from MMCM
    -- Jitter-cleaned reference for other clock generation
    -- in application firmware layer. Buffer in application.
    clk_50mhz_no_buf : out std_logic;

    -- 100MHz reference for core interfaces
    -- This is internally BUFG'd from the RX clock system.
    clk_100mhz : out std_logic;

    -- TX communication clocks
    -- These are phase-shifted based on commands received
    -- from the Spartan. This overcomes the inherent limitations
    -- of the Spartan-6 silicon. There are 84 11.9ps taps and then
    -- the phase shifter will wrap.
    clk_100mhz_tx : out std_logic;
    clk_500mhz_tx : out std_logic;

    -- PS en should be pulsed for one clock cycle in the clk_100mhz_rx domain. 
    tx_ps_en   : in  std_logic;
    tx_ps_done : out std_logic;

    -- RX communication clocks
    -- These are configured with static phase.
    -- The idelay is used to synchronize
    clk_100mhz_rx : out std_logic;
    clk_500mhz_rx : out std_logic

    );
end base;

architecture rtl of base is

  signal clk_sys : std_logic;

  signal mmcm_reset, pll_reset, idelayctrl_reset : std_logic := '1';
  signal mmcm_locked, pll_locked                 : std_logic := '0';
  signal mmcm_fb, pll_fb                         : std_logic;

  signal int_clk_100mhz_tx, int_clk_500mhz_tx                    : std_logic;
  signal int_clk_100mhz_rx, pre_clk_100mhz_rx, int_clk_500mhz_rx : std_logic;
  signal int_clk_300mhz_idelay, int_clk_100mhz                   : std_logic;
  signal idelay_rdy, clk_300mhz_idelay                           : std_logic;

begin

  -- Reference clock input buffer
  inst_input_clk : component unisim.vcomponents.IBUFGDS
    generic map (
      DIFF_TERM  => true,
      IOSTANDARD => "LVDS_25"
      )
    port map (
      I  => clk_sys_p,
      IB => clk_sys_n,
      O  => clk_sys
      );

  -- Master reset
  master_reset : process(clk_sys)
    variable reset_counter : natural range 2000 downto 0 := 2000;
  begin
    if rising_edge(clk_sys) then
      if reset_counter = 0 then
        pll_reset <= '0';
      else
        reset_counter := reset_counter - 1;
      end if;
    end if;
  end process master_reset;

  -- MMCM instance - TX clocks and no-buffer reference for user logic
  -- FVCO == 1000MHz
  -- Fine tuning requires 56 PS taps to cover 1ns
  inst_mmcm_adv : component unisim.vcomponents.MMCME2_ADV
    generic map (
      BANDWIDTH            => "HIGH",
      CLKOUT4_CASCADE      => false,
      COMPENSATION         => "ZHOLD",
      STARTUP_WAIT         => false,
      DIVCLK_DIVIDE        => 1,
      CLKFBOUT_MULT_F      => 20.000,
      CLKFBOUT_PHASE       => 0.000,
      CLKFBOUT_USE_FINE_PS => false,
      CLKOUT0_DIVIDE_F     => 10.000,   -- 100MHz TX
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKOUT0_USE_FINE_PS  => true,
      CLKOUT1_DIVIDE       => 2,        -- 500MHz TX
      CLKOUT1_PHASE        => 0.000,
      CLKOUT1_DUTY_CYCLE   => 0.500,
      CLKOUT1_USE_FINE_PS  => true,
      CLKOUT4_DIVIDE       => 20,       -- 50MHz no buf
      CLKOUT4_PHASE        => 0.000,
      CLKOUT4_DUTY_CYCLE   => 0.500,
      CLKOUT4_USE_FINE_PS  => false,
      CLKIN1_PERIOD        => 20.0,
      REF_JITTER1          => 0.005
      )
    port map (
      clkin1   => clk_sys,
      clkout0  => int_clk_100mhz_tx,
      clkout1  => int_clk_500mhz_tx,
      clkout2  => open,
      clkout3  => open,
      clkout4  => clk_50mhz_no_buf,
      clkfbin  => mmcm_fb,
      clkfbout => mmcm_fb,
      clkin2   => '0',
      clkinsel => '1',
      DADDR    => (others => '0'),
      DCLK     => '0',
      DEN      => '0',
      DI       => (others => '0'),
      DWE      => '0',

      -- Dynamic phase shift
      -- Phase shift is always increment, wrap-around.
      -- Shifts the inputs to the TX PLL, shifting all the
      -- output clocks at the same time. This avoids creating
      -- shifts in the TX subsystem that cause timing errors.
      PSCLK    => pre_clk_100mhz_rx,
      PSEN     => tx_ps_en,
      PSINCDEC => '1',
      PSDONE   => tx_ps_done,

      -- Other control and status signals
      LOCKED       => mmcm_locked,
      CLKINSTOPPED => open,
      CLKFBSTOPPED => open,
      PWRDWN       => '0',
      RST          => mmcm_reset
      );

  -- RX subsystem PLL  
  inst_pll_adv : component unisim.vcomponents.PLLE2_ADV
    generic map (
      bandwidth          => "OPTIMIZED",
      clkfbout_mult      => 30,
      clkfbout_phase     => 0.0,
      clkin1_period      => 20.0,
      clkout0_divide     => 5,          -- 300MHz IDELAY
      clkout0_duty_cycle => 0.5,
      clkout0_phase      => 0.0,
      clkout1_divide     => 15,         -- 100MHz RX
      clkout1_duty_cycle => 0.5,
      clkout1_phase      => 0.0,
      clkout2_divide     => 3,          -- 500MHz RX
      clkout2_duty_cycle => 0.5,
      clkout2_phase      => 0.0,
      compensation       => "ZHOLD",
      divclk_divide      => 1,
      ref_jitter1        => 0.100
      )
    port map (
      clkout0  => int_clk_300mhz_idelay,
      clkout1  => int_clk_100mhz_rx,
      clkout2  => int_clk_500mhz_rx,
      locked   => pll_locked,
      clkfbin  => pll_fb,
      clkfbout => pll_fb,
      clkin1   => clk_sys,
      clkin2   => '0',
      clkinsel => '1',
      pwrdwn   => '0',
      rst      => pll_reset,
      daddr    => (others => '0'),
      dclk     => '0',
      den      => '0',
      drdy     => open,
      di       => (others => '0'),
      do       => open,
      dwe      => '0'
      );

  -- Release MMCM reset when PLL is locked.
  mmcm_reset <= not(pll_locked);

  -- Release IDELAYCTRL reset when PLL is locked.
  idelayctrl_reset <= not(pll_locked);

  -- Use BUFH to restrict placement
  inst_bufh_clk_300mhz_idelay : component unisim.vcomponents.BUFH
    port map (
      i => int_clk_300mhz_idelay,
      o => clk_300mhz_idelay
      );

  -- IDELAYCTRL instance for RX
  inst_idelay_ctrl : component unisim.vcomponents.IDELAYCTRL
    port map (
      rst    => idelayctrl_reset,
      refclk => clk_300mhz_idelay,
      rdy    => idelay_rdy
      );

  -- Release global reset when MMCM and IDELAYCTRL are locked
  -- PLL must be locked by this point
  async_reset <= not(mmcm_locked and idelay_rdy);

  -- Use BUFH to restrict placement
  inst_bufh_clk_100mhz_tx : component unisim.vcomponents.BUFH
    port map (
      i => int_clk_100mhz_tx,
      o => clk_100mhz_tx
      );

  -- Use BUFH to restrict placement
  inst_bufh_clk_500mhz_tx : component unisim.vcomponents.BUFH
    port map (
      i => int_clk_500mhz_tx,
      o => clk_500mhz_tx
      );

  -- Use BUFH to restrict placement
  inst_bufh_clk_100mhz_rx : component unisim.vcomponents.BUFH
    port map (
      i => int_clk_100mhz_rx,
      o => pre_clk_100mhz_rx
      );

  -- Buffered to connect to phase shifter
  clk_100mhz_rx <= pre_clk_100mhz_rx;

  -- Use BUFH to restrict placement
  inst_bufh_clk_500mhz_rx : component unisim.vcomponents.BUFH
    port map (
      i => int_clk_500mhz_rx,
      o => clk_500mhz_rx
      );

  -- This is virtually unused by the core, and is provided for user logic
  -- Non-FIFO external signals (e.g. LEDs / status) except for RX debug
  -- are retimed into this clock domain
  inst_bufg_clk_100mhz : component unisim.vcomponents.BUFG
    port map (
      i => int_clk_100mhz_rx,
      o => clk_100mhz
      );

end rtl;

--
-- k7_rx_8b10b
--
-- 8b10b communication system, with flow control
--
-- NOTE: In Kintex-7 IDELAY is configured to use an IDELAYCTRL with a 300MHz
-- REFCLK_FREQUENCY, the maximum for an HR 7 series bank
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;

entity k7_rx_8b10b is
  port (

    -- SERDES reset
    serdes_reset : in std_logic;

    -- Byte, and DDR 10b clock
    clk_1x, clk_5x : in std_logic;

    ---- Serial data in
    rx_p, rx_n : in std_logic;

    -- IDELAY setting and bitslip controls
    delay   : in std_logic_vector(4 downto 0);
    bitslip : in std_logic;

    -- Data outputs
    is_k, code_error, disparity_error : out std_logic;
    data_out                          : out std_logic_vector(7 downto 0);

    debug_data_10b : out std_logic_vector(9 downto 0)

    );
end entity k7_rx_8b10b;

architecture rtl of k7_rx_8b10b is

  component decode_8b10b
    port(
      clk             : in  std_logic;
      data_in         : in  std_logic_vector(9 downto 0);
      data_out        : out std_logic_vector(7 downto 0);
      is_k            : out std_logic;
      code_error      : out std_logic;
      disparity_error : out std_logic
      );
  end component;

  signal data_in, del_data_in, inv_clk_5x, shift1, shift2, idelay_ld : std_logic;
  signal int_data                                                    : std_logic_vector(9 downto 0);
  signal r_idelay_value, r_r_idelay_value                            : std_logic_vector(4 downto 0);

begin

  -- Inverted hs clock signal
  inv_clk_5x <= not(clk_5x);

  -- Delay value load
  r_idelay_value   <= delay          when rising_edge(clk_1x);
  r_r_idelay_value <= r_idelay_value when rising_edge(clk_1x);
  idelay_ld        <= '1'            when r_r_idelay_value /= r_idelay_value else '0';

  -- LVDS IOB
  -- High performance mode, internal diff term
  inst_data_in_ibufds : component unisim.vcomponents.IBUFDS
    generic map (
      IOSTANDARD   => "LVDS_25",
      IBUF_LOW_PWR => false,
      DIFF_TERM    => true
      )
    port map (
      I  => rx_p,
      IB => rx_n,
      O  => data_in
      );

  inst_idelay : component unisim.vcomponents.IDELAYE2
    generic map (
      DELAY_SRC             => "IDATAIN",   -- IOB
      IDELAY_TYPE           => "VAR_LOAD",  -- Variable load mode
      REFCLK_FREQUENCY      => 300.0,
      HIGH_PERFORMANCE_MODE => "TRUE",
      IDELAY_VALUE          => 0,
      PIPE_SEL              => "FALSE",
      SIGNAL_PATTERN        => "DATA"
      )
    port map (
      C           => clk_1x,
      IDATAIN     => data_in,
      DATAOUT     => del_data_in,
      CNTVALUEIN  => r_idelay_value,
      LD          => idelay_ld,
      CNTVALUEOUT => open,
      DATAIN      => '0',
      INC         => '0',
      REGRST      => '0',
      LDPIPEEN    => '0',
      CINVCTRL    => '0',
      CE          => '0'
      );

  -- ISERDES2 receivers
  inst_iserdes_master : component unisim.vcomponents.ISERDESE2
    generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 10,
      INTERFACE_TYPE    => "NETWORKING",
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      NUM_CE            => 2,
      OFB_USED          => "FALSE",
      IOBDELAY          => "IFD",
      SERDES_MODE       => "MASTER"
      )
    port map (
      clk          => clk_5x,
      clkb         => inv_clk_5x,
      clkdiv       => clk_1x,
      ddly         => del_data_in,
      q8           => int_data(2),
      q7           => int_data(3),
      q6           => int_data(4),
      q5           => int_data(5),
      q4           => int_data(6),
      q3           => int_data(7),
      q2           => int_data(8),
      q1           => int_data(9),
      rst          => serdes_reset,
      shiftout1    => shift1,
      shiftout2    => shift2,
      clkdivp      => '0',
      ce1          => '1',
      ce2          => '1',
      oclk         => '0',
      oclkb        => '0',
      bitslip      => bitslip,
      shiftin1     => '0',
      shiftin2     => '0',
      ofb          => '0',
      dynclksel    => '0',
      dynclkdivsel => '0',
      d            => '0',
      o            => open
      );

  inst_iserdes_slave : component unisim.vcomponents.ISERDESE2
    generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 10,
      INTERFACE_TYPE    => "NETWORKING",
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      NUM_CE            => 2,
      OFB_USED          => "FALSE",
      IOBDELAY          => "IFD",
      SERDES_MODE       => "SLAVE"
      )
    port map (
      clk          => clk_5x,
      clkb         => inv_clk_5x,
      clkdiv       => clk_1x,
      d            => '0',
      q4           => int_data(0),
      q3           => int_data(1),
      rst          => serdes_reset,
      clkdivp      => '0',
      ce1          => '1',
      ce2          => '1',
      oclk         => '0',
      oclkb        => '0',
      bitslip      => bitslip,
      shiftin1     => shift1,
      shiftin2     => shift2,
      ofb          => '0',
      dynclksel    => '0',
      dynclkdivsel => '0',
      ddly         => '0',
      o            => open
      );

  debug_data_10b <= int_data;

  inst_decode_8b10b : decode_8b10b
    port map (
      clk             => clk_1x,
      data_in         => int_data,
      data_out        => data_out,
      is_k            => is_k,
      code_error      => code_error,
      disparity_error => disparity_error
      );

end architecture rtl;

--
-- crc_32
--
-- Standard ethernet frame CRC-32 calculator and checker.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc_32 is
  port (
    sync_reset : in  std_logic;
    clk        : in  std_logic;
    enable     : in  std_logic := '1';
    data       : in  std_logic_vector(7 downto 0);
    crc        : out std_logic_vector(31 downto 0);
    error      : out std_logic
    );
end crc_32;

architecture rtl of crc_32 is

  -- Reverse the input vector
  function reversed(slv : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(slv'reverse_range);
  begin
    for i in slv'range loop
      result(i) := slv(i);
    end loop;
    return result;
  end reversed;

  function crc_gen (data_in : std_logic_vector(7 downto 0); crc_in : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable d      : std_logic_vector(7 downto 0);
    variable c      : std_logic_vector(31 downto 0);
    variable newcrc : std_logic_vector(31 downto 0);
  begin
    d          := data_in;
    c          := crc_in;
    newcrc(0)  := d(6) xor d(0) xor c(24) xor c(30);
    newcrc(1)  := d(7) xor d(6) xor d(1) xor d(0) xor c(24) xor c(25) xor c(30) xor c(31);
    newcrc(2)  := d(7) xor d(6) xor d(2) xor d(1) xor d(0) xor c(24) xor c(25) xor c(26) xor c(30) xor c(31);
    newcrc(3)  := d(7) xor d(3) xor d(2) xor d(1) xor c(25) xor c(26) xor c(27) xor c(31);
    newcrc(4)  := d(6) xor d(4) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(28) xor c(30);
    newcrc(5)  := d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(24) xor c(25) xor c(27) xor c(28) xor c(29) xor c(30) xor c(31);
    newcrc(6)  := d(7) xor d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30) xor c(31);
    newcrc(7)  := d(7) xor d(5) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(29) xor c(31);
    newcrc(8)  := d(4) xor d(3) xor d(1) xor d(0) xor c(0) xor c(24) xor c(25) xor c(27) xor c(28);
    newcrc(9)  := d(5) xor d(4) xor d(2) xor d(1) xor c(1) xor c(25) xor c(26) xor c(28) xor c(29);
    newcrc(10) := d(5) xor d(3) xor d(2) xor d(0) xor c(2) xor c(24) xor c(26) xor c(27) xor c(29);
    newcrc(11) := d(4) xor d(3) xor d(1) xor d(0) xor c(3) xor c(24) xor c(25) xor c(27) xor c(28);
    newcrc(12) := d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(4) xor c(24) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30);
    newcrc(13) := d(7) xor d(6) xor d(5) xor d(3) xor d(2) xor d(1) xor c(5) xor c(25) xor c(26) xor c(27) xor c(29) xor c(30) xor c(31);
    newcrc(14) := d(7) xor d(6) xor d(4) xor d(3) xor d(2) xor c(6) xor c(26) xor c(27) xor c(28) xor c(30) xor c(31);
    newcrc(15) := d(7) xor d(5) xor d(4) xor d(3) xor c(7) xor c(27) xor c(28) xor c(29) xor c(31);
    newcrc(16) := d(5) xor d(4) xor d(0) xor c(8) xor c(24) xor c(28) xor c(29);
    newcrc(17) := d(6) xor d(5) xor d(1) xor c(9) xor c(25) xor c(29) xor c(30);
    newcrc(18) := d(7) xor d(6) xor d(2) xor c(10) xor c(26) xor c(30) xor c(31);
    newcrc(19) := d(7) xor d(3) xor c(11) xor c(27) xor c(31);
    newcrc(20) := d(4) xor c(12) xor c(28);
    newcrc(21) := d(5) xor c(13) xor c(29);
    newcrc(22) := d(0) xor c(14) xor c(24);
    newcrc(23) := d(6) xor d(1) xor d(0) xor c(15) xor c(24) xor c(25) xor c(30);
    newcrc(24) := d(7) xor d(2) xor d(1) xor c(16) xor c(25) xor c(26) xor c(31);
    newcrc(25) := d(3) xor d(2) xor c(17) xor c(26) xor c(27);
    newcrc(26) := d(6) xor d(4) xor d(3) xor d(0) xor c(18) xor c(24) xor c(27) xor c(28) xor c(30);
    newcrc(27) := d(7) xor d(5) xor d(4) xor d(1) xor c(19) xor c(25) xor c(28) xor c(29) xor c(31);
    newcrc(28) := d(6) xor d(5) xor d(2) xor c(20) xor c(26) xor c(29) xor c(30);
    newcrc(29) := d(7) xor d(6) xor d(3) xor c(21) xor c(27) xor c(30) xor c(31);
    newcrc(30) := d(7) xor d(4) xor c(22) xor c(28) xor c(31);
    newcrc(31) := d(5) xor c(23) xor c(29);
    return newcrc;
  end crc_gen;

  -- Magic residue for ethernet CRC
  constant residue     : std_logic_vector(31 downto 0) := x"C704DD7B";
  signal reversed_data : std_logic_vector(7 downto 0);
  signal int_crc       : std_logic_vector(31 downto 0) := x"FFFFFFFF";

begin

  -- Reverse the data bits
  reversed_data <= reversed(data);

  -- CRC calculation
  calc : process(clk)
  begin
    if (rising_edge(clk)) then
      if (sync_reset = '1') then
        int_crc <= (others => '1');
      else
        if (enable = '1') then
          int_crc <= crc_gen(reversed_data, int_crc);
        end if;
      end if;
    end if;
  end process calc;

  crc   <= int_crc;
  error <= '1' when int_crc /= residue else '0';

end rtl;

--
-- k7_tx_8b10b
--
-- 8b10b communication system, with flow control
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;

entity k7_tx_8b10b is
  port (

    -- SERDES reset
    serdes_reset : std_logic;

    -- Byte clock and DDR 10b clock
    clk_1x, clk_5x : in std_logic;

    -- LVDS serial data out
    tx_p, tx_n : out std_logic;

    -- Parallel data in & word read strobe
    data_in : in std_logic_vector(7 downto 0);
    is_k    : in std_logic

    );
end entity k7_tx_8b10b;

architecture rtl of k7_tx_8b10b is

  component encode_8b10b
  port(
    clk      : in  std_logic;
    is_k     : in  std_logic;
    data_in  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(9 downto 0)
    );
  end component;  

  signal value_10b                : std_logic_vector(9 downto 0);
  signal data_out, shift1, shift2 : std_logic;

begin

  -- 8b10b encoder
  inst_encode_8b10b : encode_8b10b
    port map (
      clk      => clk_1x,
      is_k     => is_k,
      data_in  => data_in,
      data_out => value_10b
      );

  -- OSERDESE2 master instance
  inst_oserdes_master : component unisim.vcomponents.OSERDESE2
    generic map (
      DATA_RATE_OQ   => "DDR",
      DATA_RATE_TQ   => "SDR",
      DATA_WIDTH     => 10,
      SERDES_MODE    => "MASTER",
      TRISTATE_WIDTH => 1
      )
    port map (
      rst      => serdes_reset,
      oq       => data_out,
      clk      => clk_5x,
      clkdiv   => clk_1x,
      d1       => value_10b(0),
      d2       => value_10b(1),
      d3       => value_10b(2),
      d4       => value_10b(3),
      d5       => value_10b(4),
      d6       => value_10b(5),
      d7       => value_10b(6),
      d8       => value_10b(7),
      oce      => '1',
      shiftin1 => shift1,
      shiftin2 => shift2,
      t1       => '0',
      t2       => '0',
      t3       => '0',
      t4       => '0',
      tbytein  => '0',
      tce      => '0'
      );

  -- OSERDESE2 slave instance
  inst_oserdes_slave : component unisim.vcomponents.OSERDESE2
    generic map (
      DATA_RATE_OQ   => "DDR",
      DATA_RATE_TQ   => "SDR",
      DATA_WIDTH     => 10,
      SERDES_MODE    => "SLAVE",
      TRISTATE_WIDTH => 1
      )
    port map (
      rst       => serdes_reset,
      clk       => clk_5x,
      clkdiv    => clk_1x,
      d1        => '1',
      d2        => '1',
      d3        => value_10b(8),
      d4        => value_10b(9),
      d5        => '1',
      d6        => '1',
      d7        => '1',
      d8        => '1',
      oce       => '1',
      shiftout1 => shift1,
      shiftout2 => shift2,
      shiftin1  => '0',
      shiftin2  => '0',
      t1        => '0',
      t2        => '0',
      t3        => '0',
      t4        => '0',
      tbytein   => '0',
      tce       => '0'
      );

  -- LVDS output buffer
  inst_data_out_obufds : component unisim.vcomponents.OBUFDS
    generic map (
      IOSTANDARD => "LVDS_25",
      SLEW       => "FAST"
      )
    port map (
      O  => tx_p,
      OB => tx_n,
      I  => data_out
      );

end architecture rtl;

--
-- comms_link
--
-- High speed tx/rx 8b10b pair with associated synchronization and flow control
-- logic for Kintex-7 side of HS link.
--
-- [K28.5] is used as alignment / sync comma (at least two consecutive K28.5s allow for
-- disparity match on the receiver irrepective of its current running disparity).
-- [LAST_BYTE, K28.3, CRC, CRC, CRC, CRC] is end of frame marker plus packet CRC.
-- [K28.4] is a backpressure request and the other side of the link must
-- not transmit more data for a fixed period after receipt to avoid
-- overflow of the receiver FIFO.
-- [K28.2] is a phase-shift request from the RX on the other side of the link.
-- It triggers a single phase shift operation in the Kintex MMCM.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Mercury kernel - rx link trainer
-- Could have implemented as a VHDL state machine but it
-- would have more complex and taken more space
--library link_trainer;

entity comms_link is
  port (

    -- Synchronized internally to clk
    async_reset : in std_logic;

    -- Common clocks
    clk_1x_tx, clk_1x_rx : in std_logic;
    clk_5x_tx, clk_5x_rx : in std_logic;

    -- TX phase shift request clocked in the RX 1x domain
    tx_phase_shift : out std_logic;

    -- TX / RX LVDS ports
    tx_p, tx_n : out std_logic;
    rx_p, rx_n : in  std_logic;

    -- Channel FIFO interface
    outbound_data      : in  std_logic_vector(7 downto 0);
    outbound_available : in  std_logic;
    outbound_frame_end : in  std_logic;
    outbound_read      : out std_logic;

    inbound_data      : out std_logic_vector(7 downto 0);
    inbound_available : in  std_logic;  -- NOTE: To compensate for latency,
                                        -- this must depend on almost-full,
                                        -- not full.
    inbound_frame_end : out std_logic;
    inbound_write     : out std_logic;

    -- Debug signals (RX domain) - do not connect for normal use
    debug_rx_10b_data_out        : out std_logic_vector(9 downto 0);
    debug_rx_is_k                : out std_logic;
    debug_rx_data_out            : out std_logic_vector(7 downto 0);
    debug_rx_locked              : out std_logic;
    debug_rx_delay               : out std_logic_vector(4 downto 0);
    debug_rx_code_error          : out std_logic;
    debug_rx_disparity_error     : out std_logic;
    debug_rx_crc_error           : out std_logic;
    debug_rx_backpressure_needed : out std_logic;
    debug_tx_backpressure_needed : out std_logic;
    debug_rx_delay_start         : out std_logic_vector(7 downto 0);
    debug_rx_delay_end           : out std_logic_vector(7 downto 0);
    debug_rx_delay_last_start    : out std_logic_vector(7 downto 0);
    debug_rx_delay_last_end      : out std_logic_vector(7 downto 0);
    debug_rx_scan_bits           : out std_logic_vector(31 downto 0)

    );
end entity comms_link;

architecture rtl of comms_link is

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
    component k7_tx_8b10b
    port (
      -- SERDES reset
      serdes_reset : std_logic;

      -- Byte clock and DDR 10b clock
      clk_1x, clk_5x : in std_logic;

      -- LVDS serial data out
      tx_p, tx_n : out std_logic;

      -- Parallel data in & word read strobe
      data_in : in std_logic_vector(7 downto 0);
      is_k    : in std_logic
      );
  end component;
  component k7_rx_8b10b
    port (
      -- SERDES reset
      serdes_reset : std_logic;

      -- Byte clock and DDR 10b clock
      clk_1x, clk_5x : in std_logic;

      ---- Serial data in
      rx_p, rx_n : in std_logic;

      -- IDELAY setting and bitslip controls
      delay   : in std_logic_vector(4 downto 0);
      bitslip : in std_logic;

      -- Data outputs
      is_k, code_error, disparity_error : out std_logic;
      data_out                          : out std_logic_vector(7 downto 0);

      debug_data_10b : out std_logic_vector(9 downto 0)

      );
  end component;
  component crc_32
    port (
      sync_reset : in  std_logic;
      clk        : in  std_logic;
      enable     : in  std_logic := '1';
      data       : in  std_logic_vector(7 downto 0);
      crc        : out std_logic_vector(31 downto 0);
      error      : out std_logic
      );
  end component;
  component link_trainer
  port (
    clk : in std_logic;
    sync_reset : in  std_logic;
    rx_bitslip : out std_logic;
    rx_delay : out std_logic_vector(4 downto 0);
    rx_disparity_error : in std_logic;
    rx_crc_error : in std_logic;
    rx_code_error : in std_logic;
    rx_locked : out std_logic;
    rx_delay_start : out std_logic_vector(7 downto 0);
    rx_delay_end : out std_logic_vector(7 downto 0);
    rx_delay_last_start : out std_logic_vector(7 downto 0);
    rx_delay_last_end : out std_logic_vector(7 downto 0);
    rx_scan_bits : out std_logic_vector(31 downto 0)
    );
end component;

  -- K codes
  constant K28P2 : std_logic_vector(7 downto 0) := x"5C";
  constant K28P3 : std_logic_vector(7 downto 0) := x"7C";
  constant K28P4 : std_logic_vector(7 downto 0) := x"9C";
  constant K28P5 : std_logic_vector(7 downto 0) := x"BC";
  --constant K28P6 : std_logic_vector(7 downto 0) := x"DC";

  constant K_COMMA                : std_logic_vector(7 downto 0) := K28P5;
  constant K_CRC                  : std_logic_vector(7 downto 0) := K28P3;
  constant K_BACKPRESSURE_REQUEST : std_logic_vector(7 downto 0) := K28P4;
  constant K_PHASE_SHIFT          : std_logic_vector(7 downto 0) := K28P2;

  -- Signals
  signal tx_sync_reset, rx_sync_reset, rx_trainer_sync_reset             : std_logic                     := '1';
  signal tx_backpressure_needed                                          : std_logic                     := '0';
  signal rx_bitslip, rx_locked, rx_backpressure_needed                   : std_logic                     := '0';
  signal rx_delay                                                        : std_logic_vector(4 downto 0)  := "00000";
  signal rx_crc_error, rx_code_error, rx_disparity_error                 : std_logic                     := '0';
  signal tx_crc, rx_crc, latched_tx_crc, latched_rx_crc, received_rx_crc : std_logic_vector(31 downto 0) := (others => '0');
  signal tx_backpressure_count                                           : natural range 31 downto 0     := 0;
  signal rx_backpressure_count                                           : natural range 15 downto 0     := 0;
  signal rx_crc_count                                                    : natural range 4 downto 0      := 0;
  signal tx_data_in, rx_data_out                                         : std_logic_vector(7 downto 0)  := (others => '0');
  signal int_outbound_read, tx_is_k, rx_is_k                             : std_logic                     := '0';
  signal tx_crc_reset, rx_crc_reset                                      : std_logic                     := '1';
  signal tx_crc_enable, rx_crc_enable                                    : std_logic                     := '0';

  -- TX state
  type type_tx_state is (
    COMMA,
    TRANSMIT,
    CRC_LATCH,
    CRC_COPY,
    CRC_RESET,
    BACKPRESSURE
    );
  signal tx_state              : type_tx_state              := CRC_RESET;
  signal tx_state_proc_counter : natural range 255 downto 0 := 15;

  -- RX state
  type type_rx_state is (
    WAIT_LOCK,
    RECEIVE_DATA,
    RECEIVE_CRC,
    CHECK_CRC,
    WAIT_RETRAIN
    );
  signal rx_state              : type_rx_state            := WAIT_LOCK;
  signal rx_state_proc_counter : natural range 3 downto 0 := 3;

  -- Inbound registered / debug signals & CDCs
  signal int_inbound_write, int_inbound_frame_end, pre_inbound_write                                                                                                                                                                                                                  : std_logic                    := '0';
  signal pre_inbound_data                                                                                                                                                                                                                                                             : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_state_is_backpressure, pre_tx_state_is_backpressure, rx_domain_tx_state_is_backpressure, r_rx_domain_tx_state_is_backpressure, r_tx_domain_tx_backpressure_needed, r_tx_domain_rx_backpressure_needed, tx_domain_tx_backpressure_needed, tx_domain_rx_backpressure_needed : std_logic                    := '1';
  signal rx_delay_start, rx_delay_end, rx_delay_last_start, rx_delay_last_end                                                                                                                                                                                                         : std_logic_vector(7 downto 0) := (others => '0');
  signal int_phase_shift, inv_rx_locked                                                                                                                                                                                                                                                              : std_logic                    := '0';

begin

  -- Debug signals
  debug_rx_data_out            <= rx_data_out;
  debug_rx_is_k                <= rx_is_k;
  debug_rx_locked              <= rx_locked;
  debug_rx_delay               <= rx_delay;
  debug_rx_crc_error           <= rx_crc_error;
  debug_rx_disparity_error     <= rx_disparity_error;
  debug_rx_code_error          <= rx_code_error;
  debug_tx_backpressure_needed <= tx_backpressure_needed;
  debug_rx_backpressure_needed <= rx_backpressure_needed;
  debug_rx_delay_start         <= rx_delay_start;
  debug_rx_delay_end           <= rx_delay_end;
  debug_rx_delay_last_start    <= rx_delay_last_start;
  debug_rx_delay_last_end      <= rx_delay_last_end;

  -- Transmitter only comes out of reset once the rx is locked
  -- This intentionally stalls the receiver on the other end - training of the
  -- Spartan comes after the Kintex has locked so we ensure the phase shift signals
  -- are properly received
  inst_sync_tx_reset_gen : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => clk_1x_tx,
      input  => inv_rx_locked,
      output => tx_sync_reset
      );
  inv_rx_locked <= not(rx_locked);

  inst_sync_rx_reset_gen : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => clk_1x_rx,
      input  => async_reset,
      output => rx_sync_reset
      );

  -- TX state process
  tx_state_proc : process(clk_1x_tx)
  begin
    if rising_edge(clk_1x_tx) then
      if tx_sync_reset = '1' then
        tx_state              <= COMMA;
        tx_state_proc_counter <= 3;
      else
        case tx_state is

          -- Generate a stream of 4 commas
          when COMMA =>
            tx_state_proc_counter <= tx_state_proc_counter - 1;
            if tx_state_proc_counter = 0 then
              tx_state              <= TRANSMIT;
              tx_state_proc_counter <= 255;
            end if;
            -- Generate commas if we are asked pause transmission
            if r_tx_domain_tx_backpressure_needed = '1' then
              tx_state              <= COMMA;
              tx_state_proc_counter <= 3;
            end if;
            -- Send a request for backpressure on opposite side of link
            if r_tx_domain_rx_backpressure_needed = '1' then
              tx_state <= BACKPRESSURE;
            end if;

          -- Transmit data
          when TRANSMIT =>
            tx_state_proc_counter <= tx_state_proc_counter - 1;
            -- Throw in a comma block after 256 bytes
            if tx_state_proc_counter = 0 then
              tx_state              <= COMMA;
              tx_state_proc_counter <= 3;
            end if;
            -- Generate commas if we are asked to stop transmitting
            if r_tx_domain_tx_backpressure_needed = '1' then
              tx_state              <= COMMA;
              tx_state_proc_counter <= 3;
            end if;
            -- Request backpressure on opposite side of link
            if r_tx_domain_rx_backpressure_needed = '1' then
              tx_state <= BACKPRESSURE;
            end if;
            -- Finish checksum even if we see a backpressure request if we
            -- just ended a frame as it isn't 'data' anyway
            if (outbound_frame_end and outbound_available) = '1' then
              tx_state <= CRC_LATCH;
            end if;

          when CRC_LATCH =>
            tx_state_proc_counter <= 3;
            tx_state              <= CRC_COPY;

          when CRC_COPY =>
            tx_state_proc_counter <= tx_state_proc_counter - 1;
            if tx_state_proc_counter = 0 then
              tx_state <= CRC_RESET;
            end if;

          when CRC_RESET =>
            tx_state              <= COMMA;
            tx_state_proc_counter <= 3;

          when BACKPRESSURE =>
            tx_state              <= COMMA;
            tx_state_proc_counter <= 3;

          when others =>
            tx_state              <= COMMA;
            tx_state_proc_counter <= 3;

        end case;
      end if;
    end if;
  end process tx_state_proc;

  -- Latch-and-shift for TX CRC
  tx_crc_proc : process(clk_1x_tx)
  begin
    if rising_edge(clk_1x_tx) then
      if tx_state = CRC_LATCH then
        latched_tx_crc <= tx_crc;
      else
        latched_tx_crc <= latched_tx_crc(23 downto 0) & x"00";
      end if;
    end if;
  end process tx_crc_proc;

  -- Coding mux for transmitter
  tx_data_in <= outbound_data when (tx_state = TRANSMIT) and (outbound_available = '1') else
                K28P3                        when (tx_state = CRC_LATCH) else
                latched_tx_crc(31 downto 24) when (tx_state = CRC_COPY) else
                K28P4                        when (tx_state = BACKPRESSURE) else
                K28P5;

  tx_is_k <= '0' when (tx_state = TRANSMIT) and (outbound_available = '1') else
             '1' when (tx_state = CRC_LATCH) else
             '0' when (tx_state = CRC_COPY) else
             '1' when (tx_state = BACKPRESSURE) else
             '1';

  -- Other control logic
  outbound_read     <= int_outbound_read;
  int_outbound_read <= '1' when (tx_state = TRANSMIT)                                                        else '0';
  tx_crc_reset      <= '1' when (tx_state = CRC_RESET)                                                       else '0';
  tx_crc_enable     <= '1' when (tx_state = TRANSMIT) and ((outbound_available and int_outbound_read) = '1') else '0';

  -- TX checksum block
  inst_tx_checksum : crc_32
    port map (
      sync_reset => tx_crc_reset,
      clk        => clk_1x_tx,
      enable     => tx_crc_enable,
      data       => outbound_data,
      crc        => tx_crc
      );

  -- TX block including 8b10b encoder
  inst_k7_tx_8b10b : k7_tx_8b10b
    port map (
      serdes_reset => tx_sync_reset,
      clk_1x       => clk_1x_tx,
      clk_5x       => clk_5x_tx,
      tx_p         => tx_p,
      tx_n         => tx_n,
      data_in      => tx_data_in,
      is_k         => tx_is_k
      );

  -- Mercury kernel - trains the receiver, retrains on any error after lock
  inst_rx_link_trainer : link_trainer
    port map (
      clk                 => clk_1x_rx,
      sync_reset          => rx_sync_reset,
      rx_bitslip          => rx_bitslip,
      rx_delay            => rx_delay,
      rx_crc_error        => rx_crc_error,
      rx_disparity_error  => rx_disparity_error,
      rx_code_error       => rx_code_error,
      rx_locked           => rx_locked,
      rx_delay_start      => rx_delay_start,
      rx_delay_end        => rx_delay_end,
      rx_delay_last_start => rx_delay_last_start,
      rx_delay_last_end   => rx_delay_last_end,
      rx_scan_bits        => debug_rx_scan_bits
      );

  -- RX block including 8b10b decoder
  inst_k7_rx_8b10b : k7_rx_8b10b
    port map (
      serdes_reset    => rx_sync_reset,
      clk_1x          => clk_1x_rx,
      clk_5x          => clk_5x_rx,
      rx_p            => rx_p,
      rx_n            => rx_n,
      delay           => rx_delay,
      bitslip         => rx_bitslip,
      data_out        => rx_data_out,
      is_k            => rx_is_k,
      code_error      => rx_code_error,
      disparity_error => rx_disparity_error,
      debug_data_10b  => debug_rx_10b_data_out
      );

  -- RX checksum block
  inst_rx_checksum : crc_32
    port map (
      sync_reset => rx_crc_reset,
      clk        => clk_1x_rx,
      enable     => rx_crc_enable,
      data       => rx_data_out,
      crc        => rx_crc
      );

  rx_crc_enable <= '1' when (rx_is_k = '0') and (rx_state = RECEIVE_DATA)
                   else '0';

  -- The clocks for each side are decoupled so you have to use a CDC method
  -- to pass the signals between them.

  -- CDC to shift TX backpressure request into TX domain
  tx_domain_tx_backpressure_needed   <= tx_backpressure_needed           when rising_edge(clk_1x_tx);
  r_tx_domain_tx_backpressure_needed <= tx_domain_tx_backpressure_needed when rising_edge(clk_1x_tx);

  -- Backpressure request detection
  -- This will stall transmission for at least 32 clock cycles
  tx_backpressure_proc : process(clk_1x_rx)
  begin
    if rising_edge(clk_1x_rx) then
      tx_backpressure_needed <= '0';
      if rx_locked = '0' then
        -- Force idle TX when RX is not locked to prevent accidental overflow
        tx_backpressure_count  <= 31;
        tx_backpressure_needed <= '1';
      else
        if (rx_data_out = K28P4) and (rx_is_k = '1') then
          tx_backpressure_count  <= 31;
          tx_backpressure_needed <= '1';
        elsif tx_backpressure_count /= 0 then
          tx_backpressure_count  <= tx_backpressure_count - 1;
          tx_backpressure_needed <= '1';
        end if;
      end if;
    end if;
  end process tx_backpressure_proc;

  -- CDC to shift TX backpressure signal into RX domain and RX backpressure
  -- signal into TX domain
  pre_tx_state_is_backpressure         <= '1'                                when tx_state = BACKPRESSURE else '0';
  tx_state_is_backpressure             <= pre_tx_state_is_backpressure       when rising_edge(clk_1x_tx);
  rx_domain_tx_state_is_backpressure   <= tx_state_is_backpressure           when rising_edge(clk_1x_rx);
  r_rx_domain_tx_state_is_backpressure <= rx_domain_tx_state_is_backpressure when rising_edge(clk_1x_rx);

  tx_domain_rx_backpressure_needed   <= rx_backpressure_needed           when rising_edge(clk_1x_tx);
  r_tx_domain_rx_backpressure_needed <= tx_domain_rx_backpressure_needed when rising_edge(clk_1x_tx);

  -- Backpressure request generation
  -- Generate one every 16 clock cycles
  rx_backpressure_proc : process(clk_1x_rx)
  begin
    if rising_edge(clk_1x_rx) then
      -- Clear the backpressure request when the TX sends one to the other end
      if r_rx_domain_tx_state_is_backpressure = '1' then
        rx_backpressure_needed <= '0';
      end if;
      -- The counter prevents too many requests jamming up the TX with backpressure
      -- requests instead of continuing to send data
      if rx_backpressure_count /= 0 then
        rx_backpressure_count <= rx_backpressure_count - 1;
      elsif inbound_available = '0' then
        rx_backpressure_count  <= 15;
        rx_backpressure_needed <= '1';
      end if;
    end if;
  end process rx_backpressure_proc;

  -- Data transfer
  -- Only transfer when locked
  -- Latch-and-shift for RX CRC
  rx_state_proc : process(clk_1x_rx)
  begin
    if rising_edge(clk_1x_rx) then

      rx_crc_error <= '0';
      rx_crc_reset <= '0';

      if (rx_locked = '0') then
        rx_state <= WAIT_LOCK;
      else
        case rx_state is

          when WAIT_LOCK =>
            -- If we are here, by design we are locked
            rx_state <= RECEIVE_DATA;

          when RECEIVE_DATA =>
            -- Keep an eye out for packet end
            if (rx_data_out = K28P3) and (rx_is_k = '1') then
              -- Frame end is not delayed by a cycle to align with byte written
              -- in previous clock cycle
              latched_rx_crc        <= rx_crc;
              rx_crc_reset          <= '1';
              rx_state_proc_counter <= 3;
              -- End of packet, followed by CRC
              rx_state              <= RECEIVE_CRC;
            end if;

          when RECEIVE_CRC =>
            received_rx_crc       <= received_rx_crc(23 downto 0) & rx_data_out;
            rx_state_proc_counter <= rx_state_proc_counter - 1;
            if rx_state_proc_counter = 0 then
              rx_state <= CHECK_CRC;
            end if;

          when CHECK_CRC =>
            rx_state <= RECEIVE_DATA;
            if latched_rx_crc /= received_rx_crc then
              rx_crc_error <= '1';
              rx_state     <= WAIT_RETRAIN;
            end if;

          when WAIT_RETRAIN =>
            rx_crc_error <= '1';
            rx_state     <= WAIT_RETRAIN;

          when others =>
            rx_state <= WAIT_RETRAIN;

        end case;

      end if;
    end if;
  end process rx_state_proc;

  -- Phase shift receiver
  int_phase_shift <= '1' when (rx_is_k = '1') and (rx_data_out = K_PHASE_SHIFT) else
                     '0';
  tx_phase_shift <= int_phase_shift when rising_edge(clk_1x_rx);

  -- Output to FIFO
  int_inbound_write     <= '1' when (rx_is_k = '0') and (rx_state = RECEIVE_DATA) else '0';
  int_inbound_frame_end <= '1' when (rx_is_k = '1') and (rx_data_out = K28P3)     else '0';

  -- Frame end is signalled the cycle after the last byte, so we only register
  -- once to align the strobe
  pre_inbound_write <= int_inbound_write     when rising_edge(clk_1x_rx);
  pre_inbound_data  <= rx_data_out           when rising_edge(clk_1x_rx);
  inbound_write     <= pre_inbound_write     when rising_edge(clk_1x_rx);
  inbound_data      <= pre_inbound_data      when rising_edge(clk_1x_rx);
  inbound_frame_end <= int_inbound_frame_end when rising_edge(clk_1x_rx);

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unimacro;

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

    -- Reset signal output to rest of system
    async_reset : out std_logic;

    -- Reference 50MHz clock from Spartan-6
    clk_sys_p, clk_sys_n : in std_logic;

    -- System clock reference from MMCM
    -- Jitter-cleaned reference for other clock generation
    -- in application firmware layer. Buffer in application.
    clk_50mhz_no_buf : out std_logic;

    -- 100MHz reference for core interfaces
    -- This is internally BUFG'd from the RX clock system.
    clk_100mhz : out std_logic;

    -- Status signals to indicate data is being moved in / out of the FPGA
    -- (clk_100mhz domain)
    transmitting, receiving : out std_logic;

    -- Differential pins connected to Spartan-6 - Kintex-7 bridge
    data_in_p, data_in_n   : in  std_logic;
    data_out_p, data_out_n : out std_logic;

    -- LED pass-through interface (clk_100mhz domain)
    led_lpc_r, led_lpc_g, led_lpc_b : in std_logic := '0';
    led_hpc_r, led_hpc_g, led_hpc_b : in std_logic := '0';

    -- Channel 1 interface (port 50004)
    channel_1_clk                : in  std_logic;
    channel_1_inbound_data       : out std_logic_vector(7 downto 0);
    channel_1_inbound_available  : out std_logic;
    channel_1_inbound_frame_end  : out std_logic;
    channel_1_inbound_read       : in  std_logic                    := '1';
    channel_1_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_1_outbound_available : out std_logic;
    channel_1_outbound_frame_end : in  std_logic                    := '1';
    channel_1_outbound_write     : in  std_logic                    := '0';

    -- Channel 2 interface (port 50005)
    channel_2_clk                : in  std_logic;
    channel_2_inbound_data       : out std_logic_vector(7 downto 0);
    channel_2_inbound_available  : out std_logic;
    channel_2_inbound_frame_end  : out std_logic;
    channel_2_inbound_read       : in  std_logic                    := '1';
    channel_2_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_2_outbound_available : out std_logic;
    channel_2_outbound_frame_end : in  std_logic                    := '1';
    channel_2_outbound_write     : in  std_logic                    := '0';

    -- Channel 3 interface (port 50006)
    channel_3_clk                : in  std_logic;
    channel_3_inbound_data       : out std_logic_vector(7 downto 0);
    channel_3_inbound_available  : out std_logic;
    channel_3_inbound_frame_end  : out std_logic;
    channel_3_inbound_read       : in  std_logic                    := '1';
    channel_3_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_3_outbound_available : out std_logic;
    channel_3_outbound_frame_end : in  std_logic                    := '1';
    channel_3_outbound_write     : in  std_logic                    := '0';

    -- Channel 4 interface (port 50007)
    channel_4_clk                : in  std_logic;
    channel_4_inbound_data       : out std_logic_vector(7 downto 0);
    channel_4_inbound_available  : out std_logic;
    channel_4_inbound_frame_end  : out std_logic;
    channel_4_inbound_read       : in  std_logic                    := '1';
    channel_4_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    channel_4_outbound_available : out std_logic;
    channel_4_outbound_frame_end : in  std_logic                    := '1';
    channel_4_outbound_write     : in  std_logic                    := '0';

    -- Multicast
    multicast_clk                : in  std_logic;
    multicast_inbound_data       : out std_logic_vector(7 downto 0);
    multicast_inbound_available  : out std_logic;
    multicast_inbound_frame_end  : out std_logic;
    multicast_inbound_read       : in  std_logic                    := '1';
    multicast_outbound_data      : in  std_logic_vector(7 downto 0) := (others => '0');
    multicast_outbound_available : out std_logic;
    multicast_outbound_frame_end : in  std_logic                    := '1';
    multicast_outbound_write     : in  std_logic                    := '0';

    -- Debug signals
    debug_rx_10b_data_out        : out std_logic_vector(9 downto 0);
    debug_rx_is_k                : out std_logic;
    debug_rx_data_out            : out std_logic_vector(7 downto 0);
    debug_rx_locked              : out std_logic;
    debug_rx_delay               : out std_logic_vector(4 downto 0);
    debug_rx_code_error          : out std_logic;
    debug_rx_disparity_error     : out std_logic;
    debug_rx_crc_error           : out std_logic;
    debug_rx_backpressure_needed : out std_logic;
    debug_tx_backpressure_needed : out std_logic;
    debug_rx_delay_start         : out std_logic_vector(7 downto 0);
    debug_rx_delay_end           : out std_logic_vector(7 downto 0);
    debug_rx_delay_last_start    : out std_logic_vector(7 downto 0);
    debug_rx_delay_last_end      : out std_logic_vector(7 downto 0);
    debug_rx_scan_bits           : out std_logic_vector(31 downto 0);
    debug_tx_phase_shift_done    : out std_logic

    );
end qf2_core;

architecture rtl of qf2_core is

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
  component comms_link
    port (

      -- Synchronized internally to clk
      async_reset : in std_logic;

      -- Clocks
      clk_1x_tx, clk_1x_rx : in std_logic;
      clk_5x_tx, clk_5x_rx : in std_logic;

      -- TX phase shift request
      tx_phase_shift : out std_logic;

      -- TX / RX LVDS ports
      tx_p, tx_n : out std_logic;
      rx_p, rx_n : in  std_logic;

      -- Channel FIFO interface
      outbound_data      : in  std_logic_vector(7 downto 0);
      outbound_available : in  std_logic;
      outbound_frame_end : in  std_logic;
      outbound_read      : out std_logic;

      inbound_data      : out std_logic_vector(7 downto 0);  -- := (others => '0');
      inbound_available : in  std_logic;  -- NOTE: To compensate for latency,
                                          -- this must depend on almost-full,
                                          -- not full.
      inbound_frame_end : out std_logic;  --                    := '0';
      inbound_write     : out std_logic;  --                    := '0';

      -- Debug signals
      debug_rx_10b_data_out        : out std_logic_vector(9 downto 0);
      debug_rx_is_k                : out std_logic;
      debug_rx_data_out            : out std_logic_vector(7 downto 0);
      debug_rx_locked              : out std_logic;
      debug_rx_delay               : out std_logic_vector(4 downto 0);
      debug_rx_code_error          : out std_logic;
      debug_rx_disparity_error     : out std_logic;
      debug_rx_crc_error           : out std_logic;
      debug_rx_backpressure_needed : out std_logic;
      debug_tx_backpressure_needed : out std_logic;
      debug_rx_delay_start         : out std_logic_vector(7 downto 0);
      debug_rx_delay_end           : out std_logic_vector(7 downto 0);
      debug_rx_delay_last_start    : out std_logic_vector(7 downto 0);
      debug_rx_delay_last_end      : out std_logic_vector(7 downto 0);
      debug_rx_scan_bits           : out std_logic_vector(31 downto 0)

      );
  end component;
  component base
    port (

      -- Reset signal output to rest of system
      async_reset : out std_logic;

      -- Reference 50MHz clock from Spartan-6
      clk_sys_p, clk_sys_n : in std_logic;

      -- System clock reference from MMCM
      -- Jitter-cleaned reference for other clock generation
      -- in application firmware layer. Buffer in application.
      clk_50mhz_no_buf : out std_logic;

      -- 100MHz reference for core interfaces
      -- This is internally BUFG'd from the RX clock system.
      clk_100mhz : out std_logic;

      -- TX communication clocks
      -- These are phase-shifted based on commands received
      -- from the Spartan. This overcomes the inherent limitations
      -- of the Spartan-6 silicon. There are 84 11.9ps taps and then
      -- the phase shifter will wrap.
      clk_100mhz_tx : out std_logic;
      clk_500mhz_tx : out std_logic;

      -- PS en should be pulsed for one clock cycle in the clk_100mhz_rx domain. 
      tx_ps_en   : in  std_logic;
      tx_ps_done : out std_logic;

      -- RX communication clocks
      -- These are configured with static phase.
      -- The idelay is used to synchronize
      clk_100mhz_rx : out std_logic;
      clk_500mhz_rx : out std_logic

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
  signal inbound_bridge_almost_full                  : std_logic;
  signal inbound_bridge_available                    : std_logic;
  signal inbound_bridge_write                        : std_logic;
  signal outbound_bridge_dout, outbound_bridge_din   : std_logic_vector(8 downto 0);
  signal outbound_bridge_empty, outbound_bridge_full : std_logic;
  signal outbound_bridge_read                        : std_logic;

  -- LED update signals
  signal led_outbound_read  : std_logic := '0';
  signal led_outbound_empty : std_logic := '1';
  signal led_outbound_dout  : std_logic_vector(8 downto 0);

  -- Channel FIFO signals
  signal int_channel_1_clk                                           : std_logic := '0';
  signal channel_1_inbound_fifo_din, channel_1_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_1_inbound_fifo_write, channel_1_inbound_fifo_read   : std_logic;
  signal channel_1_inbound_fifo_full, channel_1_inbound_fifo_empty   : std_logic;
  signal channel_1_outbound_fifo_din, channel_1_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_1_outbound_fifo_write, channel_1_outbound_fifo_read : std_logic;
  signal channel_1_outbound_fifo_full, channel_1_outbound_fifo_empty : std_logic;

  signal int_channel_2_clk                                           : std_logic := '0';
  signal channel_2_inbound_fifo_din, channel_2_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_2_inbound_fifo_write, channel_2_inbound_fifo_read   : std_logic;
  signal channel_2_inbound_fifo_full, channel_2_inbound_fifo_empty   : std_logic;
  signal channel_2_outbound_fifo_din, channel_2_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_2_outbound_fifo_write, channel_2_outbound_fifo_read : std_logic;
  signal channel_2_outbound_fifo_full, channel_2_outbound_fifo_empty : std_logic;

  signal int_channel_3_clk                                           : std_logic := '0';
  signal channel_3_inbound_fifo_din, channel_3_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_3_inbound_fifo_write, channel_3_inbound_fifo_read   : std_logic;
  signal channel_3_inbound_fifo_full, channel_3_inbound_fifo_empty   : std_logic;
  signal channel_3_outbound_fifo_din, channel_3_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_3_outbound_fifo_write, channel_3_outbound_fifo_read : std_logic;
  signal channel_3_outbound_fifo_full, channel_3_outbound_fifo_empty : std_logic;

  signal int_channel_4_clk                                           : std_logic := '0';
  signal channel_4_inbound_fifo_din, channel_4_inbound_fifo_dout     : std_logic_vector(8 downto 0);
  signal channel_4_inbound_fifo_write, channel_4_inbound_fifo_read   : std_logic;
  signal channel_4_inbound_fifo_full, channel_4_inbound_fifo_empty   : std_logic;
  signal channel_4_outbound_fifo_din, channel_4_outbound_fifo_dout   : std_logic_vector(8 downto 0);
  signal channel_4_outbound_fifo_write, channel_4_outbound_fifo_read : std_logic;
  signal channel_4_outbound_fifo_full, channel_4_outbound_fifo_empty : std_logic;

  signal int_multicast_clk                                           : std_logic := '0';
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

  signal clk_100mhz_tx, clk_100mhz_rx, clk_500mhz_tx, clk_500mhz_rx                                                : std_logic;
  signal tx_phase_shift                                                                                            : std_logic                    := '0';
  signal int_clk_100mhz, int_async_reset, tx_sync_reset, rx_sync_reset                                             : std_logic                    := '1';
  signal tx_domain_transmitting, rx_domain_receiving, p_p_transmitting, p_p_receiving, p_transmitting, p_receiving : std_logic                    := '0';
  signal global_domain_leds, tx_domain_leds, r_tx_domain_leds                                                      : std_logic_vector(5 downto 0) := (others => '0');

begin

  -- Base clock / reset block
  inst_base : base
    port map (
      async_reset      => int_async_reset,
      clk_sys_p        => clk_sys_p,
      clk_sys_n        => clk_sys_n,
      clk_50mhz_no_buf => clk_50mhz_no_buf,
      clk_100mhz       => int_clk_100mhz,
      clk_100mhz_tx    => clk_100mhz_tx,
      clk_500mhz_tx    => clk_500mhz_tx,
      clk_100mhz_rx    => clk_100mhz_rx,
      clk_500mhz_rx    => clk_500mhz_rx,
      tx_ps_en         => tx_phase_shift,
      tx_ps_done       => debug_tx_phase_shift_done
      );

  -- Pass-through
  async_reset <= int_async_reset;
  clk_100mhz  <= int_clk_100mhz;

  -- Hold the reset for the receiver after the ISERDES is reset for a
  -- few cycles to allow it to initialise
  inst_tx_sync_reset : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => clk_100mhz_tx,
      input  => int_async_reset,
      output => tx_sync_reset
      );

  -- Use a async-sync shift block to cross the transmitting debug signal into
  -- the global 100MHz domain and hold for a few cycles to ensure passage
  tx_domain_transmitting <= (outbound_word_available and outbound_bridge_read) when rising_edge(clk_100mhz_tx);
  inst_tx_pulse_lengthen : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => int_clk_100mhz,
      input  => tx_domain_transmitting,
      output => p_p_transmitting
      );
  p_transmitting <= p_p_transmitting when rising_edge(int_clk_100mhz);
  transmitting   <= p_transmitting   when rising_edge(int_clk_100mhz);

  outbound_word_available <= not(outbound_bridge_empty);

  inst_outbound_bridge_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
      RDCLK       => clk_100mhz_tx,
      RDEN        => outbound_bridge_read,
      RST         => int_async_reset,
      WRCLK       => clk_100mhz_tx,
      WREN        => outbound_copy
      );

  -- TX demux interface
  proc_tx_demux : process(clk_100mhz_tx)
  begin
    if rising_edge(clk_100mhz_tx) then

      state_outbound_copy <= '0';

      if tx_sync_reset = '1' then
        outbound_stream_select <= "0000";
        outbound_state         <= INIT;
      else

        case outbound_state is

          when INIT =>

            if (outbound_empty or outbound_bridge_full) = '0' then

              -- Map the target
              outbound_target        <= outbound_stream_select;
              outbound_stream_select <= "1111";
              state_outbound_copy    <= '1';
              outbound_state         <= SWITCH;

            else

              -- Check the next stream
              outbound_stream_select <= std_logic_vector(unsigned(outbound_stream_select) + 1);
              if outbound_stream_select = "0101" then
                outbound_stream_select <= "0000";
              end if;

            end if;

          when SWITCH =>

            outbound_stream_select <= outbound_target;
            outbound_state         <= STREAM;

          when STREAM =>

            state_outbound_copy <= '1';

            if outbound_copy = '1' then

              -- Finish on frame end
              if outbound_bridge_din(8) = '1' then

                state_outbound_copy <= '0';
                outbound_state      <= INIT;

                -- Check the next stream
                outbound_stream_select <= std_logic_vector(unsigned(outbound_stream_select) + 1);
                if outbound_stream_select = "0101" then
                  outbound_stream_select <= "0000";
                end if;

              end if;

            end if;

          when others =>
            outbound_stream_select <= "0000";
            outbound_state         <= INIT;

        end case;

      end if;
    end if;
  end process proc_tx_demux;

  outbound_copy <= (not(outbound_empty) and not(outbound_bridge_full)) and state_outbound_copy;

  outbound_empty <=
    channel_1_outbound_fifo_empty when outbound_stream_select = "0000" else
    channel_2_outbound_fifo_empty when outbound_stream_select = "0001" else
    channel_3_outbound_fifo_empty when outbound_stream_select = "0010" else
    channel_4_outbound_fifo_empty when outbound_stream_select = "0011" else
    multicast_outbound_fifo_empty when outbound_stream_select = "0100" else
    led_outbound_empty            when outbound_stream_select = "0101" else
    '0';

  outbound_bridge_din <=
    channel_1_outbound_fifo_dout when outbound_stream_select = "0000" else
    channel_2_outbound_fifo_dout when outbound_stream_select = "0001" else
    channel_3_outbound_fifo_dout when outbound_stream_select = "0010" else
    channel_4_outbound_fifo_dout when outbound_stream_select = "0011" else
    multicast_outbound_fifo_dout when outbound_stream_select = "0100" else
    led_outbound_dout            when outbound_stream_select = "0101" else
    ("00000" & outbound_target);

  channel_1_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0000" else '0';
  channel_2_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0001" else '0';
  channel_3_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0010" else '0';
  channel_4_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0011" else '0';
  multicast_outbound_fifo_read <= outbound_copy when outbound_stream_select = "0100" else '0';
  led_outbound_read            <= outbound_copy when outbound_stream_select = "0101" else '0';

  -- Cross the LED signals from the clk_100mhz domain (or whatever else) into
  -- the TX domain. We don't need to take great care here as a glitch wouldn't
  -- be obvious to anyone visibly inspecting them and is not a critical path.
  global_domain_leds <= led_hpc_b & led_hpc_g & led_hpc_r & led_lpc_b & led_lpc_g & led_lpc_r when rising_edge(int_clk_100mhz);
  tx_domain_leds     <= global_domain_leds                                                    when rising_edge(clk_100mhz_tx);
  r_tx_domain_leds   <= tx_domain_leds                                                        when rising_edge(clk_100mhz_tx);
  inst_led_update_proc : process(clk_100mhz_tx)
  begin
    if rising_edge(clk_100mhz_tx) then
      if tx_sync_reset = '1' then
        -- Initialize LED status on reset
        led_outbound_empty <= '0';
        led_outbound_dout  <= "100" & r_tx_domain_leds;
      else
        if led_outbound_empty = '0' then
          if led_outbound_read = '1' then
            led_outbound_empty <= '1';
          end if;
        elsif led_outbound_dout /= ("100" & r_tx_domain_leds) then
          led_outbound_empty <= '0';
          led_outbound_dout  <= "100" & r_tx_domain_leds;
        end if;
      end if;
    end if;
  end process inst_led_update_proc;

  -- HS comms
  inst_comms_link : comms_link
    port map (
      async_reset    => int_async_reset,
      clk_1x_tx      => clk_100mhz_tx,
      clk_1x_rx      => clk_100mhz_rx,
      clk_5x_tx      => clk_500mhz_tx,
      clk_5x_rx      => clk_500mhz_rx,
      tx_phase_shift => tx_phase_shift,

      tx_p => data_out_p,
      tx_n => data_out_n,
      rx_p => data_in_p,
      rx_n => data_in_n,

      outbound_data      => outbound_bridge_dout(7 downto 0),
      outbound_available => outbound_word_available,
      outbound_frame_end => outbound_bridge_dout(8),
      outbound_read      => outbound_bridge_read,

      inbound_data      => inbound_bridge_din(7 downto 0),
      inbound_available => inbound_bridge_available,
      inbound_frame_end => inbound_bridge_din(8),
      inbound_write     => inbound_bridge_write,

      -- Debug signals
      debug_rx_10b_data_out        => debug_rx_10b_data_out,
      debug_rx_data_out            => debug_rx_data_out,
      debug_rx_is_k                => debug_rx_is_k,
      debug_rx_locked              => debug_rx_locked,
      debug_rx_delay               => debug_rx_delay,
      debug_rx_code_error          => debug_rx_code_error,
      debug_rx_disparity_error     => debug_rx_disparity_error,
      debug_rx_crc_error           => debug_rx_crc_error,
      debug_rx_backpressure_needed => debug_rx_backpressure_needed,
      debug_tx_backpressure_needed => debug_tx_backpressure_needed,
      debug_rx_delay_start         => debug_rx_delay_start,
      debug_rx_delay_end           => debug_rx_delay_end,
      debug_rx_delay_last_start    => debug_rx_delay_last_start,
      debug_rx_delay_last_end      => debug_rx_delay_last_end,
      debug_rx_scan_bits           => debug_rx_scan_bits
      );

  -- Hold the reset for the receiver after the ISERDES is reset for a
  -- few cycles to allow it to initialise
  inst_rx_sync_reset : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => clk_100mhz_rx,
      input  => int_async_reset,
      output => rx_sync_reset
      );

  inbound_bridge_available <= not(inbound_bridge_almost_full);

  -- Use a async-sync shift block to cross the transmitting debug signal into
  -- the global 100MHz domain
  rx_domain_receiving <= (inbound_bridge_available and inbound_bridge_write) when rising_edge(clk_100mhz_rx);
  inst_rx_pulse_lengthen : async_to_sync_reset_shift
    generic map (
      LENGTH => 4
      )
    port map (
      clk    => int_clk_100mhz,
      input  => rx_domain_receiving,
      output => p_p_receiving
      );
  p_receiving <= p_p_receiving when rising_edge(int_clk_100mhz);
  receiving   <= p_receiving   when rising_edge(int_clk_100mhz);

  inst_inbound_bridge_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
      ALMOSTFULL  => inbound_bridge_almost_full,
      DO          => inbound_bridge_dout,
      EMPTY       => inbound_bridge_empty,
      FULL        => open,
      RDCOUNT     => inbound_bridge_fifo_rdcount,
      RDERR       => open,
      WRCOUNT     => inbound_bridge_fifo_wrcount,
      WRERR       => open,
      DI          => inbound_bridge_din,
      RDCLK       => clk_100mhz_rx,
      RDEN        => inbound_copy,
      RST         => int_async_reset,
      WRCLK       => clk_100mhz_rx,
      WREN        => inbound_bridge_write
      );

  -- RX demux interface
  proc_rx_demux : process(clk_100mhz_rx)
  begin
    if rising_edge(clk_100mhz_rx) then

      state_inbound_copy <= '0';

      if rx_sync_reset = '1' then
        inbound_stream_select <= "1111";
        inbound_state        <= INIT;
      else

        case inbound_state is

          when INIT =>

            inbound_stream_select <= "1111";

            if inbound_bridge_empty = '0' then
              state_inbound_copy <= '1';
              inbound_state      <= SWITCH;
            end if;

          when SWITCH =>

            inbound_stream_select <= inbound_bridge_dout(3 downto 0);
            inbound_state         <= STREAM;

          when STREAM =>

            state_inbound_copy <= '1';

            if inbound_copy = '1' then

              -- Finish on frame end
              if inbound_bridge_dout(8) = '1' then
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

    inst_channel_1_inbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_1_inbound_fifo_full,
        RDCOUNT     => channel_1_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_1_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_1_inbound_fifo_din,
        RDCLK       => int_channel_1_clk,
        RDEN        => channel_1_inbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => clk_100mhz_rx,
        WREN        => channel_1_inbound_fifo_write
        );

    inst_channel_1_outbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_1_outbound_fifo_full,
        RDCOUNT     => channel_1_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_1_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_1_outbound_fifo_din,
        RDCLK       => clk_100mhz_tx,
        RDEN        => channel_1_outbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => int_channel_1_clk,
        WREN        => channel_1_outbound_fifo_write
        );

    g_loopback_channel_1 : if CHANNEL_1_LOOPBACK = true generate

      -- Use the internal clock for loopback
      int_channel_1_clk <= clk_100mhz_rx;

      channel_1_outbound_fifo_din   <= channel_1_inbound_fifo_dout;
      channel_1_inbound_fifo_read   <= not(channel_1_inbound_fifo_empty or channel_1_outbound_fifo_full);
      channel_1_outbound_fifo_write <= not(channel_1_inbound_fifo_empty or channel_1_outbound_fifo_full);

    end generate g_loopback_channel_1;

    g_n_loopback_channel_1 : if CHANNEL_1_LOOPBACK = false generate

      -- Use external clock when not in loopback
      int_channel_1_clk <= channel_1_clk;

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

    inst_channel_2_inbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_2_inbound_fifo_full,
        RDCOUNT     => channel_2_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_2_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_2_inbound_fifo_din,
        RDCLK       => int_channel_2_clk,
        RDEN        => channel_2_inbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => clk_100mhz_rx,
        WREN        => channel_2_inbound_fifo_write
        );

    inst_channel_2_outbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_2_outbound_fifo_full,
        RDCOUNT     => channel_2_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_2_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_2_outbound_fifo_din,
        RDCLK       => clk_100mhz_tx,
        RDEN        => channel_2_outbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => int_channel_2_clk,
        WREN        => channel_2_outbound_fifo_write
        );

    g_loopback_channel_2 : if CHANNEL_2_LOOPBACK = true generate

      -- Use the internal clock for loopback
      int_channel_2_clk <= clk_100mhz_rx;

      channel_2_outbound_fifo_din   <= channel_2_inbound_fifo_dout;
      channel_2_inbound_fifo_read   <= not(channel_2_inbound_fifo_empty or channel_2_outbound_fifo_full);
      channel_2_outbound_fifo_write <= not(channel_2_inbound_fifo_empty or channel_2_outbound_fifo_full);

    end generate g_loopback_channel_2;

    g_n_loopback_channel_2 : if CHANNEL_2_LOOPBACK = false generate

      -- Use external clock when not in loopback
      int_channel_2_clk <= channel_2_clk;

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

    inst_channel_3_inbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_3_inbound_fifo_full,
        RDCOUNT     => channel_3_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_3_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_3_inbound_fifo_din,
        RDCLK       => int_channel_3_clk,
        RDEN        => channel_3_inbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => clk_100mhz_rx,
        WREN        => channel_3_inbound_fifo_write
        );

    inst_channel_3_outbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_3_outbound_fifo_full,
        RDCOUNT     => channel_3_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_3_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_3_outbound_fifo_din,
        RDCLK       => clk_100mhz_tx,
        RDEN        => channel_3_outbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => int_channel_3_clk,
        WREN        => channel_3_outbound_fifo_write
        );

    g_loopback_channel_3 : if CHANNEL_3_LOOPBACK = true generate

      -- Use the internal clock for loopback
      int_channel_3_clk <= clk_100mhz_rx;

      channel_3_outbound_fifo_din   <= channel_3_inbound_fifo_dout;
      channel_3_inbound_fifo_read   <= not(channel_3_inbound_fifo_empty or channel_3_outbound_fifo_full);
      channel_3_outbound_fifo_write <= not(channel_3_inbound_fifo_empty or channel_3_outbound_fifo_full);

    end generate g_loopback_channel_3;

    g_n_loopback_channel_3 : if CHANNEL_3_LOOPBACK = false generate

      -- Use external clock when not in loopback
      int_channel_3_clk <= channel_3_clk;

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

    inst_channel_4_inbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_4_inbound_fifo_full,
        RDCOUNT     => channel_4_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_4_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_4_inbound_fifo_din,
        RDCLK       => int_channel_4_clk,
        RDEN        => channel_4_inbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => clk_100mhz_rx,
        WREN        => channel_4_inbound_fifo_write
        );

    inst_channel_4_outbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => channel_4_outbound_fifo_full,
        RDCOUNT     => channel_4_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => channel_4_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => channel_4_outbound_fifo_din,
        RDCLK       => clk_100mhz_tx,
        RDEN        => channel_4_outbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => int_channel_4_clk,
        WREN        => channel_4_outbound_fifo_write
        );

    g_loopback_channel_4 : if CHANNEL_4_LOOPBACK = true generate

      -- Use the internal clock for loopback
      int_channel_4_clk <= clk_100mhz_rx;

      channel_4_outbound_fifo_din   <= channel_4_inbound_fifo_dout;
      channel_4_inbound_fifo_read   <= not(channel_4_inbound_fifo_empty or channel_4_outbound_fifo_full);
      channel_4_outbound_fifo_write <= not(channel_4_inbound_fifo_empty or channel_4_outbound_fifo_full);

    end generate g_loopback_channel_4;

    g_n_loopback_channel_4 : if CHANNEL_4_LOOPBACK = false generate

      -- Use external clock when not in loopback
      int_channel_4_clk <= channel_4_clk;

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

    inst_multicast_inbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => multicast_inbound_fifo_full,
        RDCOUNT     => multicast_inbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => multicast_inbound_fifo_wrcount,
        WRERR       => open,
        DI          => multicast_inbound_fifo_din,
        RDCLK       => int_multicast_clk,
        RDEN        => multicast_inbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => clk_100mhz_rx,
        WREN        => multicast_inbound_fifo_write
        );

    inst_multicast_outbound_fifo : component unimacro.vcomponents.FIFO_DUALCLOCK_MACRO
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
        FULL        => multicast_outbound_fifo_full,
        RDCOUNT     => multicast_outbound_fifo_rdcount,
        RDERR       => open,
        WRCOUNT     => multicast_outbound_fifo_wrcount,
        WRERR       => open,
        DI          => multicast_outbound_fifo_din,
        RDCLK       => clk_100mhz_tx,
        RDEN        => multicast_outbound_fifo_read,
        RST         => int_async_reset,
        WRCLK       => int_multicast_clk,
        WREN        => multicast_outbound_fifo_write
        );

    -- Mappings
    int_multicast_clk <= multicast_clk;

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

