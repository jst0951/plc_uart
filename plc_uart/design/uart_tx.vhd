library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  
entity uart_tx is
  port(
    nRst    : in std_logic;
    clk     : in std_logic;
    start_sig : in std_logic;
    data      : in std_logic_vector(7 downto 0);
    tx        : out std_logic;
    busy      : out std_logic
  );
end uart_tx;

architecture BEH of uart_tx is
  -- state machine
  type state_type is (IDLE, START, SEND, PARITY, STOP);
  signal state : state_type;
  -- pclk(115200bps, 8.68us) generation
  signal cnt  : std_logic_vector(8 downto 0);
  signal pclk : std_logic;
  -- start_sig rising edge detection
  signal start_d  : std_logic;
  signal flag : std_logic;
  -- temporarily hold data
  signal tempdata : std_logic_vector(7 downto 0);
  -- data send
  signal bit_cnt : std_logic_vector(2 downto 0);
  signal tx_data : std_logic_vector(7 downto 0);
  
begin
  -- pclk(115200bps, 8.68us) generation
  process(nRst,clk)
  begin
    if (nRst = '0') then
      cnt <= (others => '0');
      pclk <= '0';
    elsif rising_edge(clk) then
      if (cnt = 433) then
        cnt <= (others => '0');
        pclk <= not pclk;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  -- start_sig rising edge detection(+ move data to tempdata)
  process(nRst, clk)
  begin
    if (nRst = '0') then
      start_d <= '0';
      flag <= '0';
      tempdata <= (others => '0');
    elsif rising_edge(clk) then
      start_d <= start_sig;
      if (start_d = '0' and start_sig = '1') then
        flag <= '1';
        tempdata <= data;
      elsif (state = START) then
        flag <= '0';
      end if;
    end if;
  end process;  
  
  -- state machine
  process(nRst, pclk)
  begin
    if (nRSt = '0') then
      state <= IDLE;
      bit_cnt <= (others => '0');
      tx_data <= (others => '0');
    elsif rising_edge(pclk) then
      case state is
        
        when IDLE =>
          if (flag = '1') then
            state <= START;
          else
            state <= IDLE;
          end if;
          bit_cnt <= (others => '0');
          tx_data <= (others => '0');
          
        WHEN START =>
          state <= SEND;
          tx_data <= tempdata;
        
        WHEN SEND =>
          if (bit_cnt = 7) then
            state <= PARITY;
            bit_cnt <= (others => '0');
          else
            state <= SEND;
            bit_cnt <= bit_cnt + 1;
            tx_data <= '0' & tx_data(7 downto 1);
          end if;
        
        WHEN PARITY =>
          state <= STOP;
          
        WHEN STOP =>
          state <= IDLE;
          
        when OTHERS =>
      end case;
    end if;
  end process;
  
  tx <= tx_data(0) WHEN state = SEND else
        '0'        WHEN state = START or state = PARITY else
        '1';
  busy <= '1' WHEN state = IDLE else '0';
  
end BEH;