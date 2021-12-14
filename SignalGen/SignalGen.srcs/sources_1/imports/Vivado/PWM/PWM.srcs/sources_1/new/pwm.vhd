----------------------------------------------------------------------------------
-- Company: UTN.BA DDcLP 2021
-- Casi Engineer: Catuogno Fabian
-- 
-- Create Date: 24.11.2021 23:37:57
-- Design Name: Generador de señales
-- Module Name: pwm - Arch_pwm
-- Project Name: Signal Gen
-- Target Devices: Arty (Artix-7)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm is
	Port (
		piPrescaller : in std_logic_vector(24-1 downto 0);	--(P2) Parametro para definir frec del pwm 
		piDutyParam : in std_logic_vector(10-1 downto 0);	--(P1) Parametro para definir duty cycle fijo 

		piPrescallerDuty : in std_logic_vector(24-1 downto 0); --(P4) del pizarron -Parametro que setea velocidad con que leera RAM (variación de Duty)
		piDutyVar : in std_logic_vector(10-1 downto 0);	--Duty variable leido desde la RAM
		poAddr: out std_logic_vector(10-1 downto 0); --direccion de memoria a leer

		piSelectDuty: in std_logic; --(P3) selecciona si usar duty fijo o leer de memoria 
		
		poPWM: out std_logic;

		piRst : in std_logic;
		piClk : in std_logic
	);
end pwm;

architecture Arch_pwm of pwm is

--Interconexion de TC del contador prescaller y enable del sig. contador
signal sPrescallerTC : std_logic;
--Salida del mux que switchea duty fijo o variable (desde RAM)
signal sDutyMux : std_logic_vector(10-1 downto 0);
--conexion de la salida del contador con una de las entradas del comparador
signal sCompFrec : std_logic_vector(10-1 downto 0);
--Interconexion de TX del contador presscaleer2 con enable del gen. de direcciones
signal sRamConTC : std_logic;



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
		N => 10,   -- Numero de bits
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
		N => 24   -- Numero de bits
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => '1',
		piMod => piPrescallerDuty,
		poTc  => sRamConTC,
		poQ   => open
	);

--Generador de direcciones de memoria RAM
Inst_AddrCont : entity work.CounterModM
	Generic map(
		N => 10,   -- Numero de bits
		M => 1023    -- Modulo del contador
	)
	Port map(
		piClk => piClk,
		piRst => piRst,
		piEna => sRamConTC,
		poTc  => open,
		poQ   => poAddr
	);

	sDutyMux <= piDutyParam when piSelectDuty = '0' else piDutyVar;
	poPWM <= '1' when unsigned(sCompFrec) < unsigned(sDutyMux) else '0';

end Arch_pwm;
