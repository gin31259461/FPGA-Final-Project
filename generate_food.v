task generate_food(
  input int rand_x, rand_y,
  input logic[7:0] board[7:0],
  output logic[7:0] new_board[7:0]
);

  board[rand_x][rand_y] = 1'b0;
  new_board = board;
  
endtask
