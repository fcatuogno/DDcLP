----------------------------------------------------------------------------------
--
-- led blink
-- arty board
-- 16.09.2021
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity CounterModM is
  Generic(
  N: NATURAL := 4;   -- Nmero de bits
  M: NATURAL := 10   -- Modulo del contador
  );
  Port (
  piClk : in  std_logic;
  piRst : in  std_logic;
  piEna : in  std_logic;
  poTc  : out std_logic;
  poQ   : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture Behavioral of CounterModM is
  
signal srQ_now, sQ_next : std_logic_vector(N-1 downto 0);
signal sTc : std_logic;

begin

  poQ <= srQ_now ;
  poTc <= sTc;

  process(piClk)
  begin

    if rising_edge(piClk) then

      if piRst = '1' then
        srQ_now <= (others=> '0');
      elsif piEna='1' then
        srQ_now <= sQ_next ;
      end if;   
    end if;
  end process;

    sTc <= '1' when unsigned(srQ_now) = to_unsigned(M-1,N) else '0';
    sQ_next <= std_logic_vector( unsigned(srQ_now) + 1) when sTc='0' else std_logic_vector(TO_UNSIGNED(0,N));

end architecture;