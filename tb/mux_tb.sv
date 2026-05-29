module mux_tb;

    parameter WIDTH = 8;
    parameter N     = 4;

    logic [N-1:0][WIDTH-1:0] din;
    logic [$clog2(N)-1:0] select;
    logic [WIDTH-1:0] dout;

    mux #(.WIDTH(WIDTH), .N(N)) uut (
        .din(din),
        .select(select),
        .dout(dout)
    );

    task test(input int idx);
        begin
            select = idx;
            #1;

            $display("TESTE %0d | select=%0d | esperado=%h | obtido=%h",
                     idx, select, din[idx], dout);

            if (dout !== din[idx]) begin
                $display("ERRO no teste %0d", idx);
            end else begin
                $display("OK no teste %0d", idx);
            end

            #1;
        end
    endtask

    initial begin
        $dumpfile("mux_wave.vcd");
        $dumpvars(0, mux_tb);

        // inicialização dos dados
        din[0] = 8'hAA;
        din[1] = 8'hBB;
        din[2] = 8'hCC;
        din[3] = 8'hDD;

        test(0);
        test(1);
        test(2);
        test(3);


        #20;
        $dumpflush;
        $display("Fim dos testes");

        $finish;
    end

endmodule
