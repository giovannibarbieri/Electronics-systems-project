library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity top_level_limit_cases_tb is
end top_level_limit_cases_tb;

architecture beh of top_level_limit_cases_tb is
    constant clk_period : time := 100 ns;
    constant T_RESET : time := 250 ns;
    constant N          : positive := 8;
    constant M          : positive := 4;

    component top_level is
        generic(
            N : natural := 8; -- number of bits of the registers
            M : natural := 4 -- number of bits of the memory addresses
        );
        port(
            en : in std_logic;
            clk : in std_logic;
            rst : in std_logic;
            input : in std_logic_vector(N-1 downto 0);
            output : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    signal en_ext : std_logic := '0';
    signal clk : std_logic := '0';
    signal rst_ext   : std_logic := '0';
    signal input_ext : std_logic_vector(N - 1 downto 0) := (others => '0');
    signal output_ext : std_logic_vector(N - 1 downto 0);
    signal testing : boolean := true;
begin

    clk <= not clk after clk_period/2 when testing else '0';
    rst_ext <= '1' after T_RESET;
    
    DUT: top_level
        generic map(
            N => N,
            M => M
        )
        port map (
            en => en_ext,
            clk => clk,
            rst => rst_ext,
            input => input_ext,
            output => output_ext 
        );

    STIMULI : process(clk, rst_ext)
        variable t : integer := 0;
    begin
        if rst_ext = '0' then
            input_ext <= (others => '0');
            en_ext <= '0';
            t := 0;
        elsif rising_edge(clk) then
            case t is
                when 0 => en_ext <= '1';
                when 1 => 
                when 2 => 
                when 9 => input_ext <= "01111111";
                when 12 => input_ext <= "00111111";
                when 5 =>
                when 6 =>
                when 21 => input_ext <= "11110111";
                when 24 => input_ext <= "11111101";
                when 38 => en_ext <= '0'; 
                when 50 => testing <= false;
                when others =>
            end case;
            t := t+1;
        end if;
    end process;

end architecture;