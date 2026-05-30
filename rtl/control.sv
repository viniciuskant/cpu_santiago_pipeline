module control (
    input  logic clk,
    input  logic rst,
    input  logic p_error,
    input  logic [6:0] cmd_in,

    output logic aluin_reg_en,
    output logic datain_reg_en,
    output logic memoryWrite,
    output logic memoryRead,
    output logic selmux2,
    output logic cpu_rdy,
    output logic aluout_reg_en,
    output logic rst_out,
    output logic nvalid_data,
    output logic [1:0] in_select_a,
    output logic [1:0] in_select_b,
    output logic [3:0] opcode
);

    logic [2:0] in_opcode;
    logic feedback_select, propagate_error, instruction_alu;
    // opitei por tirar poir assim consigo zerar a saída com WRITE ou replicar din2 quando NOP
    // logic result_valid; // indica se a instrução atual produz resultado, tudo menos NOP ou memoryWrite

    assign in_select_a = cmd_in[6:5];
    assign in_select_b = cmd_in[4:3];
    assign instruction_alu = ~cmd_in[2];
    assign feedback_select = (in_select_a == 2'b11) || (in_select_b == 2'b11);
    assign propagate_error = p_error && feedback_select && instruction_alu;

    assign rst_out = rst;
    assign in_opcode = cmd_in[2:0];

    // decodificação do opcode
    always_comb begin
        memoryWrite = 1'b0;
        memoryRead  = 1'b0;
        selmux2     = 1'b1; // por padrão, seleciona saída da ALU
        nvalid_data = propagate_error;
        // result_valid = 1'b1;

        case (in_opcode)
            3'b101: begin  // MEM_READ
                memoryRead = 1'b1;
                selmux2 = 1'b0; // seleciona saída da memória
            end
            3'b110: begin  // MEM_WRITE
                memoryWrite = 1'b1;
                selmux2 = 1'b0;   // seleciona memoria
                // result_valid = 1'b0;
            end
            3'b100, 3'b111: begin  // NOPs
                // result_valid = 1'b0;
                selmux2 = 1'b1;
            end
        endcase
    end

    // sinais para os registradores de pipeline
    assign aluin_reg_en = 1'b1; // sempre escreve operandos no ID/EX
    assign datain_reg_en = 1'b1; // sempre carrega nova instrução no IF/ID, TODO: apenas para teste, logo mudar
    // assign aluout_reg_en = result_valid; // só escreve resultado se válido
    assign aluout_reg_en = 1; // só escreve resultado se válido

    // só ready após 3 ciclos, lógica básica para teste
    logic [1:0] fill_counter;
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            fill_counter <= 2'b00;
        else if (fill_counter < 2'b11)
            fill_counter <= fill_counter + 1'b1;
    end
    assign cpu_rdy = (fill_counter >= 2'b11);  

    assign opcode = {1'b0, in_opcode}; // extensão para 4 bits

endmodule