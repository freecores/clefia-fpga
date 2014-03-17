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
-- Design Name:   Core Testbench for 256-bit key size
-- Module Name:   core_enc_tb
-- Project Name:  CLEFIA Type-III
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity core_enc_tb is
end core_enc_tb;

architecture behavior OF core_enc_tb is

	component core
	    port ( data_in 		: in std_logic_vector (127 downto 0);
	           data_out 	: out std_logic_vector (127 downto 0);
			   skey 		: in std_logic_vector (255 downto 0);
	           clk 			: in std_logic;
	           reset 		: in std_logic;
	           enc_dec 		: in std_logic;
	           start 		: in std_logic;
			   expand_key 	: in std_logic;
	           key_size_192 : in std_logic;
	           key_size_256 : in std_logic;	              
	           ack 			: out std_logic;
	           done_cypher 	: out std_logic;
	           done 		: out std_logic
			);
	end component;

	-- Clock period definitions
	constant clk_period : time := 10 ns;	

	-- Design signals
  	signal clk 			: std_logic;
  	signal reset 		: std_logic := '0';
  	signal wk 			: std_logic_vector(255 downto 0) := (others => '0');
  	signal start 		: std_logic := '0';
	signal data_in 		: std_logic_vector(127 downto 0) := (others => '0');
	signal data_out 	: std_logic_vector(127 downto 0);
  	signal done 		: std_logic;
  	signal done_core 	: std_logic;
  	signal ack 			: std_logic := '0';
	-- Config signals
	signal expand_key 		: std_logic := '0';
  	signal encrypt_decrypt 	: std_logic := '0';
	signal key_size_192 	: std_logic := '0';
  	signal key_size_256 	: std_logic := '0';

  	-- Test Vetors
  	-- signal zeros 	: std_logic_vector (255 downto 0) := (others => '0');
  	-- signal wk_128 	: std_logic_vector (127 downto 0) := X"ffeeddccbbaa99887766554433221100";
  	-- signal wk_192 	: std_logic_vector (127 downto 0) := X"ffeeddccbbaa99887766554433221100" xor X"f0e0d0c0b0a090800011223344556677";
  	-- signal wk_256 	: std_logic_vector (127 downto 0) := X"ffeeddccbbaa99887766554433221100" xor X"f0e0d0c0b0a090807060504030201000";

  	-- Shared key
  	-- signal data_in_128 : std_logic_vector (255 downto 0) := X"ffeeddccbbaa9988776655443322110000000000000000000000000000000000";
  	-- signal data_in_192 : std_logic_vector (255 downto 0) := X"ffeeddccbbaa99887766554433221100f0e0d0c0b0a090800011223344556677";
  	signal shared_key : std_logic_vector (255 downto 0) := X"ffeeddccbbaa99887766554433221100f0e0d0c0b0a090807060504030201000";
	signal plain_text : std_logic_vector (127 downto 0) := X"000102030405060708090a0b0c0d0e0f";  	
	
	-- Round counter signal
	signal rcounter : integer := 0;	

begin

	DUT : core port map ( 
	    clk 			=> clk,
	    reset 			=> reset,		
		data_in 		=> data_in,
		data_out 		=> data_out,
		skey 			=> wk,
	    enc_dec 		=> encrypt_decrypt,
	    start 			=> start,
		expand_key 		=> expand_key,
	    key_size_192 	=> key_size_192,
	    key_size_256 	=> key_size_256,
	    ack 			=> ack,
	    done_cypher 	=> done_core,
	    done 			=> done
	);

   	-- Clock process definitions
   	clk_process :process
   	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
   	end process;

  	-- Stimulus process
  	stim_proc: process  
  	begin
		reset <= '1';
		wait for clk_period;		
	    -- Configuration
	    data_in <= plain_text; -- & X"00000000000000000000000000000000";
	    wk <= shared_key;	    	  
	    key_size_192 <= '0';
	    key_size_256 <= '0';
	    wait for clk_period;
	    -- First we need to generate the Round Keys
	    expand_key <= '1';
	    encrypt_decrypt <= '0';
	    wait for clk_period;
	    reset <= '0';
	    wait for clk_period;
	    start <= '1';
		wait for clk_period;
		start <= '0';
	  	wait until done = '1';
	  	wait for 2 * clk_period;
	  	expand_key <= '0';
	  	reset <= '1';
	  	wait for 2 * clk_period;
	  	reset <= '0';
	  	start <= '1';
	  	wk <= shared_key;
	  	data_in <= plain_text;
	  	wait for clk_period;
	  	start <= '0';
	  	wait until done_core = '1';
	  	wait for clk_period;
	  	assert false report "end of simulation" severity failure;	  	
	end process;

	-- Round counter process
	round_counter : process 
	begin
		if (start = '1') then
			rcounter <= rcounter + 1;
		elsif (rcounter /= 0) then 
			rcounter <= rcounter + 1;
		end if;
		wait for clk_period;
	end process;

	-- String output data
  	monitor : process
	    function to_string(sv: Std_Logic_Vector) return string is
	      use std.textio.all;
	      use ieee.std_logic_textio.all;
	      variable lp: line;
	    begin
	      hwrite(lp, sv);
	      return lp.all;
	    end;        
  	begin
		if(done_core = '1') then
			report to_string(data_out);
		end if;
		wait for clk_period;
  	end process;	

  	-- Cyphered Output data
  	-- ciphertext: de2bf2fd9b74aacdf1298555459494fd (128 bit)
	-- ciphertext: e2482f649f028dc480dda184fde181ad (192 bit)

	-- key Expand expected results: 
	-- Expected Lkey for 128 bit key   = 8f89a61b 9db9d0f3 93e65627 da0d027e
	-- Expected Lkey L for 192 bit key = db05415a 800082db 7cb8186c d788c5f3
	-- Expected Lkey R for 192 bit key = 1ca9b2e1 b4606829 c92dd35e 2258a432	
	-- Expected Lkey L for 256 bit key = 477e8f09 66ee5378 2cc2be04 bf55e28f
	-- Expected Lkey R for 256 bit key = d6c10b89 4eeab575 84bd5663 cc933940 
end;