library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity datapath is
    Generic
    (
        N : integer := 16
    );
    Port
    (
        clk      : in  std_logic;                       -- clock
        rst      : in  std_logic;                       -- reset
        zero     : out std_logic;                       -- ZERO? flag
        carry    : out std_logic;                       -- CARRY flag
        RF_sel   : in  std_logic_vector(1 downto 0);    -- Register file Rd in selector
        Rd_sel   : in  std_logic_vector(2 downto 0);    -- Register Rd selector
        Rd_wr    : in  std_logic := '0';                -- Rd write
        Rm_sel   : in  std_logic_vector(2 downto 0);    -- Rm register selector
        Rn_sel   : in  std_logic_vector(2 downto 0);    -- Rn register selector
        Immed    : in  std_logic_vector(N-1 downto 0);  -- Immediate value
        alu_op   : in  std_logic_vector(3 downto 0);    -- ula operation
        RAM_sel  : in  std_logic;                       -- RAM din selector 
        RAM_din  : in  std_logic_vector(N-1 downto 0);  -- RAM D input (from RAM module)
        RAM_dout : out std_logic_vector(N-1 downto 0);  -- RAM Q output (to RAM module)
        RAM_addr : out std_logic_vector(N-1 downto 0);  -- RAM address
        alu_result : out std_logic_vector(N-1 downto 0) -- NEW: ALU result for debug
    );
end datapath;

architecture Behavioral of datapath is
    -- signals to handle output and input volatile values
    signal Rd_signal        : std_logic_vector(N-1 downto 0);
    signal Rm_signal        : std_logic_vector(N-1 downto 0);
    signal Rn_signal        : std_logic_vector(N-1 downto 0);
    signal alu_out_signal   : std_logic_vector(N-1 downto 0);
begin
    -- MUX for RAM data input (what gets written to RAM)
    RAM_dout <= Rn_signal when RAM_sel = '0' else Immed;
    
    -- MUX for Register File input (what gets written to registers)
    -- RF_sel encoding:
    -- "00" = Rm (register-to-register move)
    -- "01" = RAM output (load from memory)
    -- "10" = Immediate value (MOV Rd, #imm)
    -- "11" = ALU output (arithmetic/logic operations)
    RF_MUX  : Rd_signal <= Rm_signal       when RF_sel = "00" else
                           RAM_din         when RF_sel = "01" else  -- FIXED: Use RAM_din input port
                           Immed           when RF_sel = "10" else
                           alu_out_signal;                          -- default: RF_sel = "11"
                           
    REGISTER_FILE : entity work.register_file
        Generic map
        (
            N => 16
        )
        Port map
        (
            clk     => clk,
            rst     => rst,
            Rd_sel  => Rd_sel,
            Rd_wr   => Rd_wr,
            Rm_sel  => Rm_sel,
            Rn_sel  => Rn_sel,
            Rd      => Rd_signal,
            Rm      => Rm_signal,
            Rn      => Rn_signal
        );
        
    ALU : entity work.alu
        Generic map
        (
            N => 16
        )
        Port map
        (
            A     => Rm_signal,
            B     => Rn_signal,
            zero  => zero,
            carry => carry,
            Immed => Immed,
            op    => alu_op,
            Q     => alu_out_signal
        );
    
    -- Output ALU result for debugging
    alu_result <= alu_out_signal;
    
    -- RAM address comes from Rm register
    RAM_addr <= Rm_signal;
    
end Behavioral;
