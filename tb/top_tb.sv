// testbench_top.sv
// Testbench for the top module (processor)
// Tests ALU operations, load/store, and error flag

`timescale 1ns / 1ps

module testbench_top;

    // Parameters
    localparam WIDTH = 8;
    localparam WIDTH_ADDRESS = 8;
    localparam N = 4;
    localparam CLK_PERIOD = 10; // ns

    // Signals
    logic clk;
    logic rst;
    logic [6:0] cmd_in;
    logic [WIDTH-1:0] din_1;
    logic [WIDTH-1:0] din_2;
    logic [WIDTH-1:0] din_3;
    logic [WIDTH-1:0] dout_low;
    logic [WIDTH-1:0] dout_high;
    logic cpu_rdy;
    logic zero;
    logic error;

    // Instantiate the top module
    top #(
        .WIDTH(WIDTH),
        .WIDTH_ADDRESS(WIDTH_ADDRESS),
        .N(N)
    ) u_top (
        .clk(clk),
        .rst(rst),
        .cmdin(cmd_in),
        .din_1(din_1),
        .din_2(din_2),
        .din_3(din_3),
        .dout_low(dout_low),
        .dout_high(dout_high),
        .cpu_rdy(cpu_rdy),
        .zero(zero),
        .error(error)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench_top); 
    end

    // Test sequence
    initial begin
        rst = 1;
        cmd_in = 7'b00_00_100; // NOP
        din_1 = 8'd5;
        din_2 = 8'd3;
        din_3 = 8'd10;
        
        // Reset pulse
        repeat(2) @(posedge clk);
        rst = 0;
        
        // Wait for initial RESET state to finish and first instruction to be fetched
        // The first RESET state loads cmd_in into regCMD_IN. Then it goes to FETCH, EXEC, STORE.
        // We need to provide the first instruction during the RESET state.
        // Since we assert rst=0 after 2 cycles, we set cmd_in before that.
        
        // Instruction 1: ADD din_1 (5) + din_2 (3) = 8
        // select A = 00 (din_1), select B = 01 (din_2), opcode ADD = 000
        cmd_in = 7'b00_01_000;  // A=din_1, B=din_2, ADD
        @(posedge clk);
        // Wait for completion of this instruction (cpu_rdy goes high at STORE)
        wait(cpu_rdy == 1);
        @(posedge clk);
        // Check result
        $display("Time %0t: ADD 5+3 = %d (low) %d (high) – expected 8", $time, dout_low, dout_high);
        assert(dout_low == 8'd8) else $error("ADD result wrong!");
        assert(zero == 0) else $error("ADD zero flag wrong!");
        assert(error == 0) else $error("ADD error flag wrong!");
        
        // Instruction 2: SUB din_1 - din_2 = 5-3=2
        cmd_in = 7'b00_01_001;  // A=din_1, B=din_2, SUB
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: SUB 5-3 = %d – expected 2", $time, dout_low);
        assert(dout_low == 8'd2) else $error("SUB result wrong!");
        
        // Instruction 3: MUL din_1 * din_2 = 5*3=15 (fits in low byte)
        cmd_in = 7'b00_01_010;  // A=din_1, B=din_2, MUL
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: MUL 5*3 = %d – expected 15", $time, dout_low);
        assert(dout_low == 8'd15) else $error("MUL result wrong!");
        
        // Instruction 4: DIV din_1 / din_2 = 5/3 = 1 (integer division)
        cmd_in = 7'b00_01_011;  // A=din_1, B=din_2, DIV
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: DIV 5/3 = %d – expected 1", $time, dout_low);
        assert(dout_low == 8'd1) else $error("DIV result wrong!");
        assert(error == 0) else $error("DIV by non‑zero should not set error");
        
        // Instruction 5: DIV by zero -> error must be set
        // Use B = din_3? But din_3=10, not zero. We need a zero operand.
        // We can write a zero into one of the data registers using a previous result or using din_?.
        // Simpler: change din_2 to 0 dynamically (but din_2 is an input, can be changed anytime).
        // However to be realistic, we can store zero into memory and load it, or just change din_2 now.
        // For testbench, we can modify din_2 directly. But the processor may have sampled din_2 already.
        // We need to ensure the DIV instruction sees zero. Let's set din_2=0 before the instruction.
        din_2 = 8'd0;
        @(posedge clk);
        cmd_in = 7'b00_01_011; // A=din_1 (5), B=din_2 (0), DIV
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: DIV 5/0 -> error flag = %b", $time, error);
        assert(error == 1) else $error("Division by zero should set error!");
        
        // Restore din_2 for later tests
        din_2 = 8'd3;
        
        // Instruction 6: LOAD from memory (opcode 101)
        // First, we need to have a valid memory address. Let's use the result of ADD (8) as address.
        // The address comes from regA_out. To control regA_out, we can perform an ADD that writes to regA.
        // The processor already did ADD earlier, but regA_out may have changed. We'll explicitly put address 8 into regA.
        // We can do a dummy ADD with address value? Simpler: use din_1 as address.
        // Set din_1 = 8 (address). Then ADD din_1 + 0? But we need to move address to regA.
        // The ALU result from ADD would go to regCPU_OUT, not to regA. regA is loaded from muxA during FETCH.
        // So we can directly use din_1 = address and select A=din_1, B=anything, and do a NOP? But NOP not defined.
        // Instead, we can use a SUB with zero to pass address through ALU.
        // First, write some data to memory address 8 using STORE.
        // STORE uses regA_out as address, regCPU_OUT as data.
        // So let's store a known value (e.g., 42) at address 8.
        // We'll do: 
        //   a) move address 8 to regA: perform ADD with A=din_1 (8), B=0 (use din_2=0) -> result 8, but result goes to dout, not to regA.
        // Wait, regA is loaded during FETCH from muxA, which selects based on in_select_a. So to set regA, we must have the desired value on the selected input during FETCH.
        // Instead, we can directly use the address from din_1 and use STORE with A=din_1, B=whatever. The address will be taken from regA_out which is loaded from muxA during FETCH of the STORE instruction.
        // So we can do:
        //   Instruction: STORE with A=din_1 (address 8), B=din_2 (data 42). But the data to store comes from regCPU_OUT, which comes from either ALU or memory.
        //   We need to have the data 42 in regCPU_OUT. We can compute it with ALU: e.g., ADD din_2=42 with 0.
        // Let's do two instructions: first compute 42 into regCPU_OUT, then STORE.
        
        // Step 6a: Load data 42 into regCPU_OUT using ADD
        din_1 = 8'd42; // data
        din_2 = 8'd0;
        cmd_in = 7'b00_01_000; // ADD 42+0 = 42
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: ADD 42+0 = %d", $time, dout_low);
        // Now regCPU_OUT = 42
        
        // Step 6b: STORE to address 8 (use din_3 as address source)
        din_3 = 8'd8; // address
        // For STORE, we need A select to be din_3 (address), B select don't care, opcode STORE = 110
        cmd_in = 7'b10_00_110; // A=din_3 (bits 6-5 = 10 -> index 2? Let's check: muxA_in[2]=din_3, yes), B=any, opcode STORE
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: STORE data 42 at address 8", $time);
        
        // Step 6c: LOAD from address 8 (opcode 101)
        // Need A=din_3 (address 8), opcode LOAD
        cmd_in = 7'b10_00_101; // A=din_3, B=any, LOAD
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: LOAD from address 8 -> data = %d (expected 42)", $time, dout_low);
        assert(dout_low == 8'd42) else $error("LOAD result wrong!");
        
        // Instruction 7: STORE to verify memory write and read back
        // Write value 99 to address 5
        // First compute 99
        din_1 = 8'd99;
        din_2 = 8'd0;
        cmd_in = 7'b00_01_000; // ADD 99+0
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        // STORE to address 5
        din_3 = 8'd5;
        cmd_in = 7'b10_00_110; // STORE
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        // LOAD from address 5
        cmd_in = 7'b10_00_101; // LOAD
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: LOAD from address 5 -> data = %d (expected 99)", $time, dout_low);
        assert(dout_low == 8'd99) else $error("STORE/LOAD test failed!");
        
        // Test zero flag: subtract equal numbers -> zero=1
        din_1 = 8'd7;
        din_2 = 8'd7;
        cmd_in = 7'b00_01_001; // SUB
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: SUB 7-7 = %d, zero=%b (expected 1)", $time, dout_low, zero);
        assert(zero == 1) else $error("Zero flag not set on equal subtraction!");
        assert(dout_low == 0) else $error("Subtraction result wrong!");
        
        // Test error flag on division by zero again, but now with a different zero source
        din_1 = 8'd100;
        din_2 = 8'd0;
        cmd_in = 7'b00_01_011; // DIV
        @(posedge clk);
        wait(cpu_rdy == 1);
        @(posedge clk);
        $display("Time %0t: DIV 100/0 -> error=%b (expected 1)", $time, error);
        assert(error == 1) else $error("Division by zero error not detected!");
        
        $display("Testbench finished successfully.");
        $finish;
    end

    // Optional: Monitor memory contents if needed (depends on memory module)
    // We could add a dump of memory if the memory module has a read interface, but not required.

endmodule