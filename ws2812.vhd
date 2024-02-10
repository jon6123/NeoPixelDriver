LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ws2812 is

    port
    (
        i_clk   : IN STD_LOGIC;
        i_trig  : IN STD_LOGIC;
        o_data  : OUT STD_LOGIC
    );

end ws2812;

architecture ws2812_architecture of ws2812 is

-- CLK counter signals
signal c_CNT_80KHZ  : natural := 31;
signal r_CNT_80KHZ  : natural range 0 to c_CNT_80KHZ;
signal b_CLK_80KHZ  : std_logic := '1';

signal b_CLK_gate  : std_logic := '0';
signal c_MAX_bits  : natural := 24;
signal r_CNT_bits  : natural range 0 to (2 * c_MAX_bits);


begin

    p_CLK_80KHZ : process(i_clk, i_trig) is
    begin

        -- if trigger signal recieved then start gated process
        if rising_edge(i_trig) then
            b_CLK_gate <= '1';
        end if;

        -- during gated process
        if b_CLK_gate = '1' then

            -- calculate ws2812 clk and count roll overs
            if rising_edge(i_clk) then
                if r_CNT_80KHZ = c_CNT_80KHZ - 1 then
                    b_CLK_80KHZ <= not b_CLK_80KHZ;
                    r_CNT_80KHZ <= 0;
                    r_CNT_bits <= r_CNT_bits + 1;
                else
                    r_CNT_80KHZ <= r_CNT_80KHZ + 1;
                end if;       
            end if;

        end if;

        -- if ws2812 CLK rollover count (bit edges) = edges of max bits, then close gate
        if r_CNT_bits = (2 * c_MAX_bits) - 1 then
            b_CLK_gate <= '0';
            b_CLK_80KHZ <= '1';
            r_CNT_bits <= 0;
        end if;

    end process;

-- output signals, clk gated
o_data   <= b_CLK_80KHZ and b_CLK_gate;

end ws2812_architecture;