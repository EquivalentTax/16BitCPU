library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom is
    Generic
    (
        addr_width : integer := 16;
        data_width : integer := 16
    );
    Port 
    ( 
        clk     : in  std_logic;                                    -- clock
        en      : in  std_logic;                                    -- enable
        addr    : in  std_logic_vector(addr_width-1 downto 0);      -- address input (BYTE address)
        dout    : out std_logic_vector(data_width-1 downto 0)       -- instruction data output
    );
end rom;

architecture Behavioral of rom is
    type memory is array(0 to (2**addr_width)-1) of std_logic_vector(data_width-1 downto 0);
    signal rom_block : memory := (
        0 => x"1802",   -- MOV R0, #2
        1 => x"1903",   -- MOV R1, #3
        2 => x"4204",   -- ADD R2, R0, R1
        3 => x"FFFF",   -- HALT
        others => (others => '0')
    );
    
    -- Convert byte address to word address by dividing by 2 (right shift by 1)
    signal word_addr : std_logic_vector(addr_width-1 downto 0);
    
begin
    -- Divide byte address by 2 to get word address
    -- addr[15:1] gives us addr/2
    word_addr <= '0' & addr(addr_width-1 downto 1);
    
    -- Asynchronous (combinational) read
    dout <= rom_block(to_integer(unsigned(word_addr)));
    
end Behavioral;