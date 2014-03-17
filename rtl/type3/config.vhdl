library clefia;
library ieee;
use ieee.std_logic_1164.all;

package synthesis is
	constant FPGA_XILINX 	: boolean := true;
	constant FPGA_ALTERA 	: boolean := false;
	constant ASIC 			: boolean := (not FPGA_XILINX) and (not FPGA_XILINX);
	constant CIPHER_ONLY	: boolean := true;
end synthesis;

package design is
	-- Key expansion
	constant round26	: bit_vector (5 downto 0) := "011010"; -- 128-bit key
	constant round40 	: bit_vector (5 downto 0) := "101000"; -- 192-256-bit key
	-- Ciphering round numbers
	constant round36	: bit_vector (5 downto 0) := "100100"; -- 36 rounds (128-bit input)
	constant round44	: bit_vector (5 downto 0) := "101100"; -- 44 rounds (192-bit input)
	constant round52	: bit_vector (5 downto 0) := "110100"; -- 52 rounds (256-bit input)
end design;