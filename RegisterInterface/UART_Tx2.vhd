library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.All;


entity UART_Tx is
	Generic (
		BAUD_RATE_PRESCALLER : NATURAL := 10417
	);
	Port (
		piclk	: in STD_LOGIC; --A fin de que las salida sean registradas
		piRst	: in STD_LOGIC; --reset
		piStart	: in STD_LOGIC; --start transmision
		piDato	: in std_logic_vector(8-1 downto 0);
		poTx	: out STD_LOGIC; --serial out
		poReady : out STD_LOGIC
	);
end UART_Tx;

architecture Arch_UART_Tx of UART_Tx is

	type STATE is (W, BI, B7, B6, B5, B4, B3, B2, B1, B0, BS);
	signal st_a, st_f : STATE;

	--registro de la data:
	signal sRegDato_a, sRegDato_f : std_logic_vector(8-1 downto 0); 

	signal sTimerRst : std_logic;
	signal piTC : std_logic;

	signal poSout : std_logic;

	--constant cDATO : std_logic_vector(8-1 downto 0) := "00110000";
	--signal sDATO2Tx : s

	constant cBIT_START : std_logic := '0';
	constant cBIT_STOP : std_logic := '1';
	constant cLINE_IDLE : std_logic := '1';

begin
	InstTimer : entity  work.CounterModM
	  Generic Map(
	--    Tw = 104.166us
	--    Fclk = 100M
	--    Modulo = Tw * Fclk = 104.16 10e-6 * 100 10e6 =  10416 10e0 = 10416
	--    Cauntos bits necesito:
	--    N => 26,      -- log2(100M/2=50M) 
	--    M => 2000000  -- Arty
	    N => natural ( ceil ( log2( real(BAUD_RATE_PRESCALLER) ) ) ),
	    M => BAUD_RATE_PRESCALLER
	  )
	  Port Map(
	    piClk => piClk,-- : in  std_logic;
	    piRst => sTimerRst,-- : in  std_logic;
	    piEna => '1',-- : in  std_logic;
	    poTc  => piTC,--  : out std_logic;
	    poQ   => open -- : out std_logic_vector(N-1 downto 0)
	  );

	process(piClk)
	begin
		if rising_edge(piClk) then

			if piRst = '1' then
				st_a <= W;
				sRegDato_a <= (others => '0'); 
			else
				st_a <= st_f;
				sRegDato_a <= sRegDato_f;
			end if;
		end if;
	end process;

	process(st_a,piTC,piStart,piDato,sRegDato_a)
	begin

		--mantiene valor
		st_f <= st_a;

		--debe registrarse el dato de entrada. Agregar piData a lista de sensibilidad
		sRegDato_f <= sRegDato_a;

		--valores por defecto
		poSout <= '1';
		sTimerRst <= '0';
		poReady <= '0';

		case st_a is
			when W =>
				poSout <= cLINE_IDLE;
				poReady <= '1';
				sTimerRst <= '1';
				if piStart = '1' then
					sRegDato_f <= piDato;
					st_f <= BI;
				end if;
			when BI =>
				poSout <= cBIT_START;
				if piTC = '1' then
					st_f <= B7;
				end if;
			when B7 => 
				poSout <= sRegDato_a(0);
				if piTC = '1' then
					st_f <= B6;
				end if;
			when B6 =>
				poSout <= sRegDato_a(1);
				if piTC = '1' then
					st_f <= B5;
				end if;
			when B5 =>
				poSout <= sRegDato_a(2);
				if piTC = '1' then
					st_f <= B4;
				end if;
			when B4 =>
				poSout <= sRegDato_a(3);
				if piTC = '1' then
					st_f <= B3;
				end if;
			when B3 =>
				poSout <= sRegDato_a(4);
				if piTC = '1' then
					st_f <= B2;
				end if;
			when B2 =>
				poSout <= sRegDato_a(5);
				if piTC = '1' then
					st_f <= B1;
				end if;
			when B1 =>
				poSout <= sRegDato_a(6);
				if piTC = '1' then
					st_f <= B0;
				end if;
			when B0 => 
				poSout <= sRegDato_a(7);
				if piTC = '1' then
					st_f <= BS;
				end if;
			when BS =>
				poSout <= cBIT_STOP;
				if piTC = '1' then
					st_f <= W;
				end if;
			when others =>
				st_f <= W;
				poSout <= cLINE_IDLE;
		end case;		
	end process;

	process(piClk)
	begin
		if rising_edge(piClk) then

			if piRst = '1' then
				poTx <= cLINE_IDLE;
			else
				poTx <= poSout;
			end if;
		end if;
	end process;

end Arch_UART_Tx;
