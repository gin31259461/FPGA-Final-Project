/*
IO 33 => CR1
IO 41 => CG1
IO 81 => CB1
IO 49 => S0 --matrix select
IO 57 => S4 --button
IO 61 => COM4 --seg select
IO 65 => D1 --LED
IO 73 => A --seg
*/

module snake(
  output logic[7:0] DATA_R, DATA_G, DATA_B,
  output logic[3:0] SEL,
  output logic[7:0] SEG,
  output logic[1:0] COM,
  output logic[8:0] speed,
  input logic CLK, L, U, D, R
);


/////////////////////////////////////////////// Gates

  divfreq F0(CLK, CLK_div, speed_control);
  divfreq1000HZ F1(CLK, CLK_div1000HZ, bcd_out, score, tens_score, COM);
  BCD2Seg F2(bcd_out, SEG);

  
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
  
  int rand_index;
  int rand_x[31:0] =
  '{
    2, 6, 5, 7, 0, 1, 4, 3,
    0, 6, 4, 7, 5, 2, 3, 7,
    5, 0, 7, 4, 1, 7, 2, 6,
    3, 0, 5, 6, 7, 1, 3, 4
  };
  
  int rand_y[31:0] =
  '{
    6, 5, 7, 2, 3, 4, 0, 1,
    3, 1, 5, 0, 7, 6, 4, 2,
    7, 0, 6, 4, 2, 5, 1, 3,
    0, 2, 4, 7, 6, 3, 5, 1
  };
  
  initial begin
  
    DATA_B = 8'b11111111;
    DATA_G = 8'b11111111;
    DATA_R = 8'b11111111;
	 
    SEL = 4'b1000;
    motion = 2'b11;
	 
    rand_index = 0;
    snake_body_index = 0;
	 
    check_status = 0;
    game_over_status = 0;
	 
    snake_head_x = 4;
    snake_head_y = 5;

    current_x = snake_head_x;
    current_y = snake_head_y;
	 
    speed_control = 25000000;
    speed_level = 0;
	 
    score = 4'b0000;
    tens_score = 4'b0000;
	 
    i = 0;
    repeat(30) begin
      snake_body[i][0] = -1;
      snake_body[i][1] = -1;
      i += 1;
    end
	 
  end
  
/*
00 => R
01 => D
10 => U
11 => L 
*/

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
		
      if(snake_head_x > 7 || snake_head_x < 0)
        game_over_status = 1;
      else if(snake_head_y > 7 || snake_head_y < 0)
        game_over_status = 1;
		  
      else begin
        i = 0;
	repeat(29) begin
	if(snake_head_x == snake_body[i][0] && snake_head_y == snake_body[i][1])
	  game_over_status = 1;
	  i += 1;
	end
      end
	   
      if(snake_head_x == food_xor && snake_head_y == food_yor) begin
        rand_index += 1;
	 score += 1'b1;
		  
	if(snake_body_index != 29) begin
	  snake_body_index += 1;
	  check_status = 1;
	end
      end
		
      if(score == 4'b1010) begin
        score = 4'b0000;
	tens_score += 1'b1;
	speed_control -= 2000000;
	 speed_level += 1;
      end
  
      if(rand_index > 31)
        rand_index = 0;

      if(check_status == 1) begin
        snake_body[snake_body_index][0] = current_x;
        snake_body[snake_body_index][1] = current_y;
	check_status = 0;
      end
		
      else if(check_status == 0) begin
        board[snake_head_x][snake_head_y] = 1'b0;
	board[snake_body[0][0]][snake_body[0][1]] = 1'b1;
	i = 0;
	repeat(29) begin
	snake_body[i][0] = snake_body[i+1][0];
        snake_body[i][1] = snake_body[i+1][1];
	i += 1;
        end
      snake_body[snake_body_index][0] = current_x;
      snake_body[snake_body_index][1] = current_y;
      end	
	   current_x = snake_head_x;
	   current_y = snake_head_y;
    end	 
  end

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
endmodule
