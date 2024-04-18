library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity top_level is
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

architecture struct of top_level is
    
    component simple_cpu is
        generic(
            N : natural := 8; -- number of bits of the registers
            M : natural := 4 -- number of bits of the memory addresses
        );
        port(
            en : in std_logic;
            clk : in std_logic;
            rst : in std_logic;
            instr : in std_logic_vector(N-1 downto 0);
            pc : out std_logic_vector(M-1 downto 0);
            input : in std_logic_vector(N-1 downto 0);
            output : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component rom is
        generic(
            N : natural := 8;
            M : natural := 4
        );
        port(
            pc : in std_logic_vector(M-1 downto 0);
            instr_rom : out std_logic_vector(N-1 downto 0)
        );
    end component;

    signal ROM_INSTR : std_logic_vector(N-1 downto 0);
    signal PC_ROM : std_logic_vector(M-1 downto 0);

begin 

    CPU: simple_cpu
    generic map(
        N => N,
        M => M
    )
    port map(
        en => en,
        clk => clk,
        rst => rst,
        instr => ROM_INSTR,
        pc => PC_ROM, 
        input => input,
        output => output
    );

    R: ROM
    generic map(
        N => N,
        M => M
    )
    port map(
        pc => PC_ROM,
        instr_rom => ROM_INSTR
    );

end architecture;