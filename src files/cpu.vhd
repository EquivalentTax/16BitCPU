library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu is
    Generic
    (
        N : integer := 16
    );
    Port
    (
        clk        : in  std_logic;                         -- clock
        rst        : in  std_logic;                         -- reset
        output_pc  : out std_logic_vector(15 downto 0);     -- debug: program counter
        output_alu : out std_logic_vector(15 downto 0)      -- debug: ALU result
    );
end cpu;

architecture Behavioral of cpu is
    -- Control signals
    signal ROM_addr   : std_logic_vector(N-1 downto 0);
    signal ROM_dout   : std_logic_vector(N-1 downto 0);
    signal ROM_en     : std_logic;
    signal RAM_sel    : std_logic;
    signal RAM_we     : std_logic;
    signal stack_en   : std_logic;
    signal stack_op   : std_logic_vector(1 downto 0);
    signal Immed      : std_logic_vector(N-1 downto 0);
    signal RF_sel     : std_logic_vector(1 downto 0);
    signal Rd_sel     : std_logic_vector(2 downto 0);
    signal Rm_sel     : std_logic_vector(2 downto 0);
    signal Rn_sel     : std_logic_vector(2 downto 0);
    signal Rd_wr      : std_logic; 
    signal alu_op     : std_logic_vector(3 downto 0);
    
    -- Data signals
    signal RAM_din    : std_logic_vector(N-1 downto 0);  -- Data read FROM RAM
    signal RAM_dout   : std_logic_vector(N-1 downto 0);  -- Data written TO RAM
    signal RAM_addr   : std_logic_vector(N-1 downto 0);  -- RAM address
    signal alu_result : std_logic_vector(N-1 downto 0);  -- ALU output
    
begin
    -- Datapath: Register file + ALU + data routing
    DATAPATH : entity work.datapath
        Generic map (N => 16)
        Port map
        (
            clk        => clk,
            rst        => rst,
            zero       => open,          
            carry      => open,
            RF_sel     => RF_sel,
            Rd_sel     => Rd_sel,
            Rd_wr      => Rd_wr,
            Rm_sel     => Rm_sel,
            Rn_sel     => Rn_sel,
            Immed      => Immed,
            alu_op     => alu_op,
            RAM_sel    => RAM_sel,
            RAM_din    => RAM_din,      -- Data FROM RAM to register file
            RAM_dout   => RAM_dout,     -- Data FROM register file TO RAM
            RAM_addr   => RAM_addr,     -- Address for RAM operations
            alu_result => alu_result 
        );
    
    -- Control Unit: FSM + PC + IR
    CONTROL_UNIT : entity work.control_unit
        Generic map (N => 16)
        Port map
        (
            clk      => clk,
            rst      => rst,
            Immed    => Immed,
            IR_data  => ROM_dout,    -- Instruction from ROM
            ROM_addr => ROM_addr,    -- Address to ROM (PC value)
            RAM_sel  => RAM_sel,
            RAM_we   => RAM_we,
            ROM_en   => ROM_en,
            RF_sel   => RF_sel,
            Rd_sel   => Rd_sel,
            Rd_wr    => Rd_wr,
            Rm_sel   => Rm_sel,
            Rn_sel   => Rn_sel,
            alu_op   => alu_op
        );
        
    -- ROM: Program memory
    ROM : entity work.rom
        Port map
        (
            clk  => clk,
            en   => ROM_en,
            addr => ROM_addr,
            dout => ROM_dout
        );
    
    -- RAM: Data memory
    RAM : entity work.ram
        Port map
        (
            clk      => clk,
            we       => RAM_we,
            stack_en => stack_en,
            stack_op => stack_op,
            din      => RAM_dout,    -- Data TO RAM (from datapath)
            addr     => RAM_addr,    -- Address from datapath
            dout     => RAM_din      -- Data FROM RAM (to datapath)
        );
   
    -- Debug outputs
    output_pc  <= ROM_addr;      -- Shows which instruction address is being fetched
    output_alu <= alu_result;    -- Shows ALU result
  
end Behavioral;
