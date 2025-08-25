library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stepmotor is
    port (
        clk   : in  std_logic;
        en    : in  std_logic;
        dir   : in  std_logic;
        vel   : in  std_logic_vector(1 downto 0);
        steps : in  unsigned(15 downto 0); -- número de passos
        phase : out std_logic_vector(3 downto 0);
        busy  : out std_logic              -- indica motor em movimento
    );
end entity;

architecture rtl of stepmotor is

    signal cnt        : unsigned(23 downto 0) := (others => '0');
    signal step_idx   : integer range 0 to 3 := 0;
    signal phase_reg  : std_logic_vector(3 downto 0) := "0000";
    signal div_limit  : unsigned(23 downto 0) := (others => '0');
    signal target_div : unsigned(23 downto 0);

    signal steps_left : unsigned(15 downto 0) := (others => '0');
    signal en_d       : std_logic := '0'; -- memória do EN para detectar borda

    -- constantes para divisão de clock
    constant DIV0 : unsigned(23 downto 0) := to_unsigned(500_000, 24);
    constant DIV1 : unsigned(23 downto 0) := to_unsigned(5_000_000, 24);
    constant DIV2 : unsigned(23 downto 0) := to_unsigned(10_000_000, 24);
    constant DIV3 : unsigned(23 downto 0) := to_unsigned(25_000_000, 24);

begin
    --------------------------------------------------------------------
    -- Seleção da velocidade alvo
    --------------------------------------------------------------------
    process(vel)
    begin
        case vel is
            when "00"   => target_div <= DIV0;
            when "01"   => target_div <= DIV1;
            when "10"   => target_div <= DIV2;
            when others => target_div <= DIV3;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Lógica principal
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- detecta borda de subida de EN
            en_d <= en;

            if en = '0' then
                -- motor parado
                steps_left <= (others => '0');
                cnt        <= (others => '0');

            else
                -- start: só carrega steps_left na borda 0->1
                if (en_d = '0') and (steps > 0) then
                    steps_left <= steps;
                    cnt        <= (others => '0');
                    div_limit  <= target_div; -- evita passo inicial muito rápido
                end if;

                -- execução enquanto ainda houver passos
                if steps_left > 0 then
                    -- aceleração suave
                    if div_limit < target_div then
                        div_limit <= div_limit + 1;
                    elsif div_limit > target_div then
                        div_limit <= div_limit - 1;
                    end if;

                    -- contador de tempo para gerar passo
                    if cnt = div_limit then
                        cnt <= (others => '0');

                        -- avança ou retrocede step_idx
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

                        -- decrementa passos restantes
                        steps_left <= steps_left - 1;

                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Tabela de fases
    --------------------------------------------------------------------
    process(step_idx, en, steps_left)
    begin
        if en = '0' or steps_left = 0 then
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
    -- Saídas
    --------------------------------------------------------------------
    phase <= phase_reg;
    busy  <= '1' when (steps_left > 0 and en = '1') else '0';

end architecture;
