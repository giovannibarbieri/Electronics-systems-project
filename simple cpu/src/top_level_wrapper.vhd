library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity top_level_wrapper is
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
end entity;

architecture struct of top_level_wrapper is
    
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

begin

    TOP_LEVEL_WRAPPER: top_level
        generic map(
            N => 8,
            M => 4
        )
        port map(
            en => en,
            clk => clk,
            rst =>rst,
            input => input,
            output => output
        );



end architecture;