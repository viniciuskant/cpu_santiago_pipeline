`timescale 1ns/1ps

module ALU_tb;

    localparam WIDTH = 8;

    logic [WIDTH-1:0] in1, in2;
    logic [3:0] op;
    logic nvalid_data;
    logic [2*WIDTH-1:0] out;
    logic zero;
    logic error;

    // DUT
    ALU #(.WIDTH(WIDTH)) dut (
        .in1(in1),
        .in2(in2),
        .op(op),
        .nvalid_data(nvalid_data),
        .out(out),
        .zero(zero),
        .error(error)
    );

    // tarefa de teste
    task run_test(
        input signed [WIDTH-1:0] a,
        input signed [WIDTH-1:0] b,
        input [3:0] operation,
        input signed [2*WIDTH-1:0] expected
    );
        begin
            in1 = a;
            in2 = b;
            op  = operation;
            nvalid_data = 0;

            #1; // espera combinacional

            if (out !== expected) begin
                $display("ERRO: op=%b | %0d , %0d => esperado=%0d, obtido=%0d",
                         operation, a, b, expected, $signed(out));
            end else begin
                $display("OK: op=%b | %0d , %0d => %0d",
                         operation, a, b, $signed(out));
            end
        end
    endtask

    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, ALU_tb);

        // ADD (0000)
        run_test(8'h0a, 8'h05, 4'b0000, 16'h000f); // 10 + 5
        run_test(8'hf6, 8'h05, 4'b0000, 16'hfffb); //-10 + 5

        // SUB (0001)
        run_test(10, 3, 4'b0001, 7);
        run_test(-10, -5, 4'b0001, -5);

        // MUL (1010)
        run_test(4, 3, 4'b1010, 12);
        run_test(-4, 3, 4'b1010, -12);

        // DIV (1011)
        run_test(20, 4, 4'b1011, 5);
        run_test(-20, 4, 4'b1011, -5);

        // divisão por zero
        in1 = 10;
        in2 = 0;
        op  = 4'b1011;
        #1;
        if (error)
            $display("OK: divisão por zero detectada");
        else
            $display("ERRO: divisão por zero NÃO detectada");

        run_test(10, -10, 4'b0000, 16'h0000);
        #1
        if (zero)
            $display("OK: zero detectado");
        else
            $display("ERRO: zero NÃO detectado");


        run_test(10, -10, 4'b0001, 16'h0014);

        $display("Teste Terminado");
        $finish;
    end

endmodule
