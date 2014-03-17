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
-- Design Name:   CLEFIA Tyoe-III Cipher Datapath
-- Module Name:   data_path_pipeline
-- Project Name:  FPGA Compact CLEFIA Type-III
--
-- Dependencies:   tbox_0_0, tbox_0_1, data_registry 
--------------------------------------------------------------------------------
library ieee;
library clefia;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use clefia.synthesis.all;

entity data_path_pipeline is
    Port ( 
		data_in 		: in std_logic_vector (255 downto 0);
		whitening_key 	: in std_logic_vector (127 downto 0);
		round_key 		: in std_logic_vector (31 downto 0);
        clk 			: in std_logic;
		reset 			: in std_logic;
		expand_key		: in std_logic;
		gfn_type 		: in std_logic; -- 1 : GFN8; 0 : GFN4
		encrypt_decrypt : in std_logic;
		sel0 			: in std_logic_vector(1 downto 0);
		sel1 			: in std_logic;
		sel2 			: in std_logic;
		sel3 			: in std_logic_vector(1 downto 0);
		t0_t1 			: in std_logic;
 		lp3 			: out  std_logic_vector (31 downto 0);
		lp2 			: out  std_logic_vector (31 downto 0);
		data_out 		: out  std_logic_vector (127 downto 0)
	);
end data_path_pipeline;

architecture behavioral of data_path_pipeline is

	component data_registry
	port(
		data_in 	: in std_logic_vector (31 downto 0);
		clk 		: in std_logic;
		enable 		: in std_logic;
		reset 		: in std_logic;          
		data_out 	: out std_logic_vector (31 downto 0));
	end component;

	-- T-BOX 1
	component TBOX_0
	port (
		clka	: in std_logic;
		addra	: in std_logic_vector (8 downto 0);
		douta	: out std_logic_vector (31 downto 0);
		clkb	: in std_logic;
		addrb	: in std_logic_vector (8 downto 0);
		doutb	: out std_logic_vector (31 downto 0));
	end component;
	
	-- T-BOX 2
	component TBOX_1
	port (
		clka	: in std_logic;
		addra	: in std_logic_vector(8 downto 0);
		douta	: out std_logic_vector(31 downto 0);
		clkb	: in std_logic;
		addrb	: in std_logic_vector(8 downto 0);
		doutb	: out std_logic_vector(31 downto 0));
	end component;

--	-- Synplicity black box declaration
--	attribute syn_black_box : boolean;
--	attribute syn_black_box of T_0_2: component is true;
--	attribute syn_black_box of T_1_3: component is true;
--	
	-- Input signals
	signal a0, b0, c0, d0, e0, f0, g0, h0 	: std_logic_vector (31 downto 0);
	-- Internal signals
	signal i0, i1, i2 						: std_logic_vector (31 downto 0);
	signal u0, u1, u2, u3 					: std_logic_vector (31 downto 0);
	signal x0, x1 							: std_logic_vector (31 downto 0);
	-- Output of tbox final registry
	signal rt0, rt1, rt2, rt3 				: std_logic_vector (31 downto 0);
	-- Output of registry
	signal r0, r1, r2, r3, r4 				: std_logic_vector (31 downto 0);
	signal r5, r6, r7, r8, r9, r10 			: std_logic_vector (31 downto 0);
	-- BRAM input address
	signal addr0, addr1, addr2, addr3 		: std_logic_vector (8 downto 0);

	
begin
	-- 0(255 downto 224) 1(223 downto 192) 2(191 downto 160) 3(159 downto 128) 4(127 downto 96) 5(95 downto 64) 6(63 downto 32) 7(32 downto 0)
	a0 <= data_in (255 downto 224); -- P0
	c0 <= data_in (191 downto 160); -- P2
	e0 <= data_in (127 downto  96); -- P4
	g0 <= data_in (63  downto  32); -- P6

	b0 <= data_in (223 downto 192) when expand_key = '1' else 
		  data_in (223 downto 192) xor whitening_key (127 downto 96) when encrypt_decrypt = '0' else data_in (223 downto 192) xor whitening_key (63 downto 32); -- P1
	d0 <= data_in (159 downto 128) when expand_key = '1' else
		  data_in (159 downto 128) xor whitening_key (95 downto 64) when encrypt_decrypt = '0' else data_in (159 downto 128) xor whitening_key (31 downto 0); -- P3
	f0 <= data_in (95  downto  64); -- P5
	h0 <= data_in (31  downto   0); -- P7 


   	process (a0, b0, c0, d0, e0, f0, g0, h0, u0, u1, sel0) is
   	begin
    	case sel0 is
	    	when "00" => i0 <= a0; u0 <= b0;
	        when "01" => i0 <= c0; u0 <= d0;
	        when "10" => i0 <= e0; u0 <= f0;
	        when "11" => i0 <= g0; u0 <= h0;
	        when others => i0 <= (others => '0'); u0 <= (others => '0');
    	end case;
	end process;

	i1 <= i0 when sel1 = '0' else u2;
	i2 <= i1 xor round_key;

	u1 <= u0 when sel1 = '0' else u3;
	u2 <= x1 when sel2 = '0' else r3;

   	process (r4, r6, r10, sel3) is
   	begin
    	case sel3 is
	    	when "00" => u3 <= r4;
	        when "01" => u3 <= r6;
	        when "10" => u3 <= r10;
	        when others => u3 <= (others => '0');
    	end case;
	end process;	
	
	addr0 <= t0_t1 & i2 (31 downto 24);
	addr1 <= t0_t1 & i2 (23 downto 16);
	addr2 <= t0_t1 & i2 (15 downto 8);
	addr3 <= t0_t1 & i2 (7 downto 0);

	-- Rounk Keys Memory
	DEVICE_SELECT : 
		if (FPGA_XILINX) generate
		begin		
			tbox_0_0 : TBOX_0
				port map (
					clka => clk,
					addra => addr0,
					douta => rt0,
					clkb => clk,
					addrb => addr2,
					doutb => rt2);
					
			tbox_1_0 : TBOX_1
				port map (
					clka => clk,
					addra => addr1,
					douta => rt1,
					clkb => clk,
					addrb => addr3,
					doutb => rt3);
		end generate;
	-- end T-BOX device select
	data_registry_0 : data_registry 
		port map (
			data_in => u1,
			clk => clk,
			enable => '1',
			data_out => r0,
			reset => reset
		);
		
	data_registry_1 : data_registry 
		port map (
			data_in => r0,
			clk => clk,
			enable => '1',
			data_out => r1,
			reset => reset
		);

	data_registry_2 : data_registry 
		port map (
			data_in => x1,
			clk => clk,
			enable => '1',
			data_out => r2,
			reset => reset
		);

	data_registry_3 : data_registry 
		port map (
			data_in => r2,
			clk => clk,
			enable => '1',
			data_out => r3,
			reset => reset
		);

	data_registry_4: data_registry 
		port map (
			data_in => i1,
			clk => clk,
			enable => '1',
			data_out => r4,
			reset => reset
		);

	data_registry_5: data_registry 
		port map (
			data_in => r4,
			clk => clk,
			enable => '1',
			data_out => r5,
			reset => reset
		);	

	data_registry_6 : data_registry 
		port map (
			data_in => r5,
			clk => clk,
			enable => '1',
			data_out => r6,
			reset => reset
		);	

	data_registry_7 : data_registry 
		port map (
			data_in => r6,
			clk => clk,
			enable => '1',
			data_out => r7,
			reset => reset
		);

	data_registry_8 : data_registry 
		port map (
			data_in => r7,
			clk => clk,
			enable => '1',
			data_out => r8,
			reset => reset
		);

	data_registry_9 : data_registry 
		port map (
			data_in => r8,
			clk => clk,
			enable => '1',
			data_out => r9,
			reset => reset
		);

	data_registry_10: data_registry 
		port map (
			data_in => r9,
			clk => clk,
			enable => '1',
			data_out => r10,
			reset => reset
		);

	-- Reorganizing XOR operations / F-Functions from T-BOX data
	x0 (31 downto 24) <= (rt0 (31 downto 24) xor rt2 (15 downto 8)) xor
										(rt1 (31 downto 24) xor rt3 (15 downto 8));
	x0 (23 downto 16) <= (rt0 (23 downto 16) xor rt2 (7  downto 0)) xor 
										(rt1 (23 downto 16) xor rt3 (7  downto 0));
	x0 (15 downto 8)  <= (rt0 (15 downto  8) xor rt2 (31 downto 24)) xor
										(rt1 (15 downto  8) xor rt3 (31 downto 24));
	x0 (7 downto 0)   <= (rt0 (7  downto  0) xor rt2 (23 downto 16)) xor
										(rt1 (7  downto  0) xor rt3 (23 downto 16));
										
	x1 <= x0 xor r1;
	
	-- Output data
	data_out (127 downto 96) <= r6;
	data_out (95 downto 64) <= r4 xor whitening_key (63 downto 32) when encrypt_decrypt = '0' else r2 xor whitening_key (127 downto 96);
	data_out (63 downto 32) <= r5;
	data_out (31 downto 0) <= x1 xor whitening_key (31 downto 0) when encrypt_decrypt = '0' else x1 xor whitening_key (95 downto 64);	

	lp2 <= r7;
	lp3 <= r5 when gfn_type = '0' else r3;

end behavioral;

