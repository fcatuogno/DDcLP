----------------------------------------------------------------------------------
-- Company: UTN.BA DDcLP 2021
-- Casi Engineer: Catuogno Fabian
-- 
-- Create Date: 10.11.2021 23:00:37
-- Design Name: Generador de señales
-- Module Name: RegisterInterface - Arch_RegisterInterface
-- Project Name: Signal Gen
-- Target Devices: Arty (Artix-7)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Para arracxar el sistema
-- V 1.0
-- TRAMA_init [SOF=0xA5] [CMD: {0,1}] [PARAM2: {0,1,2,3}] [VAL#0] [EOF=0x5A]

--V 2.0
--TRAMA [SOF=0xA5] [CMD: {0,1}] [PARAM1: {0,1,2}] [PARAM2: {0,1,2,3}] [VAL#0] [VAL#1] [VAL#2] [VAL#3]  [EOF=0x5A]
--respouesta
--TRAMA [SOF=0xA5] [CMD: 0] [PARAM1: {0,1,2}] [PARAM2: {0,1,2,3}] [VAL#0] [VAL#1] [VAL#2] [VAL#3]  [EOF=0x5A]

--escribir en el registro 3 del banco 2 el valor 0x1023
--[SOF=0xA5] [CMD:1] [PARAM1:1] [PARAM2: 3] [VAL#0: 0x23] [VAL#1: 0x10] [VAL#2: 0xfruta ] [VAL#3: 0xfruta] [EOF=0x5A]

--V 3.0
-- se suma:
-- BlockRam de 32x1024
-- [SOF=0xA5] [CMD:2] [VAL#0] [VAL#1] [VAL#2] [VAL#3] .... [VAL#0] [VAL#1] [VAL#2] [VAL#3] [EOF=0x5A]

entity RegisterInterface is
	Port (
		piClk : in std_logic ;
		piRst : in std_logic ;

		-- data desde modulo de comunicaci�n
		poDATA : out std_logic_vector(8-1 downto 0);
		piUartTxReady : in std_logic;
		poStartTX : out std_logic;

		piDATA : in std_logic_vector(8-1 downto 0);
		piDataReady : in std_logic;

		poReg_8_0 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_1 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_2 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_3 : out std_logic_vector(1*8-1 downto 0);

		poReg_16_0 : out std_logic_vector(2*8-1 downto 0);
		poReg_16_1 : out std_logic_vector(2*8-1 downto 0);
		poReg_16_2 : out std_logic_vector(2*8-1 downto 0);
		poReg_16_3 : out std_logic_vector(2*8-1 downto 0);
	
		poReg_32_0 : out std_logic_vector(4*8-1 downto 0);
		poReg_32_1 : out std_logic_vector(4*8-1 downto 0);
		poReg_32_2 : out std_logic_vector(4*8-1 downto 0);
		poReg_32_3 : out std_logic_vector(4*8-1 downto 0);

		--RAM Data BUS - 32 bit
		poDataRAM : out std_logic_vector(32-1 downto 0);
		--RAM Addres BUS
		piAddress : in std_logic_vector(10-1 downto 0)

	);
end RegisterInterface;



architecture Arch_RegisterInterface of RegisterInterface is

--signal para escritura de la RAM
signal sWrRAM : std_logic;
signal sDataRAM : std_logic_vector(32-1 downto 0);

--signal para lectura de RAM
signal sRDataRAM : std_logic_vector(32-1 downto 0);

--Banco de Registros 1 (8 bits)
signal poReg_8_0_a, poReg_8_0_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_1_a, poReg_8_1_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_2_a, poReg_8_2_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_3_a, poReg_8_3_f : std_logic_vector(1*8-1 downto 0);

--Banco de Registros 2 (16 bits)
signal poReg_16_0_a, poReg_16_0_f : std_logic_vector(2*8-1 downto 0);
signal poReg_16_1_a, poReg_16_1_f : std_logic_vector(2*8-1 downto 0);
signal poReg_16_2_a, poReg_16_2_f : std_logic_vector(2*8-1 downto 0);
signal poReg_16_3_a, poReg_16_3_f : std_logic_vector(2*8-1 downto 0);

--Banco de Registros 3 (32 bits)
signal poReg_32_0_a, poReg_32_0_f : std_logic_vector(4*8-1 downto 0);
signal poReg_32_1_a, poReg_32_1_f : std_logic_vector(4*8-1 downto 0);
signal poReg_32_2_a, poReg_32_2_f : std_logic_vector(4*8-1 downto 0);
signal poReg_32_3_a, poReg_32_3_f : std_logic_vector(4*8-1 downto 0);


--registros de FSM
type TSTATE is (W_SOF, W_CMD, W_PARAM1, W_PARAM2, W_VAL0, W_VAL1, W_VAL2, W_VAL3, W_EOF,
				S_SOF, S_CMD, S_PARAM1, S_PARAM2, S_VAL0, S_VAL1, S_VAL2, S_VAL3, S_EOF,
				W_RAMVAL0,W_RAMVAL1,W_RAMVAL2,W_RAMVAL3,WR_RAM
				);
signal st_a, st_f : TSTATE;

--registros de comandos
signal sCMDReg_a, sCMDReg_f : std_logic_vector(8-1 downto 0);
signal sPARAM1Reg_a, sPARAM1Reg_f: std_logic_vector(8-1 downto 0);
signal sPARAM2Reg_a, sPARAM2Reg_f: std_logic_vector(8-1 downto 0);
signal sVAL0Reg_a, sVAL0Reg_f : std_logic_vector(8-1 downto 0);
signal sVAL1Reg_a, sVAL1Reg_f : std_logic_vector(8-1 downto 0);
signal sVAL2Reg_a, sVAL2Reg_f : std_logic_vector(8-1 downto 0);
signal sVAL3Reg_a, sVAL3Reg_f : std_logic_vector(8-1 downto 0);

--registro para la salida
signal sDATA_a, sDATA_f : std_logic_vector(8-1 downto 0);

--constantes
constant SOF_BYTE : std_logic_vector(8-1 downto 0) := "10100101"; --0xA5
constant EOF_BYTE : std_logic_vector(8-1 downto 0) := "01011010"; --0x5A

constant READ_BYTE : std_logic_vector(8-1 downto 0) := "00000000"; --0x00
constant WRITE_BYTE : std_logic_vector(8-1 downto 0) := "00000001"; --0x01
constant FILL_RAM : std_logic_vector(8-1 downto 0) := "00000010"; --0x02
constant READ_RAM : std_logic_vector(8-1 downto 0) := "00000011"; --0x03


--signals para control de contador TsimeOut
signal sTimeOutRst : std_logic;
signal sTimeOutTC : std_logic;

--signal para control de contador de llenado de RAM
signal sAddressRst : std_logic;
signal sAddresIncrement : std_logic; 
signal sAddressTC : std_logic;
signal sAddressCont : std_logic_vector(10-1 downto 0);

begin
	--instancia RAM
	InstRAM : entity work.MyBlockRAMDualPort
	generic map(
		N_BITS_DATA => 32,
		N_BITS_ADDR => 10 -- capacidad 2**10 = 1024
	)
	Port map(
		piClk => piClk,

		piWr     => sWrRAM,
		piDataWr => sDataRAM,
		piAddrWr => sAddressCont,
		poDataRd_1 => sRDataRAM,

		poDataRd_2 => poDataRAM,
		piAddrRd_2 => piAddress 
	);

	--instancia contador TimeOut para Rx
	InstCount : entity work.CounterModM
	  Generic Map(
		--Fclk = 100MHz ;
		--Tclk = 1/Fclk = 10 ns
		--TimeOut = 100ms
		-- 
		-- Modulo = TimeOut / Tclk
		--Modulo = 400.000us / 0.010 us = 40.000.000 
		N => 26,   -- Numero de bits
		M => 40000000   -- Modulo del contador
	)
	  Port Map(
		piClk => piClk,-- : in  std_logic;
		piRst => sTimeOutRst,-- : in  std_logic;
		piEna => '1',-- : in  std_logic;
		poTc  => sTimeOutTC,--  : out std_logic;
		poQ   => open -- : out std_logic_vector(N-1 downto 0)
	);

	--instancia contador llenado de RAM
	InstCountRAM : entity work.CounterModM
	  Generic Map(
		N => 10,   -- Numero de bits
		M => 1024   -- Modulo del contador
	)
	  Port Map(
		piClk => piClk,
		piRst => sAddressRst,
		piEna => sAddresIncrement,
		poTc  => sAddressTC,
		poQ   => sAddressCont
	);
	  

	--conexion de la salida con el registro
	poDATA <= sDATA_a;

	--conexion de las salidas de los registros
	poReg_8_0 <= poReg_8_0_a;
	poReg_8_1 <= poReg_8_1_a;
	poReg_8_2 <= poReg_8_2_a;
	poReg_8_3 <= poReg_8_3_a;

	poReg_16_0 <= poReg_16_0_a;
	poReg_16_1 <= poReg_16_1_a;
	poReg_16_2 <= poReg_16_2_a;
	poReg_16_3 <= poReg_16_3_a;

	poReg_32_0 <= poReg_32_0_a;
	poReg_32_1 <= poReg_32_1_a;
	poReg_32_2 <= poReg_32_2_a;
	poReg_32_3 <= poReg_32_3_a;

	process(piClk)
	begin
		if rising_edge(piClk) then
			--registros de comandos y recepcion
			sCMDReg_a <= sCMDReg_f;
			sPARAM1Reg_a <= sPARAM1Reg_f;
			sPARAM2Reg_a <= sPARAM2Reg_f;
			sVAL0Reg_a <= sVAL0Reg_f;
			sVAL1Reg_a <= sVAL1Reg_f;
			sVAL2Reg_a <= sVAL2Reg_f;
			sVAL3Reg_a <= sVAL3Reg_f;
			sDATA_a <= sDATA_f;

			--registros 
			poReg_8_0_a <= poReg_8_0_f;
			poReg_8_1_a <= poReg_8_1_f;
			poReg_8_2_a <= poReg_8_2_f;
			poReg_8_3_a <= poReg_8_3_f;

			poReg_16_0_a <= poReg_16_0_f;
			poReg_16_1_a <= poReg_16_1_f;
			poReg_16_2_a <= poReg_16_2_f;
			poReg_16_3_a <= poReg_16_3_f;

			poReg_32_0_a <= poReg_32_0_f;
			poReg_32_1_a <= poReg_32_1_f;
			poReg_32_2_a <= poReg_32_2_f;
			poReg_32_3_a <= poReg_32_3_f;

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

	--conexión con puerto de escritura de la RAM
	sDataRAM <= sVAL0Reg_a & sVAL1Reg_a & sVAL2Reg_a & sVAL3Reg_a; 

	process(piDataReady, piDATA, st_a, sCMDReg_a, sPARAM1Reg_a, sPARAM2Reg_a,
			sVAL0Reg_a, sVAL1Reg_a, sVAL2Reg_a, sVAL3Reg_a,
			sTimeOutTC, sDATA_a, piUartTxReady,
			poReg_8_0_a, poReg_8_1_a, poReg_8_2_a, poReg_8_3_a,
			poReg_16_0_a, poReg_16_1_a, poReg_16_2_a, poReg_16_3_a,
			poReg_32_0_a, poReg_32_1_a, poReg_32_2_a, poReg_32_3_a,
			sAddressTC, sAddressCont,
			sRDataRAM)
	begin
		--valores por defecto
		st_f <= st_a;
		sCMDReg_f <= sCMDReg_a;
		sVAL0Reg_f <= sVAL0Reg_a;
		sVAL1Reg_f <= sVAL1Reg_a;
		sVAL2Reg_f <= sVAL2Reg_a;
		sVAL3Reg_f <= sVAL3Reg_a;
		sPARAM1Reg_f <= sPARAM1Reg_a;
		sPARAM2Reg_f <= sPARAM2Reg_a;
		sDATA_f <= sDATA_a;

		poReg_8_0_f <= poReg_8_0_a;
		poReg_8_1_f <= poReg_8_1_a;
		poReg_8_2_f <= poReg_8_2_a;
		poReg_8_3_f <= poReg_8_3_a;

		poReg_16_0_f <= poReg_16_0_a;
		poReg_16_1_f <= poReg_16_1_a;
		poReg_16_2_f <= poReg_16_2_a;
		poReg_16_3_f <= poReg_16_3_a;

		poReg_32_0_f <= poReg_32_0_a;
		poReg_32_1_f <= poReg_32_1_a;
		poReg_32_2_f <= poReg_32_2_a;
		poReg_32_3_f <= poReg_32_3_a;

		sTimeOutRst <= '0';
		poStartTX <= '0';
		sAddressRst <= '0';
		sWrRAM <= '0';
		sAddresIncrement <= '0';

		case st_a is
			when W_SOF =>
				if piDataReady = '1' and piDATA = SOF_BYTE then
					sTimeOutRst <= '1';
					st_f <= W_CMD;
				end if;

			when W_CMD =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then --recib� el dato?
					if (piDATA = READ_BYTE or piDATA = WRITE_BYTE) then --el dato es correcto?
						sCMDReg_f <= piDATA; --dato correcto
						st_f <= W_PARAM1;
						sTimeOutRst <= '1';
					elsif(piDATA = FILL_RAM) then
						sCMDReg_f <= piDATA; --dato correcto
						st_f <= W_RAMVAL0;
						sAddressRst <= '1'; --Reseteo contador a Address 0x000
						sTimeOutRst <= '1';
					elsif(piDATA = READ_RAM) then
						sCMDReg_f <= piDATA; --dato correcto
						--st_f <= W_EOF;
						st_f <= W_SOF;						
						sAddressRst <= '1'; --Reseteo contador a Address 0x000
						sTimeOutRst <= '1';
					else
						st_f <= W_SOF; --dato incorrecto, descarto trama
					end if;
				end if;
						
			when W_PARAM1 => --Seleccion de Banco de registros
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato?
					if unsigned(piDATA) < to_unsigned(3,8) then --3 bancos (8,16,32 bits)
						sPARAM1Reg_f <= piDATA;
						st_f <= W_PARAM2; --dato correcto
						sTimeOutRst <= '1';
					else
						st_f <= W_SOF; --dato incorrecto, descarto trama
					end if;
				end if;

			when W_PARAM2 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato?
					if unsigned(piDATA) < to_unsigned(4,8) then --4 registros por banco
						sPARAM2Reg_f <= piDATA;
						st_f <= W_VAL0; --dato correcto
						sTimeOutRst <= '1';
					else
						st_f <= W_SOF; --dato incorrecto, descarto trama
					end if;
				end if;

			when W_VAL0 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato?
					sVAL0Reg_f <= piDATA;
					st_f <= W_VAL1; --dato correcto
					sTimeOutRst <= '1';
				end if;

			when W_VAL1 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato?
					sVAL1Reg_f <= piDATA;
					st_f <= W_VAL2; --dato correcto
					sTimeOutRst <= '1';
				end if;

			when W_VAL2 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato?
					sVAL2Reg_f <= piDATA;
					st_f <= W_VAL3; --dato correcto
					sTimeOutRst <= '1';
				end if;

			when W_VAL3 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato? 
					sVAL3Reg_f <= piDATA;
					sTimeOutRst <= '1';
					st_f <= W_EOF;
				end if;

			when W_RAMVAL0 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato? 
					sVAL0Reg_f <= piDATA;
					sTimeOutRst <= '1';
					st_f <= W_RAMVAL1;
				end if;

			when W_RAMVAL1 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato? 
					sVAL1Reg_f <= piDATA;
					sTimeOutRst <= '1';
					st_f <= W_RAMVAL2;
				end if;

			when W_RAMVAL2 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato? 
					sVAL2Reg_f <= piDATA;
					sTimeOutRst <= '1';
					st_f <= W_RAMVAL3;
				end if;

			when W_RAMVAL3 =>
				if sTimeOutTC = '1' then --venci� time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recib� dato? 
					sVAL3Reg_f <= piDATA;
					sTimeOutRst <= '1';
					st_f <= WR_RAM;
				end if;

			when WR_RAM =>
				sWrRAM <= '1';
				sAddresIncrement <= '1';
				st_f <= W_RAMVAL0;
				sTimeOutRst <= '1';

				if sAddressTC = '1' then --llen� la RAM?
					--st_f <= W_EOF;
					st_f <= W_SOF; --En el estado W_EOF se prepara registro para enviar SOF
					--sTimeOutRst <= '1';			
					sAddressRst <= '1'; --Reseteo contador a Address 0x000
					sTimeOutRst <= '1';
				end if;

			when W_EOF =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piDataReady = '1' and piDATA = EOF_BYTE then
						--switch para escribir/leer registro
						case sCMDReg_a is
							when READ_BYTE =>
								st_f <= S_SOF;	
								sDATA_f <= SOF_BYTE; --Preparo la salida para enviar en el proximo estado
								sTimeOutRst <= '1'; --Este Lucio me lo hizo comentar. TimeOut al enviar?
							when WRITE_BYTE =>
								case sPARAM1Reg_a is
									when x"00" => --banco de 8 bits		
									st_f <= S_SOF;
									sDATA_f <= SOF_BYTE; --Preparo la salida para enviar en el proximo estado
										case sPARAM2Reg_a is
											when x"00" =>
												poReg_8_0_f <= sVAL0Reg_a;
											when x"01" =>
												poReg_8_1_f <= sVAL0Reg_a;
											when x"02" =>
												poReg_8_2_f <= sVAL0Reg_a;
											when x"03" =>
												poReg_8_3_f <= sVAL0Reg_a;
											when others =>
											--si llego aca validaste como el orto
											st_f <= W_SOF;
										end case;
									
									when x"01" => --banco de 16 bits
										st_f <= S_SOF;
										sDATA_f <= SOF_BYTE;
										case sPARAM2Reg_a is
											when x"00" =>
												poReg_16_0_f <= sVAL0Reg_a & sVAL1Reg_a;
											when x"01" =>
												poReg_16_1_f <= sVAL0Reg_a & sVAL1Reg_a;
											when x"02" =>
												poReg_16_2_f <= sVAL0Reg_a & sVAL1Reg_a;
											when x"03" =>
												poReg_16_3_f <= sVAL0Reg_a & sVAL1Reg_a; 
											when others =>
											--si llego aca validaste como el orto
											st_f <= W_SOF;
										end case;

									when x"02" => --banco de 32 bits
										st_f <= S_SOF;
										sDATA_f <= SOF_BYTE;
										case sPARAM2Reg_a is
											when x"00" =>
												poReg_32_0_f <= sVAL0Reg_a & sVAL1Reg_a & sVAL2Reg_a & sVAL3Reg_a;
											when x"01" =>
												poReg_32_1_f <= sVAL0Reg_a & sVAL1Reg_a & sVAL2Reg_a & sVAL3Reg_a;
											when x"02" =>
												poReg_32_2_f <= sVAL0Reg_a & sVAL1Reg_a & sVAL2Reg_a & sVAL3Reg_a;
											when x"03" =>
												poReg_32_3_f <= sVAL0Reg_a & sVAL1Reg_a & sVAL2Reg_a & sVAL3Reg_a;
											when others =>
											--si llego aca validaste como el orto
											st_f <= W_SOF;
										end case;
									when others =>
										--si llego aca validaste como el orto
										st_f <= W_SOF;
								end case;
							when others =>
								--si llego aca validaste como el orto
								st_f <= W_SOF;
						end case;
				end if;

			when S_SOF =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					sDATA_f <= sCMDReg_a;
					st_f <= S_CMD;
					sTimeOutRst <= '1';
				end if;

			when S_CMD =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					sTimeOutRst <= '1';
					sDATA_f <= sPARAM1Reg_a;
					st_f <= S_PARAM1;
				end if;

			when S_PARAM1 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					sDATA_f <= sPARAM2Reg_a;
					st_f <= S_PARAM2;
					sTimeOutRst <= '1';
				end if;

			when S_PARAM2 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_VAL0;
					sTimeOutRst <= '1';

					case sPARAM1Reg_a is
						when x"00" =>
							--case de registro de 8 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_8_0_a;
								when x"01" =>
									sDATA_f <= poReg_8_1_a;
								when x"02" =>
									sDATA_f <= poReg_8_2_a;
								when x"03" =>
									sDATA_f <= poReg_8_3_a;
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when x"01" =>
							--case de registro de 16 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_16_0_a(15 downto 8);
								when x"01" =>
									sDATA_f <= poReg_16_1_a(15 downto 8);
								when x"02" =>
									sDATA_f <= poReg_16_2_a(15 downto 8);
								when x"03" =>
									sDATA_f <= poReg_16_3_a(15 downto 8);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;
							
						when x"02" =>
							--case de registro de 32 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_32_0_a(31 downto 24);
								when x"01" =>
									sDATA_f <= poReg_32_1_a(31 downto 24);
								when x"02" =>
									sDATA_f <= poReg_32_2_a(31 downto 24);
								when x"03" =>
									sDATA_f <= poReg_32_3_a(31 downto 24);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when others =>
							--si llego aca validaste como el orto
							st_f <= W_SOF;
					end case;
				end if;

			when S_VAL0 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_VAL1;
					case sPARAM1Reg_a is
						when x"00" =>
							--case de registro de 8 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_8_0_a;
								when x"01" =>
									sDATA_f <= poReg_8_1_a;
								when x"02" =>
									sDATA_f <= poReg_8_2_a;
								when x"03" =>
									sDATA_f <= poReg_8_3_a;
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when x"01" =>
							--case de registro de 16 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_16_0_a(7 downto 0);
								when x"01" =>
									sDATA_f <= poReg_16_1_a(7 downto 0);
								when x"02" =>
									sDATA_f <= poReg_16_2_a(7 downto 0);
								when x"03" =>
									sDATA_f <= poReg_16_3_a(7 downto 0);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;
							
						when x"02" =>
							--case de registro de 32 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_32_0_a(23 downto 16);
								when x"01" =>
									sDATA_f <= poReg_32_1_a(23 downto 16);
								when x"02" =>
									sDATA_f <= poReg_32_2_a(23 downto 16);
								when x"03" =>
									sDATA_f <= poReg_32_3_a(23 downto 16);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when others =>
							--si llego aca validaste como el orto
							st_f <= W_SOF;
					end case;
				end if;

			when S_VAL1 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_VAL2;
					sTimeOutRst <= '1';
					case sPARAM1Reg_a is
						when x"00" =>
							--case de registro de 8 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_8_0_a;
								when x"01" =>
									sDATA_f <= poReg_8_1_a;
								when x"02" =>
									sDATA_f <= poReg_8_2_a;
								when x"03" =>
									sDATA_f <= poReg_8_3_a;
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when x"01" =>
							--case de registro de 16 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_16_0_a(7 downto 0);
								when x"01" =>
									sDATA_f <= poReg_16_1_a(7 downto 0);
								when x"02" =>
									sDATA_f <= poReg_16_2_a(7 downto 0);
								when x"03" =>
									sDATA_f <= poReg_16_3_a(7 downto 0);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;
							
						when x"02" =>
							--case de registro de 32 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_32_0_a(15 downto 8);
								when x"01" =>
									sDATA_f <= poReg_32_1_a(15 downto 8);
								when x"02" =>
									sDATA_f <= poReg_32_2_a(15 downto 8);
								when x"03" =>
									sDATA_f <= poReg_32_3_a(15 downto 8);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when others =>
							--si llego aca validaste como el orto
							st_f <= W_SOF;
					end case;
				end if;

			when S_VAL2 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_VAL3;
					--sTimeOutRst <= '1';
					case sPARAM1Reg_a is
						when x"00" =>
							--case de registro de 8 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_8_0_a;
								when x"01" =>
									sDATA_f <= poReg_8_1_a;
								when x"02" =>
									sDATA_f <= poReg_8_2_a;
								when x"03" =>
									sDATA_f <= poReg_8_3_a;
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when x"01" =>
							--case de registro de 16 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_16_0_a(7 downto 0);
								when x"01" =>
									sDATA_f <= poReg_16_1_a(7 downto 0);
								when x"02" =>
									sDATA_f <= poReg_16_2_a(7 downto 0);
								when x"03" =>
									sDATA_f <= poReg_16_3_a(7 downto 0);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;
							
						when x"02" =>
							--case de registro de 32 bits
							case sPARAM2Reg_a is
								when x"00" =>	
									sDATA_f <= poReg_32_0_a(7 downto 0);
								when x"01" =>
									sDATA_f <= poReg_32_1_a(7 downto 0);
								when x"02" =>
									sDATA_f <= poReg_32_2_a(7 downto 0);
								when x"03" =>
									sDATA_f <= poReg_32_3_a(7 downto 0);
								when others =>
									--si llego aca validaste como el orto
									st_f <= W_SOF;
								end case;

						when others =>
							--si llego aca validaste como el orto
							st_f <= W_SOF;
					end case;
				end if;

			when S_VAL3 =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_EOF;
					sDATA_f <= EOF_BYTE;
					sTimeOutRst <= '1';
				end if;

			when S_EOF =>
				if piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= W_SOF;
				end if;

			when others =>
				st_f <= W_SOF;          
		end case;
	end process;
end architecture Arch_RegisterInterface;
