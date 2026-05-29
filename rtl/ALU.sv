module ALU #(
    WIDTH = 8
) (
    input [WIDTH-1:0] in1, in2,
    input [3:0] op,
    input nvalid_data,
    output logic signed [2*WIDTH-1:0] out,
    output logic zero,
    output logic error
);
    localparam SH_MAX_WIDTH = $clog2(WIDTH);


    logic zero_in2;
    assign zero = ~(|out);
    assign zero_in2 = ~(|in2);
    assign error = (op ==4'b0011 & zero_in2) | nvalid_data;

    logic signed [2*WIDTH-1:0] sin1, sin2;

    assign sin1 = signed'(in1); // extensão para signed (complemento de dois)
    assign sin2 = signed'(in2); // extensão para signed (complemento de dois)

    always_comb begin
        if (nvalid_data == 1'b0) begin
            case (op)
                4'b0000: out = sin1 + sin2; // ADD (signed)
                4'b0001: out = sin1 - sin2; // SUB (signed)
                4'b0010: out = sin1 * sin2; // MUL (signed)
                4'b0011: out = (zero_in2) ? -1 : sin1 / sin2; //cometi um erro aqui, não podia atribuir FFFF, pois 
                                                            //ele entende isso como sem sinal e faz uma conversão em cima disso
                default: out = sin2;
            endcase
        end else begin
            out = -1;
        end
    end

endmodule
