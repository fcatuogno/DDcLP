----------------------------------------------------------------------------------
-- Company: UTN.BA DDcLP 2021
-- Casi Engineer: Catuogno Fabian
-- 
-- Create Date: 03.11.2021 23:44:21
-- Design Name: Generador de señales
-- Module Name: CounterEspecial - Arch_CounterEspecial
-- Project Name: Signal Gen
-- Target Devices: Arty (Artix-7)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CounterEspecial is
  generic( N: NATURAL := 10;
           M: NATURAL := 500
        );
    Port ( 
    piClk,piRst,piEna : in std_logic ;
    poQ : out std_logic_vector(N-1 downto 0);
    poTc : out std_logic;
    poTc_Half : out std_logic
   );
end entity;

architecture Arch_CounterEspecial of CounterEspecial is
    signal sQ : unsigned(N-1 downto 0) ;
begin

    poQ <= std_logic_vector(sQ);
     
    process(piClk)
    begin
        if rising_edge(piClk) then

            if piRst = '1' then
                sQ <= (others => '0');
                poTc<='0';
                poTc_Half<='0';
            elsif piEna ='1' then
                
                poTc_Half<='0';
                if sQ = to_unsigned(M/2-1 , N) then
                    poTc_Half <='1' ;
                end if;
                
                sQ <= sQ + to_unsigned(1,N);
                poTc <='0' ;
                if sQ = to_unsigned(M-1 , N) then
                    sQ <= to_unsigned(0,N);
                    poTc <='1' ;
                end if;

            end if;
        end if;
    end process;


end architecture;
