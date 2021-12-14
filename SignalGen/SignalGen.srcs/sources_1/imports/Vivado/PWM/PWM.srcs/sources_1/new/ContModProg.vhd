----------------------------------------------------------------------------------
-- Company: UTN.BA DDcLP 2021
-- Casi Engineer: Catuogno Fabian
-- 
-- Create Date: 16.09.2021
-- Design Name: Generador de señales
-- Module Name: ProgCounterModM - Behavioral
-- Project Name: Signal Gen
-- Target Devices: Arty (Artix-7)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ProgCounterModM is
	Generic(
		N: NATURAL := 4   -- Numero de bits
	);
	Port (
		piClk : in  std_logic;
		piRst : in  std_logic;
		piEna : in  std_logic;
		poTc  : out std_logic;
		piMod : in std_logic_vector(N-1 downto 0);
		poQ   : out std_logic_vector(N-1 downto 0)
	);
end entity;

architecture Behavioral of ProgCounterModM is
  signal sQ   : unsigned(N-1 downto 0);

begin

 poQ<= std_logic_vector(sQ);

  process(piClk)
  begin
  
    if rising_edge(piClk) then
    
      if piRst = '1' then
        sQ <= (others =>'0');
        poTc<= '0'; 
      elsif piEna = '1' then
        sQ <= sQ + 1;
        poTc<= '0';
        if sQ = unsigned(piMod)-1 then
          sQ <= (others =>'0');
          poTc<= '1';
        end if;
      end if ;    
        
    end if;
  
  end process;

end architecture;