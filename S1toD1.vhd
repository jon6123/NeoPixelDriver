LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity S1toD1 is
    port
    (
        i_S1 : IN STD_LOGIC;
        o_intermediate : OUT STD_LOGIC
    );

end S1toD1;


architecture S1toD1_architecture of S1toD1 is

begin

o_intermediate <= not i_S1;

end S1toD1_architecture;