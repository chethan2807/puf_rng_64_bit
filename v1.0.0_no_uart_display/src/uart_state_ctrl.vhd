library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity uart_state_ctrl is
    Port ( send_msg : in  STD_LOGIC;
           send_data : in  STD_LOGIC;
           uartRdy : in  STD_LOGIC;
		   clk 	: in  STD_LOGIC;
		   data 	: in  STD_LOGIC_VECTOR (10 downto 0);
           rom_rd : out  STD_LOGIC;
           uartSend : out  STD_LOGIC;
		   uartData : out  STD_LOGIC_VECTOR (7 downto 0)
		   );
end uart_state_ctrl;


architecture Behavioral of uart_state_ctrl is
--Signal declaration

--The CHAR_ARRAY type is a variable length array of 8 bit std_logic_vectors. 
--Each std_logic_vector contains an ASCII value and represents a character in
--a string. The character at index 0 is meant to represent the first
--character of the string, the character at index 1 is meant to represent the
--second character of the string, and so on.
type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);

constant MAX_STR_LEN : integer := 24;
constant BTN_STR_LEN : natural := 20;
constant DATA_STR_LEN : natural := 14; -- 11+ \t  \n + \r
--constant TOTAL_STR_LEN : natural := 203; --11(challenge) + 192 (3*64 rom content) 

--Button press string definition.
--constant BTN_STR : CHAR_ARRAY(0 to 23) :=     				(X"42",  --B
--															  X"75",  --u
--															  X"74",  --t
--															  X"74",  --t
--															  X"6F",  --o
--															  X"6E",  --n
--															  X"20",  -- 
--															  X"70",  --p
--															  X"72",  --r
--															  X"65",  --e
--															  X"73",  --s
--															  X"73",  --s
--															  X"20",  --
--															  X"64",  --d
--															  X"65",  --e
--															  X"74",  --t
--															  X"65",  --e
--															  X"63",  --c
--															  X"74",  --t
--															  X"65",  --e
--															  X"64",  --d
--															  X"21",  --!
--															  X"0A",  --\n
--															  X"0D"); --\r
--	20 len														  
constant BTN_STR : CHAR_ARRAY(0 to 19) :=     				( X"63",  --c
															  X"68",  --h
															  X"61",  --a
															  X"6C",  --l
															  X"6C",  --l
															  X"65",  --e
															  X"6E",  --n
															  X"67",  --g
															  X"65",  --e
															  X"09",  --\t
															  X"72",  --r
															  X"65",  --e
															  X"73",  --s
															  X"70",  --p
															  X"6F",  --o
															  X"6E",  --n
															  X"73",  --s
															  X"65",  --e
															  X"0A",  --\n
															  X"0D"); --\r															  
															  

--The type definition for the UART state machine type. Here is a description of what
--occurs during each state:
-- RST_REG     -- Do Nothing. This state is entered after configuration or a user reset.
--                The state is set to LD_INIT_STR.
-- LD_INIT_STR -- The Welcome String is loaded into the sendStr variable and the strIndex
--                variable is set to zero. The welcome string length is stored in the StrEnd
--                variable. The state is set to SEND_CHAR.
-- SEND_CHAR   -- uartSend is set high for a single clock cycle, signaling the character
--                data at sendStr(strIndex) to be registered by the UART_TX_CTRL at the next
--                cycle. Also, strIndex is incremented (behaves as if it were post 
--                incremented after reading the sendStr data). The state is set to RDY_LOW.
-- RDY_LOW     -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go low, 
--                indicating a send operation has begun. State is set to WAIT_RDY.
-- WAIT_RDY    -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go high, 
--                indicating a send operation has finished. If READY is high and strEnd = 
--                StrIndex then state is set to WAIT_BTN, else if READY is high and strEnd /=
--                StrIndex then state is set to SEND_CHAR.
-- WAIT_BTN    -- Do nothing. Wait for a button press on BTNU, BTNL, BTND, or BTNR. If a 
--                button press is detected, set the state to LD_BTN_STR.
-- LD_BTN_STR  -- The Button String is loaded into the sendStr variable and the strIndex
--                variable is set to zero. The button string length is stored in the StrEnd
--                variable. The state is set to SEND_CHAR.
type UART_STATE_TYPE is (WAIT_BTN, LD_BTN_STR, SEND_CHAR, RDY_LOW, WAIT_RDY,WAIT_DATA,LD_DATA);

--Contains the current string being sent over uart.
signal sendStr : CHAR_ARRAY(0 to (MAX_STR_LEN - 1));
signal resultStr : CHAR_ARRAY(0 to (DATA_STR_LEN - 1));

--Contains the length of the current string being sent over uart.
signal strEnd : natural;

--Contains the index of the next character to be sent over uart
--within the sendStr variable.
signal strIndex : natural;


--Current uart state signal
signal uartState : UART_STATE_TYPE := WAIT_BTN;

signal challenge_byte : std_logic_vector(2 downto 0) := (others => '0');
signal send_heading, send_result : std_logic := '0';
signal challenge_sent : std_logic := '0';

  -- function CONV (SLV8 :STD_LOGIC_VECTOR (7 downto 0)) return CHARACTER is
    -- constant XMAP :INTEGER :=0;
    -- variable TEMP :INTEGER :=0;
  -- begin
    -- for i in SLV8'range loop
      -- TEMP:=TEMP*2;
      -- case SLV8(i) is
        -- when '0' | 'L'  => null;
        -- when '1' | 'H'  => TEMP :=TEMP+1;
        -- when others     => TEMP :=TEMP+XMAP;
      -- end case;
    -- end loop;
    -- return CHARACTER'VAL(TEMP);
  -- end CONV;
 -- subtype byte is std_ulogic_vector(7 downto 0);
 
   -- function to_character(b: byte) return character is
  -- begin
    -- return character'val(to_integer(unsigned(b)));
  -- end function;
  
  -- function to_byte(c : character) return byte is
  -- begin
    -- return byte(to_unsigned(character'pos(c), 8));
  -- end function;

begin

----------------------------------------------------------
------              UART state machine                 -------
----------------------------------------------------------


--Next Uart state logic (states described above)
next_uartState_process : process (clk)
begin
	if (rising_edge(clk)) then
			
		case uartState is 
			when WAIT_BTN =>
				--send_heading <= '1';
				--send_result <= '0';
				if (send_msg = '1') then
					uartState <= LD_BTN_STR;
				end if;
			when LD_BTN_STR =>
				--send_heading <= '1';
				--send_result <= '0';
				uartState <= SEND_CHAR;
			when SEND_CHAR =>
				uartState <= RDY_LOW;
			when RDY_LOW =>
				uartState <= WAIT_RDY;
			when WAIT_RDY =>
				if (uartRdy = '1') then
					if (strEnd = strIndex) then
						uartState 		<= WAIT_DATA;
						--send_heading 	<= '0';
					else
						uartState <= SEND_CHAR;
					end if;
				end if;
			when WAIT_DATA =>
				if (send_data = '1') then
					uartState <= LD_DATA;
					--send_heading <= '0';
					send_result <= '1';
				end if;
			when LD_DATA =>
				--send_heading <= '0';
				--send_result <= '1';
				uartState <= SEND_CHAR;
			
			when others=> --should never be reached
				uartState <= WAIT_BTN;
			end case;
		
	end if;
end process;

--Loads the sendStr and strEnd signals when a LD state is
--is reached.
--string_load_process : process (clk)
--begin
--	if (rising_edge(clk)) then
--			sendStr(0 to 10) <= BTN_STR;
--			strEnd <= TOTAL_STR_LEN;
--	end if;
--end process;

string_load_process : process (clk)
begin
	if (rising_edge(clk)) then
		if (uartState = LD_BTN_STR) then
			sendStr(0 to 19) <= BTN_STR;
			strEnd <= BTN_STR_LEN;
		elsif (uartState = LD_DATA) then
			sendStr(0) <= data(0) + X"30"; --convert to ascii
			sendStr(1) <= data(1) + X"30";
			sendStr(2) <= data(2) + X"30";
			sendStr(3) <= data(3) + X"30";
			sendStr(4) <= data(4) + X"30";
			sendStr(5) <= data(5) + X"30";
			sendStr(6) <= data(6) + X"30";
			sendStr(7) <= data(7) + X"30";
			sendStr(8) <= data(8) + X"30";
			sendStr(9) <= data(9) + X"30";
			sendStr(10) <= X"09";
			sendStr(11) <= data(10) + X"30";
			sendStr(12) <= X"0A";
			sendStr(13) <= X"0D";
			strEnd <= DATA_STR_LEN;
		end if;
	end if;
end process;

--Conrols the strIndex signal so that it contains the index
--of the next character that needs to be sent over uart
char_count_process : process (clk)
begin
	if (rising_edge(clk)) then
		if (uartState = LD_BTN_STR or  uartState = LD_DATA) then
			strIndex <= 0;
		elsif (uartState = SEND_CHAR) then
			strIndex <= strIndex + 1;
		end if;
	end if;
end process;


--Controls the UART_TX_CTRL signals
char_load_process : process (CLK)
begin
	if (rising_edge(CLK)) then
		if (uartState = SEND_CHAR) then
			uartSend <= '1';
			uartData <= sendStr(strIndex);
		else
			uartSend <= '0';
		end if;
	end if;
end process;




--Controls the uart_state_ctrl signals
--char_load_process : process (clk)
--begin
--	if (rising_edge(clk)) then
--		rom_rd	<= '0';
--		if (uartState = SEND_CHAR) then
--			uartSend <= '1';
--			if (strIndex < 12) then
--				uartData <= sendStr(strIndex);
--			else
--				if (challenge_byte = "000") then
--					uartData <= challenge_data(15 downto 12) + X"30"; --0	48	digit 0
--					challenge_byte <= "001";
--				elsif (challenge_byte = "001") then 
--					uartData <= challenge_data(11 downto 8) + X"30";
--					challenge_byte <= "010";
--				elsif (challenge_byte = "010") then 
--					uartData <= challenge_data(7 downto 4) + X"30";
--					challenge_byte <= "011";
--				elsif (challenge_byte = "011") then 
--					uartData <= challenge_data(3 downto 0) + X"30";
--					challenge_byte <= "100";
--				elsif (challenge_byte = "100") then 
--					uartData <= X"0A"; -- /n
--					challenge_byte <= "101";
--				elsif (challenge_byte = "101") then 
--					uartData <= X"0D"; -- /r cursor should move to the left most
--					challenge_byte <= "000";
--					rom_rd	<= '1';
--				end if;
--			end if; 
--				
--		else
--			uartSend <= '0';
--		end if;
--	end if;
--end process;

end Behavioral;