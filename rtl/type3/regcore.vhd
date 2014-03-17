-- This file is part of CLEFIA Type-III FPGA IP-core.
--
-- CLEFIA Type-III is free FPGA IP-core: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- CLEFIA Type-III is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------
-- Company: Instituto Superior Tecnico de Lisboa
-- Engineer: João Carlos Nunes Bittencourt
--
-- Design Name:   CLEFIA Type-III I/O Register Parser
-- Module Name:   reg_core
-- Project Name:  FPGA Compact CLEFIA Type-III
--
-- Dependencies:  core
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity reg_core is
   port ( 
   			data_in 	: in  std_logic_vector (31 downto 0);
           	data_out_p 	: out  std_logic_vector (31 downto 0);
		   	sel 		: in  std_logic_vector (3 downto 0);
           	clk 		: in  std_logic;
           	reset 		: in  std_logic;
           	enc_dec 	: in  std_logic;
           	start 		: in  std_logic;
		   	expand_key	: in std_logic;
           	ack 		: out  std_logic;
           	done 		: out  std_logic;
           	done_key 	: out std_logic;
           	key_size192 : in  std_logic;
           	key_size256 : in  std_logic
			  );
end reg_core;

architecture behavioral of reg_core is


	component core is
    port ( data_in 		: in std_logic_vector (127 downto 0);
           data_out 	: out std_logic_vector (127 downto 0);
		   skey			: in std_logic_vector(255 downto 0);
           clk 			: in std_logic;
           reset 		: in std_logic;
           enc_dec 		: in std_logic;
           start 		: in std_logic;
		   expand_key	: in std_logic;
           key_size_192 : in std_logic;
           key_size_256 : in std_logic;	
           ack 			: out std_logic;
           done_cypher  : out std_logic;
           done 		: out std_logic );
	end component;

signal data_in_reg : std_logic_vector (127 downto 0);
signal data_out, data_out_reg : std_logic_vector (127 downto 0);
signal key_reg:std_logic_vector(255 downto 0);
            
signal reset_reg : std_logic;
signal enc_dec_reg : std_logic;
signal start_reg : std_logic;
signal expand_key_reg:std_logic;
signal ack_reg : std_logic;
signal done_reg : std_logic;
signal done_key_reg : std_logic;
signal key_size192_reg : std_logic;
signal key_size256_reg : std_logic;

begin

	core_u0 : core port map ( 
		data_in => data_in_reg,
		data_out => data_out_reg,
		skey => key_reg,
	    clk => clk,
	    reset => reset_reg,
	    enc_dec => enc_dec_reg,
	    start => start_reg,
		expand_key => expand_key_reg,
	    key_size_192 => key_size192_reg,
	    key_size_256 => key_size256_reg,
	    ack => ack_reg,
	    done_cypher => done_reg,
	    done => done_key_reg
	);
	
	
reg_proc : process (clk)
begin
	if clk'event and clk='1' then  --clk rising edge
	
		-- Shared key input
		if (sel = "0000") then
		key_reg(31 downto 0) <= data_in;
		elsif  (sel = "0001") then
		key_reg(63 downto 32) <= data_in;
		elsif  (sel = "0010") then
		key_reg(95 downto 64) <= data_in;
		elsif  (sel = "0011") then
		key_reg(127 downto 96) <= data_in;
		elsif  (sel = "0100") then
		key_reg (159 downto 128) <= data_in;
		elsif  (sel = "0101") then
		key_reg(191 downto 160) <= data_in;
		elsif  (sel = "0110") then
		key_reg(223 downto 192) <= data_in;
		elsif  (sel = "0111") then
		key_reg(255 downto 224) <= data_in;
		-- Plain text input
		elsif  (sel = "1000") then
		data_in_reg (31 downto 0) <= data_in;
		elsif  (sel = "1001") then
		data_in_reg(31 +32 downto 32) <= data_in;
		elsif  (sel = "1010") then
		data_in_reg(31 +64 downto 64) <= data_in;
		elsif  (sel = "1011") then
		data_in_reg(127 downto 127-31) <= data_in;
		end if;		
		
		reset_reg 		<= reset;
		enc_dec_reg 	<= enc_dec;
		start_reg 		<= start;
		expand_key_reg 	<= expand_key;
		ack 			<= ack_reg;
		key_size192_reg <= key_size192;
		key_size256_reg <= key_size256;

		if (done_reg = '1') then
			data_out 		<= data_out_reg;
		end if;
		done 			<= done_reg;
		done_key 		<= done_key_reg;		
		
	end if;
end process;	

data_out_p <= 	data_out(31 downto 0) when (sel = "0000") else		
				data_out(63 downto 32) when (sel = "0001") else
				data_out(95 downto 64) when (sel = "0011") else
				data_out(127 downto 96) when (sel = "0100") else
				(others => '0');

end behavioral;

