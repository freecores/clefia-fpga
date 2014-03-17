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
-- Design Name:   CLEFIA Type-III Key Expansion
-- Module Name:   key_exp
-- Project Name:  FPGA Compact CLEFIA Type-III
--
-- Dependencies:  key_mem
--
----------------------------------------------------------------------------------
library ieee;
library clefia;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use clefia.synthesis.all;

entity key_exp is
    Port ( 
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
           
end key_exp;

architecture behavioral of key_exp is

component key_mem
	port (
		clka 	: in std_logic;
		ena 	: in std_logic;
		wea 	: in std_logic_vector(0 downto 0);
		addra	: in std_logic_vector(8 downto 0);
		dina	: in std_logic_vector(31 downto 0);
		douta	: out std_logic_vector(31 downto 0);
		clkb	: in std_logic;
		enb		: in std_logic;
		web		: in std_logic_vector(0 downto 0);
		addrb	: in std_logic_vector(8 downto 0);
		dinb	: in std_logic_vector(31 downto 0);
		doutb	: out std_logic_vector(31 downto 0));
end component;

signal lkey_l, lkey_r		: std_logic_vector(127 downto 0);
signal lkey					: std_logic_vector(127 downto 0);
signal lkey_ij				: std_logic_vector(31  downto 0);

signal sel_ij 				: std_logic_vector(1 downto 0);
signal odd, odd_r			: std_logic;
signal gfn_type 			: std_logic; -- 0 for GFN-4, 1 for GFN-8

signal count 				: std_logic_vector(5 downto 0);
signal count_r 				: std_logic_vector(5 downto 0);
signal count_lr 			: std_logic_vector(1 downto 0);
signal constant_addr		: std_logic_vector(5 downto 0);
signal const_ij				: std_logic_vector(31 downto 0);
signal start_value 			: std_logic_vector(5 downto 0);
signal load_lkey0			: std_logic;
signal load_lkey1			: std_logic;
signal sigma_lr				: std_logic;
signal load_lr				: std_logic;
signal load_lr_r			: std_logic;
signal load_sigma			: std_logic;

signal stop					: std_logic;
signal stop_r				: std_logic;

signal ena, enb 			: std_logic;
signal wea, web 			: std_logic_vector(0  downto 0);
signal addra, addrb 		: std_logic_vector(8  downto 0);
signal dinb 				: std_logic_vector(31 downto 0);

signal kl, kr, wkey_r		: std_logic_vector(127 downto 0);
signal ki, rk_ij			: std_logic_vector(31  downto 0);

begin

kl 	<= 	key(255 downto 128);
kr 	<= 	key(127 downto 0) when key_size_256 = '1' else
	  	key(127 downto 64) & not key(255 downto 192) when key_size_192 = '1' else
	  	key(255 downto 128) when gfn_type = '0' else 
	  	(others => '0');

w_key_lr <= kl & kr; -- Generate K for data input in key expansion

wkey_r <= kl xor kr when gfn_type = '1' else
		  kl;

ki  <= 	kr(31 downto 0)					when sel_ij = "00" and load_lr_r = '0' else
		kr(32+31 downto 32+0)			when sel_ij = "11" and load_lr_r = '0' else
		kr(64+31 downto 64+0)			when sel_ij = "10" and load_lr_r = '0' else
		kr(64+32+31 downto 64+32+0) 	when sel_ij = "01" and load_lr_r = '0' else
		kl(31 downto 0)					when sel_ij = "00" and load_lr_r = '1' else
		kl(32+31 downto 32+0)			when sel_ij = "11" and load_lr_r = '1' else
		kl(64+31 downto 64+0)			when sel_ij = "10" and load_lr_r = '1' else
		kl(64+32+31 downto 64+32+0);-- 	when sel_ij = "11" and load_lr_r = '1'

rk_ij <= const_ij xor ki xor lkey_ij when odd_r = '1' else 
		 const_ij xor lkey_ij;

-- Select through L key left and L key right
lkey <= lkey_r when load_lr_r = '1' and gfn_type = '1' else lkey_l;
-- Mux for step L calculation
lkey_ij <= lkey(31 downto 0)				when sel_ij = "00" else
		   lkey(32+31 downto 32+0)			when sel_ij = "11" else
		   lkey(64+31 downto 64+0)			when sel_ij = "10" else
		   lkey(64+32+31 downto 64+32+0); --when sel_ij = "00"

wea <= "1" when load_lkey1 = '1' and (stop_r = '0') else 
	   "0";

-- Process sigma funcion and 
L_Key_Proc : process (clk)
	variable tmp2, tmp1 : std_logic_vector (127 downto 0);
begin
	if clk'event and clk = '1' then  -- clk rising edge
		stop_r <= stop; 
		load_lr_r <= load_lr;
		odd_r <= odd;
		w_key <= wkey_r;
		count_r <= count;
		-- Star swapping (sigma function)
		if(load_sigma = '1' and load_lkey1 = '1') then
			----------------- Sigma( L ) -----------------
			--           Double swap function
			if(sigma_lr = '0' or gfn_type = '0') then
				tmp1 := lkey_l(120 downto 64) & lkey_l(6 downto 0) & lkey_l(127 downto 121) & lkey_l(63 downto 7); --Sigma(lkey_l);	
				lkey_l <= tmp1;
			else 
				tmp1 := lkey_r(120 downto 64) & lkey_r(6 downto 0) & lkey_r(127 downto 121) & lkey_r(63 downto 7); --Sigma(lkey_r);	
				lkey_r <= tmp1;
			end if;	
			----------------------------------------------			
		else	
			if (load_lkey0 = '0') and (load_lkey1 = '0') then -- 
				lkey_l(127 downto 96) <= lp2;
				lkey_l(95  downto 64) <= lp3;
			-- Setting up L 128 bits
			elsif (load_lkey0 = '1') and (load_lkey1 = '0') then 
				lkey_l(63 downto 32) <= lp2;
				lkey_l(31 downto  0) <= lp3;
			elsif (load_lkey0 = '1') and (load_lkey1 = '1') then 
				lkey_r(127 downto 96) <= lp2;
				lkey_r(95  downto 64) <= lp3;
			elsif (load_lkey0 = '0') and (load_lkey1 = '1' and count(5 downto 0) < "000011") then 
				lkey_r(63 downto 32) <= lp2;
				lkey_r(31 downto  0) <= lp3;	
			end if;			
		end if;
		
	end if;
end process L_Key_Proc ; 

-- Store the round keys
KeyMemory : key_mem
		port map (
			clka => clk,
			ena => ena,
			wea => wea,
			addra => addra,
			dina => rk_ij,
			douta => rki,
---------------------------
-- Constants are stored in port b
			clkb => clk,
			enb => enb,
			web => web,
			addrb => addrb,
			dinb => dinb,
			doutb => const_ij
			);

control:process (clk)
begin
	if clk'event and clk = '1' then  --clk rising edge
		if (expand_key = '0' or start = '0') then
			count <= "111111"; --(others => '1');
			constant_addr <= start_value; -- used for 192 and 256 key generation, starting with 26 for 128 bits
			load_sigma <= '0';
			load_lkey0 <= '0';
			load_lkey1 <= '0';
			count_lr <= "10";
		elsif (stop_r = '0') then 
			count <= conv_std_logic_vector ( unsigned ( count ) + 1 , 6);
			constant_addr <= conv_std_logic_vector ( unsigned ( constant_addr ) + 1 , 6);
			if (load_lkey1 = '0') then 
				load_lkey1 <= load_lkey0;
			end if;
			load_lkey0 <= not load_lkey1;
			if (count(1 downto 0) = "11" ) then
				load_sigma <= load_lkey1; --'1'; -- or load_sigma;		
				count_lr <= conv_std_logic_vector ( unsigned ( count_lr ) + 1 , 2);
			else
				load_sigma <= '0';
			end if;
		end if; 
	end if;
end process control;

sigma_lr <= count_lr(1);
load_lr  <= count_lr(0) xor count_lr(1);

sel_ij <= count(1 downto 0);

addra 	<=	"000" & rki_add when expand_key = '0' else
			"000" & count_r when load_lkey1 = '1' else
			"001" & rki_add when key_size_192 = '0' and key_size_256 ='0' else
		  	"010" & rki_add when key_size_192 = '1' and key_size_256 ='0' else
		  	"100" & rki_add; -- when key_size_192 = '0' and key_size_256 ='1' else

addrb 	<= 	"001" & constant_addr when key_size_192 = '0' and key_size_256 ='0' else
		  	"011" & constant_addr when key_size_192 = '1' and key_size_256 ='0' else
		  	"101" & constant_addr; -- when key_size_192 = '0' and key_size_256 ='1';

odd <= count(2);

ena  <= '1'; -- enable read from port A (output the round keys)
enb  <= '1'; -- enable read from port B (output te defined constants)
web  <= (others => '0'); -- disable write
dinb <= (others => '-'); -- using only one port memory

start_value <= conv_std_logic_vector( 2**6 - 1 - 9*4  -1,6) when key_size_192 = '0' and key_size_256 ='0' else  -- the start value is the correct one minous 1, for the clock delay
			   conv_std_logic_vector( 2**7 - 1 - 11*4 -1,6) when key_size_192 = '1' and key_size_256 ='0' else
			   conv_std_logic_vector( 2**7 - 1 - 13*4 -1,6) when key_size_192 = '0' and key_size_256 ='1' else
			   (others => '0');

stop <= start when (constant_addr = "111111") else '0';

gfn_type <= key_size_192 or key_size_256;

done <= stop and start;

end behavioral;