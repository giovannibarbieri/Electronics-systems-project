library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;

entity instr_rom is
    generic(
        N : natural := 8;
        M : natural := 4
    );
    port(
        pc : in std_logic_vector(M-1 downto 0);
        instr_rom : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture struct of rom is
    type rom_t is array (natural range 0 to 15) of std_logic_vector(N-1 downto 0);
    constant R : rom_t := (
        "10110100", -- ADD R3, R2
        "10110101", -- MUL R2, R3
        "10000010", -- OUT R2
        "01000001", -- IN R1
        "10000001", -- IN R2
        "01100101", -- MUL R2, R1
        "10000010", -- OUT R2
        "01000001", -- IN R1
        "10000001", -- IN R2
        "10010100", -- ADD R1, R2
        "01000010", -- OUT R1
        "10000111", -- LSR R2
        "10000010", -- OUT R2
        "10000110", -- LSL R2
        "10000010", -- OUT R2 
        "10000000" -- RCSR R2
    );
begin
    instr_rom <= R(conv_integer(unsigned(pc)));
end architecture;