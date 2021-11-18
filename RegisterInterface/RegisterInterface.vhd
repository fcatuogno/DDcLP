----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.11.2021 23:00:37
-- Design Name: 
-- Module Name: RegisterInterface - Arch_RegisterInterface
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

-- Para arracxar el sistema
-- 
-- TRAMA_init [SOF=0xA5] [CMD: {0,1}] [PARAM2: {0,1,2,3}] [VAL#0] [EOF=0x5A]

entity RegisterInterface is
	Port (
		piClk : in std_logic ;
		piRst : in std_logic ;

		-- data desde modulo de comunicación
		poDATA : out std_logic_vector(8-1 downto 0);
		piUartTxReady : in std_logic;
		poStartTX : out std_logic;

		piDATA : in std_logic_vector(8-1 downto 0);
		piDataReady : in std_logic;

		poReg_8_0 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_1 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_2 : out std_logic_vector(1*8-1 downto 0);
		poReg_8_3 : out std_logic_vector(1*8-1 downto 0)
	);
end RegisterInterface;



architecture Arch_RegisterInterface of RegisterInterface is

signal poReg_8_0_a, poReg_8_0_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_1_a, poReg_8_1_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_2_a, poReg_8_2_f : std_logic_vector(1*8-1 downto 0);
signal poReg_8_3_a, poReg_8_3_f : std_logic_vector(1*8-1 downto 0);

--registros de FSM
type TSTATE is (W_SOF, W_CMD, W_PARAM2, W_VAL0, W_EOF,
				S_SOF, S_CMD, S_PARAM2, S_VAL0, S_EOF);
signal st_a, st_f : TSTATE;

--registros de comandos
signal sCMDReg_a, sCMDReg_f : std_logic_vector(8-1 downto 0);
signal sPARAM2Reg_a, sPARAM2Reg_f: std_logic_vector(8-1 downto 0);
signal sVAL0Reg_a, sVAL0Reg_f : std_logic_vector(8-1 downto 0);

--registro para la salida
signal sDATA_a, sDATA_f : std_logic_vector(8-1 downto 0);
--signal poStartTX_a, poStartTX_f : std_logic; --Hago que sea registro para sincronizarlo (No mandar antes de que este el dato en poDATA)

--constantes
constant SOF_BYTE : std_logic_vector(8-1 downto 0) := "10100101"; --0xA5
constant EOF_BYTE : std_logic_vector(8-1 downto 0) := "01011010"; --0x5A

constant READ_BYTE : std_logic_vector(8-1 downto 0) := "00000000"; --0x01
constant WRITE_BYTE : std_logic_vector(8-1 downto 0) := "00000001"; --0x02

--signals para control de contador
signal sTimeOutRst : std_logic;
signal sTimeOutTC : std_logic;

begin

	--instanciar contador
	InstCount : entity work.CounterModM
	  Generic Map(
	--Fclk = 100MHz ;
	--Tclk = 1/Fclk = 10 ns
	--TimeOut = 100ms
	-- 
	-- Modulo = TimeOut / Tclk
	--
	--  Modulo = 100ms / 0.010 ms = 10000 
		N => 14,   -- Numero de bits
		M => 10000   -- Modulo del contador
	)
	  Port Map(
	    piClk => piClk,-- : in  std_logic;
	    piRst => sTimeOutRst,-- : in  std_logic;
	    piEna => '1',-- : in  std_logic;
	    poTc  => sTimeOutTC,--  : out std_logic;
	    poQ   => open -- : out std_logic_vector(N-1 downto 0)
	  );

	--conexion de la salida con el registro
	poDATA <= sDATA_a;
	--poStartTX <= poStartTX_a;

	poReg_8_0 <= poReg_8_0_a;
	poReg_8_1 <= poReg_8_1_a;
	poReg_8_2 <= poReg_8_2_a;
	poReg_8_3 <= poReg_8_3_a;

	--registro de comandos:
	process(piClk)
	begin
		if rising_edge(piClk) then
			sCMDReg_a <= sCMDReg_f;
			sPARAM2Reg_a <= sPARAM2Reg_f;
			sVAL0Reg_a <= sVAL0Reg_f;
			sDATA_a <= sDATA_f;
			--poStartTX_a <= poStartTX_f;

			--registros 
			poReg_8_0_a <= poReg_8_0_f;
			poReg_8_1_a <= poReg_8_1_f;
			poReg_8_2_a <= poReg_8_2_f;
			poReg_8_3_a <= poReg_8_3_f;
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

	process(piDataReady, piDATA, st_a, sCMDReg_a, sPARAM2Reg_a, sVAL0Reg_a, sTimeOutTC, sDATA_a, piUartTxReady,
			poReg_8_0_a,
			poReg_8_1_a,
			poReg_8_2_a,
			poReg_8_3_a)
	begin
		--valores por defecto
		st_f <= st_a;
		sCMDReg_f <= sCMDReg_a;
		sVAL0Reg_f <= sVAL0Reg_a;
		sPARAM2Reg_f <= sPARAM2Reg_a;
		sDATA_f <= sDATA_a;

		poReg_8_0_f <= poReg_8_0_a;
		poReg_8_1_f <= poReg_8_1_a;
		poReg_8_2_f <= poReg_8_2_a;
		poReg_8_3_f <= poReg_8_3_a;

		sTimeOutRst <= '0';
		--poStartTX_f <= '0';
		poStartTX <= '0';

		case st_a is
			when W_SOF =>
				if piDataReady = '1' and piDATA = SOF_BYTE then
					sTimeOutRst <= '1';
					st_f <= W_CMD;
				end if;

			when W_CMD =>
				if sTimeOutTC = '1' then --venció time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then --recibí el dato?
					if (piDATA = READ_BYTE or piDATA = WRITE_BYTE) then --el dato es correcto?
						sCMDReg_f <= piDATA; --dato correcto
						st_f <= W_PARAM2;
						sTimeOutRst <= '1';
					else
						st_f <= W_SOF; --dato incorrecto, descarto trama
					end if;
				end if;

			when W_PARAM2 =>
				if sTimeOutTC = '1' then --venció time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recibí dato?
					if unsigned(piDATA) > to_unsigned(0,8) and unsigned(piDATA) < to_unsigned(5,8) then --dato correcto?
						sPARAM2Reg_f <= piDATA;
						st_f <= W_VAL0; --dato correcto
						sTimeOutRst <= '1';
					else
						st_f <= W_SOF; --dato incorrecto, descarto trama
					end if;
				end if;

			when W_VAL0 =>
				if sTimeOutTC = '1' then --venció time out?
					st_f <= W_SOF;
				elsif piDataReady = '1' then -- recibí dato?
					sVAL0Reg_f <= piDATA;
					st_f <= W_EOF; --dato correcto
					sTimeOutRst <= '1';
				end if;

			when W_EOF =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piDataReady = '1' and piDATA = EOF_BYTE then
					
					--switch para escribir/leer registro
					case sCMDReg_a is
						when READ_BYTE =>
							--Paso al siguiente estado, de cualquier manera leerá y enviará registro
							st_f <= S_SOF;
							sDATA_f <= SOF_BYTE;
							--sTimeOutRst <= '1';
						when WRITE_BYTE =>
							case sPARAM2Reg_a is
								when x"01" =>
									poReg_8_0_f <= sVAL0Reg_a;
									st_f <= S_SOF;
									sDATA_f <= SOF_BYTE;
								when x"02" =>
									poReg_8_1_f <= sVAL0Reg_a;
									st_f <= S_SOF;
									sDATA_f <= SOF_BYTE;
								when x"03" =>
									poReg_8_2_f <= sVAL0Reg_a;
									st_f <= S_SOF;
									sDATA_f <= SOF_BYTE;
								when x"04" =>
									poReg_8_3_f <= sVAL0Reg_a;
									st_f <= S_SOF;
									sDATA_f <= SOF_BYTE; 
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
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piUartTxReady = '1' then
					poStartTX <= '1';
					sDATA_f <= sCMDReg_a;
					st_f <= S_CMD;
					sTimeOutRst <= '1';
				end if;
			
			when S_CMD =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piUartTxReady = '1' then
					poStartTX <= '1';
					sDATA_f <= sPARAM2Reg_a;
					st_f <= S_PARAM2;
					sTimeOutRst <= '1';
				end if;

			when S_PARAM2 =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_VAL0;
					sTimeOutRst <= '1';

					case sPARAM2Reg_a is --esto estaba preguntando  el command en vez del nro de registro
						when x"01" =>	
							sDATA_f <= poReg_8_0_a;
							--sDATA_f <= "01010101";	--debug purposes
						when x"02" =>
							sDATA_f <= poReg_8_1_a;
							--sDATA_f <= sVAL0Reg_a;
						when x"03" =>
							sDATA_f <= poReg_8_2_a;
						when x"04" =>
							sDATA_f <= poReg_8_3_a;
						when others =>
							--si llego aca validaste como el orto
							st_f <= W_SOF;
						end case;
				end if;

			when S_VAL0 =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= S_EOF;
					sDATA_f <= EOF_BYTE;
					sTimeOutRst <= '1';
				end if;

			when S_EOF =>
				if sTimeOutTC = '1' then
					st_f <= W_SOF;
				elsif piUartTxReady = '1' then
					poStartTX <= '1';
					st_f <= W_SOF;
				end if;

			when others =>
				st_f <= W_SOF;          
		end case;
	end process;
end architecture Arch_RegisterInterface;
