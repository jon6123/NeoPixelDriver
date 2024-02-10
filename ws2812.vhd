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

signal c_t0h : natural := 17;
signal c_t1h : natural := 35;
signal c_t1l : natural := 30;
signal c_t0l : natural := 40;

signal b_bitState : std_logic := '1';

signal r_CNT_BIT : natural range 0 to (2 *c_CNT_80KHZ);
signal r_CNT_80KHZ  : natural range 0 to (2 *c_CNT_80KHZ);
signal b_CLK_80KHZ  : std_logic := '1';

signal b_CLK_gate  : std_logic := '0';
signal c_MAX_bits  : natural := 24;
signal r_CNT_bits  : natural range 0 to (2 * c_MAX_bits);

signal data : std_logic_vector(23 downto 0) := x"FF00FF";

begin

    p_CLK_80KHZ : process(i_clk, i_trig) is
    begin

        -- if trigger signal recieved then start gated process
        if rising_edge(i_trig) then
            b_CLK_gate <= '1';
        end if;

        -- during gated process
        if b_CLK_gate = '1' then

            if b_bitState = '1' then
                if data(r_CNT_bits) = '1' then
                    r_CNT_BIT <= c_t1h;
                else
                    r_CNT_BIT <= c_t0h;
                end if;
            else
                if data(r_CNT_bits) = '1' then
                    r_CNT_BIT <= c_t1l;
                else
                    r_CNT_BIT <= c_t0l;
                end if;
            end if;

            -- calculate ws2812 clk and count roll overs
            if rising_edge(i_clk) then
                if r_CNT_80KHZ = r_CNT_BIT - 1 then
                    b_CLK_80KHZ <= not b_CLK_80KHZ;
                    r_CNT_80KHZ <= 0;
                    if b_bitState = '0' then
                        r_CNT_bits <= r_CNT_bits + 1;
                        b_bitState <= '1';
                    else
                        b_bitState <= '0';
                    end if;
                else
                    r_CNT_80KHZ <= r_CNT_80KHZ + 1;
                end if;       
            end if;

        end if;

        -- if ws2812 CLK rollover count (bit edges) = edges of max bits, then close gate
        if r_CNT_bits = c_MAX_bits then
            b_CLK_gate <= '0';
            b_CLK_80KHZ <= '1';
            r_CNT_bits <= 0;
        end if;

    end process;

-- output signals, clk gated
o_data   <= b_CLK_80KHZ and b_CLK_gate;

end ws2812_architecture;