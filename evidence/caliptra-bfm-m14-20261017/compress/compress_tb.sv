`default_nettype none

module compress_tb
    import abr_params_pkg::*;
    import compress_defines_pkg::*;
    ();

localparam int NUM_POLY = 4;
localparam int WORDS = NUM_POLY * (MLKEM_N / 4);
localparam int MAX_BITS = WORDS * 4 * 11;

logic clk_tb, reset_n_tb, zeroize_tb, en_tb;
logic compare_mode_tb;
logic [2:0] num_poly_tb;
compress_mode_t mode_tb;
logic [ABR_MEM_ADDR_WIDTH-1:0] src_base_tb, dest_base_tb;
mem_if_t mem_rd_req_tb;
logic [3:0][REG_SIZE-1:0] mem_rd_data_tb;
logic [1:0] api_rw_en_tb;
logic [ABR_MEM_ADDR_WIDTH-1:0] api_rw_addr_tb;
logic [DATA_WIDTH-1:0] api_wr_data_tb, api_rd_data_tb;
logic compare_failed_tb, compress_done_tb;

logic [3:0][REG_SIZE-1:0] input_mem [0:WORDS-1];
logic [MAX_BITS-1:0] expected_bits;
int expected_bit_count, expected_word_count, output_word_count;
int testcase_errors, total_errors;
logic done_seen_tb;

compress_top dut (
    .clk(clk_tb), .reset_n(reset_n_tb), .zeroize(zeroize_tb),
    .compress_enable(en_tb), .mode(mode_tb), .compare_mode(compare_mode_tb),
    .num_poly(num_poly_tb), .src_base_addr(src_base_tb), .dest_base_addr(dest_base_tb),
    .mem_rd_req(mem_rd_req_tb), .mem_rd_data(mem_rd_data_tb),
    .api_rw_en(api_rw_en_tb), .api_rw_addr(api_rw_addr_tb), .api_wr_data(api_wr_data_tb),
    .api_rd_data(api_rd_data_tb), .compare_failed(compare_failed_tb),
    .compress_done(compress_done_tb)
);

initial begin
    clk_tb = 0;
    forever #5 clk_tb = ~clk_tb;
end

always @(posedge clk_tb) begin
    if (compress_done_tb === 1'b1)
        done_seen_tb = 1;

    if (reset_n_tb && mem_rd_req_tb.rd_wr_en === RW_READ)
        mem_rd_data_tb <= input_mem[mem_rd_req_tb.addr];
    else
        mem_rd_data_tb <= '0;

    if (reset_n_tb && api_rw_en_tb[0]) begin
        if (output_word_count >= expected_word_count) begin
            $display("Unexpected API write at address %0d", api_rw_addr_tb);
            testcase_errors++;
            total_errors++;
        end else begin
            if (api_rw_addr_tb !== (dest_base_tb + output_word_count)) begin
                $display("Address mismatch: expected %0d got %0d", dest_base_tb + output_word_count, api_rw_addr_tb);
                testcase_errors++;
                total_errors++;
            end
            if (api_wr_data_tb !== expected_bits[output_word_count*DATA_WIDTH +: DATA_WIDTH]) begin
                $display("Data mismatch at output %0d: expected %h got %h", output_word_count,
                         expected_bits[output_word_count*DATA_WIDTH +: DATA_WIDTH], api_wr_data_tb);
                testcase_errors++;
                total_errors++;
            end
        end
        output_word_count++;
    end
end

task automatic reset_dut;
begin
    en_tb = 0;
    done_seen_tb = 0;
    reset_n_tb = 0;
    repeat (3) @(negedge clk_tb);
    reset_n_tb = 1;
    repeat (2) @(negedge clk_tb);
end
endtask

task automatic prepare_vectors(input int d);
    int coeff, rounded, bit_idx, flat_idx;
begin
    expected_bits = '0;
    expected_bit_count = 0;
    for (int poly = 0; poly < NUM_POLY; poly++) begin
        for (int word_idx = 0; word_idx < MLKEM_N/4; word_idx++) begin
            for (int lane = 0; lane < 4; lane++) begin
                flat_idx = word_idx*4 + lane;
                case (flat_idx)
                    0: coeff = 0;
                    1: coeff = 1;
                    2: coeff = MLKEM_Q/2;
                    3: coeff = MLKEM_Q-1;
                    default: coeff = (poly*977 + flat_idx*137 + flat_idx*flat_idx*7 + 11) % MLKEM_Q;
                endcase
                input_mem[poly*(MLKEM_N/4)+word_idx][lane] = REG_SIZE'(coeff);
                rounded = ((coeff << d) + MLKEM_Q/2) / MLKEM_Q;
                for (bit_idx = 0; bit_idx < d; bit_idx++) begin
                    expected_bits[expected_bit_count] = (rounded >> bit_idx) & 1;
                    expected_bit_count++;
                end
            end
        end
    end
    expected_word_count = expected_bit_count / DATA_WIDTH;
end
endtask

task automatic compress_test(input compress_mode_t mode, input int d, input int dest);
    int cycles;
begin
    reset_dut();
    prepare_vectors(d);
    output_word_count = 0;
    testcase_errors = 0;
    if ((expected_bit_count % DATA_WIDTH) != 0) begin
        $display("Expected stream is not word aligned");
        testcase_errors++;
        total_errors++;
    end
    src_base_tb = '0;
    dest_base_tb = ABR_MEM_ADDR_WIDTH'(dest);
    mode_tb = mode;
    num_poly_tb = NUM_POLY;
    compare_mode_tb = 0;
    api_rd_data_tb = '0;
    zeroize_tb = 0;
    @(negedge clk_tb);
    en_tb = 1;
    @(negedge clk_tb);
    en_tb = 0;
    cycles = 0;
    while (!done_seen_tb && cycles < 10000) begin
        @(negedge clk_tb);
        cycles++;
    end
    repeat (2) @(negedge clk_tb);
    if (!done_seen_tb) begin
        $display("compress_done timeout in mode %0d", mode);
        $display("timeout detail: cycles=%0d writes=%0d/%0d addr=%0d state=%0d read_done=%b busy=%b valid=%b hold=%b buffer=%b/%b api=%b",
                 cycles, output_word_count, expected_word_count, mem_rd_req_tb.addr,
                 dut.cmp_ctrl_inst.read_fsm_state_ps, dut.read_done, dut.compress_busy,
                 dut.mem_rd_data_valid, dut.mem_rd_data_hold, dut.buffer_valid, dut.buffer_valid_f, api_rw_en_tb);
        testcase_errors++;
        total_errors++;
    end
    if (output_word_count != expected_word_count) begin
        $display("Write count mismatch in mode %0d: expected %0d got %0d", mode, expected_word_count, output_word_count);
        testcase_errors++;
        total_errors++;
    end
    if (testcase_errors == 0)
        $display("Mode %0d passed (%0d packed writes)", mode, output_word_count);
    else
        $display("Mode %0d failed with %0d errors", mode, testcase_errors);
end
endtask

initial begin
    reset_n_tb = 0;
    zeroize_tb = 0;
    en_tb = 0;
    compare_mode_tb = 0;
    num_poly_tb = NUM_POLY;
    mode_tb = compress1;
    src_base_tb = '0;
    dest_base_tb = '0;
    api_rd_data_tb = '0;
    expected_word_count = 0;
    output_word_count = 0;
    testcase_errors = 0;
    total_errors = 0;
    repeat (3) @(negedge clk_tb);

    compress_test(compress1, 1, 'h40);
    compress_test(compress5, 5, 'h80);
    compress_test(compress11, 11, 'hC0);

    if (total_errors == 0)
        $display("* TESTCASE PASSED");
    else
        $display("* TESTCASE FAILED with %0d errs.", total_errors);
    $finish;
end

endmodule
