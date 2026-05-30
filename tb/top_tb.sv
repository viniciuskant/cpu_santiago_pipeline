`timescale 1us/10ns

module top_tb_completo ();
  // parameters
  localparam CLK_PERIOD = 10;
  localparam      WIDTH = 8;

  logic clk = 0;
  logic rst;
  logic [6:0] cmdin;
  logic [WIDTH-1:0] din_1 = 0;
  logic [WIDTH-1:0] din_2 = 0;
  logic [WIDTH-1:0] din_3 = 0;
  logic [WIDTH-1:0] dout_low;
  logic [WIDTH-1:0] dout_high;
  logic cpu_rdy;
  logic zero;
  logic error;

  typedef enum logic [2:0] {
    ADD   = 0,
    SUB   = 1,
    MUL   = 2,
    DIV   = 3,
    NOP1  = 4,
    LOAD  = 5,
    STORE = 6,
    NOP2  = 7
  } opcode_t;

  typedef struct packed {
    logic [1:0] sel_a; // inputs
    logic [1:0] sel_b;
    opcode_t    op;
    logic [7:0] op1;
    logic [7:0] op2;
    logic [7:0] op3;

    logic [7:0] exp_high; // outputs
    logic [7:0] exp_low; 
    logic       exp_zero;
    logic       exp_error;
  } test_instr_t;


  localparam int NUM_TESTS = 34;
  test_instr_t test_program[NUM_TESTS] = '{
    // sel_a, sel_b, op, op1, op2, op3,             exp_high, exp_low, exp_zero, exp_error
    '{2'b00, 2'b01, ADD, 8'd5, 8'd3, 8'd0,               8'd0,  8'd8, 1'b0, 1'b0},
    '{2'b00, 2'b01, SUB, 8'd5, 8'd3, 8'd0,               8'd0,  8'd2, 1'b0, 1'b0},
    '{2'b00, 2'b01, SUB, 8'd3, 8'd5, 8'd0,               8'd255,  8'd254, 1'b0, 1'b0},
    '{2'b00, 2'b01, MUL, 8'd7, 8'd6, 8'd0,               8'd0,  8'd42, 1'b0, 1'b0},
    '{2'b00, 2'b01, DIV, 8'd10, 8'd2, 8'd0,               8'd0,  8'd5, 1'b0, 1'b0},
    '{2'b00, 2'b01, DIV, 8'd10, 8'd0, 8'd0,               8'd255,  8'd255, 1'b0, 1'b1},

    '{2'b00, 2'b11, ADD, 8'd10,8'd0, 8'd0,               8'd255,  8'd255, 1'b0, 1'b1},
    '{2'b11, 2'b10, SUB, 8'd0, 8'd0, 8'd10,              8'd255,  8'd255, 1'b0, 1'b1},
    '{2'b11, 2'b10, NOP1, 8'd0, 8'd0, 8'd200,               8'd0,  8'd200, 1'b0, 1'b0},
    '{2'b00, 2'b01, SUB, 8'd3, 8'd3, 8'd0,               8'd0,  8'd0, 1'b1, 1'b0},

    '{2'b00, 2'b01, ADD, 8'd2, 8'd3, 8'd0,               8'd0,  8'd5, 1'b0, 1'b0},
    '{2'b00, 2'b11, ADD, 8'd7, 8'd0, 8'd0,               8'd0,  8'd12, 1'b0, 1'b0},
    '{2'b00, 2'b10, STORE, 8'd128, 8'd0, 8'd0,               8'd0,  8'd0, 1'b0, 1'b0},
    '{2'b10, 2'b10, LOAD, 8'd0, 8'd0, 8'd128,               8'd0,  8'd12, 1'b0, 1'b0},
    '{2'b11, 2'b00, ADD, 8'd42, 8'd0, 8'd0,              8'd0,  8'd42, 1'b0, 1'b0},

    '{2'b00, 2'b00, ADD, 8'd2, 8'd0, 8'd0,               8'd0, 8'd4, 1'b0, 1'b0},
    '{2'b01, 2'b10, STORE, 8'd0, 8'd0, 8'd0,               8'd0, 8'd0, 1'b0, 1'b0}, //mem[0] = 4
    '{2'b00, 2'b01, SUB, 8'd1, 8'd33, 8'd0,               8'd255, 8'd224, 1'b0, 1'b0},
    '{2'b00, 2'b10, STORE, 8'd1, 8'd2, 8'd0,               8'd0, 8'd0, 1'b0, 1'b0}, //mem[1] = 1
    '{2'b00, 2'b01, DIV, 8'd0, 8'd1, 8'd0,               8'd0, 8'd0, 1'b1, 1'b0},
    '{2'b00, 2'b10, STORE, 8'd2, 8'd3, 8'd3,               8'd0, 8'd0, 1'b0, 1'b0}, //mem[2] = 0
    '{2'b10, 2'b00, ADD, 8'd0, 8'd0, 8'd7,               8'd0, 8'd7, 1'b0, 1'b0}, 
    '{2'b10, 2'b10, STORE, 8'd3, 8'd6, 8'd3,               8'd0, 8'd0, 1'b0, 1'b0}, //mem[3] = 7
    '{2'b00, 2'b10, MUL, 8'd8, 8'd0, 8'd8,                 8'd0, 8'd64, 1'b0, 1'b0},
    '{2'b00, 2'b10, STORE, 8'd4, 8'd8, 8'd0,               8'd0, 8'd0, 1'b0, 1'b0}, //mem[3] = 0

    '{2'b00, 2'b10, LOAD, 8'd0, 8'd0, 8'd0,               8'd0, 8'd4, 1'b0, 1'b0},
    '{2'b01, 2'b10, LOAD, 8'd0, 8'd1, 8'd0,               8'd0, 8'd224, 1'b0, 1'b0},
    '{2'b10, 2'b10, LOAD, 8'd0, 8'd0, 8'd2,               8'd0, 8'd0, 1'b0, 1'b0},
    '{2'b00, 2'b10, MUL, 8'd32, 8'd0, 8'd32,               8'd4, 8'd0, 1'b0, 1'b0},
    '{2'b01, 2'b10, LOAD, 8'd0, 8'd3, 8'd0,               8'd0, 8'd7, 1'b0, 1'b0},
    '{2'b00, 2'b10, LOAD, 8'd4, 8'd0, 8'd0,               8'd0, 8'd64, 1'b0, 1'b0},

    '{2'b00, 2'b01, DIV, 8'd0, 8'd0, 8'd0,               8'd255, 8'd255, 1'b0, 1'b1},
    '{2'b00, 2'b11, ADD, 8'd0, 8'd0, 8'd0,               8'd255, 8'd255, 1'b0, 1'b1},
    '{2'b11, 2'b01, SUB, 8'd0, 8'd0, 8'd0,               8'd255, 8'd255, 1'b0, 1'b1}

  };

  string test_names[NUM_TESTS] = '{
    "ADD_5_3", "SUB_5_3", "SUB_3_5", "MUL_7_6", "DIV_10_2",
    "DIV_10_0", "INVALID_ADD", "INVALID_SUB", "NOP_CLEAR_ERR", "SUB_ZERO",
    "ADD_2_3", "FEEDBACK_ADD", "STORE128", "LOAD128", "FEEDBACK_LOAD",
    "ADD_2_2", "STORE4", "SUB2_127", "STORE1", "DIV0_1", "STORE0", "ADD_0_7", "STORE7", "MUL8_8", "STORE0",
    "LOAD0", "LOAD1", "LOAD2", "MUL_SHIFT", "LOAD3", "LOAD4",
    "DIV_ERROR", "ADD_ERROR", "SUB_ERROR"

  };

  top #(
    .WIDTH (WIDTH)
  ) uu_top (
    .clk       (clk),
    .rst       (rst),
    .cmdin     (cmdin),
    .din_1     (din_1),
    .din_2     (din_2),
    .din_3     (din_3),
    .dout_low  (dout_low),
    .dout_high (dout_high),
    .cpu_rdy   (cpu_rdy),
    .zero      (zero),
    .error     (error)
  );

  always #(CLK_PERIOD/2) clk = ~clk;

  task automatic run_test_program();
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer i;

    test_instr_t t = test_program[0];

    cmdin = {t.sel_a, t.sel_b, t.op};
    din_1 = t.op1;
    din_2 = t.op2;
    din_3 = t.op3;

    @(posedge clk); 

    t = test_program[1];

    cmdin = {t.sel_a, t.sel_b, t.op};
    din_1 = t.op1;
    din_2 = t.op2;
    din_3 = t.op3;

    @(posedge clk); 

    t = test_program[2];

    cmdin = {t.sel_a, t.sel_b, t.op};
    din_1 = t.op1;
    din_2 = t.op2;
    din_3 = t.op3;

    @(posedge clk); //pipeline cheio
    wait(cpu_rdy == 1);

    for (i = 3; i < NUM_TESTS; i = i + 1) begin
      t = test_program[i - 3];

      $write("%2d: %-20s", i - 3, test_names[i - 3]);
      if (dout_low  === t.exp_low  &&
          dout_high === t.exp_high &&
          zero      === t.exp_zero &&
          error     === t.exp_error) begin
        $write(" PASS");
        pass_cnt++;
      end else begin
        $write(" FAIL");
        fail_cnt++;
        $write("\n     Expected: low=%2d high=%2d zero=%1d error=%1d",
               t.exp_low, t.exp_high, t.exp_zero, t.exp_error);
        $write("\n     Actual:   low=%2d high=%2d zero=%1d error=%1d",
               dout_low, dout_high, zero, error);
      end
      $write("\n");

      t = test_program[i];
      cmdin = {t.sel_a, t.sel_b, t.op};
      din_1 = t.op1;
      din_2 = t.op2;
      din_3 = t.op3;
  
      wait(cpu_rdy == 1);
      @(posedge clk);
    end
    
    for (i = NUM_TESTS - 3; i < NUM_TESTS; i = i + 1) begin
      t = test_program[i];
      cmdin = {t.sel_a, t.sel_b, t.op};
      din_1 = t.op1;
      din_2 = t.op2;
      din_3 = t.op3;

      $write("%2d: %-20s", i, test_names[i]);
      if (dout_low  === t.exp_low  &&
          dout_high === t.exp_high &&
          zero      === t.exp_zero &&
          error     === t.exp_error) begin
        $write(" PASS");
        pass_cnt++;
      end else begin
        $write(" FAIL");
        fail_cnt++;
        $write("\n     Expected: low=%2d high=%2d zero=%1d error=%1d",
                t.exp_low, t.exp_high, t.exp_zero, t.exp_error);
        $write("\n     Actual:   low=%2d high=%2d zero=%1d error=%1d",
                dout_low, dout_high, zero, error);
      end
      $write("\n");

      @(posedge clk);
      wait(cpu_rdy == 1);
    end


    $display("\n===========================================================");
    $display("Test summary: PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
    $display("===========================================================");
    if (fail_cnt == 0)
      $display("*** ALL TESTS PASSED ***");
    else
      $display("*** SOME TESTS FAILED ***");
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top_tb_completo);

    @(posedge clk); 
    rst = 1;
    @(posedge clk); 
    rst = 0;

    run_test_program();

    #1000;
    $finish();
  end

endmodule