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
-- Design Name:   CLEFIA Tyoe-III Core
-- Module Name:   core
-- Project Name:  CLEFIA Type-III ciphering core
--
-- Dependencies:   data_path_pipeline, state_machine
--------------------------------------------------------------------------------
library ieee;
library clefia;
use ieee.std_logic_1164.all;
use clefia.synthesis.all;

entity core is
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
 		   --lp3 			: out std_logic_vector (31 downto 0);
		   --lp2 			: out std_logic_vector (31 downto 0);
           ack 			: out std_logic;
           done_cypher  : out std_logic;
           done 		: out std_logic );
end core;

architecture behavioral of core is

component data_path_pipeline
	port (
		data_in 		: in std_logic_vector (255 downto 0);
		whitening_key 	: in std_logic_vector (127 downto 0);
		round_key 		: in std_logic_vector (31 downto 0);
        clk 			: in std_logic;
		reset 			: in std_logic;
		expand_key		: in std_logic;
		gfn_type 		: in std_logic;
		encrypt_decrypt	: in std_logic;
		sel0 			: in std_logic_vector (1 downto 0);
		sel1 			: in std_logic;
		sel2 			: in std_logic;
		sel3 			: in std_logic_vector (1 downto 0);
		t0_t1 			: in std_logic;
 		lp3 			: out  std_logic_vector (31 downto 0);
		lp2 			: out  std_logic_vector (31 downto 0);
		data_out 		: out  std_logic_vector (127 downto 0));
	end component;
	

	component RK_BRAM
	port (
		clka	: in std_logic;
		wea 	: in std_logic_vector (0 downto 0);
		dina 	: in std_logic_vector (31 downto 0);
		addra	: in std_logic_vector (5 downto 0);
		douta	: out std_logic_vector (31 downto 0));
	end component;

	component key_exp is
    port ( 
		rst 			: in std_logic;
		clk  			: in std_logic;    	
		expand_key 		: in std_logic;
		lp3 			: in std_logic_vector (31 downto 0);
        lp2 			: in std_logic_vector (31 downto 0);
        key 			: in std_logic_vector (255 downto 0);
		rki_add 		: in std_logic_vector (5 downto 0);
		key_size_192 	: in std_logic;
		key_size_256 	: in std_logic;
		start 			: in std_logic;
		w_key 			: out std_logic_vector (127 downto 0);
		w_key_lr		: out std_logic_vector (255 downto 0);
		rki 			: out std_logic_vector (31 downto 0);
		done 			: out std_logic
	);
           
	end component;	

	component state_machine
	port (
		clk 				: in std_logic;
        reset 				: in std_logic;
        enc_dec 			: in std_logic;
		expand_key			: in std_logic;
        key_size_192	 	: in std_logic;
        key_size_256 		: in std_logic;
        start 				: in std_logic;

        ack 				: out std_logic;
        done 				: out std_logic;
        round_key_address 	: out std_logic_vector (5 downto 0);
        sel0 				: out std_logic_vector (1 downto 0);
        sel1 				: out std_logic;
        Sel2 				: out std_logic;
        sel3 				: out std_logic_vector (1 downto 0);
        t0_t1 				: out std_logic );
	end component;

signal plain_text   : std_logic_vector(255 downto 0);

signal w_key 		: std_logic_vector(127 downto 0);
signal w_key_lr		: std_logic_vector(255 downto 0);
signal rkaddr 		: std_logic_vector (5 downto 0);
signal round_key 	: std_logic_vector (31 downto 0);
signal lp2, lp3		: std_logic_vector (31 downto 0);

signal sel1, Sel2  	: std_logic; 
signal t0_t1 		: std_logic;
signal sel0, sel3 	: std_logic_vector(1 downto 0);
signal done_core  	: std_logic;
signal gfn_type		: std_logic;

begin

	done_cypher <=  done_core and not expand_key;
	plain_text 	<=  data_in & X"00000000000000000000000000000000" when expand_key = '0' else
	 				w_key_lr; -- when expand_key = '1'

	-- Data Path Pipelined
	data_path_pipeline_0 : data_path_pipeline 
		port map (
			data_in => plain_text,
			whitening_key => w_key, --whitening_key,
			round_key => round_key,
			clk => clk,
			reset => reset,
			expand_key => expand_key,
			gfn_type => gfn_type,
			encrypt_decrypt => enc_dec,
			sel0 => sel0,
			sel1 => sel1,
			sel2 => Sel2,
			sel3 => sel3,
			t0_t1 => t0_t1,
			data_out => data_out,
			lp3 => lp3,
			lp2 => lp2
		);
		
	gfn_type <= (key_size_192 or key_size_256); -- 1 : GFN8; 0 : GFN4
	
	-- Rounk Keys Memory
	-- round_key_memory : RK_BRAM
	-- port map (
	-- 	clka => clk,
	-- 	wea => "0",
	-- 	dina => (others => '0'),
	-- 	addra => rkaddr,
	-- 	douta => round_key
	-- );

	key_exp_0 : key_exp
	   port map ( 
			rst 			=> reset,
			clk  			=> clk,
			expand_key 		=> expand_key,
			lp3 			=> lp3,
		 lp2 			=> lp2,
		 key 			=> skey,
			rki_add 		=> rkaddr,
			key_size_192 	=> key_size_192,
			key_size_256 	=> key_size_256,
			start 			=> done_core,
			w_key 			=> w_key,
			w_key_lr		=> w_key_lr,
			rki 			=> round_key,
			done 			=> done
	);			
	
	-- CLEFIA Cipher core control	
	core_controller: state_machine 
		port map (
			clk => clk,
			reset => reset,
			expand_key => expand_key,
			enc_dec => enc_dec,
			key_size_192 => key_size_192,
			key_size_256 => key_size_256,
			start => start,
			ack => ack,
			done => done_core,
			round_key_address => rkaddr,
			sel0 => sel0,
			sel1 => sel1,
			Sel2 => Sel2,
			sel3 => sel3,
			t0_t1 => t0_t1
		);
		
end behavioral;

