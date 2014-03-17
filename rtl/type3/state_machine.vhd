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
-- Design Name:   CLEFIA Type-III State Machine
-- Module Name:   state_machine
-- Project Name:  FPGA Compact CLEFIA Type-III
--
----------------------------------------------------------------------------------
library ieee;
library clefia;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use clefia.design.all;

entity state_machine is
    Port ( 
    	clk 				: in std_logic;
        reset 				: in std_logic;
        enc_dec 			: in std_logic;
		expand_key			: in std_logic;
        key_size_192 		: in std_logic;
        key_size_256 		: in std_logic;
        start 				: in std_logic;
        ack 				: out std_logic;
        done 				: out std_logic;
        round_key_address 	: out std_logic_vector (5 downto 0);
        sel0 				: out std_logic_vector (1 downto 0);
        sel1 				: out std_logic;
        sel2 				: out std_logic;
        sel3 				: out std_logic_vector (1 downto 0);
        t0_t1 				: out std_logic);
end state_machine;

architecture behavioral of state_machine is

-- states
type state_type is (
	-- encoding states
	st1_idle, st2_start, st3_pre0, st4_pre1, st5_pre2, st5_pre3, st5_pre4, st5_pre5,
	st6_ack, st7_loop0, st7_loop1, st7_loop2, st7_loop3, st8_last, st9_done,
	-- decoding states
	std1_idle, std2_start, std3_pre, std4_ack, std5_loop0, std6_loop1, std7_last, std8_done);

signal state, next_state : state_type := st1_idle;

-- internal signals for outputs
signal ack_i 		: std_logic := '0';
signal done_i 		: std_logic := '0';
signal sel0_i 		: std_logic_vector (1 downto 0) := "00";
signal sel1_i 		: std_logic := '0';
signal sel2_i 		: std_logic := '0';
signal sel3_i 		: std_logic_vector (1 downto 0) := "00";
signal t0_t1_i 		: std_logic := '0';
signal roundaddr_i 	: std_logic_vector (5 downto 0) := (others => '0');
signal roundaddr_o 	: std_logic_vector (5 downto 0) := (others => '0');
signal round_number : std_logic_vector (5 downto 0) := "100100"; --36 rounds default

begin
round_key_address <= roundaddr_o;

round_number <=	to_stdlogicvector(round26) when expand_key = '1' and (key_size_192 = '0' and key_Size_256 = '0') else
				to_stdlogicvector(round40) when expand_key = '1' and (key_size_192 = '1' or  key_Size_256 = '1') else
				--"101101" when expand_key = '1' and (key_size_192 = '0' and key_Size_256 = '1') else -- 45
				to_stdlogicvector(round44) when expand_key = '0' and key_size_192 = '1' else 
				to_stdlogicvector(round52) when expand_key = '0' and key_Size_256 = '1' else 
				to_stdlogicvector(round36); 

sync_process: process (clk)
	begin
		if (clk'event and clk = '1') then
			if (reset = '1') then
				state <= st1_idle;
				-- assign default outputs
				ack  <= '0';
				done <= '0';
				sel0 <= (others => '0');
				sel1 <= '0';
				sel2 <= '0';
				sel3 <= (others => '0');
				t0_t1 <= '0';
				roundaddr_o <= (others => '0');
			else
				state <= next_state;
				-- assign outputs
				ack <= ack_i;
				done <= done_i;
				sel0 <= sel0_i;
				sel1 <= sel1_i;
				sel2 <= sel2_i;
				sel3 <= sel3_i;
				t0_t1 <= t0_t1_i;
				roundaddr_o <= roundaddr_i;
			end if;
		end if;
	end process;

outout_code: process (next_state, roundaddr_o, expand_key, key_size_192, key_Size_256, round_number)
begin
	ack_i  <= '0';
	done_i <= '0';
	sel0_i <= (others => '0');
	sel1_i <= '0';
	if (expand_key = '1' and (key_size_192 = '1' or key_Size_256 = '1')) then sel2_i <= '1'; 
	else sel2_i <= '0'; end if;
	sel3_i <= (others => '0');
	t0_t1_i <= '0';
	case (next_state) is
		when st1_idle =>
			roundaddr_i <= (others => '0');
		when st2_start =>
			roundaddr_i <= "000001";
		when st3_pre0 =>
			sel0_i <= "01";
			--sel3_i <= "01";
			t0_t1_i <= '1';
			roundaddr_i <= "000010";
		-- put 2 more pre states before ack for key expansion
		when st4_pre1 =>
			sel0_i <= "10";
			--sel3_i <= "01";
			t0_t1_i <= '0';
			roundaddr_i <= "000011";		
		when st5_pre2 =>
			sel0_i <= "11";
			--sel3_i <= "01";
			t0_t1_i <= '1';
			roundaddr_i <= "000100";
		when st5_pre3 =>
			sel1_i <= '1';
			sel3_i <= "01";
			t0_t1_i <= '0';
			roundaddr_i <= "000101";
		when st5_pre4 =>
			sel1_i <= '1';
			sel3_i <= "01";
			t0_t1_i <= '1';
			roundaddr_i <= "000110";
		when st5_pre5 =>
			sel1_i <= '1';
			sel3_i <= "01";
			t0_t1_i <= '0';
			roundaddr_i <= "000111";	
		when st6_ack =>
			ack_i <= '1';
			sel1_i <= '1';
			if (expand_key = '1' and (key_size_192 = '1' or key_Size_256 = '1')) then 
				sel3_i <= "10";
				roundaddr_i <= "001000";
				t0_t1_i <= '1';
			else 
				sel3_i <= "00"; 
				roundaddr_i <= "000011";
				t0_t1_i <= '0';
			end if;			
		when st7_loop0 =>
			sel1_i <= '1';
			if (expand_key = '1' and (key_size_192 = '1' or key_Size_256 = '1')) then 
				sel3_i <= "01";
				t0_t1_i <= '0';
			else 
				sel3_i <= "01"; 
				t0_t1_i <= '1';
			end if;			
			roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );
		when st7_loop1 =>
			sel1_i <= '1';
			if (expand_key = '1' and (key_size_192 = '1' or key_Size_256 = '1')) then 
				sel3_i <= "01";
				t0_t1_i <= '1';
			else 
				sel3_i <= "00"; 
				t0_t1_i <= '0';
			end if;			
			roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );
		-- build loop2 for key expansion
		when st7_loop2 =>
			sel1_i <= '1';
			sel3_i <= "01";
			t0_t1_i <= '0';
			roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );
		when st7_loop3 =>
			sel1_i <= '1';
			sel3_i <= "10";
			t0_t1_i <= '1';
			roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );			
		when st8_last =>
			done_i <= expand_key;
			sel1_i <= '1';
			if (expand_key = '1' and (key_size_192 = '1' or key_Size_256 = '1')) then sel3_i <= "10";
			else sel3_i <= "01"; end if;
			t0_t1_i <= '1';
			roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );
		when st9_done =>
			done_i <= '1';
			sel1_i <= '1';
			roundaddr_i <= (others => '0');
			
		-- decode states
		-- when std1_idle =>
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( round_number) - 2 );
		-- when std2_start =>
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );
		-- when std3_pre =>
		-- 	sel0_i <= "01";
		-- 	--sel3_i <= "01";
		-- 	t0_t1_i <= '1';
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) - 3 );
		-- when std4_ack =>
		-- 	ack_i <= '1';
		-- 	sel1_i <= '1';
		-- 	sel3_i <= "00"; 
		-- 	t0_t1_i <= '0';	
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );			
		-- when std5_loop0 =>
		-- 	sel1_i <= '1';
		-- 	sel3_i <= "01"; 
		-- 	t0_t1_i <= '1';
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) - 3 );
		-- when std6_loop1 =>
		-- 	sel1_i <= '1';
		-- 	sel3_i <= "00"; 
		-- 	t0_t1_i <= '0';
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) + 1 );		
		-- when std7_last =>
		-- 	sel1_i <= '1';
		-- 	sel3_i <= "01";
		-- 	t0_t1_i <= '1';
		-- 	roundaddr_i <= std_logic_vector ( unsigned ( roundaddr_o ) - 3 );
		-- when std8_done =>
		-- 	done_i <= '1';
		-- 	sel1_i <= '1';
		-- 	roundaddr_i <= (others => '0');	
		when others =>
			roundaddr_i <= (others => '0');
	end case;
end process;
	
next_state_decode: process (state, enc_dec, start, roundaddr_o, round_number, expand_key, key_size_192, key_size_256)
	begin
		--default state for next_state to avoid latches
		next_state <= state;
		--decode next state
		case (state) is
			-- code states
			when st1_idle =>
				if (enc_dec = '1') then
					next_state <= std1_idle;
				end if;
				if (start = '1') then
					next_state <= st2_start;
				end if;
			when st2_start =>
				next_state <= st3_pre0;
			when st3_pre0 =>
				if (expand_key = '1' and (key_size_192 = '1' or key_size_256 = '1')) then 
					next_state <= st4_pre1;
				else 
					next_state <= st6_ack; 
				end if;
			when st4_pre1 => 
				next_state <= st5_pre2;
			when st5_pre2 => 
				if (key_size_192 = '1' or key_size_256 = '1') then 
					next_state <= st5_pre3;
				else 
					next_state <= st6_ack; 
				end if;
			when st5_pre3 => 
				next_state <= st5_pre4;
			when st5_pre4 => 
				next_state <= st5_pre5;				
			when st5_pre5 => 
				next_state <= st6_ack;
			when st6_ack =>
				next_state <= st7_loop0; 
			when st7_loop0 =>
				if ( roundaddr_o = std_logic_vector ( unsigned ( round_number ) ) ) then
					next_state <= st8_last;
				else
					next_state <= st7_loop1;
				end if;
			when st7_loop1 =>
				if (expand_key = '1' and (key_size_192 = '1' or key_size_256 = '1')) then 
					next_state <= st7_loop2;
				else 
					next_state <= st7_loop0; 
				end if;
			when st7_loop2 =>
				next_state <= st7_loop3;
			when st7_loop3 =>
				if ( roundaddr_o = std_logic_vector ( unsigned ( round_number ) ) ) then
					next_state <= st8_last;
				else
					next_state <= st7_loop0;
				end if;				
				-- next_state <= st7_loop0;	
			when st8_last =>
				next_state <= st9_done;
			when st9_done =>
				if (start = '1') then
					next_state <= st2_start;
				else
					if (expand_key = '1') then 
						next_state <= st9_done;
					else
						next_state <= st1_idle;
					end if;
				end if;

			-- decode states
			-- when std1_idle =>
			-- 	if (enc_dec = '0') then
			-- 		next_state <= st1_idle;
			-- 	end if;
			-- 	if (start = '1') then
			-- 		next_state <= std2_start;
			-- 	end if;
			-- when std2_start =>
			-- 	next_state <= std3_pre;
			-- when std3_pre =>
			-- 	next_state <= std4_ack;
			-- when std4_ack =>
			-- 	next_state <= std5_loop0;
			-- when std5_loop0 =>
			-- 	if ( roundaddr_o = "000000" ) then
			-- 		next_state <= std7_last;
			-- 	else
			-- 		next_state <= std6_loop1;
			-- 	end if;
			-- when std6_loop1 =>
			-- 	next_state <= std5_loop0;
			-- when std7_last =>
			-- 	next_state <= std8_done;
			-- when std8_done =>
			-- 	if (start = '1') then
			-- 		next_state <= std2_start;
			-- 	else
			-- 		next_state <= std1_idle;
			-- 	end if;
			-- just in case
			when others =>
				next_state <= st1_idle;
		end case;
	end process;


end behavioral;