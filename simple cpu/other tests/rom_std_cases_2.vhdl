library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;

entity rom is
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
        "01000001", -- IN R1
        "10000001", -- IN R2
        "10010100", -- ADD R1, R2
        "01000010", -- OUT R1
        "10000011", -- MOV R2, R0
        "00000010", -- OUT R0
        "00000001", -- IN R0
        "11000001", -- IN R3
        "11000101", -- MUL R0, R3
        "00000010", -- OUT R0
        "11000110", -- LSL R3
        "11000010", -- OUT R3 
        "00000111", -- LSR R0
        "00000010", -- OUT R0
        "10110011", -- MOV R2, R3
        "11000010" -- OUT R3
    );
begin
    instr_rom <= R(conv_integer(unsigned(pc)));
end architecture;