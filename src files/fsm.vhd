library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith.ALL;

entity fsm is
    Generic
    (
        N : integer := 16
    );
    Port 
    (
        clk      : std_logic;                            -- clock
        rst      : std_logic;                            -- reset
        zero     : out std_logic;                        -- ZERO flag
        carry    : out std_logic;                        -- CARRY flag
        ROM_en   : out std_logic;                        -- enable ROM
        PC_clr   : out std_logic;                        -- reset PC
        PC_inc   : out std_logic;                        -- PC increment (+2)
        IR_load  : out std_logic;                        -- enable IR to load instruction from ROM
        IR_data  : in  std_logic_vector(N-1 downto 0);   -- instruction data received from ROM (16 bits)
        Immed    : out std_logic_vector(N-1 downto 0);   -- Immediate value
        RAM_sel  : out std_logic;                        -- RAM value selector (immediate or register)
        RAM_we   : out std_logic;                        -- enable RAM write
        stack_en : out std_logic;                        -- enable RAM Stack
        stack_op : out std_logic_vector(1 downto 0);     -- RAM Stack operator (01 - PUSH, 10 - POP)
        RF_sel   : out std_logic_vector(1 downto 0);     -- select Register File Rd input
        Rd_sel   : out std_logic_vector(2 downto 0);     -- Register file Rd selector
        Rd_wr    : out std_logic;                        -- Register file Rd enable
        Rm_sel   : out std_logic_vector(2 downto 0);     -- Register file Rm selector
        Rn_sel   : out std_logic_vector(2 downto 0);     -- Register file Rn selector
        ula_op   : out std_logic_vector(3 downto 0);     -- ULA operation
        state    : out std_logic_vector(3 downto 0);     -- state debug port
        jump_en  : out std_logic;                        -- JUMP enable
        jump_op  : out std_logic_vector(1 downto 0)      -- JUMP Operator (00 - JMP; 01 - JEQ; 10 - JLT; 11 - JGT)
    );
end fsm;

architecture Behavioral of fsm is
    type states is (init, fetch, decode, exec_nop, exec_halt,
                    exec_mov, exec_load, exec_store, exec_ula,
                    exec_stack, exec_jump);
    signal PS, NS : states;

    signal instruction : std_logic_vector(N-1 downto 0);
begin
    --------------------------------------------------------------------
    -- Instruction register view
    --------------------------------------------------------------------
    instruction <= IR_data;

    --------------------------------------------------------------------
    -- State register
    --------------------------------------------------------------------
    seq_proc : process(clk, rst)
    begin
        if rst = '1' then
            PS <= init;
        elsif rising_edge(clk) then
            PS <= NS;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Combinational next-state and output logic
    --------------------------------------------------------------------
    comb_proc : process(PS, instruction)
    begin
        ----------------------------------------------------------------
        -- Default values for ALL outputs (avoid latches, sane behaviour)
        ----------------------------------------------------------------
        ROM_en   <= '0';
        PC_clr   <= '0';
        PC_inc   <= '0';
        IR_load  <= '0';
        Immed    <= (others => '0');
        RAM_sel  <= '0';
        RAM_we   <= '0';
        stack_en <= '0';
        stack_op <= "00";
        RF_sel   <= "00";
        Rd_sel   <= "000";
        Rd_wr    <= '0';
        Rm_sel   <= "000";
        Rn_sel   <= "000";
        ula_op   <= "0000";
        jump_en  <= '0';
        jump_op  <= "00";
        state    <= "0000";
        zero     <= '0';    -- not used yet
        carry    <= '0';    -- not used yet

        NS <= PS;           -- stay in same state by default

        ----------------------------------------------------------------
        -- State machine
        ----------------------------------------------------------------
        case PS is
            ----------------------------------------------------------------
            when init =>
                PC_clr <= '1';
                NS     <= fetch;
                state  <= "0001";

            ----------------------------------------------------------------
            when fetch =>
                PC_clr  <= '0';
                PC_inc  <= '1';    -- advance PC
                ROM_en  <= '1';    -- read ROM
                IR_load <= '1';    -- load IR
                NS      <= decode;
                state   <= "0010";

            ----------------------------------------------------------------
            when decode =>
                state <= "0011";   -- decode state id

                -- Decide which exec state to go to
                if instruction = x"0000" then
                    NS    <= exec_nop;
                    state <= "0011";
                elsif instruction = x"FFFF" then
                    NS    <= exec_halt;
                    state <= "0100";
                elsif instruction(15 downto 12) = "0001" then  -- MOV
                    NS    <= exec_mov;
                    state <= "0101";
                elsif instruction(15 downto 12) = "0010" then  -- STORE
                    NS    <= exec_store;
                    state <= "0111";
                elsif instruction(15 downto 12) = "0011" then  -- LOAD
                    NS    <= exec_load;
                    state <= "1000";
                elsif (instruction(15 downto 11) = "00000" and instruction(1 downto 0) = "01") or
                      (instruction(15 downto 11) = "00000" and instruction(1 downto 0) = "10") then
                    NS <= exec_stack;
                elsif instruction(15 downto 11) = "00001" then  -- JUMP
                    NS <= exec_jump;
                elsif (instruction(15 downto 12) = "0000" and instruction(1 downto 0) = "11") or -- CMP
                       instruction(15 downto 12) = "0100" or     -- ADD
                       instruction(15 downto 12) = "0101" or     -- SUB
                       instruction(15 downto 12) = "0110" or     -- MUL
                       instruction(15 downto 12) = "0111" or     -- AND
                       instruction(15 downto 12) = "1000" or     -- ORR
                       instruction(15 downto 12) = "1001" or     -- NOT
                       instruction(15 downto 12) = "1010" or     -- XOR
                       instruction(15 downto 12) = "1011" or     -- SHR
                       instruction(15 downto 12) = "1100" or     -- SHL
                       instruction(15 downto 12) = "1101" or     -- ROR
                       instruction(15 downto 12) = "1110" then   -- ROL
                    NS    <= exec_ula;
                    state <= "1001";
                else
                    NS    <= exec_nop;
                    state <= "1010";
                end if;

            ----------------------------------------------------------------
            when exec_nop =>
                -- Just go back to fetch next instruction
                NS    <= fetch;
                state <= "0010";

            ----------------------------------------------------------------
            when exec_halt =>
                -- Stay here forever
                NS    <= exec_halt;
                state <= "1011";

            ----------------------------------------------------------------
            when exec_mov =>
                if instruction(11) = '0' then
                    -- MOV Rd, Rm
                    Rd_sel <= instruction(10 downto 8);
                    Rm_sel <= instruction(7 downto 5);
                    RF_sel <= "00";
                else
                    -- MOV Rd, #Im
                    Rd_sel <= instruction(10 downto 8);
                    Immed  <= x"00" & instruction(7 downto 0);
                    RF_sel <= "10";
                end if;
                Rd_wr <= '1';
                NS    <= fetch;
                state <= "1100";

            ----------------------------------------------------------------
            when exec_store =>
                if instruction(11) = '0' then
                    -- STR [Rm], Rn
                    Rm_sel <= instruction(7 downto 5);
                    Rn_sel <= instruction(4 downto 2);
                else
                    -- STR [Rm], #Im
                    Rm_sel <= instruction(7 downto 5);
                    Immed  <= x"00" & instruction(10 downto 8) & instruction(4 downto 0);
                end if;
                RAM_we  <= '1';
                RAM_sel <= instruction(11);
                NS      <= fetch;
                state   <= "1101";

            ----------------------------------------------------------------
            when exec_load =>
                Rd_sel <= instruction(10 downto 8);
                Rm_sel <= instruction(7 downto 5);
                RF_sel <= "01";
                Rd_wr  <= '1';
                NS     <= fetch;
                state  <= "1111";

            ----------------------------------------------------------------
            when exec_ula =>
                Rd_sel <= instruction(10 downto 8);
                Rm_sel <= instruction(7 downto 5);
                Rn_sel <= instruction(4 downto 2);
                RF_sel <= "11";
                Rd_wr  <= '1';
                ula_op <= instruction(15 downto 12);
                state  <= "1001";
                NS     <= fetch;

                if (instruction(15 downto 12) = "1011" or
                    instruction(15 downto 12) = "1100") then
                    Immed <= x"00" & "000" & instruction(4 downto 0);
                end if;

            ----------------------------------------------------------------
            when exec_stack =>
                Rn_sel   <= instruction(4 downto 2);
                Rd_sel   <= instruction(10 downto 8);
                RAM_sel  <= '0';
                RAM_we   <= '1';
                stack_en <= '1';
                stack_op <= instruction(1 downto 0);
                RF_sel   <= "01";
                NS       <= fetch;

            ----------------------------------------------------------------
            when exec_jump =>
                jump_en <= '1';
                jump_op <= instruction(1 downto 0);
                Immed   <= x"00" & instruction(9 downto 2);
                NS      <= fetch;

            ----------------------------------------------------------------
            when others =>
                NS    <= fetch;
                state <= "0010";
        end case;
    end process;
end Behavioral;












