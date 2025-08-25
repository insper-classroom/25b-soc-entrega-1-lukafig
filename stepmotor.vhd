library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stepmotor is
    port (
        clk   : in  std_logic;
        en    : in  std_logic;
        dir   : in  std_logic;
        vel   : in  std_logic_vector(1 downto 0);
        phase : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of stepmotor is

    signal cnt       : unsigned(23 downto 0) := (others => '0');
    signal step_idx  : integer range 0 to 3 := 0;
    signal phase_reg : std_logic_vector(3 downto 0) := "0000";

    -- constantes para divisão de clock (ajuste conforme necessário)
    constant DIV0 : unsigned(23 downto 0) := to_unsigned(1_000_000, 24);  -- mais rápido
    constant DIV1 : unsigned(23 downto 0) := to_unsigned(12_000_000, 24);
    constant DIV2 : unsigned(23 downto 0) := to_unsigned(16_000_000, 24);
    constant DIV3 : unsigned(23 downto 0) := to_unsigned(25_000_000, 24); -- mais lento

    signal div_limit : unsigned(23 downto 0);

begin
    --------------------------------------------------------------------
    -- Multiplexador da velocidade
    --------------------------------------------------------------------
    process(vel)
    begin
        case vel is
            when "00"   => div_limit <= DIV0;
            when "01"   => div_limit <= DIV1;
            when "10"   => div_limit <= DIV2;
            when others => div_limit <= DIV3;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Contador para gerar passos
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                if cnt = div_limit then
                    cnt <= (others => '0');
                    -- avança ou retrocede
                    if dir = '0' then
                        if step_idx = 3 then
                            step_idx <= 0;
                        else
                            step_idx <= step_idx + 1;
                        end if;
                    else
                        if step_idx = 0 then
                            step_idx <= 3;
                        else
                            step_idx <= step_idx - 1;
                        end if;
                    end if;
                else
                    cnt <= cnt + 1;
                end if;
            else
                cnt <= (others => '0');
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Tabela de fases
    --------------------------------------------------------------------
    process(step_idx, en)
    begin
        if en = '0' then
            phase_reg <= "0000";
        else
            case step_idx is
                when 0 => phase_reg <= "0001";
                when 1 => phase_reg <= "0010";
                when 2 => phase_reg <= "0100";
                when 3 => phase_reg <= "1000";
                when others => phase_reg <= "0000";
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Saída
    --------------------------------------------------------------------
    phase <= phase_reg;

end architecture;
