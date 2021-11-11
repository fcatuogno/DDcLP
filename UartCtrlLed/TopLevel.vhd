----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2021 20:14:02
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
		piData : in std_logic; --modificado

		poLED : out std_logic_vector(4 downto 1)
		);
end TopLevel;


architecture Arch_TopLevel of TopLevel is

signal sData : std_logic_vector(8-1 downto 0);
signal sDataReceived : std_logic;

begin

--Instancia FSM
Inst_FSM : entity work.CtrlLed_FSM
	Port map(
		piRst => piRst,
		piClk => piClk,
		piData => sData,
		piDataReceived => sDataReceived,

		poLED => poLED
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
		poData => sData,
		piRx => piData
	);

end Arch_TopLevel;
