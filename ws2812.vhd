LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ws2812 is

port
(
    i_clk       : IN STD_LOGIC;
    i_enable    : IN STD_LOGIC;
    i_data      : IN std_logic_vector(23 downto 0);
    i_dataTrans : IN STD_LOGIC;
    o_data      : OUT STD_LOGIC
);

end ws2812;

architecture ws2812_architecture of ws2812 is

-- max clock counting for 80 khz signal (H + L)
constant c_CNT_800KHZ  : natural := 31;
constant c_CNT_55US    : natural := 2750;

-- time high time low for each bit type
-- https://cdn-shop.adafruit.com/datasheets/WS2812.pdf
constant c_T0H : natural := 17;
constant c_T1H : natural := 35;
constant c_T1L : natural := 30;
constant c_T0L : natural := 40;

-- bool signal to hold current state of bit being delivered
signal b_bitState : std_logic := '1';

signal r_CNT_STATE  : natural range 0 to (2 *c_CNT_800KHZ);   -- clk roll over for current state
signal r_CNT_CLK    : natural range 0 to (2 *c_CNT_55US);     -- clk counter for current state

constant c_MAX_bits : natural := 24;                         -- max number of bits per data entry (LED)
signal r_CNT_bits   : natural range 0 to c_MAX_bits;         -- counter to iterate through bits and finish

type data_array_type is array (natural range <>) of std_logic_vector(23 downto 0);
constant c_NUM_LEDS : natural := 12;  -- Define the number of entries in the array
TYPE machine IS(idle, running, pause);                       -- state machine
signal state        : machine;
signal in_data_array : data_array_type(0 to c_NUM_LEDS - 1) := (others => (others => '0'));

signal data : std_logic_vector(23 downto 0) := x"0000FF";

signal r_CNT_LED    : natural range 0 to c_NUM_LEDS;
signal data_array   : data_array_type(0 to c_NUM_LEDS - 1) := (
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000",
    x"000000"
);

TYPE inMachine IS(idle, recieving, recieved);                -- input state machine
signal inState      : inMachine;
signal r_CNT_DAT    : natural range 0 to c_NUM_LEDS;

begin

p_CLK_80KHZ : process(i_clk) is
begin

if rising_edge(i_clk) then

    if i_enable = '0' then
        state   <= idle;
    end if;

    -- if new transmission and rising edge of data trans
    -- begin to clock in data
    if i_dataTrans = '1' and inState = idle then
        inState <= recieving;
        r_CNT_DAT <= 0;
    end if;

    -- data input state machine
    case inState is

        when recieving =>
            in_data_array(r_CNT_DAT) <= i_data;
            r_CNT_DAT <= r_CNT_DAT + 1;
            if r_CNT_DAT > c_NUM_LEDS then
                inState <= recieved;
            end if;

        when recieved =>
            if state = idle or state = pause then
                data_array <= in_data_array;
                inState <= idle;
                r_CNT_DAT <= 0;
            end if;

        when idle =>
            r_CNT_DAT <= 0;

    end case;


    if i_enable = '1' and state = idle then
        state   <= running;
    end if;

    -- LED data output state machine
    case state is

        when running =>

            -- load data from LED array
            data    <= data_array(r_CNT_LED);

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
            if r_CNT_CLK = r_CNT_STATE - 1 then
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
            
            -- if we have counted through all bits, incriment through array
            if r_CNT_bits = c_MAX_bits then
                b_bitState <= '1';
                r_CNT_bits  <= 0;
                r_CNT_LED   <= r_CNT_LED + 1;
            end if;

            -- if end of array then end transmission and go to pause
            if r_CNT_LED = c_NUM_LEDS then
                b_bitState  <= '0';
                r_CNT_LED   <= 0;
                r_CNT_CLK   <= 0;
                state       <= pause;
            end if;

        -- pause state adds >50uS 0 to reset the LED chain ready to recieve updated cmd
        when pause =>
            b_bitState <= '0';
            if r_CNT_CLK = c_CNT_55US - 1 then
                r_CNT_CLK   <= 0;
                b_bitState  <= '1';
                state       <= running;
            else
                r_CNT_CLK <= r_CNT_CLK + 1;
            end if;  

        -- when idling reset counters and prepare bit state to 1 for first bit
        when idle =>
            r_CNT_CLK   <= 0;
            r_CNT_bits  <= 0;
            r_CNT_LED   <= 0;
            b_bitState  <= '1';

    end case;
end if;
end process;

-- output signals, clk gated
o_data   <= b_bitState and i_enable;

end ws2812_architecture;