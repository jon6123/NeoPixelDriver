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

-- max clock counting for 80 khz signal (H + L)
signal c_CNT_80KHZ  : natural := 31;

-- time high time low for each bit type
-- https://cdn-shop.adafruit.com/datasheets/WS2812.pdf
signal c_T0H : natural := 17;
signal c_T1H : natural := 35;
signal c_T1L : natural := 30;
signal c_T0L : natural := 40;

-- bool signal to hold current state of bit being delivered
signal b_bitState : std_logic := '1';

signal r_CNT_STATE : natural range 0 to (2 *c_CNT_80KHZ);   -- clk roll over for current state
signal r_CNT_CLK   : natural range 0 to (2 *c_CNT_80KHZ);   -- clk counter for current state
signal b_outstate  : std_logic := '1';                      -- main output bool to send

signal b_gate  : std_logic := '0';                          -- bool to gate, if 1 we are running
signal c_MAX_bits  : natural := 24;                         -- max number of bits per data entry (LED)
signal r_CNT_bits  : natural range 0 to c_MAX_bits;         -- counter to iterate through bits and finish

signal data : std_logic_vector(23 downto 0) := x"FF00FF";

begin

    p_CLK_80KHZ : process(i_clk, i_trig) is
    begin

        -- if trigger signal recieved then start gated transmission
        if rising_edge(i_trig) then
            b_gate <= '1';
        end if;

        -- during gated event, we are counting and transmitting
        if b_gate = '1' then

            -- depending on which bit in data, and which bit state we are in (HI or LO) 
            -- find roll over max to compare to
            if b_bitState = '1' then
                if data(r_CNT_bits) = '1' then
                    r_CNT_STATE <= c_T1H;
                else
                    r_CNT_STATE <= c_T0H;
                end if;
            else
                if data(r_CNT_bits) = '1' then
                    r_CNT_STATE <= c_T1L;
                else
                    r_CNT_STATE <= c_T0L;
                end if;
            end if;

            -- on each clk cycle, count and compare to current max
            -- if rolling over for this bit and bit state, change output
            if rising_edge(i_clk) then
                if r_CNT_CLK = r_CNT_STATE - 1 then
                    b_outstate <= not b_outstate;
                    r_CNT_CLK <= 0;
                    if b_bitState = '0' then
                        r_CNT_bits <= r_CNT_bits + 1;
                        b_bitState <= '1';
                    else
                        b_bitState <= '0';
                    end if;
                else
                    r_CNT_CLK <= r_CNT_CLK + 1;
                end if;       
            end if;

        end if;

        -- if we have counted through all bits, then close gate and end transmission
        if r_CNT_bits = c_MAX_bits then
            b_gate <= '0';
            b_outstate <= '1';
            r_CNT_bits <= 0;
        end if;

    end process;

-- output signals, clk gated
o_data   <= b_outstate and b_gate;

end ws2812_architecture;