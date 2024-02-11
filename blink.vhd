LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY blink is

    port
    (
        i_clk       : IN STD_LOGIC;
        o_ledring   : OUT std_logic_vector(23 downto 0);
        o_ledtrans  : OUT STD_LOGIC;
        o_flashing  : OUT STD_LOGIC
    );

end blink;


--  Architecture Body

architecture blink_architecture of blink is

-- Constants to create the frequencies needed:
-- 50MHZ/1Hz * 50% duty = 25,000,000
-- 50MHZ/10hz * 50% duty = 2,500,000
  
constant c_CNT_1HZ    : natural := 25000000;
constant c_CNT_10HZ   : natural := 2500000;

-- Counter signals:
signal r_CNT_1HZ    : natural range 0 to c_CNT_1HZ;
signal r_CNT_10HZ   : natural range 0 to c_CNT_10HZ;
constant c_NUM_LEDS : natural := 12;  -- Define the number of entries in the array
signal r_CNT_LEDARR : natural range 0 to 24 := 0;

-- these signals hold toggle status:
signal r_TOGGLE_1HZ : std_logic := '0';
signal r_TOGGLE_10HZ: std_logic := '0';

TYPE machine IS(idle, transmitting, finished);    -- state machine
signal state        : machine := idle;

type data_array_type is array (natural range <>) of std_logic_vector(23 downto 0);
signal data : std_logic_vector(23 downto 0) := x"0000FF";
signal data_arrayz   : data_array_type(0 to c_NUM_LEDS - 1) := (
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000",
    x"FF0000"
);

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

    p_LED_transmit : process (i_clk) is
    begin
    if rising_edge(i_clk) then
        
        if r_TOGGLE_10HZ = '1' and state = idle then
            state <= transmitting;
            --r_CNT_LEDARR <= 0;
        end if;

        case state is

            when transmitting =>
                if r_CNT_LEDARR > 12 then -- ALWAYS EQUAL TO 13???
                    data   <= x"00ff00";
                else
                    data   <= x"000010";
                end if;

                --data <= x"101010";
                --data <= data_arrayz(0);

                

                if r_CNT_LEDARR > c_NUM_LEDS then
                    r_CNT_LEDARR <= 0;
                    state <= finished;
                end if;

                r_CNT_LEDARR <= r_CNT_LEDARR + 1;

            when finished =>
                --r_CNT_LEDARR <= 0;
                if r_TOGGLE_10HZ = '0' then
                    state <= idle;
                end if;

            when idle =>
                r_CNT_LEDARR <= 0;
        end case;

    end if;
    end process;

o_ledring   <= data;
o_flashing  <= r_TOGGLE_10HZ;
o_ledtrans  <= r_TOGGLE_10HZ;

end blink_architecture;