`timescale 1us/10ns 

/*
  Esse tb é foi pensando para tentar usar a o circuito para usar o metodo babilônico da raiz e a fatorização como uma tentativa 'divertida' de verifica
  para isso foi usada duas task e também alguns nops no 'código'
*/

module top_tb_completo ();
  // parameters
  localparam CLK_PERIOD = 10;
  localparam      WIDTH = 8;

  // dut interface connectors
  logic clk = 0;
  logic rst;
  logic [6:0] cmdin;
  logic [WIDTH-1:0] din_1 = 0;
  logic [WIDTH-1:0] din_2 = 0;
  logic [WIDTH-1:0] din_3 = 0;
  logic [WIDTH-1:0] dout_low, prev_dout_low;
  logic [WIDTH-1:0] dout_high;
  logic cpu_rdy;
  logic zero;
  logic error;

  always_comb begin
    if (cpu_rdy == 1'b1) prev_dout_low = dout_low;
  end

  typedef enum logic [2:0] {
    ADD = 0,
    SUB,
    MUL,
    DIV,
    NOP1,
    LOAD,
    STORE,
    NOP2
  } ISA_ENUM_T;

  // mux instantiation
  top #(
    .WIDTH  (WIDTH  )
  ) uu_top (
    .clk(clk),
    .rst(rst),
    .cmdin(cmdin),
    .din_1(din_1),
    .din_2(din_2),
    .din_3(din_3),
    .dout_low(dout_low),
    .dout_high(dout_high),
    .cpu_rdy(cpu_rdy),
    .zero(zero),
    .error(error)
  );

  // clk gen
  always #(CLK_PERIOD/2) clk=~clk;

  task automatic run_tb_basico();
      begin
          @(posedge clk);
          rst = 1;
          @(posedge clk);
          rst = 0;

          repeat (3) @(posedge clk);//Pipeline cheio\


          // Teste 1: STORE em múltiplas posições de memória
          for (int addr = 0; addr < 5; addr++) begin
              din_1 = addr;           // endereço (via muxA)
              din_2 = addr * 2;       // dado a ser armazenado
              din_3 = 8'd00;      // zero
              cmdin = {2'b01, 2'b10, ADD};   
              wait(cpu_rdy == 1); @(posedge clk);
              cmdin = {2'b00, 2'b01, STORE};  // ajuste conforme sua codificação: bits[6:5]=00 (endereço em din_1), bits[4:3]=01 (dado em din_2)
              wait(cpu_rdy == 1); @(posedge clk);
          end

          // Agora lê de volta e verifica
          for (int addr = 0; addr < 5; addr++) begin
              din_1 = addr;           // endereço para LOAD
              cmdin = {2'b00, 2'b10, LOAD}; // LOAD: carrega memória no registrador de saída
              wait(cpu_rdy == 1); @(posedge clk);
          end

          // Teste 2: Operações aritméticas com verificação de zero e erro
          // ADD: 5 + 3 = 8
          din_1 = 5;
          din_2 = 3;
          cmdin = {2'b00, 2'b01, ADD};
          wait(cpu_rdy == 1); @(posedge clk);

          // SUB: 5 - 3 = 2
          din_1 = 5;
          din_2 = 3;
          cmdin = {2'b00, 2'b01, SUB};
          wait(cpu_rdy == 1); @(posedge clk);

          // SUB: 3 - 5 = -2 (complemento de 2) -> deve gerar zero=0, error=0
          din_1 = 3;
          din_2 = 5;
          cmdin = {2'b00, 2'b01, SUB};
          wait(cpu_rdy == 1); @(posedge clk);

          // MUL: 7 * 6 = 42 (0x2A)
          din_1 = 7;
          din_2 = 6;
          cmdin = {2'b00, 2'b01, MUL};
          wait(cpu_rdy == 1); @(posedge clk);

          // DIV: 10 / 2 = 5 (quociente em dout_low, resto em dout_high?)
          // Assumindo que a ALU coloca quociente em low e resto em high
          din_1 = 10;
          din_2 = 2;
          cmdin = {2'b00, 2'b01, DIV};
          wait(cpu_rdy == 1); @(posedge clk);

          // DIV por zero -> deve gerar error=1
          din_1 = 10;
          din_2 = 0;
          cmdin = {2'b00, 2'b01, DIV};
          wait(cpu_rdy == 1); @(posedge clk);

          // ADD com erro -> deve gerar error=1
          din_1 = 10;
          cmdin = {2'b00, 2'b11, ADD};
          wait(cpu_rdy == 1); @(posedge clk);

          // SUB com erro -> deve gerar error=1
          din_3 = 10;
          cmdin = {2'b11, 2'b10, SUB};
          wait(cpu_rdy == 1); @(posedge clk);

          // NOP com erro -> deve abaixar o erro
          cmdin = {2'b11, 2'b11, NOP1};
          wait(cpu_rdy == 1); @(posedge clk);

          // Operação que resulta em zero: 3 - 3 = 0
          din_1 = 3;
          din_2 = 3;
          cmdin = {2'b00, 2'b01, SUB};
          wait(cpu_rdy == 1); @(posedge clk);

          // Teste 3: Uso de feedback (in_select = 2'b11) com resultados anteriores
          // Primeiro, calcular um valor e armazenar no registrador (ex: ADD 2+3 =5)
          din_1 = 2;
          din_2 = 3;
          cmdin = {2'b00, 2'b01, ADD};
          wait(cpu_rdy == 1); @(posedge clk);
          // Agora usar feedback: somar o resultado anterior (5) com 7
          // in_select_a = 2'b11 (usa dout_high como operando A), in_select_b = 2'b00 (din_1)
          din_1 = 7;  // segundo operando
          cmdin = {2'b11, 2'b00, ADD};   // ADD feedback (reg_OUT high) + din_1
          wait(cpu_rdy == 1); @(posedge clk);

          // Testar feedback com resultado de memória (LOAD)
          din_1 = 0;   // endereço 0 que armazenamos 0*2=0
          cmdin = {2'b00, 2'b01, LOAD};
          wait(cpu_rdy == 1); @(posedge clk);
          // Agora usar feedback desse valor carregado (0) + 42
          din_1 = 42;
          cmdin = {2'b11, 2'b00, ADD};
          wait(cpu_rdy == 1); @(posedge clk);

          // Teste 4: Reset durante execução (já existente)
          #35;
          rst = 1;
          @(posedge clk);
          rst = 0;
          // Após reset, deve-se executar uma operação simples
          din_1 = 1;
          din_2 = 1;
          cmdin = {2'b00, 2'b01, ADD};
          wait(cpu_rdy == 1); @(posedge clk);

          $display("Testbench completed.");
          $finish;
      end
  endtask


  // main block
  initial begin
    // msim
    $dumpfile("dump.vcd");
    $dumpvars;

    // vcs to get all:
    // $fsdbDumpfile("waveform.fsdb");
    // $fsdbDumpvars("+all");

    rst = 1;
    #5;
    rst = 0;
    #5;

    run_tb_basico();

    #1000;
    $display("\n\n");
    $finish();
  end
endmodule