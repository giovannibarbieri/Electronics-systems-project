library ieee;
    use ieee.std_logic_1164.all;

entity multiplier is
    generic(
        Nbit : positive := 8
    );
    port (
        x : in std_logic_vector(Nbit - 1 downto 0);
        y : in std_logic_vector(Nbit - 1 downto 0);
        bout : out std_logic_vector(Nbit - 1 downto 0);
        overflow: out std_logic
    );
end entity;

architecture struct of multiplier is
    component half_adder is
        port (
          a    : in  std_logic;
          b    : in  std_logic;
          s    : out std_logic;
          cout : out std_logic
        );
    end component;

    component full_adder is
        port (
          a    : in  std_logic;
          b    : in  std_logic;
          cin  : in  std_logic;
          s    : out std_logic;
          cout : out std_logic
        );
      end component;
    
    -- half adder signal
    signal a_half_adder : std_logic_vector(Nbit - 2 downto 0);
    signal b_half_adder : std_logic_vector(Nbit - 2 downto 0);
    signal ha_result: std_logic_vector(Nbit - 2 downto 0);
    signal ha_cout: std_logic_vector(Nbit - 2 downto 0);

    -- first full adder row signal
    signal fa0_result: std_logic_vector(Nbit - 2 downto 0);
    signal fa0_cout: std_logic_vector(Nbit - 2 downto 0);

    -- full adder signal
    type faMatrix is array(0 to Nbit - 4) of std_logic_vector(Nbit - 2 downto 0);
    signal fa_result: faMatrix;
    signal fa_cout: faMatrix;
    type abfaMatrix is array(0 to Nbit - 3) of std_logic_vector(Nbit - 2 downto 0);
    signal a_full_adder : abfaMatrix;
    signal b_full_adder : abfaMatrix;

    -- result signal
    signal result : std_logic_vector(Nbit - 1 downto 0);
    signal ow_r: std_logic := '0';
    signal ow_c: std_logic := '0';
begin
    -- first row, half adder
    generate1_label: for j in 0 to Nbit - 2 generate
        a_half_adder(j) <= (x(j+1) and y(0));
        b_half_adder(j) <= (x(j) and y(1));
        HA_j: half_adder 
        port map (
          a    =>   a_half_adder(j),
          b    =>   b_half_adder(j),
          s    =>   ha_result(j),
          cout =>   ha_cout(j)
        );
    end generate;

    -- second row, first full adder, last one has different A input value
    generate2_label: for j in 0 to Nbit - 2 generate
        if_label1: if j = Nbit - 2 generate
            a_full_adder(0)(j) <= (x(Nbit - 1) and y(1));
            b_full_adder(0)(j) <= (x(j) and y(2));
            FA_i0: full_adder 
                port map (
                a    =>   a_full_adder(0)(j),
                b    =>   b_full_adder(0)(j),
                cin  =>   ha_cout(j),
                s    =>   fa0_result(j),
                cout =>   fa0_cout(j)
            );
        end generate;
        if_label2: if j < Nbit - 2 generate
            a_full_adder(0)(j) <= ha_result(j+1);
            b_full_adder(0)(j) <= (x(j) and y(2));
            FA_i01: full_adder
            port map (
                a    =>   a_full_adder(0)(j),
                b    =>   b_full_adder(0)(j),
                cin  =>   ha_cout(j),
                s    =>   fa0_result(j),
                cout =>   fa0_cout(j)
            );
        end generate;
    end generate;

    -- 3 to N-1 row, full adder
    generate3_label: for i in 3 to Nbit - 1 generate
        generate4_label: for j in 0 to Nbit - 2 generate
            if_label3: if j = Nbit - 2 generate
                a_full_adder(i-2)(j) <= (x(Nbit - 1) and y(i-1));
                b_full_adder(i-2)(j) <= (x(j) and y(i));
                FA_i0: full_adder 
                    port map (
                    a    =>   a_full_adder(i-2)(j),
                    b    =>   b_full_adder(i-2)(j),
                    cin  =>   fa0_cout(j),
                    s    =>   fa_result(i-3)(j),
                    cout =>   fa_cout(i-3)(j)
                );
            end generate;
            
            if_label4: if j < Nbit - 2 and i = 3 generate
                a_full_adder(i-2)(j) <= fa0_result(j+1);
                b_full_adder(i-2)(j) <= (x(j) and y(i));
                FA_i1: full_adder 
                    port map (
                    a    =>   a_full_adder(i-2)(j),
                    b    =>   b_full_adder(i-2)(j),
                    cin  =>   fa0_cout(j),
                    s    =>   fa_result(i-3)(j),
                    cout =>   fa_cout(i-3)(j)
                );
            end generate;

            if_label5: if i > 3 and j < Nbit - 2 generate
                a_full_adder(i-2)(j) <= fa_result(i-1-3)(j+1);
                b_full_adder(i-2)(j) <= (x(j) and y(i));
                FA_i2: full_adder
                port map (
                    a    =>   a_full_adder(i-2)(j),
                    b    =>   b_full_adder(i-2)(j),
                    cin  =>   fa_cout(i-4)(j),
                    s    =>   fa_result(i-3)(j),
                    cout =>   fa_cout(i-3)(j)
                );
            end generate;
        end generate;
    end generate;
    
    -- last full adders are omitted because our output has Nbit dimension
    result(0) <= (x(0) and y(0));
    result(1) <= ha_result(0);
    result(2) <= fa0_result(0);

    generate5_label: for i in 3 to Nbit-1 generate
        result(i) <= fa_result(i-3)(0);
    end generate;

    bout <= result;

    ow_r <= fa_result(4)(1) or fa_result(4)(2) or fa_result(4)(3) or fa_result(4)(4) or fa_result(4)(5) or fa_result(4)(6);
    ow_c <= fa_cout(4)(0) or fa_cout(4)(1) or fa_cout(4)(2) or fa_cout(4)(3) or fa_cout(4)(4) or fa_cout(4)(5) or fa_cout(4)(6);
    
    overflow <= ow_r or ow_c or (x(Nbit - 1) and y(Nbit - 1));

end architecture;