----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.11.2021 23:37:57
-- Design Name: 
-- Module Name: pwm - Arch_pwm
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwm is
	Port (
		--definirle una entrada para leer y registrar entradas? por ahora no

		piPrescaller : in std_logic_vector(24-1 downto 0);	--Parametro para definir frec del pwm (P2)
		piDutyParam : in std_logic_vector(10-1 downto 0);	--Parametro para definir duty cycle fijo (P1)

		piDutyVar : in std_logic_vector(10-1 downto 0);	--(P4) del pizarron -Parametro que setea velocidad con que leera RAM (variación de Duty)
		poReadDuty : out std_logic; --Genera pulso para realizar lectura de la RAM
		poAddr: out std_logic_vector(10-1 downto 0); --direccion de memoria a leer

		piSelectDuty: in std_logic; --selecciona si usar duty fijo o leer de memoria (P3)
		
		poPWM: out std_logic;

		piRst : in std_logic;
		piClk : in std_logic
	);
end pwm;

architecture Arch_pwm of pwm is

signal sPrescallerTC : std_logic;
signal sCompFrec : std_logic_vector(10-1 downto 0);

signal sRamConTC : std_logic;

--Salida del mux que switchea duty fijo o variable (desde RAM)
signal sDutyMux : std_logic_vector(10-1 downto 0);

begin
--Contador que realiza prescaller (baja frecuencia de clk para el pwm)
InstPrescaler : entity work.ProgCounterModM
	Generic map(
		N => 24   -- Numero de bits
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => '1',
		poTc  => sPrescallerTC,
		piMod => piPrescaller,
		poQ   => open
	);

--Contador que genera señal que determina la frecuencia del pwm (se comparará con la del duty)
Inst_ContFrec : entity work.CounterModM
	Generic map(
		N => 10,   -- Nomero de bits
		M => 1023    -- Modulo del contador
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => sPrescallerTC,
		poTc  => open,
		poQ   => sCompFrec
	);


--Prescaller para frecuencia de lectura de RAM
Inst_ContFrecRAM : entity work.ProgCounterModM
	Generic map(
		N => 10   -- Nomero de bits
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => '1',
		piMod => piDutyVar,
		poTc  => sRamConTC,
		poQ   => open
	);

--Generador de direcciones de memoria RAM
Inst_AddrCont : entity work.CounterModM
	Generic map(
		N => 10,   -- Nomero de bits
		M => 1023    -- Modulo del contador
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => sRamConTC,
		poTc  => open,
		poQ   => poAddr
	);

	poReadDuty <= sRamConTC;

	sDutyMux <= piDutyParam when piSelectDuty = '0' else piDutyVar;
	poPWM <= '1' when unsigned(sCompFrec) < unsigned(sDutyMux) else '0';

end Arch_pwm;
