----------------------------------------------------------------------------------
-- Company: UTN.BA DDcLP 2021
-- Casi Engineer: Catuogno Fabian
-- 
-- Create Date: 12.12.2021 18:38:10
-- Design Name: Generador de señales
-- Module Name: TopLevel - TopLevel_Arch
-- Project Name: Signal Gen
-- Target Devices: Arty (Artix-7)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopLevel is
  Generic(
    --Config Comunicacion Serie:
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

signal sDataRAM : std_logic_vector(32-1 downto 0);
signal sAddressRAM : std_logic_vector(10-1 downto 0);

--signals para control del pwm
signal sprescaler : std_logic_vector(32-1 downto 0);  --  (P2)---->Reg32_0
signal sduty : std_logic_vector(16-1 downto 0); --        (P1)---->Reg16_0
signal sprescalerRAM : std_logic_vector(32-1 downto 0); --(P4)---->Reg32_1
signal muxPWM : std_logic_vector(8-1 downto 0); --        (P3)---->Reg8_0

begin

  Inst_PWM : entity work.pwm
    Port map(
      
      piPrescaller =>  sprescaler(24-1 downto 0),--       (P2) : Parametro para definir frec del pwm 
      piDutyParam =>	sduty(10-1 downto 0),--             (P1) : Parametro para definir duty cycle fijo 
  
      piPrescallerDuty => sprescalerRAM(24-1 downto 0), --(P4) del pizarron -Parametro que setea velocidad con que leera RAM (variación de Duty)
      piDutyVar => sDataRAM(10-1 downto 0), --Lectura de los valores de RAM (Duty variable)
      poAddr => sAddressRAM, --direccion de memoria a leer
  
      piSelectDuty => muxPWM(0), --                       (P3) : selecciona si usar duty fijo o leer de memoria 
      
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
  
      poReg_8_0  => muxPWM, --(P3)
      poReg_8_1  => open,
      poReg_8_2  => open,
      poReg_8_3  => open,

      poReg_16_0 => sduty, --(P1)
      poReg_16_1 => open,
      poReg_16_2 => open,
      poReg_16_3 => open,

      poReg_32_0 => sprescaler, --(P2)
      poReg_32_1 => sprescalerRAM, --(P4)
      poReg_32_2 => open,
      poReg_32_3 => open,
  
      --RAM Data BUS - 32 bit
      poDataRAM => sDataRAM,
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