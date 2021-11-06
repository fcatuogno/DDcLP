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
  N: NATURAL := 4;   -- Nomero de bits
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
  --signal sTc  : std_logic;
  signal sQ   : unsigned(N-1 downto 0);

begin

 poQ<= std_logic_vector(sQ);
 --poTc <= sTc ;


  process(piClk)
  begin
  
    if rising_edge(piClk) then
    
      if piRst = '1' then
        sQ <= (others =>'0');
        poTc<= '0'; 
      elsif piEna = '1' then
        sQ <= sQ + 1;
        poTc<= '0';
        if sQ = M-1 then
          sQ <= (others =>'0');
          poTc<= '1';
        end if;
      end if ;    
        
    end if;
  
  end process;

end architecture;