----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.12.2021 18:38:10
-- Design Name: 
-- Module Name: TopLevel - TopLevel_Arch
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

entity TopLevel is
  Port(
    piRst : in std_logic;
		piClk : in std_logic;

    piDuty : in std_logic_vector(4-1 downto 0);
    
    poPWM: out std_logic
  );
end TopLevel;

architecture TopLevel_Arch of TopLevel is

begin

  Inst_PWM : entity work.pwm
    Port map(
      --definirle una entrada para leer y registrar entradas? por ahora no
  
      --Fclk = 100MHz ;
      --Tclk = 1/Fclk = 10 ns
      --Periodo = 100 ns (10 MHz)
      -- 
      -- Modulo = TimeOut / Tclk
      --
      --  Modulo = 100.000us / 0.10 us = 1.000.000 -----------------> No llegaba a escribir toda la RAM con estos valores
        --N => 24,   -- Numero de bits
        --M => 10000000   -- Modulo del contador
      piPrescaller =>  std_logic_vector(to_unsigned(1,24)),--Parametro para definir frec del pwm (P2)
      piDutyParam =>	piDuty & "100000",--Parametro para definir duty cycle fijo (P1)
  
      piDutyVar => "0000000000",--(P4) del pizarron -Parametro que setea velocidad con que leera RAM (variación de Duty)
      poReadDuty => open,--Genera pulso para realizar lectura de la RAM
      poAddr => open, --direccion de memoria a leer
  
      piSelectDuty=> '0', --selecciona si usar duty fijo o leer de memoria (P3)
      
      poPWM => poPWM,
  
      piRst => piRst,
      piClk => piClk
    );

end TopLevel_Arch;