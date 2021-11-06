----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.11.2021 23:11:00
-- Design Name: 
-- Module Name: Uart_Rx - Arch_Uart_Rx
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
use IEEE.MATH_REAL.ALL;

--Fclk = 100MHz ;
--Tclk = 1/Fclk = 10 ns
--BaudRate = 9600 -921600
-- El tiempo de un Bits es
-- Tbit = 1/BaudRate
-- Modulo = Tbit / Tclk
--
--  Modulo = (1/BaudRate) / (1/Fclk) = Fclk / BaudRate
--  Modulo = 100000000 / 9600 = round[10416.67] = 10417   
entity Uart_Rx is
Generic (
	BAUD_RATE_PRESCALLER : NATURAL := 10417
);
Port (
	piClk : in std_logic ;
	piRst : in std_logic ;
	poRxAvailable : out std_logic ;
	poData : out std_logic_vector (8-1 downto 0);
	piRx : in std_logic
);
end entity Uart_Rx ;


architecture Arch_Uart_Rx of Uart_Rx is

--Estados de la FSM:
type TSTATE IS (ST_WAIT_FALLING_RX,
                ST_READ_BSTART,
                ST_READ_B0,
                ST_READ_B1,
                ST_READ_B2,
                ST_READ_B3,
                ST_READ_B4,
                ST_READ_B5,
                ST_READ_B6,
                ST_READ_B7,
                ST_READ_BSTOP
                );

signal st_a ,st_f : TSTATE ;

Constant cBIT_START : std_logic := '0';
Constant cBIT_STOP  : std_logic := '1';


--Registro de salida
signal sData_reg , sData_next : std_logic_vector(8-1 downto 0) ;


-- Control de Timer (periferico)
signal sTimerRst     : std_logic;
signal sTimerTc      : std_logic;
signal sTimerTc_Half : std_logic;

begin

--Instancia de contador
Inst_Timer : entity work.CounterEspecial
  generic map(
  			N => natural(ceil( log2(real(BAUD_RATE_PRESCALLER)))),
        	M => BAUD_RATE_PRESCALLER
        )
    Port map( 
	    piClk => piClk,
	    piRst => sTimerRst,
	    piEna => '1',
	    poQ => open,
	    poTc => sTimerTc,
	    poTc_Half => sTimerTc_Half
   );


--Registro Interno (Dato)
process(piClk)
begin
	if rising_edge(piClk) then
		sData_reg <= sData_next;
	end if;
end process;

--Registro de estados
process(piClk)
begin
	if rising_edge(piClk) then
		if piRst = '1' then
			st_a <= ST_WAIT_FALLING_RX;
		else
			st_a <= st_f;
		end if;
	end if;
end process;

--conexion de salida con Registro
poData <= sData_reg;

--FSM
process( st_a, piRx, sTimerTc, sTimerTc_Half, sData_reg)
begin
--Valores por defecto para la FSM:
	st_f <= st_a;
	sData_next <= sData_reg;

	sTimerRst <= '0';
	poRxAvailable <= '0';


	case st_a is
		when ST_WAIT_FALLING_RX =>
			if piRx = cBIT_START then
				sTimerRst <= '1';
				st_f <= ST_READ_BSTART;
			end if;

		when ST_READ_BSTART =>
			if sTimerTc_Half = '1' then
				if piRx = cBIT_START then
					sTimerRst <= '1';
					st_f <= ST_READ_B0;
				else
					st_f <= ST_WAIT_FALLING_RX;
				end if;
			end if;

		when ST_READ_B0 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(0) <= piRx;
				st_f <= ST_READ_B1;
			end if;

		when ST_READ_B1 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(1) <= piRx;
				st_f <= ST_READ_B2;
			end if;

		when ST_READ_B2 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(2) <= piRx;
				st_f <= ST_READ_B3;
			end if;

		when ST_READ_B3 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(3) <= piRx;
				st_f <= ST_READ_B4;
			end if;

		when ST_READ_B4 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(4) <= piRx;
				st_f <= ST_READ_B5;
			end if;

		when ST_READ_B5 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(5) <= piRx;
				st_f <= ST_READ_B6;
			end if;

		when ST_READ_B6 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(6) <= piRx;
				st_f <= ST_READ_B7;
			end if;

		when ST_READ_B7 =>
			if sTimerTc = '1' then
				--sTimerRst <= '1';--innecesario
				sData_next(7) <= piRx;
				st_f <= ST_READ_BSTOP;
			end if;

		when ST_READ_BSTOP =>
			if sTimerTc = '1' then
				--No debo quedarme esperando por siempre si no verifica B_STOP
				st_f <= ST_WAIT_FALLING_RX;
				if piRx = '1' then --verifico B_STOP
					poRxAvailable <= '1';
				end if;
			end if;

		when others =>
			st_f <= ST_WAIT_FALLING_RX;

		end case;
end process;

end Arch_Uart_Rx;
