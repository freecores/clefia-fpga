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
-- Design Name:   Combinational D Flip-flop
-- Module Name:   data_registry
-- Project Name:  FPGA Compact CLEFIA Type-III
--
----------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Company: Instituto Superior Tcnico de Lisboa
-- Engineer: Ricardo Chaves
-- 
-- Create Date:    00:05:37 01/25/2010 
-- Design Name:    Data Registry DFF
-- Module Name:    data_registry
-- Project Name:   Clefia
-- Target Devices: Spartan 5
-- Tool versions:  13.4
-- Description:    Combinational D Flip-flop
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity data_registry is
    Port ( data_in 	: in std_logic_vector (31 downto 0);
           clk 		: in std_logic;
           enable 	: in std_logic;
           data_out : out std_logic_vector (31 downto 0);
		   reset 	: in std_logic);
end data_registry;

architecture behavioral of data_registry is

begin

	process (clk, reset)
		begin
			if (reset /= '0') then
				data_out <= X"00000000";
			elsif (clk'event and clk = '1') then
				if (enable = '1') then
					data_out <= data_in;
				end if;
			end if;		
	end process;


end behavioral;

