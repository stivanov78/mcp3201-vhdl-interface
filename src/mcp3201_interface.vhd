library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcp3201_interface is
    Port ( 
        clk      : in  STD_LOGIC;                     -- System clock
        rst      : in  STD_LOGIC;                     -- Reset
        start    : in  STD_LOGIC;                     -- Start conversion
        sclk     : out STD_LOGIC;                     -- Serial clock to ADC
        cs_n     : out STD_LOGIC;                     -- Chip select (active low)
        miso     : in  STD_LOGIC;                     -- Serial data from ADC
        data_out : out STD_LOGIC_VECTOR(11 downto 0); -- 12-bit output data
        valid    : out STD_LOGIC                      -- Data valid signal
    );
end mcp3201_interface;

architecture Behavioral of mcp3201_interface is
    -- Constants
    constant SCLK_DIVIDER : integer := 2;  -- Divide system clock for SCLK
    
    -- State machine type
    type state_type is (IDLE, CONVERT, COMPLETE);
    signal state : state_type;
    
    -- Internal signals
    signal bit_counter : integer range 0 to 15;
    signal shift_reg   : STD_LOGIC_VECTOR(15 downto 0);
    signal sclk_cnt    : integer range 0 to SCLK_DIVIDER-1;
    signal sclk_int    : STD_LOGIC;
    
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            cs_n <= '1';
            sclk_int <= '0';
            valid <= '0';
            data_out <= (others => '0');
            bit_counter <= 0;
            shift_reg <= (others => '0');
            sclk_cnt <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    cs_n <= '1';
                    valid <= '0';
                    if start = '1' then
                        state <= CONVERT;
                        cs_n <= '0';
                        bit_counter <= 15;
                    end if;
                    
                when CONVERT =>
                    -- Generate SCLK
                    if sclk_cnt = SCLK_DIVIDER-1 then
                        sclk_cnt <= 0;
                        sclk_int <= not sclk_int;
                        
                        -- Sample data on falling edge of SCLK
                        if sclk_int = '1' then
                            shift_reg <= shift_reg(14 downto 0) & miso;
                            if bit_counter = 0 then
                                state <= COMPLETE;
                            else
                                bit_counter <= bit_counter - 1;
                            end if;
                        end if;
                    else
                        sclk_cnt <= sclk_cnt + 1;
                    end if;
                    
                when COMPLETE =>
                    cs_n <= '1';
                    -- MCP3201 outputs data MSB first, starting from bit 13
                    -- Bits 15 and 14 are leading zeros
                    data_out <= shift_reg(13 downto 2);
                    valid <= '1';
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
    
    -- Output SCLK
    sclk <= sclk_int when state = CONVERT else '0';
    
end Behavioral;
