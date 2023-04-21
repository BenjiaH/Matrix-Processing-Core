----------------------------------------------------------------------------------
-- Company: UoN
-- Engineer: Yaowen Hu
-- 
-- Create Date: 2023/04/01 17:00:32
-- Design Name: IntMatProCore_32x32_16bits
-- Module Name: IntMatProCore - IntMatProCore_arch
-- Project Name: MatrixProcessingCore_32x32_16bits
-- Target Devices: xc7a15tcsg324-1
-- Tool Versions: 
-- Description: Matrix Processing Core Design
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IntMatProCore is
    Port ( Reset, Clock, WriteEnable :  in STD_LOGIC;
           BufferSel :                  in STD_LOGIC_VECTOR (1 downto 0);
           WriteAddress :               in STD_LOGIC_VECTOR (9 downto 0);
           WriteData :                  in STD_LOGIC_VECTOR (15 downto 0);
           ReadAddress :                in STD_LOGIC_VECTOR (9 downto 0);
           ReadEnable :                 in STD_LOGIC;
           ReadData :                   out STD_LOGIC_VECTOR (63 downto 0);
           DataReady :                  out STD_LOGIC);
end IntMatProCore;

architecture IntMatProCore_arch of IntMatProCore is

-- RAM IP Core
COMPONENT dpram_1024x16
    PORT (
        clka    : IN STD_LOGIC;
        wea     : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra   : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb    : IN STD_LOGIC;
        enb     : IN STD_LOGIC;
        addrb   : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END COMPONENT;

COMPONENT dpram_1024x64
    PORT (
        clka    : IN STD_LOGIC;
        wea     : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra   : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina    : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        clkb    : IN STD_LOGIC;
        enb     : IN STD_LOGIC;
        addrb   : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        doutb   : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
END COMPONENT;

-- State definitions
type StateType is ( stIdle,               -- Idle state
                    stWriteBufferA,       -- Write buffer A state : Write matrix A to RAM A
                    stWriteBufferB,       -- Write buffer B state : Write matrix B to RAM B
                    stWriteBufferC,       -- Write buffer C state : Write matrix C to RAM C
                    stReadBufferAB,       -- Read buffer A and B state : Read RAM A and B ,then do the MAC
                    stWaitReadBufferC,    -- Wait read buffer C state
                    stReadBufferC,        -- Read buffer C state : Read RAM C ,then do the MAD
                    stWaitWriteBufferD,   -- Wait write buffer D state
                    stWriteBufferD,       -- Write buffer D state : Write matrix D to RAM D
                    stComplete            -- Complete state
                  );
signal presState: stateType;
signal nextState: stateType;
signal iStateCounter: unsigned(0 downto 0);
signal iStateCounterEnable, iStateCounterReset: std_logic;

-- Internal signals definitions
-- Read/write control signals
signal  iReadEnableAB, iReadEnableC : std_logic;
signal iReadAddressA, iReadAddressB, iReadAddressC, iWriteAddressD, iWriteAddressD1: std_logic_vector(9 downto 0);
signal  iWriteEnableA, iWriteEnableB, iWriteEnableC, iWriteEnableD: std_logic_vector(0 downto 0);

-- Read/write data signals
signal iReadDataA, iReadDataA1, iReadDataB, iReadDataB1, iReadDataC: std_logic_vector (15 downto 0);

-- Matrix address signal
signal  iCountReset, iRowCountAReset, iColCountAReset, iRowCountBReset, iColCountBReset: std_logic;
signal  iCountEnable, iRowCountAEnable, iColCountAEnable, iRowCountBEnable, iColCountBEnable: std_logic;
signal  iColCountA: unsigned(4 downto 0);
signal  iRowCountA, iColCountB: unsigned(5 downto 0); 
signal  iCount: unsigned(9 downto 0); 

-- Multiply-Accumulate (MAC)
signal  iMacReset, iMacEnable, iMacEnable1: std_logic;
signal  iMacResult: std_logic_vector (63 downto 0);

-- Matrix addition (MAD)
signal  iMadReset, iMadEnable: std_logic;
signal  iMadResult: std_logic_vector (63 downto 0);

begin
    iWriteEnableA(0) <= '1' when (WriteEnable = '1' and BufferSel = "00") else
                        '0' ;
    iWriteEnableB(0) <= '1' when (WriteEnable = '1' and BufferSel = "01") else
                        '0' ;
    iWriteEnableC(0) <= '1' when (WriteEnable = '1' and BufferSel = "10") else
                        '0' ;

    -- Instantiate RAM IP Core A, B, C and D
    InputBufferA : dpram_1024x16
    PORT MAP (
        clka    => Clock,
        wea     => iWriteEnableA,
        addra   => WriteAddress,
        dina    => WriteData,
        clkb    => Clock,
        enb     => iReadEnableAB,
        addrb   => iReadAddressA,
        doutb   => iReadDataA
    );

    InputBufferB : dpram_1024x16
    PORT MAP (
        clka    => Clock,
        wea     => iWriteEnableB,
        addra   => WriteAddress,
        dina    => WriteData,
        clkb    => Clock,
        enb     => iReadEnableAB,
        addrb   => iReadAddressB,
        doutb   => iReadDataB
    );

    InputBufferC : dpram_1024x16
    PORT MAP (
        clka    => Clock,
        wea     => iWriteEnableC,
        addra   => WriteAddress,
        dina    => WriteData,
        clkb    => Clock,
        enb     => iReadEnableC,
        addrb   => iReadAddressC,
        doutb   => iReadDataC
    );

    OutputBufferD : dpram_1024x64
    PORT MAP (
        clka    => Clock,
        wea     => iWriteEnableD,
        addra   => iWriteAddressD,
        dina    => iMadResult,
        clkb    => Clock,
        enb     => ReadEnable,
        addrb   => ReadAddress,
        doutb   => ReadData
    );

    -- Map the matrix address to the RAM address
    iReadAddressA <= std_logic_vector(iRowCountA(4 downto 0) & iColCountA);
    iReadAddressB <= std_logic_vector(iColCountA & iColCountB(4 downto 0));
    iReadAddressC <= std_logic_vector(iRowCountA(4 downto 0) & iColCountB(4 downto 0));

    -- Multiply-Accumulate Unit Process
    process (Clock, Reset)
    begin
        if Reset = '1' then
            iMacResult <= (others=>'0');
        elsif rising_edge(Clock) then
            if iMacReset = '1' then
                iMacResult <= (others=>'0');
            elsif iMacEnable = '1' then
                iMacResult <= std_logic_vector(signed(iReadDataA1) * signed(iReadDataB1) + signed(iMacResult));
            end if;
        end if;
    end process;

    -- Matrix Addition Unit Process
    process (Clock, Reset)
    begin
        if Reset = '1' then
            iMadResult <= (others=>'0');
        elsif rising_edge(Clock) then
            if iMadReset = '1' then
                iMadResult <= (others=>'0');
            elsif iMadEnable = '1' then
                iMadResult <= std_logic_vector(signed(iMacResult) + signed(iReadDataC));
            end if;
        end if;
    end process;
    
    -- Configure the enable signals for MAC and MAD
    process (Clock)
    begin
        if rising_edge(Clock) then
            -- NOTE: A delay of one cycle will be introduced here which is used to offset the delay in reading ram data
            iMacEnable1 <= iReadEnableAB;
            iMadEnable <= iReadEnableC;
            iWriteAddressD1 <= std_logic_vector(iRowCountA(4 downto 0) & iColCountB(4 downto 0));
            -- Tap for a cycle delay
            iMacEnable       <= iMacEnable1;
            iWriteAddressD  <= iWriteAddressD1;
        end if;
    end process;

    -- Configure the state machine and the counters 
    process (Clock, Reset)
    begin
        if rising_edge (Clock) then
            if Reset = '1' then
                presState <= stIdle;
            else
                presState <= nextState;
            end if;
            
            if iCountReset = '1' then
                iCount <= (others=>'0');
            elsif iCountEnable = '1' then
                iCount <= iCount + 1;
            end if;

            if iRowCountAReset = '1' then
                iRowCountA <= (others=>'0');
            elsif iRowCountAEnable = '1' then
                iRowCountA <= iRowCountA + 1;
            end if;

            if iColCountAReset = '1' then
                iColCountA <= (others=>'0');
            elsif iColCountAEnable = '1' then
                iColCountA <= iColCountA + 1;
            end if;        

            if iColCountBReset = '1' then
                iColCountB <= (others=>'0');
            elsif iColCountBEnable = '1' then
                iColCountB <= iColCountB + 1;
            end if;
            
            if iStateCounterReset = '1' then
                iStateCounter <= (others=>'0');
            elsif iStateCounterEnable = '1' then
                iStateCounter <= iStateCounter + 1;
            end if;
        end if;
    end process;

    -- State machine
    process (presState, WriteEnable, BufferSel, iCount, iRowCountA, iColCountA, iColCountB, iStateCounter)
    begin
        -- signal defaults
        iCountReset <= '0';
        iCountEnable <= '1'; 

        iRowCountAReset <= '0';
        iRowCountAEnable <= '0';

        iColCountAReset <= '0';
        iColCountAEnable <= '0';

        iColCountBReset <= '0';
        iColCountBEnable <= '0';

        iReadEnableAB <= '0';
        iReadEnableC <= '0';

        iWriteEnableD(0) <= '0';
        iMacReset <= '0';
        iMadReset <= '0';

        DataReady <= '0';

        iStateCounterReset <= '0';
        iStateCounterEnable <= '0';

        case presState is

            -- In the idle state, capture BufferSel signals and go to the stWriteBufferA.
            when stIdle =>
                if (WriteEnable = '1' and BufferSel = "00") then
                    nextState <= stWriteBufferA;
                else
                    iCountReset <= '1';
                    nextState <= stIdle;
                end if;
            
            -- Write RAM A form matrix A until iCount = 1024 (i.e., 32x32=1024 elements)
            when stWriteBufferA =>
                if iCount = x"3FF" then
                    iCountReset <= '1';
                    nextState <= stWriteBufferB;
                 else
                    nextState <= stWriteBufferA;
                end if;
            
            -- Write RAM B form matrix B until iCount = 1024 (i.e., 32x32=1024 elements)
            when stWriteBufferB =>
                if iCount = x"3FF" then
                    iCountReset <= '1';
                    nextState <= stWriteBufferC;
                 else
                    nextState <= stWriteBufferB;
                end if;
            
            -- Write RAM C form matrix C until iCount = 1024 (i.e., 32x32=1024 elements)
            when stWriteBufferC =>
                if iCount = x"3FF" then
                    iCountReset <= '1';
                    iRowCountAReset <= '1';
                    iColCountAReset <= '1';
                    iColCountBReset <= '1';
                    iMacReset <= '1';
                    nextState <= stReadBufferAB;
                 else
                    nextState <= stWriteBufferC;
                end if;
            
            -- When finished writing all the RAMs, read RAM A and RAM B, then do the MAC.
            when stReadBufferAB =>
                if iRowCountA = "100000" then
                    iRowCountAReset <= '1';
                    iColCountBReset <= '1';
                    iColCountAReset <= '1';
                    nextState <= stComplete;
                elsif iColCountB = "100000" then
                    iRowCountAEnable <= '1';
                    iColCountBReset <= '1';
                    iColCountAReset <= '1';
                    nextState <= stReadBufferAB;
                elsif iColCountA = "11111" then
                    iReadEnableAB <= '1';
                    iColCountAReset <= '1';
                    iStateCounterReset <= '1';
                    nextState <= stWaitReadBufferC;
                else
                    iReadEnableAB <= '1';
                    iReadEnableC <= '0';
                    iColCountAEnable <= '1';
                    nextState <= stReadBufferAB;
                end if;
            
            -- As the MAC input signal is manually tapped for one cycle, 
            -- a delay of one cycle is required here to wait for the MAC result.
            when stWaitReadBufferC =>
                if iStateCounter = "1" then
                    iStateCounterReset <= '1';
                    nextState <= stReadBufferC;
                else
                    iStateCounterEnable <= '1';
                    nextState <= stWaitReadBufferC;
                end if;
            
            -- When finished doing MAC each time, read matrix C.
            when stReadBufferC =>
                iReadEnableC <= '1';
                nextState <= stWaitWriteBufferD;
            
            -- The MAD will be done in this state. After that reset iMadReset
            -- Change the address of the currently calculated element for the next calculation
            when stWaitWriteBufferD =>
                iMacReset <= '1';
                iColCountBEnable <= '1';
                nextState <= stWriteBufferD;
            -- Write the result to RAM D

            when stWriteBufferD =>
                iMadReset <= '1';
                iWriteEnableD(0) <= '1';
                nextState <= stReadBufferAB;
            
            -- When finished calculating all the elements, go to the idle state
            -- and set the DataReady signal to '1'
            when stComplete =>
                DataReady <= '1';
                nextState <= stIdle;
        end case;
    end process;

    -- Timing closure optimization
    process (Clock, Reset)
    begin
        if rising_edge(Clock) then
            -- Tap for a cycle delay
            iReadDataA1 <= iReadDataA;
            iReadDataB1 <= iReadDataB;
        end if;
    end process;

end IntMatProCore_arch;
