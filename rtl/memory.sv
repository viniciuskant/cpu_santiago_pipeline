module memory #(
    parameter WIDTH = 8,
    parameter WIDTH_ADDRESS = 8
) (
    input clk,
    input memoryWrite,
    input memoryRead,
    input [WIDTH-1:0] memoryWriteData,
    input [WIDTH_ADDRESS-1:0] memoryAddress,

    output logic [2*WIDTH-1:0] memoryOutData
);

    logic [2*WIDTH-1:0] mem [0:(1<<WIDTH_ADDRESS)-1];

    always_ff @(posedge clk) begin
        if (memoryWrite) begin
            mem[memoryAddress] <= memoryWriteData;
        end
    end

    always_comb begin
        if (memoryRead)
            memoryOutData = mem[memoryAddress];
        else
            memoryOutData = '0;
    end


endmodule
