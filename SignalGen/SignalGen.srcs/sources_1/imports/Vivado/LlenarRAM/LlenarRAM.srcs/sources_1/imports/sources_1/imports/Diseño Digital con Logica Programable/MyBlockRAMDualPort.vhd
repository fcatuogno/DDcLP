
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MyBlockRAMDualPort is
  generic(
    N_BITS_DATA : NATURAL := 4;
    N_BITS_ADDR : NATURAL := 3 -- capacidad 2**7 = 128
  );
  Port (
   piClk : in std_logic;
   
   piWr     : in std_logic;
   piDataWr : in std_logic_vector(N_BITS_DATA-1 downto 0);
   piAddrWr : in std_logic_vector(N_BITS_ADDR-1 downto 0);
   poDataRd_1 :out  std_logic_vector(N_BITS_DATA-1 downto 0);

   poDataRd_2 :out  std_logic_vector(N_BITS_DATA-1 downto 0);
   piAddrRd_2 : in std_logic_vector(N_BITS_ADDR-1 downto 0)
     
   );
end entity;

architecture Arch_MyBlockRAMDualPort of MyBlockRAMDualPort is

  
  type TRAM is array (0 to 2**N_BITS_ADDR-1) of std_logic_vector(N_BITS_DATA-1 downto 0);
  signal RAM : TRAM := (others=> (others=>'0')) ;
  

begin


   
   
   -- Escritura
   process(piClk)
   begin
   
     if rising_edge(piClk) then
       if piWr = '1' then       
        RAM( to_integer( unsigned(piAddrWr) ) ) <= piDataWr;       
       end if;
	   
	   poDataRd_1 <= RAM(to_integer( unsigned(piAddrWr) ));
       
        -- Lectura
        -- esto es fundamental para que use blockRam
       poDataRd_2 <= RAM(to_integer( unsigned(piAddrRd_2) ));
     end if;   
   end process;
   

end Architecture;
