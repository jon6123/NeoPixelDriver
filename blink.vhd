LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY blink is

    port
    (
        i_clk       : IN STD_LOGIC;
        o_flashing  : OUT STD_LOGIC
    );

end blink;


--  Architecture Body

architecture blink_architecture of blink is

-- Constants to create the frequencies needed:
-- 50MHZ/1Hz * 50% duty = 25,000,000
-- 50MHZ/10hz * 50% duty = 2,500,000
  
signal c_CNT_1HZ    : natural := 25000000;
signal c_CNT_10HZ   : natural := 2500000;

-- Counter signals:
signal r_CNT_1HZ    : natural range 0 to c_CNT_1HZ;
signal r_CNT_10HZ   : natural range 0 to c_CNT_10HZ;

-- these signals hold toggle status:
signal r_TOGGLE_1HZ : std_logic := '0';
signal r_TOGGLE_10HZ: std_logic := '0';

begin

    p_1HZ : process (i_clk) is
    begin
    if rising_edge(i_clk) then
        if r_CNT_1HZ = c_CNT_1HZ - 1 then
            r_TOGGLE_1HZ <= not r_TOGGLE_1HZ;
            r_CNT_1HZ <= 0;
        else
            r_CNT_1HZ <= r_CNT_1HZ + 1;
        end if;
    end if;
    end process;

    p_10HZ : process (i_clk) is
    begin
    if rising_edge(i_clk) then
        if r_CNT_10HZ = c_CNT_10HZ - 1 then
            r_TOGGLE_10HZ <= not r_TOGGLE_10HZ;
            r_CNT_10HZ <= 0;
        else
            r_CNT_10HZ <= r_CNT_10HZ + 1;
        end if;
    end if;
    end process;

o_flashing <=  r_TOGGLE_1HZ;

end blink_architecture;