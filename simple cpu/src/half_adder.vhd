library IEEE;
  use IEEE.std_logic_1164.all;

entity half_adder is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    s    : out std_logic;
    cout : out std_logic
  );
end entity;

architecture ha of half_adder is
begin

  s <= a xor b;
  
  PROC: process (a, b)
  begin
    cout <= '0';

    if (a and b) = '1' then
      cout <= '1';
    end if;

  end process;

end architecture;
