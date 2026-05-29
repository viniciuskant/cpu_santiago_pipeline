module top #(
    parameter WIDTH = 8,
    parameter WIDTH_ADDRESS = 8,
    parameter N = 4
)(
    input clk,
    input rst,
    input [6:0] cmdin,
    input [WIDTH-1:0] din_1,
    input [WIDTH-1:0] din_2,
    input [WIDTH-1:0] din_3,
    output logic [WIDTH-1:0] dout_low,
    output logic [WIDTH-1:0] dout_high,
    output logic cpu_rdy,
    output logic zero,
    output logic error
);

    // Sinais de pipeline
    logic [WIDTH-1:0] muxA_out, muxB_out;
    logic [WIDTH-1:0] regA_out, regB_out;
    logic [2*WIDTH-1:0] alu_out;
    logic [2*WIDTH-1:0] mem_out;
    logic [2*WIDTH-1:0] muxCPU_OUT;
    logic [2*WIDTH-1:0] regCPU_OUT;

    logic [1:0] in_select_a, in_select_b;
    logic [3:0] opcode;

    // Sinais do controle
    logic memoryWrite, memoryRead;
    logic selmux2;
    logic aluout_reg_en;
    logic aluin_reg_en;
    logic datain_reg_en;
    logic nvalid_data;
    logic rst_out;

    // Sinais para forwarding
    logic forwardA, forwardB; // seleciona entre reg_OUT e valor encaminhado
    logic [2*WIDTH-1:0] ex_result; // resultado do estágio EX
    logic ex_result_valid; // indica se o resultado do EX é válido
    logic ex_nvalid_data; // sinal de erro propagado do EX

    logic error_in, zero_in;
    logic [6:0] regCMD_IN; // registrador IF/ID (instrução)

    assign {dout_high, dout_low} = regCPU_OUT;

    // Pipeline Stage 1: IF
    register_bank #(.WIDTH(7)) reg_IF_ID (
        .clk(clk),
        .rst(rst),
        .in(cmdin),
        .out(regCMD_IN),
        .wr_en(datain_reg_en) // TODO: está sempre 1, implementar stall
    );


    // Controle baseada na instrução IF)
    control u_control (
        .clk(clk),
        .rst(rst),
        .p_error(error_in), // o erro dessa instrução como está chegando seria da inst anterior que está em EX
        .cmd_in(regCMD_IN),
        .aluin_reg_en(aluin_reg_en),
        .datain_reg_en(datain_reg_en),
        .memoryWrite(memoryWrite),
        .memoryRead(memoryRead),
        .selmux2(selmux2),
        .cpu_rdy(cpu_rdy),
        .aluout_reg_en(aluout_reg_en),
        .rst_out(rst_out),
        .nvalid_data(nvalid_data),
        .in_select_a(in_select_a),
        .in_select_b(in_select_b),
        .opcode(opcode)
    );

    // Lógica de Forwarding (resolve RAW hazard com feedback)
    // forwardA e forwardB = 1 quando a instrução atual (ID) usa feedback (in_select_a == 2'b11)
    // e a instrução em EX produz um resultado válido.
    assign forwardA = (in_select_a == 2'b11) && ex_result_valid;
    assign forwardB = (in_select_b == 2'b11) && ex_result_valid;

    // Estágio ID: Seleção dos operandos com forwarding
    logic [WIDTH-1:0] muxA_normal, muxB_normal;

    mux4 #(.WIDTH(WIDTH)) muxA (
        .din1(din_1),
        .din2(din_2),
        .din3(din_3),
        .din4(dout_high),
        .select(in_select_a),
        .dout(muxA_normal)
    );

    mux4 #(.WIDTH(WIDTH)) muxB (
        .din1(din_1),
        .din2(din_2),
        .din3(din_3),
        .din4(dout_low),
        .select(in_select_b),
        .dout(muxB_normal)
    );

    // Forwarding: se ativo, usa o resultado do EX; senão usa o valor normal
    logic [WIDTH-1:0] operandA, operandB;
    assign operandA = forwardA ? ex_result[2*WIDTH-1:WIDTH] : muxA_normal;
    assign operandB = forwardB ? ex_result[WIDTH-1:0] : muxB_normal;

    // Pipeline Stage 2 -> 3: registradores ID/EX 
    register_bank #(.WIDTH(WIDTH)) reg_ID_EX_A (
        .clk(clk),
        .rst(rst),
        .in(operandA),
        .out(regA_out),
        .wr_en(aluin_reg_en) // sempre 1
    );

    register_bank #(.WIDTH(WIDTH)) reg_ID_EX_B (
        .clk(clk),
        .rst(rst),
        .in(operandB),
        .out(regB_out),
        .wr_en(aluin_reg_en)
    );

    // regs para sinais de controle que devem acompanhar a instrução no EX
    logic memoryWrite_EX, memoryRead_EX, selmux2_EX, aluout_reg_en_EX;
    logic [3:0] opcode_EX;
    logic nvalid_data_EX; // erro propagado vindo do ID
    logic [1:0] in_select_a_EX, in_select_b_EX; // apenas guardei, vai que preciso depois

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            memoryWrite_EX <= 1'b0;
            memoryRead_EX  <= 1'b0;
            selmux2_EX     <= 1'b1;
            aluout_reg_en_EX <= 1'b0;
            opcode_EX      <= 4'b0;
            nvalid_data_EX <= 1'b0;
            in_select_a_EX <= 2'b0;
            in_select_b_EX <= 2'b0;
        end else begin
            memoryWrite_EX <= memoryWrite;
            memoryRead_EX  <= memoryRead;
            selmux2_EX     <= selmux2;
            aluout_reg_en_EX <= aluout_reg_en;
            opcode_EX      <= opcode;
            nvalid_data_EX <= nvalid_data;
            in_select_a_EX <= in_select_a;
            in_select_b_EX <= in_select_b;
        end
    end

    // Estágio EX: ALU, Memória e geração do resultado
    ALU #(.WIDTH(WIDTH)) u_alu (
        .in1(regA_out),
        .in2(regB_out),
        .op(opcode_EX),
        .nvalid_data(nvalid_data_EX),
        .out(alu_out),
        .zero(zero_in),
        .error(error_in)
    );

    memory #(
        .WIDTH(WIDTH),
        .WIDTH_ADDRESS(WIDTH_ADDRESS)
    ) u_memory (
        .clk(clk),
        .memoryWrite(memoryWrite_EX),
        .memoryRead(memoryRead_EX),
        .memoryWriteData({dout_low}), // dado a ser escrito (apenas parte baixa)
        .memoryAddress(regA_out[WIDTH_ADDRESS-1:0]),
        .memoryOutData(mem_out)
    );

    // selecao do resultado do EX (ALU ou memória)
    assign ex_result = (selmux2_EX == 1'b1) ? alu_out : mem_out;
    // o resultado é considerado válido se aluout_reg_en_EX está ativo
    assign ex_result_valid = aluout_reg_en_EX;

    // Registrador de saída (EX/WB)
    register_bank #(.WIDTH(2*WIDTH)) reg_EX_WB (
        .clk(clk),
        .rst(rst),
        .in(ex_result),
        .out(regCPU_OUT),
        .wr_en(aluout_reg_en_EX)
    );

    // Registrador de flags (zero e error)
    register_bank #(.WIDTH(2)) reg_FLAG_OUT (
        .clk(clk),
        .rst(rst),
        .in({zero_in, error_in}),
        .out({zero, error}),
        .wr_en(aluout_reg_en_EX)
    );



endmodule