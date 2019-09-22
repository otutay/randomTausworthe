-------------------------------------------------------------------------------
-- Title      : tausworhe vhdl file
-- Project    : noise generator
-------------------------------------------------------------------------------
-- File       : tausworthe.vhd
-- Author     : osmant  <otutaysalgir@gmail.com>
-- Company    :
-- Created    : 2019-09-08
-- Last update: 2019-09-09
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: i will implement the tausworthe algorithm to create uniform
-- random numbers. It cannot run concurrently for every step so i decided to
-- implement a subset of it. Procedures to implement this functionality follows
-- the same steps to analyze the algorithm efficiently. link is as follows:
-- https://www.rocq.inria.fr/mathfi/Premia/free-version/doc/premia-doc/pdf_html/common/math/random_doc/index.html
-- they initially gives seed C such that it has k ones followed by L-1 zeros and makes hardware
-- part trivial. Following procedures applied
-- 1- B <= q bit left shift of seed A
-- 2- B <= A xor B
-- 3- B <= (k-s) right shift of B
-- 4- A <= A & C
-- 5- A <= s bit left shift of A
-- 6- A <= A xor B
-- these steps can be written simply as follows:
-- let A is L bit vector k,q,s is some integer that has certain conditions
-- (explained in the link)
-- new random variable can be simplified as
-- rand = A[L-1-s downto L-k] & (A[L-1-q downto k-s-q] xor A[L-1 downto k-s])
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2019-09-08  1.0      osmant  Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.noisePckg.all;

entity tausworthe is

  generic (
    c_dataBitW : integer                                 := 32;
    seedA      : std_logic_vector(c_dataBitW-1 downto 0) := x"FFFFFFFF";
    seedC      : std_logic_vector(c_dataBitW-1 downto 0) := x"FFFFFFFE";
    shifterK   : integer                                 := 19;  -- k value for shifter
    shifterQ   : integer                                 := 13;  -- q value for shifter
    shifterS   : integer                                 := 12);  -- s value for shifter

  port (
    i_clk     : in  std_logic;          -- input clock
    i_rst     : in  std_logic;          -- input reset
    o_randOut : out std_logic_vector(c_dataBitW-1 downto 0)  -- output random number
    );

end entity tausworthe;
architecture RTL of tausworthe is
  signal a      : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal b      : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal c      : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal a1     : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal a2     : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal b1     : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal b2     : std_logic_vector(c_dataBitW-1 downto 0) := (others => '0');
  signal rstEnd : std_logic                               := '0';
  signal notRst : std_logic                               := '0';
  signal rst_i1 : std_logic                               := '0';

begin  -- architecture tausworthe

  -- purpose: input buffer and initializer
  -- type   : sequential
  c <= seedC;
  inputPro : process (i_clk) is
  begin  -- process inputPro
    if i_clk'event and i_clk = '1' then  -- rising clock edge
      if(i_rst = '1') then
        a <= seedA;
        b <= (others => '0');
      -- c <= seedC;
      else
        a <= a2;
        b <= b2;
      -- a <=
      --b <=a(c_dataBitW-shifterQ-1 downto 0) & std_logic_vector(to_unsigned(0,q));
      end if;
    end if;
  end process inputPro;

  b1 <= (a(c_dataBitW-shifterQ-1 downto 0) & std_logic_vector(to_unsigned(0, shifterQ))) xor a;
  b2 <= std_logic_vector(to_unsigned(0, shifterK)) & b1(c_dataBitW-1 downto shifterK);

  a1 <= a and c;
  a2 <= ((a(c_dataBitW-shifterS-1 downto 0) & std_logic_vector(to_unsigned(0, shifterS))) xor b2);



  -- purpose: latency after the reset goes low
  -- type   : sequential
  latencyPro : process (i_clk) is
  begin  -- process latencyPro
    if i_clk'event and i_clk = '1' then  -- rising clock edge
      latencyShftReg <= latencyShftReg(latencyShftReg'high-1 downto 0) & rstEnd;
    end if;
  end process latencyPro;


  notRst <= not i_rst;
  rstEnd <= rst_i1 and notRst;
  -- purpose: resetRegPro
  -- type   : sequential
  resetRegPro : process (i_clk) is
  begin  -- process resetRegPro
    if i_clk'event and i_clk = '1' then  -- rising clock edge
      rst_i1 <= i_rst;
    end if;
  end process resetRegPro;

end architecture RTL;
