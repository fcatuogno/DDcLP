----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.11.2021 23:01:22
-- Design Name: 
-- Module Name: TopLevel - Arch_TopLevel
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TopLevel is
--Fclk = 100MHz ;
	--Tclk = 1/Fclk = 10 ns
	--BaudRate = 921600
	-- El tiempo de un Bits es
	-- Tbit = 1/BaudRate
	-- Modulo = Tbit / Tclk
	--
	--  Modulo = (1/BaudRate) / (1/Fclk) = Fclk / BaudRate
	--  Modulo = 100000000 / 921600 = round[108.5] = 109 
	Generic(
		BAUD_RATE_PRESCALLER : NATURAL := 109 --921600 baudios
	);
	Port (
		piRst : in std_logic;
		piClk : in std_logic;
		piData : in std_logic; 
		poData : out std_logic;

		poLEDs : out std_logic_vector(8-1 downto 0)
		);
end TopLevel;


architecture Arch_TopLevel of TopLevel is

signal sDataRx : std_logic_vector(8-1 downto 0);
signal sDataReceived : std_logic;

signal sDataTx : std_logic_vector(8-1 downto 0);
signal sStarTx : std_logic;
signal sReadyTx : std_logic;

signal sReadRAM : std_logic_vector(32-1 downto 0);
signal sAddressRAM : std_logic_vector(8-1 downto 0);

begin

poLEDs <= sReadRAM(8-1 downto 0);

--Instancia FSM
Inst_FSM : entity work.RegisterInterface 
	Port map(
		piClk => piClk,
		piRst => piRst,

		-- data desde modulo de comunicación
		poDATA => sDataTx,
		piUartTxReady => sReadyTx,
		poStartTX => sStarTx,

		piDATA => sDataRx,
		piDataReady => sDataReceived,

		poReg_8_0 => sAddressRAM,
		poReg_8_1 => open,
		poReg_8_2 => open,
		poReg_8_3 => open,

		poReg_16_0 => open,
		poReg_16_1 => open,
		poReg_16_2 => open,
		poReg_16_3 => open,
	
		poReg_32_0 => open,
		poReg_32_1 => open,
		poReg_32_2 => open,
		poReg_32_3 => open,

		--RAM Data BUS - 32 bit
		poDataRAM => sReadRAM,
		--RAM Addr=> open,
		piAddress => "00" & sAddressRAM
		--RAM read=> open,
		--piReadRAM => '0'
	);


--instancia UART-Rx
InstUartRx : entity work.Uart_Rx
	Generic map(
		BAUD_RATE_PRESCALLER => BAUD_RATE_PRESCALLER
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		poRxAvailable => sDataReceived,
		poData => sDataRx,
		piRx => piData
	);


--intancia Uart-Tx
InstUartTx : entity work.UART_Tx
	Generic map(
		BAUD_RATE_PRESCALLER => BAUD_RATE_PRESCALLER
	)
	Port map(
		piclk => piClk,
		piRst => piRst,
		piStart => sStarTx,
		piDato => sDataTx,
		poTx => poData,
		poReady => sReadyTx
	);


end Arch_TopLevel;
