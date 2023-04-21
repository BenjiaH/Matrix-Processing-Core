----------------------------------------------------------------------------------
-- Company: UoN
-- Engineer: Yaowen Hu
-- 
-- Create Date: 2023/04/01 17:02:01
-- Design Name: tb_IntMatProCore_32x32_16bits
-- Module Name: tb_IntMatProCore - tb
-- Project Name: MatrixProcessingCore_32x32_16bits
-- Target Devices: xc7a15tcsg324-1
-- Tool Versions: 
-- Description: Testbench for Matrix Processing Core Design
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
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_IntMatProCore is
--  Port ( );
end tb_IntMatProCore;

architecture tb of tb_IntMatProCore is

component IntMatProCore
    Port(
        Reset, Clock, WriteEnable :  in STD_LOGIC;
        BufferSel :                  in STD_LOGIC_VECTOR (1 downto 0);
        WriteAddress :               in STD_LOGIC_VECTOR (9 downto 0);
        WriteData :                  in STD_LOGIC_VECTOR (15 downto 0);
        ReadAddress :                in STD_LOGIC_VECTOR (9 downto 0);
        ReadEnable :                 in STD_LOGIC;
        ReadData :                   out STD_LOGIC_VECTOR (63 downto 0);
        DataReady :                  out STD_LOGIC
        );
end component;

-- Signals of the testbench definitions
signal tb_Reset : STD_LOGIC := '0';
signal tb_Clock : STD_LOGIC := '0';
signal tb_WriteEnable : STD_LOGIC := '0';
signal tb_BufferSel : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
signal tb_WriteAddress : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
signal tb_WriteData : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
signal tb_ReadAddress : STD_LOGIC_VECTOR (9 downto 0) := (others => '0');
signal tb_ReadEnable : STD_LOGIC := '0';
signal tb_ReadData : STD_LOGIC_VECTOR (63 downto 0) := (others => '0');
signal tb_DataReady : STD_LOGIC := '0';

-- Clock definition
-- Clock frequency = 5 MHz
constant period : time := 200 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut_IntMatProCore : IntMatProCore
        Port Map(
            Reset           => tb_Reset,
            Clock           => tb_Clock,
            WriteEnable     => tb_WriteEnable,
            BufferSel       => tb_BufferSel,
            WriteAddress    => tb_WriteAddress,
            WriteData       => tb_WriteData,
            ReadAddress     => tb_ReadAddress,
            ReadEnable      => tb_ReadEnable,
            ReadData        => tb_ReadData,
            DataReady       => tb_DataReady
        );

    -- Clock generation process
    process is
    begin
        while now <= 42300 * period loop
            tb_Clock <= '0';
            wait for period / 2;
            tb_Clock <= '1';
            wait for period / 2;
        end loop;
        wait;
    end process;

    -- Reset generation process
    process is
    begin
        tb_Reset <= '1';
        wait for 50 * period;
        tb_Reset <= '0';
        wait;   
    end process;

    -- Write to RAM from txt file process
    writing: process is
        -- Define fileID and open the file in read mode
        file FIA: TEXT open READ_MODE is "InputA.txt";
        file FIB: TEXT open READ_MODE is "InputB.txt";
        file FIC: TEXT open READ_MODE is "InputC.txt";
        -- Define variables
        variable L: LINE;
        variable tb_PreCharacterSpace: string(5 downto 1);      -- Pre-character space: "    '"
        variable tb_MatrixData: std_logic_vector(15 downto 0);  -- Each row contains 16 bits data
    begin
        -- Init
        tb_WriteEnable <= '0';
        tb_WriteAddress <= "11"&x"FF";

        wait for 20 * period;

        -- Write "InputA.txt" to RAM A
        while not ENDFILE(FIA)  loop
            READLINE(FIA, L);
            READ(L, tb_PreCharacterSpace);
            HREAD(L, tb_MatrixData);
            wait until falling_edge(tb_Clock);
            -- Iterate through all addresses
            tb_WriteAddress <= std_logic_vector(unsigned(tb_WriteAddress) + 1);
            tb_BufferSel <= "00";
            tb_WriteEnable <= '1';
            tb_WriteData <=tb_MatrixData;
        end loop;

        -- Write "InputB.txt" to RAM B
        while not ENDFILE(FIB)  loop
            READLINE(FIB, L);
            READ(L, tb_PreCharacterSpace);
            HREAD(L, tb_MatrixData);
            wait until falling_edge(tb_Clock);
            -- Iterate through all addresses
            tb_WriteAddress <= std_logic_vector(unsigned(tb_WriteAddress) + 1);
            tb_BufferSel <= "01";
            tb_WriteEnable <= '1';
            tb_WriteData <=tb_MatrixData;
        end loop;

        -- Write "InputC.txt" to RAM C
        while not ENDFILE(FIC)  loop
            READLINE(FIC, L);
            READ(L, tb_PreCharacterSpace);
            HREAD(L, tb_MatrixData);
            wait until falling_edge(tb_Clock);
            -- Iterate through all addresses
            tb_WriteAddress <= std_logic_vector(unsigned(tb_WriteAddress) + 1);
            tb_BufferSel <= "10";
            tb_WriteEnable <= '1';
            tb_WriteData <=tb_MatrixData;
        end loop;

        wait for period;
        tb_WriteEnable <= '0';
        wait; 
    end process;

    -- Read from RAM C after matrix calculation process
    reading: process is
        -- Define fileID and open the file in write mode
        file FO: TEXT open WRITE_MODE is "OutputD.txt";
        file FI: TEXT open READ_MODE is "OutputD_matlab.txt";
        -- Define variables
        variable L, Lm: LINE;
        variable tb_PreCharacterSpace: string(5 downto 1);      -- Pre-character space: "    '"
        variable v_ReadDatam: std_logic_vector(63 downto 0);    -- Each row contains 64 bits data
        variable v_OK: boolean;                                 -- Check if the result is correct
    begin
        tb_ReadEnable <= '0';
        tb_ReadAddress <= (others =>'0');

        -- Wait for matrix calculation done
        wait until rising_edge(tb_DataReady);
        wait until falling_edge(tb_DataReady);

        -- Write "OutputD.txt" from RAM D
        Write(L, STRING'("Data from Matlab"), Left, 20);
        Write(L, STRING'("Data from Simulation"), Left, 24);
        Write(L, STRING'("Results"));
        WRITELINE(FO, L);
        tb_ReadEnable<= '1';
        while not ENDFILE(FI)  loop
            wait until rising_edge(tb_Clock);
            wait for 10 ns;

            READLINE(FI, Lm);
            READ(Lm, tb_PreCharacterSpace);
            HREAD(Lm, v_ReadDatam);
            if v_ReadDatam = tb_ReadData then
                v_OK := True;
            else
                v_OK := False;
            end if;
            HWRITE(L, v_ReadDatam, Left, 20);
            HWRITE(L, tb_ReadData, Left, 24);
            WRITE(L, v_OK, Left, 10);
            WRITELINE(FO, L);

            -- Iterate through all addresses
            tb_ReadAddress <= std_logic_vector(unsigned(tb_ReadAddress) + 1);
        end loop;
        Write(L, STRING'("---------------- EOF ----------------"));
        WRITELINE(FO, L);
        tb_ReadEnable <= '0';
        wait;
    end process;

end tb;
