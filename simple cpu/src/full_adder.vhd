library IEEE;
  use IEEE.std_logic_1164.all;

entity full_adder is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    cin  : in  std_logic;
    s    : out std_logic;
    cout : out std_logic
  );
end entity;

architecture beh of full_adder is
begin

  s <= a xor b xor cin;
  
  PROC: process (a, b, cin)
  begin
    cout <= '0';

    if (a and b) = '1' then
      cout <= '1';
    end if;


    if (a = '1') and (cin = '1') then
      cout <= '1';
    end if;


    if (b and cin) = '1' then
      cout <= '1';
    end if;
  end process;

end architecture;
