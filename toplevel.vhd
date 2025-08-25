library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity toplevel is
    port (
        fpga_clk_50 : in  std_logic;
        fpga_switch_pio       : in  std_logic_vector(9 downto 0);
        fpga_led_pio     : out std_logic_vector(9 downto 0);
        GPIO     : out std_logic_vector(35 downto 0)
    );
end entity;

architecture rtl of toplevel is

    -- Instância do componente stepmotor
		component stepmotor is
			port (
				clk   : in  std_logic;
				en    : in  std_logic;
				dir   : in  std_logic;
				vel   : in  std_logic_vector(1 downto 0);
				steps : in  unsigned(15 downto 0);
				phase : out std_logic_vector(3 downto 0);
				busy  : out std_logic
    );
		end component;


    signal phase_s : std_logic_vector(3 downto 0);

begin
    ----------------------------------------------------------------
    -- Instanciando o motor
    ----------------------------------------------------------------
u_motor : stepmotor
    port map (
        clk   => fpga_clk_50,
        en    => fpga_switch_pio(0),
        dir   => fpga_switch_pio(1),
        vel   => fpga_switch_pio(3 downto 2),
        steps => (unsigned(fpga_switch_pio(9 downto 4)) & "0000000000"),
        phase => phase_s,
        busy  => fpga_led_pio(9) -- LED indica motor em movimento
    );


    ----------------------------------------------------------------
    -- Conectando fases ao GPIO
    ----------------------------------------------------------------
    GPIO(3 downto 0) <= phase_s;

    ----------------------------------------------------------------
    -- LEDs para debug
    ----------------------------------------------------------------
    fpga_led_pio(0) <= fpga_switch_pio(0);          -- mostra EN
    fpga_led_pio(1) <= fpga_switch_pio(1);          -- mostra DIR
    fpga_led_pio(3 downto 2) <= fpga_switch_pio(3 downto 2); -- mostra velocidade
    fpga_led_pio(8 downto 4) <= (others => '0'); -- não usados

    ----------------------------------------------------------------
    -- Restante dos GPIOs ficam em zero
    ----------------------------------------------------------------
    GPIO(35 downto 4) <= (others => '0');

end architecture;
