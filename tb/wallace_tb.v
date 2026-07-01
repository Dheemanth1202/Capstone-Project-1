`timescale 1ns/1ps

module wallace_tb;


    parameter CLK_PERIOD   = 10;    // 10 ns = 100 MHz
    parameter RST_CYCLES   = 3;     // Reset for 3 clock cycles
    parameter RANDOM_TESTS = 20;    // Random test vectors


    reg         clk;
    reg         rst_n;
    reg         valid_in;
    reg  [7:0]  a;
    reg  [7:0]  b;
    wire [15:0] p;
    wire        valid_out;

    wallace_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .a         (a),
        .b         (b),
        .p         (p),
        .valid_out (valid_out)
    );


    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;


    initial begin
        $dumpfile("sim/wallace_wave.vcd");

        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, valid_in);
        $dumpvars(0, a);
        $dumpvars(0, b);
        $dumpvars(0, p);
        $dumpvars(0, valid_out);
    end


    reg [7:0]  a_d1, a_d2, a_d3;
    reg [7:0]  b_d1, b_d2, b_d3;
    reg        vld_d1, vld_d2, vld_d3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1   <= 0; a_d2   <= 0; a_d3   <= 0;
            b_d1   <= 0; b_d2   <= 0; b_d3   <= 0;
            vld_d1 <= 0; vld_d2 <= 0; vld_d3 <= 0;
        end else begin
            a_d1   <= a;       a_d2   <= a_d1;   a_d3   <= a_d2;
            b_d1   <= b;       b_d2   <= b_d1;   b_d3   <= b_d2;
            vld_d1 <= valid_in; vld_d2 <= vld_d1; vld_d3 <= vld_d2;
        end
    end


    integer  pass_count;
    integer  fail_count;
    reg [15:0] expected;
    reg [7:0]  rand_a, rand_b;

    initial begin
        pass_count = 0;
        fail_count = 0;
    end


    always @(posedge clk) begin
        if (valid_out) begin
            expected = a_d3 * b_d3;   // 3-cycle delayed inputs
            if (p === expected) begin
                pass_count = pass_count + 1;
                $display("[%0t ns] PASS: 0x%02X * 0x%02X = 0x%04X",
                         $time, a_d3, b_d3, p);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t ns] FAIL: 0x%02X * 0x%02X | expected=0x%04X got=0x%04X",
                         $time, a_d3, b_d3, expected, p);
            end
        end
    end


    task apply_vector;
        input [7:0] in_a;
        input [7:0] in_b;
        begin
            @(posedge clk);
            #1;
            a        = in_a;
            b        = in_b;
            valid_in = 1'b1;
        end
    endtask


    integer n;

    initial begin


        rst_n    = 1'b0;
        valid_in = 1'b0;
        a        = 8'h00;
        b        = 8'h00;

        $display("=============================================================");
        $display("  8x8 Wallace Tree Multiplier — Clocked Waveform Testbench  ");
        $display("=============================================================");
        $display("  CLK Period : %0d ns  |  Reset : %0d cycles", CLK_PERIOD, RST_CYCLES);
        $display("=============================================================\n");


        repeat (RST_CYCLES) @(posedge clk);
        #1;
        rst_n = 1'b1;
        $display("[%0t ns] Reset released.\n", $time);


        $display("[1] Directed Vectors:");
        apply_vector(8'hA5, 8'h3C); 
        apply_vector(8'hFF, 8'h7F);
        apply_vector(8'h1E, 8'h1E); 
        apply_vector(8'h3C, 8'h33);  
        apply_vector(8'h0F, 8'hF0);  
        apply_vector(8'h01, 8'hFF); 
        apply_vector(8'h10, 8'h10); 
        apply_vector(8'hAA, 8'h55);  
        apply_vector(8'h80, 8'h80);  
        apply_vector(8'h12, 8'h34); 
        apply_vector(8'hDE, 8'hAD);  
        apply_vector(8'hBE, 8'hEF);  

        valid_in = 1'b0;


        @(posedge clk); @(posedge clk); @(posedge clk);

        $display("");


        $display("[2] Random Vectors:");
        repeat (RANDOM_TESTS) begin
            rand_a = $random;
            rand_b = $random;
            apply_vector(rand_a, rand_b);
        end
        valid_in = 1'b0;


        @(posedge clk); @(posedge clk); @(posedge clk); @(posedge clk);


        $display("\n=============================================================");
        $display("  SIMULATION COMPLETE");
        $display("  Total Pass : %0d", pass_count);
        $display("  Total Fail : %0d", fail_count);
        if (fail_count == 0)
            $display("  RESULT     : *** PASS ***");
        else
            $display("  RESULT     : *** FAIL ***");
        $display("  Waveform   : sim/wallace_wave.vcd  (open with GTKWave)");
        $display("=============================================================");

        $finish;
    end


    initial begin
        #100_000;
        $display("[TIMEOUT] Aborting simulation.");
        $finish;
    end

endmodule
