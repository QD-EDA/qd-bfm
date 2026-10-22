module command_width;
  bit [2:0] op_code;
  integer fd;

  initial begin
    fd = $fopen("commands.hex", "w");
    op_code = 1; $fwrite(fd, "%02X\n", op_code - 1);
    op_code = 2; $fwrite(fd, "%02X\n", op_code - 1);
    op_code = 3; $fwrite(fd, "%02X\n", op_code - 1);
    op_code = 1; $fwrite(fd, "%02X\n", op_code - 3'd1);
    op_code = 2; $fwrite(fd, "%02X\n", op_code - 3'd1);
    op_code = 3; $fwrite(fd, "%02X\n", op_code - 3'd1);
    $fwrite(fd, "%02X\n", 1);
    $fwrite(fd, "%02X\n", 2);
    $fwrite(fd, "%02X\n", 3'd1);
    $fwrite(fd, "%02X\n", 3'd2);
    $fclose(fd);
  end
endmodule
