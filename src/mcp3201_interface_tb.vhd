library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcp3201_interface_tb is
end mcp3201_interface_tb;

architecture Behavioral of mcp3201_interface_tb is
    -- Component Declaration
    component mcp3201_interface
        Port ( 
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            start    : in  STD_LOGIC;
            sclk     : out STD_LOGIC;
            cs_n     : out STD_LOGIC;
            miso     : in  STD_LOGIC;
            data_out : out STD_LOGIC_VECTOR(11 downto 0);
            valid    : out STD_LOGIC
        );
    end component;
    
    -- Test signals
    signal clk      : STD_LOGIC := '0';
    signal rst      : STD_LOGIC := '0';
    signal start    : STD_LOGIC := '0';
    signal sclk     : STD_LOGIC;
    signal cs_n     : STD_LOGIC;
    signal miso     : STD_LOGIC := '0';
    signal data_out : STD_LOGIC_VECTOR(11 downto 0);
    signal valid    : STD_LOGIC;
    
    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;
    
    -- Test data
    signal test_data : STD_LOGIC_VECTOR(11 downto 0) := X"A5C";
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: mcp3201_interface
    port map (
        clk      => clk,
        rst      => rst,
        start    => start,
        sclk     => sclk,
        cs_n     => cs_n,
        miso     => miso,
        data_out => data_out,
        valid    => valid
    );
    
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD*2;
        rst <= '0';
        wait for CLK_PERIOD*2;
        
        -- Start conversion
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        -- Simulate ADC output (MCP3201 sends MSB first)
        -- First two bits are leading zeros
        wait until cs_n = '0';
        
        -- Send test data
        for i in 13 downto 2 loop
            wait until falling_edge(sclk);
            miso <= test_data(i-2);
        end loop;
        
        -- Wait for completion
        wait until valid = '1';
        
        -- Verify output
        assert data_out = test_data
            report "Test failed: Expected " & to_hstring(test_data) & 
                   " but got " & to_hstring(data_out)
            severity ERROR;
            
        -- Wait some time before starting next conversion
        wait for CLK_PERIOD*10;
        
        -- Start another conversion
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        -- Simulate different test data
        test_data <= X"5A3";
        wait until cs_n = '0';
        
        for i in 13 downto 2 loop
            wait until falling_edge(sclk);
            miso <= test_data(i-2);
        end loop;
        
        -- Wait for completion
        wait until valid = '1';
        
        -- Verify output
        assert data_out = test_data
            report "Test failed: Expected " & to_hstring(test_data) & 
                   " but got " & to_hstring(data_out)
            severity ERROR;
            
        -- End simulation
        wait for CLK_PERIOD*10;
        report "Simulation completed successfully";
        wait;
    end process;
    
end Behavioral;
