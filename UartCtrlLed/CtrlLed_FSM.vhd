----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.11.2021 23:18:43
-- Design Name: 
-- Module Name: CtrlLed_FSM - Arch_CtrlLed_FSM
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CtrlLed_FSM is
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

		poLED : out std_logic_vector(4 downto 1)
	);
end CtrlLed_FSM;

architecture Arch_CtrlLed_FSM of CtrlLed_FSM is

--señales
signal sDataReceived : std_logic;
signal sData : std_logic_vector(8-1 downto 0);
signal sTimeOutTC : std_logic;
signal sTimeOutRst : std_logic;

--salidas registradas
signal sLEDReg_a, sLEDReg_f : std_logic_vector(4 downto 1);

--registros de FSM
type TSTATE is (W_SOF, W_CMD, W_VALOR, W_EOF);
signal st_a, st_f : TSTATE;

--registros de comandos
signal sCMDReg_a, sCMDReg_f : std_logic_vector(8-1 downto 0);
signal sVALORReg_a, sVALORReg_f : std_logic_vector(8-1 downto 0);

--constantes
constant SOF_BYTE : std_logic_vector(8-1 downto 0) := "10100101"; --0xA5
constant EOF_BYTE : std_logic_vector(8-1 downto 0) := "01011010"; --0x5A

constant ON_BYTE : std_logic_vector(8-1 downto 0) := "00000001"; --0x01
constant OFF_BYTE : std_logic_vector(8-1 downto 0) := "00000010"; --0x02

begin
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

	--instancia contador timeout
	InstTimeOUT : entity work.CounterModM
	--Fclk = 100MHz ;
	--Tclk = 1/Fclk = 10 ns
	--TimeOut = 100ms
	-- 
	-- Modulo = TimeOut / Tclk
	--
	--  Modulo = 100ms / 0.010 ms = 10000 
	Generic map(
		N => 14,   -- Numero de bits
		M => 10000   -- Modulo del contador
	)
	Port map(
		piClk => piClk,
		piRst => sTimeOutRst,
		piEna => '1',
		poTc  => sTimeOutTC,
		poQ   => open
	);


	--registro de comandos:
	process(piClk)
	begin
		if rising_edge(piClk) then
			sCMDReg_a <= sCMDReg_f;
			sVALORReg_a <= sVALORReg_f;
			sLEDReg_a <= sLEDReg_f;
		end if;
	end process;

	--registro de estados
	process(piClk)
	begin
		if rising_edge(piClk) then
			if piRst = '1' then
				st_a <= W_SOF;
			else
				st_a <= st_f;
			end if;
		end if;
	end process;

	--conexion de salida con Registro
	poLED <= sLEDReg_a;

	process(sDataReceived, sData, st_a, sCMDReg_a, sVALORReg_a, sLEDReg_a, sTimeOutTC)
	begin
		--valores por defecto
		st_f <= st_a;
		sCMDReg_f <= sCMDReg_a;
		sVALORReg_f <= sVALORReg_a;
		sLEDReg_f <= sLEDReg_a;

		sTimeOutRst <= '0';

		case st_a is
			when W_SOF =>
				if sDataReceived = '1' and sData = SOF_BYTE then
					sTimeOutRst <= '1';
					st_f <= W_CMD;
				end if;

			when W_CMD =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif sDataReceived = '1' and (sData = ON_BYTE or sData = OFF_BYTE) then
					sCMDReg_f <= sData;
					st_f <= W_VALOR;
					sTimeOutRst <= '1';
				end if;

			when W_VALOR =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif sDataReceived = '1' and unsigned(sData) > to_unsigned(0,8) and unsigned(sData) < to_unsigned(5,8)then
					sVALORReg_f <= sData;
					st_f <= W_EOF;
					sTimeOutRst <= '1';
				end if;

			when W_EOF =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif sDataReceived = '1' and sData = EOF_BYTE then
					st_f <= W_SOF; 
					if sCMDReg_a = ON_BYTE then
						sLEDReg_f(to_integer(unsigned(sVALORReg_a))) <= '1';
					else 
						sLEDReg_f(to_integer(unsigned(sVALORReg_a))) <= '0';
					end if;
				end if;
			when others =>
				st_f <= W_SOF;					
		end case;
	end process;
end Arch_CtrlLed_FSM;
