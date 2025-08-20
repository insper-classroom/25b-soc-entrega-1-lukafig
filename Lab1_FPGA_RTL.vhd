library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Lab1_FPGA_RTL is
    port (
        -- Globals
        fpga_clk_50      : in  std_logic;

        -- I/Os
        fpga_led_pio     : out std_logic_vector(5 downto 0);
        fpga_button_pio  : in  std_logic_vector(3 downto 0); -- buttons
        fpga_switch_pio  : in  std_logic_vector(3 downto 0)  -- switches
    );
end entity;

architecture rtl of Lab1_FPGA_RTL is

    signal blink        : std_logic := '0';
    signal counter      : integer := 0;
    signal blink_limit  : integer := 10000000;
    signal led_state    : std_logic_vector(5 downto 0) := (others => '0');

begin

    -- Determine blink rate from switches
    process(fpga_switch_pio)
    begin
        case fpga_switch_pio is
            when "0000" => blink_limit <= 5_000_000;   -- Fast
            when "0001" => blink_limit <= 10_000_000;  -- Medium
            when "0010" => blink_limit <= 20_000_000;  -- Slow
            when others => blink_limit <= 40_000_000;  -- Very slow
        end case;
    end process;

    -- Blink generation
    process(fpga_clk_50)
    begin
        if rising_edge(fpga_clk_50) then
            if counter < blink_limit then
                counter <= counter + 1;
            else
                blink <= not blink;
                counter <= 0;
            end if;
        end if;
    end process;

    -- LED control with buttons
process(fpga_clk_50)
begin
    if rising_edge(fpga_clk_50) then
        if fpga_button_pio(0) = '0' then
            led_state(0) <= blink;
        else
            led_state(0) <= '0';
        end if;

        if fpga_button_pio(1) = '0' then
            led_state(1) <= blink;
        else
            led_state(1) <= '0';
        end if;

        if fpga_button_pio(2) = '0' then
            led_state(2) <= blink;
        else
            led_state(2) <= '0';
        end if;

        if fpga_button_pio(3) = '0' then
            led_state(3) <= blink;
        else
            led_state(3) <= '0';
        end if;

        -- LEDs 4 and 5 always blink
        led_state(4) <= blink;
        led_state(5) <= blink;
    end if;
end process;

    -- Assign to outputs
    fpga_led_pio <= led_state;

end rtl;
