LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity ANDFILE is
    port
    (
        i_intermediate : IN STD_LOGIC;
        i_S2 : IN STD_LOGIC;
        o_D1 : OUT STD_LOGIC
    );

end ANDFILE;


architecture ANDFILE_architecture of ANDFILE is


begin

o_D1 <=  i_intermediate and not i_S2;

end ANDFILE_architecture;