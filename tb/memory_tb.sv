module memory_tb;

    parameter WIDTH = 8;
    parameter WIDTH_ADDRESS = 3;
    parameter PERIOD = 10;

    logic clk;
    logic memoryWrite;
    logic memoryRead;
    logic [2*WIDTH-1:0] memoryWriteData;
    logic [WIDTH_ADDRESS-1:0] memoryAddress;
    logic [2*WIDTH-1:0] memoryOutData;

    // clock
    always #(PERIOD/2) clk = ~clk;

    // DUT (ajuste o nome se for diferente)
    memory uut (
        .clk(clk),
        .memoryWrite(memoryWrite),
        .memoryRead(memoryRead),
        .memoryWriteData(memoryWriteData),
        .memoryAddress(memoryAddress),
        .memoryOutData(memoryOutData)
    );

    initial begin
        $dumpfile("memory_wave.vcd");
        $dumpvars(0, memory_tb);

        clk = 0;
        memoryWrite = 0;
        memoryRead = 0;
        memoryWriteData = 0;
        memoryAddress = 0;

        $display("==== INICIO DOS TESTES ====");

        // Caso 1: escrever e ler endereço 0
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 0;
        memoryWriteData = 16'hAAAA;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        @(posedge clk);
        $display("Caso 1 - Addr 0: %h", memoryOutData);
        memoryRead = 0;

        // Caso 2: endereço máximo
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 8'hFF;
        memoryWriteData = 16'h5555;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        @(posedge clk);
        $display("Caso 2 - Addr FF: %h", memoryOutData);
        memoryRead = 0;

        // Caso 3: sobrescrever endereço
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 8'h10;
        memoryWriteData = 16'h1111;
        @(posedge clk);
        memoryWriteData = 16'h2222;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        @(posedge clk);
        $display("Caso 3 - Sobrescrita Addr 10: %h", memoryOutData);
        memoryRead = 0;

        // Caso 4: leitura sem escrita prévia
        @(posedge clk);
        memoryAddress = 8'h20;
        memoryRead = 1;
        @(posedge clk);
        $display("Caso 4 - Leitura sem escrita Addr 20: %h", memoryOutData);
        memoryRead = 0;

        // Caso 5: write e read ao mesmo tempo
        @(posedge clk);
        memoryAddress = 8'h30;
        memoryWriteData = 16'hDEAD;
        memoryWrite = 1;
        memoryRead = 1;
        @(posedge clk);
        $display("Caso 5 - RW simultâneo Addr 30: %h", memoryOutData);
        memoryWrite = 0;
        memoryRead = 0;

        // Caso 6: trocar endereço rápido
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 8'h40;
        memoryWriteData = 16'hAAAA;
        @(posedge clk);
        memoryAddress = 8'h41;
        memoryWriteData = 16'hBBBB;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        memoryAddress = 8'h40;
        @(posedge clk);
        $display("Caso 6 - Addr 40: %h", memoryOutData);

        memoryAddress = 8'h41;
        @(posedge clk);
        $display("Caso 6 - Addr 41: %h", memoryOutData);
        memoryRead = 0;

        // Caso 7: dados zero
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 8'h50;
        memoryWriteData = 0;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        @(posedge clk);
        $display("Caso 7 - Zero Addr 50: %h", memoryOutData);
        memoryRead = 0;

        // Caso 8: dados máximos
        @(posedge clk);
        memoryWrite = 1;
        memoryAddress = 8'h60;
        memoryWriteData = 16'hFFFF;
        @(posedge clk);
        memoryWrite = 0;

        memoryRead = 1;
        @(posedge clk);
        $display("Caso 8 - Max Addr 60: %h", memoryOutData);
        memoryRead = 0;

        $display("Fim dos testes");
        $finish;
    end

endmodule
