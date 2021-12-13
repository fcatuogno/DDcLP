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
  Generic(
    --Config Comuniacion Serie
    --Fclk = 100MHz ;
      --Tclk = 1/Fclk = 10 ns
      --BaudRate = 921600
      -- El tiempo de un Bits es
      -- Tbit = 1/BaudRate
      -- Modulo = Tbit / Tclk
      --
      --  Modulo = (1/BaudRate) / (1/Fclk) = Fclk / BaudRate
      --  Modulo = 100000000 / 921600 = round[108.5] = 109 
    BAUD_RATE_PRESCALLER : NATURAL := 109 --921600 baudios 
  );
  Port(
    piRst : in std_logic;
		piClk : in std_logic;

    --Comunicacion Serie
    piData : in std_logic; 
		poData : out std_logic;


    --piDuty : in std_logic_vector(4-1 downto 0);
    
    --Salida pwm
    poPWM: out std_logic
  );
end TopLevel;

architecture TopLevel_Arch of TopLevel is

--signal para comunicacion de interfaz de registros
signal sDataRx : std_logic_vector(8-1 downto 0);
signal sDataReceived : std_logic;

signal sDataTx : std_logic_vector(8-1 downto 0);
signal sStarTx : std_logic;
signal sReadyTx : std_logic;

signal sReadRAM : std_logic_vector(32-1 downto 0);
signal sAddressRAM : std_logic_vector(10-1 downto 0);

--signal para conectar registro con duty estatico
signal sduty : std_logic_vector(16-1 downto 0); 

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
      piDutyParam =>	sduty(10-1 downto 0),--Parametro para definir duty cycle fijo (P1)
  
      piDutyVar => "0000000000",--(P4) del pizarron -Parametro que setea velocidad con que leera RAM (variación de Duty)
      poReadDuty => open,--Genera pulso para realizar lectura de la RAM
      poAddr => open, --direccion de memoria a leer
  
      piSelectDuty=> '0', --selecciona si usar duty fijo o leer de memoria (P3)
      
      poPWM => poPWM,
  
      piRst => piRst,
      piClk => piClk
    );

  Inst_RegInterface : entity work.RegisterInterface
    Port map(
      piClk => piClk,
      piRst => piRst,
  
      -- data desde modulo de comunicación
      poDATA => sDataTx,
      piUartTxReady => sReadyTx,
      poStartTX => sStarTx,

      piDATA => sDataRx,
      piDataReady => sDataReceived,
  
      poReg_8_0  => open,
      poReg_8_1  => open,
      poReg_8_2  => open,
      poReg_8_3  => open,

      poReg_16_0 => sduty,
      poReg_16_1 => open,
      poReg_16_2 => open,
      poReg_16_3 => open,

      poReg_32_0 => open,
      poReg_32_1 => open,
      poReg_32_2 => open,
      poReg_32_3 => open,
  
      --RAM Data BUS - 32 bit
      poDataRAM => sReadRAM,
      piAddress => sAddressRAM
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

end TopLevel_Arch;