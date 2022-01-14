# Verilog Snake

### Authors: 109321019 109321055

## I/O unit:

### `8x8 LED matrix` : game screen  
![matrix](https://github.com/gin31259461/FPGA-final-project/blob/master/image/matrix.jpg?raw=true)
### `7 segment` : count score  
![segment](https://github.com/gin31259461/FPGA-final-project/blob/master/image/seg.jpg?raw=true)
### `LEDs` : display speed
![led](https://github.com/gin31259461/FPGA-final-project/blob/master/image/led.jpg?raw=true)

## Features
* 7-seg record score, LEDs show speed level, matrix is main game sceen.
* when snake eat dot, snake will lengthen.
* touch boarder or itself, snake die.
* speed go faster if get more score.
* if snake length > 30, no lengthen, just speed up.

## Modules

### main module snake
``` v 
module snake(
  output logic[7:0] DATA_R, DATA_G, DATA_B, // connect to matrix's R G B
  output logic[3:0] SEL, // connect to matrix select S0 ~ En
  output logic[7:0] SEG, // connect to 7-seg A ~ dot
  output logic[1:0] COM, // connect to 7-seg COM3, COM4
  output logic[8:0] speed, // connect to LEDs D1 ~ D8
  input logic CLK, L, U, D, R // connect to button S1 ~ S4
);
```

### BCD to segment module
``` v
module BCD2Seg(BCD, seg);
  input[3:0] BCD; // score BCD input
  output logic[6:0] seg; // output 7-seg signal to SEG
```

### Divfreq modules
``` v
module divfreq(CLK, CLK_div, speed_control);
  input CLK; // FPGA CLK
  input int speed_control; // input speed value so we can easily change snake speed
  output logic CLK_div; // output CLK that was divide
```
``` v
module divfreq1000HZ(CLK, CLK_div, bcd_out, score, tens_score, COM);
  input CLK; // FPGA CLK
  input logic[3:0] score, tens_score; // input score and tens score, help us control 7-seg score
  output logic CLK_div; // output 1000HZ CLK
  output logic[3:0] bcd_out; // output bcd_out that connect to SEG
  output logic[1:0] COM; // connect to COM
```
### Generate snake food task 
``` v
task generate_food(
  input int rand_x, rand_y, // input random index that we defined
  input logic[7:0] board[7:0], // input board that record matrix status
  output logic[7:0] new_board[7:0] // output update board
);
```

### Detail
``` v
/////////////////////////////////////////////// Gates

  divfreq F0(CLK, CLK_div, speed_control);
  divfreq1000HZ F1(CLK, CLK_div1000HZ, bcd_out, score, tens_score, COM);
  BCD2Seg F2(bcd_out, SEG);
```
`here declare another module file`
``` v
/////////////////////////////////////////////// Board

  logic[7:0] board[7:0] =
  '{
    8'b11111111, //x, y start position
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111
  };             //matrix x, y start position : row=x, col=y
  
    logic[7:0] game_over[7:0] =
  '{
    8'b10101010,
    8'b01010101,
    8'b10101010,
    8'b01010101,
    8'b10101010,
    8'b01010101,
    8'b10101010,
    8'b01010101
  };
```
`create initial matrix and game over status`
``` v
/////////////////////////////////////////////// Initial

  int snake_head_x, snake_head_y;
  int snake_tail_x, snake_tail_y;
  int current_x, current_y;
  int new_snake_tail_x, new_snake_tail_y;
  int food_xor, food_yor;
  int speed_control;
  int speed_level;
  int snake_body[29:0][1:0];
  int snake_body_index;
  int check_status, game_over_status;
  
  int i;
  
  logic[3:0] score;
  logic[3:0] tens_score;
  logic[3:0] bcd_out;
  bit[1:0] motion;
```
`... declare some variable and constant`

``` v
/////////////////////////////////////////////// Motion
	 
  always @(posedge CLK_div) begin
  
    if(game_over_status != 1) begin
	 
      generate_food(rand_x[rand_index], rand_y[rand_index], board, board);
      food_xor = rand_x[rand_index];
      food_yor = rand_y[rand_index];

      if(motion == 2'b00)
       snake_head_x += 1;
      else if(motion == 2'b01)
       snake_head_y += 1;
      else if(motion ==2'b10)
       snake_head_y -= 1;
      else if(motion == 2'b11)
       snake_head_x -= 1;
```
`... most operation it's here random food, snake movation, snake lengthen, if game over etc.`
``` v
/////////////////////////////////////////////// Control button

  always @(posedge CLK_div1000HZ) begin
    	
    if({L, U, D, R} == 4'b1000 && motion != 2'b00)
      motion = 2'b11;
    else if({L, U, D, R} == 4'b0100 && motion != 2'b01)
      motion = 2'b10;
    else if({L, U, D, R} == 4'b0010 && motion != 2'b10)
      motion = 2'b01;
    else if({L, U, D, R} == 4'b0001 && motion != 2'b11)
      motion = 2'b00;
    else
      motion = motion;
  end
```
`when button click, snake immediately do movation by 1000HZ CLK`
``` v
/////////////////////////////////////////////// Screen

  always @(posedge CLK_div1000HZ) begin 
    	
    if(SEL == 4'b1111)
	    SEL = 4'b1000;
	  else
	    SEL = SEL + 1'b1;
	 
	  if(game_over_status == 1) begin
	    DATA_G = 8'b11111111;
	    DATA_R = game_over[SEL[2:0]];
	  end
	  else
	    DATA_G = board[SEL[2:0]];
  end
  
  always @(speed_level)
    case(speed_level)
	    0: speed = 8'b10000000;
      1: speed = 8'b11000000;
      2: speed = 8'b11100000;
      3: speed = 8'b11110000;
      4: speed = 8'b11111000;
      5: speed = 8'b11111100;
      6: speed = 8'b11111110;
      7: speed = 8'b11111111;
	  endcase
```
`always update matrix at every snake movation`  
`when speed level changed, update output level of LEDs`

[## Demo video](https://drive.google.com/file/d/1c8j4ZdsNbCl-l_QzpenQULFqLHYlGXve/view?usp=sharing)
