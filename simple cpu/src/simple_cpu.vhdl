library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity simple_cpu is
    generic(
        N : natural := 8;   -- number of bits of the registers
        M : natural := 4    -- number of bits of the memory addresses
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
end entity;

architecture struct of simple_cpu is
    component DFF_N is
        generic (
            N : natural := 8
        );
        port (
            clk   : in std_logic;
            arstn : in std_logic;
            en    : in std_logic;
            d     : in std_logic_vector(N - 1 downto 0);
            q     : out std_logic_vector(N - 1 downto 0)
        );
      end component;

    component ripple_carry_adder is
        generic (
            Nbit : positive := 8
        );
        port (
            a    : in  std_logic_vector(Nbit - 1 downto 0);
            b    : in  std_logic_vector(Nbit - 1 downto 0);
            cin  : in  std_logic;
            s    : out std_logic_vector(Nbit - 1 downto 0);
            cout : out std_logic
        );
      end component;

    component multiplier is
        generic(
            Nbit : positive := 8
        );
        port (
            x : in std_logic_vector(Nbit - 1 downto 0);
            y : in std_logic_vector(Nbit - 1 downto 0);
            bout : out std_logic_vector(Nbit - 1 downto 0);
            overflow: out std_logic
        );
    end component;

    -- internal register signal
    signal R0 : std_logic_vector(N-1 downto 0);
    signal R1: std_logic_vector(N-1 downto 0);
    signal R2 : std_logic_vector(N-1 downto 0);
    signal R3 : std_logic_vector(N-1 downto 0);

    signal SR : std_logic_vector(N-1 downto 0);         -- status register
    signal IR : std_logic_vector(N-1 downto 0);         -- instruction register
    signal PC_reg : std_logic_vector(M-1 downto 0);     -- program counter 
    signal REG_IN : std_logic_vector(N-1 downto 0);     -- input
    signal REG_OUT : std_logic_vector(N-1 downto 0);    -- output
    
    --- ripple carry adder input/output signal
    signal Rca_a : std_logic_vector(N-1 downto 0);
    signal Rca_b : std_logic_vector(N-1 downto 0);
    signal Rca_s : std_logic_vector(N-1 downto 0);

    --- multiplier input/output signal
    signal PMultiplier_x : std_logic_vector(N-1 downto 0);
    signal PMultiplier_y : std_logic_vector(N-1 downto 0);
    signal PMultiplier_result : std_logic_vector(N-1 downto 0);
    signal PMultiplier_overflow : std_logic;

    -- temp signal used for counting the number of clock per instruction
    signal stato : std_logic_vector(2 downto 0);

begin

    Rca: ripple_carry_adder 
        generic map(
          Nbit => N
        )
        port map(
          a    => Rca_a,
          b    => Rca_b,
          cin  => '0',
          s    => Rca_s,
          cout => open
        );

    PMultiplier: multiplier 
        generic map(
          Nbit => N
        )
        port map(
          x    => PMultiplier_x,
          y    => PMultiplier_y,
          bout    => PMultiplier_result,
          overflow => PMultiplier_overflow
        );    

    simple_cpu_process: process(clk, rst, en)
        variable Nbit : natural := N;
    begin
        if rst = '0' then

            pc <= (others => '0');
            output <= (others => '0');
            R0 <= (others => '0');
            R1 <= (others => '0');
            R2 <= (others => '0');
            R3 <= (others => '0');
            IR <= (others => '0');
            PC_reg <= (others => '0');
            REG_IN <= (others => '0');
            REG_OUT <= (others => '0');
            SR <= "00000000";
            
            Rca_a <= (others => '0');
            Rca_b <= (others => '0');

            PMultiplier_x <= (others => '0');
            PMultiplier_y <= (others => '0');
            
            stato <= "001";
        elsif rising_edge(clk) and en = '1' then

            case(instr(2 downto 0)) is
                -- RCSR
                when "000" =>
                    -- write SR in Rx

                    if stato = "001" then
                        case(instr(7 downto 6)) is
                            -- Rx0
                            when "00" => R0 <= SR;
                            -- Rx1
                            when "01" => R1 <= SR;
                            -- Rx2
                            when "10" => R2 <= SR;
                            -- Rx3
                            when "11" => R3 <= SR;
                            when others => null;
                        end case;
                    end if;
                    
                    if stato = "001" then
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                        stato <= "000";  
                    else 
                        stato <= std_logic_vector(unsigned(stato) + 1);
                    end if;
                    
                -- IN
                when "001" =>   
                    -- send the input to the register REG_IN
                    if stato = "001" then
                        REG_IN <= input;
                    end if;

                    if stato = "010" then
                        case(instr(7 downto 6)) is
                            -- Rx0
                            when "00" =>
                                R0 <= REG_IN;
                            -- Rx1
                            when "01" =>
                                R1 <= REG_IN;
                            -- Rx2
                            when "10" =>
                                R2 <= REG_IN;
                            -- Rx3
                            when "11" =>
                                R3 <= REG_IN;
                            when others => null;
                        end case;
                    end if;

                    if stato = "010" then
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        stato <= "000";
                    else 
                        stato <= std_logic_vector(unsigned(stato) + 1);
                    end if;
                    
                -- OUT
                when "010" =>

                    if stato = "001" then
                        case(instr(7 downto 6)) is
                            -- Rx0
                            when "00" =>
                                REG_OUT <= R0;
                            -- Rx1
                            when "01" =>
                                REG_OUT <= R1;
                            -- Rx2
                            when "10" =>
                                REG_OUT <= R2;
                            -- Rx3
                            when "11" =>
                                REG_OUT <= R3;
                            when others => null;
                        end case;
                    end if;
    
                    if stato = "010" then
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                        stato <= "000";
                    else 
                        stato <= std_logic_vector(unsigned(stato) + 1);
                    end if;

                -- MOV
                when "011" =>
                    
                    if stato = "001" then
                       case(instr(7 downto 6)) is
                        -- Rx0
                        when "00" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" => R0 <= R0;
                                -- Ry1
                                when "01" => R1 <= R0;
                                -- Ry2
                                when "10" => R2 <= R0;
                                -- Ry3
                                when "11" => R3 <= R0;
                                when others => null;
                            end case;
                        -- Rx1
                        when "01" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" => R0 <= R1;
                                -- Ry1
                                when "01" => R1 <= R1;
                                -- Ry2
                                when "10" => R2 <= R1;
                                -- Ry3
                                when "11" => R3 <= R1;
                                when others => null;
                            end case;
                        -- Rx2
                        when "10" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" => R0 <= R2;
                                -- Ry1
                                when "01" => R1 <= R2;
                                -- Ry2
                                when "10" => R2 <= R2;
                                -- Ry3
                                when "11" => R3 <= R2;
                                when others => null;
                            end case;
                        -- Rx3
                        when "11" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" => R0 <= R3;
                                -- Ry1
                                when "01" => R1 <= R3;
                                -- Ry2
                                when "10" => R2 <= R3;
                                -- Ry3
                                when "11" => R3 <= R3;
                                when others => null;
                            end case;
                        when others => null;
                    end case;
                end if; 

                if stato = "001" then
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                    stato <= "000";  
                else 
                    stato <= std_logic_vector(unsigned(stato) + 1);
                end if;

                -- ADD
                when "100" =>
                    
                if stato /= "000" then
                    case(instr(7 downto 6)) is
                        -- Rx0
                        when "00" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    Rca_a <= R0;
                                    Rca_b <= R0;

                                    if stato = "010" then
                                        SR(2) <= R0(N-1) and R0(N-1);   -- set overflow bit
                                        R0 <= Rca_s;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    Rca_a <= R0;
                                    Rca_b <= R1;

                                    if stato = "010" then
                                        SR(2) <= R0(N-1) and R1(N-1);   -- set overflow bit
                                        R1 <= Rca_s;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    Rca_a <= R0;
                                    Rca_b <= R2;

                                    if stato = "010" then
                                        SR(2) <= R0(N-1) and R2(N-1);   -- set overflow bit
                                        R2 <= Rca_s;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    Rca_a <= R0;
                                    Rca_b <= R3;

                                    if stato = "010" then
                                        SR(2) <= R0(N-1) and R3(N-1);   -- set overflow bit
                                        R3 <= Rca_s;
                                    end if;
                                when others => null;
                            end case;
                        -- Rx1
                        when "01" =>
                            case(instr(5 downto 4)) is
                                when "00" =>
                                    -- Ry0
                                    Rca_a <= R1;
                                    Rca_b <= R0;

                                    if stato = "010" then
                                        SR(2) <= R1(N-1) and R0(N-1);   -- set overflow bit
                                        R0 <= Rca_s;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    Rca_a <= R1;
                                    Rca_b <= R1;

                                    if stato = "010" then
                                        SR(2) <= R1(N-1) and R1(N-1);   -- set overflow bit
                                        R1 <= Rca_s;
                                    end if;
                                    -- Ry2
                                when "10" =>
                                    Rca_a <= R1;
                                    Rca_b <= R2;

                                    if stato = "010" then
                                        SR(2) <= R1(N-1) and R2(N-1);   -- set overflow bit
                                        R2 <= Rca_s; 
                                    end if;
                                -- Ry3
                                when "11" =>
                                    Rca_a <= R1;
                                    Rca_b <= R3;

                                    if stato = "010" then
                                        SR(2) <= R1(N-1) and R3(N-1);   -- set overflow bit
                                        R3 <= Rca_s;
                                    end if;
                                when others => null;
                            end case;
                        -- Rx2
                        when "10" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    Rca_a <= R2;
                                    Rca_b <= R0;

                                    if stato = "010" then
                                        SR(2) <= R2(N-1) and R0(N-1);   -- set overflow bit
                                        R0 <= Rca_s;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    Rca_a <= R2;
                                    Rca_b <= R1;

                                    if stato = "010" then
                                        SR(2) <= R2(N-1) and R1(N-1);   -- set overflow bit
                                        R1 <= Rca_s; 
                                    end if;
                                -- Ry2
                                when "10" =>
                                    Rca_a <= R2;
                                    Rca_b <= R2;

                                    if stato = "010" then
                                        SR(2) <= R2(N-1) and R2(N-1);   -- set overflow bit 
                                        R2 <= Rca_s;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    Rca_a <= R2;
                                    Rca_b <= R3;

                                    if stato = "010" then
                                        SR(2) <= R2(N-1) and R3(N-1);   -- set overflow bit
                                        R3 <= Rca_s;
                                    end if;

                                when others => null;
                            end case;
                        -- Rx3
                        when "11" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    Rca_a <= R3;
                                    Rca_b <= R0;

                                    if stato = "010" then
                                        SR(2) <= R3(N-1) and R0(N-1);   -- set overflow bit
                                        R0 <= Rca_s;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    Rca_a <= R3;
                                    Rca_b <= R1;

                                    if stato = "010" then
                                        SR(2) <= R3(N-1) and R1(N-1);   -- set overflow bit
                                        R1 <= Rca_s;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    Rca_a <= R3;
                                    Rca_b <= R2;
                                    
                                    if stato = "010" then
                                        SR(2) <= R3(N-1) and R2(N-1);   -- set overflow bit
                                        R2 <= Rca_s;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    Rca_a <= R3;
                                    Rca_b <= R3;

                                    if stato = "010" then
                                        SR(2) <= R3(N-1) and R3(N-1);   -- set overflow bit
                                        R3 <= Rca_s;
                                    end if;
                                when others => null;
                            end case;
                        when others => null;
                    end case;
                    
                end if;

                if stato = "010" then
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                    stato <= "000";
                    if(Rca_s = "00000000") then
                        SR(3) <= '1';
                    else
                        SR(3) <= '0';
                    end if;  
                else 
                    stato <= std_logic_vector(unsigned(stato) + 1);
                end if;

                --MUL
                when "101" =>
                if stato /= "000" then
                    case(instr(7 downto 6)) is
                        -- Rx0
                        when "00" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    PMultiplier_x <= R0;
                                    PMultiplier_y <= R0;

                                    if stato = "010" then
                                        R0 <= PMultiplier_result;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    PMultiplier_x <= R0;
                                    PMultiplier_y <= R1;

                                    if stato = "010" then
                                        R1 <= PMultiplier_result;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    PMultiplier_x <= R0;
                                    PMultiplier_y <= R2;

                                    if stato = "010" then
                                        R2 <= PMultiplier_result;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    PMultiplier_x <= R0;
                                    PMultiplier_y <= R3;

                                    if stato = "010" then
                                        R3 <= PMultiplier_result;
                                    end if;
                                when others => null;
                            end case;
                        -- Rx1
                        when "01" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    PMultiplier_x <= R1;
                                    PMultiplier_y <= R0;

                                    if stato = "010" then
                                        R0 <= PMultiplier_result;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    PMultiplier_x <= R1;
                                    PMultiplier_y <= R1;

                                    if stato = "010" then
                                        R1 <= PMultiplier_result;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    PMultiplier_x <= R1;
                                    PMultiplier_y <= R2;

                                    if stato = "010" then
                                        R2 <= PMultiplier_result; 
                                    end if;
                                -- Ry3
                                when "11" =>
                                    PMultiplier_x <= R1;
                                    PMultiplier_y <= R3;

                                    if stato = "010" then
                                        R3 <= PMultiplier_result;
                                    end if;
                                when others => null;
                            end case;
                        -- Rx2
                        when "10" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    PMultiplier_x <= R2;
                                    PMultiplier_y <= R0;

                                    if stato = "010" then
                                        R0 <= PMultiplier_result;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    PMultiplier_x <= R2;
                                    PMultiplier_y <= R1;
                                    
                                    if stato = "010" then
                                        R1 <= PMultiplier_result;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    PMultiplier_x <= R2;
                                    PMultiplier_y <= R2;

                                    if stato = "010" then
                                        R2 <= PMultiplier_result;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    PMultiplier_x <= R2;
                                    PMultiplier_y <= R3;
                                    
                                    if stato = "010" then
                                        R3 <= PMultiplier_result;
                                    end if;
                                when others => null;
                            end case;
                        -- Rx3
                        when "11" =>
                            case(instr(5 downto 4)) is
                                -- Ry0
                                when "00" =>
                                    PMultiplier_x <= R3;
                                    PMultiplier_y <= R0;

                                    if stato = "010" then
                                        R0 <= PMultiplier_result;
                                    end if;
                                -- Ry1
                                when "01" =>
                                    PMultiplier_x <= R3;
                                    PMultiplier_y <= R1;

                                    if stato = "010" then
                                        R1 <= PMultiplier_result;
                                    end if;
                                -- Ry2
                                when "10" =>
                                    PMultiplier_x <= R3;
                                    PMultiplier_y <= R2;

                                    if stato = "010" then
                                        R2 <= PMultiplier_result;
                                    end if;
                                -- Ry3
                                when "11" =>
                                    PMultiplier_x <= R3;
                                    PMultiplier_y <= R3;

                                    if stato = "010" then
                                        R3 <= PMultiplier_result;
                                    end if;
                                when others => null;
                            end case;
                        when others => null;
                    end case;
                    
                end if;

                if stato = "010" then
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                    stato <= "000"; 
                    SR(2) <= PMultiplier_overflow;
                    if(PMultiplier_result = "00000000") then
                        SR(3) <= '1';
                    else
                        SR(3) <= '0';
                    end if; 
                else 
                    stato <= std_logic_vector(unsigned(stato) + 1);
                end if;
            
                -- LSL
                when "110" =>
                if stato = "001" then
                    case(instr(7 downto 6)) is
                        -- Rx0
                        when "00" =>
                            SR(1) <= R0(N-1);
                            R0 <= R0(N-2 downto 0) & '0';
                        -- Rx1
                        when "01" =>
                            SR(1) <= R1(N-1);
                            R1 <= R1(N-2 downto 0) & '0';
                        -- Rx2
                        when "10" =>
                            SR(1) <= R2(N-1);
                            R2 <= R2(N-2 downto 0) & '0';
                        -- Rx3
                        when "11" =>
                            SR(1) <= R3(N-1);
                            R3 <= R3(N-2 downto 0) & '0';
                        when others => null;
                    end case;
                end if;
                
                if stato = "001" then
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                    stato <= "000";  
                else 
                    stato <= std_logic_vector(unsigned(stato) + 1);
                end if;

                -- LSR
                when "111" =>
                    if stato = "001" then
                        case(instr(7 downto 6)) is
                            -- Rx0
                            when "00" =>
                                SR(1) <= R0(0);
                                R0 <= '0' & R0(N-1 downto 1);
                            -- Rx1
                            when "01" =>
                                SR(1) <= R1(0);
                                R1 <= '0' & R1(N-1 downto 1);
                            -- Rx2
                            when "10" =>
                                SR(1) <= R2(0);
                                R2 <= '0' & R2(N-1 downto 1);
                            -- Rx3
                            when "11" =>
                                SR(1) <= R3(0);
                                R3 <= '0' & R3(N-1 downto 1);
                            when others => null;
                        end case;
                    end if;

                    if stato = "001" then
                        PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);  
                        stato <= "000";  
                    else 
                        stato <= std_logic_vector(unsigned(stato) + 1);
                    end if;

                when others => null;
            end case;

            IR <= instr;
            pc <= PC_reg;
            output <= REG_OUT;
        end if;

        if rst = '1' and en = '0' then
            SR(0) <= '0';
        end if;

        if rst = '1' and en = '1' then
            SR(0) <= '1';
        end if;

    end process;
end architecture;