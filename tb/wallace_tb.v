// =============================================================================
// Module      : wallace_tb
// Description : Clocked testbench for the 8x8 Wallace Tree Multiplier.
//               Generates waveform with: clk, rst_n, a, b, p, valid_out
//
// Waveform Output: sim/wallace_wave.vcd  (open with GTKWave)
//
// Simulate:
//   iverilog -o sim/wallace_tb tb/wallace_tb.v rtl/wallace_top.v \
//            rtl/partial_product.v rtl/full_adder.v rtl/half_adder.v
//   vvp sim/wallace_tb
// =============================================================================

`timescale 1ns/1ps

module wallace_tb;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter CLK_PERIOD   = 10;    // 10 ns = 100 MHz
    parameter RST_CYCLES   = 3;     // Reset for 3 clock cycles
    parameter RANDOM_TESTS = 20;    // Random test vectors

    // =========================================================================
    // DUT Signals
    // =========================================================================
    reg         clk;
    reg         rst_n;
    reg         valid_in;
    reg  [7:0]  a;
    reg  [7:0]  b;
    wire [15:0] p;
    wire        valid_out;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    wallace_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .a         (a),
        .b         (b),
        .p         (p),
        .valid_out (valid_out)
    );

    // =========================================================================
    // Clock Generation  (10 ns period)
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // VCD Waveform Dump
    // =========================================================================
    initial begin
        $dumpfile("sim/wallace_wave.vcd");
        // Dump ONLY the 6 signals you want to see in GTKWave
        $dumpvars(0, clk);
        $dumpvars(0, rst_n);
        $dumpvars(0, valid_in);
        $dumpvars(0, a);
        $dumpvars(0, b);
        $dumpvars(0, p);
        $dumpvars(0, valid_out);
    end

    // =========================================================================
    // 2-deep shift register to track applied inputs through the pipeline
    // DUT has 2-cycle latency: inputs register -> compute -> output register
    // =========================================================================
    reg [7:0]  a_d1, a_d2;
    reg [7:0]  b_d1, b_d2;
    reg        vld_d1, vld_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1   <= 0; a_d2   <= 0;
            b_d1   <= 0; b_d2   <= 0;
            vld_d1 <= 0; vld_d2 <= 0;
        end else begin
            a_d1   <= a;       a_d2   <= a_d1;
            b_d1   <= b;       b_d2   <= b_d1;
            vld_d1 <= valid_in; vld_d2 <= vld_d1;
        end
    end

    // =========================================================================
    // Bookkeeping
    // =========================================================================
    integer  pass_count;
    integer  fail_count;
    reg [15:0] expected;
    reg [7:0]  rand_a, rand_b;

    initial begin
        pass_count = 0;
        fail_count = 0;
    end

    // =========================================================================
    // Output Checker — fires every cycle when valid_out is high
    // =========================================================================
    always @(posedge clk) begin
        if (valid_out) begin
            expected = a_d2 * b_d2;   // 2-cycle delayed inputs
            if (p === expected) begin
                pass_count = pass_count + 1;
                $display("[%0t ns] PASS: 0x%02X * 0x%02X = 0x%04X",
                         $time, a_d2, b_d2, p);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t ns] FAIL: 0x%02X * 0x%02X | expected=0x%04X got=0x%04X",
                         $time, a_d2, b_d2, expected, p);
            end
        end
    end

    // =========================================================================
    // Task: apply_vector  — drives one vector on rising clock edge
    // =========================================================================
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

    // =========================================================================
    // Main Stimulus
    // =========================================================================
    integer n;

    initial begin

        // ----- Initialise -----
        rst_n    = 1'b0;
        valid_in = 1'b0;
        a        = 8'h00;
        b        = 8'h00;

        $display("=============================================================");
        $display("  8x8 Wallace Tree Multiplier — Clocked Waveform Testbench  ");
        $display("=============================================================");
        $display("  CLK Period : %0d ns  |  Reset : %0d cycles", CLK_PERIOD, RST_CYCLES);
        $display("=============================================================\n");

        // =====================================================================
        // 1.  Reset
        // =====================================================================
        repeat (RST_CYCLES) @(posedge clk);
        #1;
        rst_n = 1'b1;
        $display("[%0t ns] Reset released.\n", $time);

        // =====================================================================
        // 2.  Directed Test Vectors  (visible on waveform as distinct hex values)
        // =====================================================================
        $display("[1] Directed Vectors:");
        apply_vector(8'hA5, 8'h3C);  // 165 * 60  = 9900  = 0x26AC
        apply_vector(8'hFF, 8'h7F);  // 255 * 127 = 32385 = 0x7E81
        apply_vector(8'h1E, 8'h1E);  //  30 *  30 = 900   = 0x0384
        apply_vector(8'h3C, 8'h33);  //  60 *  51 = 3060  = 0x0BF4
        apply_vector(8'h0F, 8'hF0);  //  15 * 240 = 3600  = 0x0E10
        apply_vector(8'h01, 8'hFF);  //   1 * 255 = 255   = 0x00FF
        apply_vector(8'h10, 8'h10);  //  16 *  16 = 256   = 0x0100
        apply_vector(8'hAA, 8'h55);  // 170 *  85 = 14450 = 0x3872
        apply_vector(8'h80, 8'h80);  // 128 * 128 = 16384 = 0x4000
        apply_vector(8'h12, 8'h34);  //  18 *  52 = 936   = 0x03A8
        apply_vector(8'hDE, 8'hAD);  // 222 * 173 = 38406 = 0x95E6
        apply_vector(8'hBE, 8'hEF);  // 190 * 239 = 45410 = 0xB162

        valid_in = 1'b0;

        // Let pipeline drain (2 extra cycles)
        @(posedge clk); @(posedge clk);

        $display("");

        // =====================================================================
        // 3.  Random Tests
        // =====================================================================
        $display("[2] Random Vectors:");
        repeat (RANDOM_TESTS) begin
            rand_a = $random;
            rand_b = $random;
            apply_vector(rand_a, rand_b);
        end
        valid_in = 1'b0;

        // Let pipeline drain
        @(posedge clk); @(posedge clk); @(posedge clk);

        // =====================================================================
        // 4.  Summary
        // =====================================================================
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

    // =========================================================================
    // Timeout watchdog
    // =========================================================================
    initial begin
        #100_000;
        $display("[TIMEOUT] Aborting simulation.");
        $finish;
    end

endmodule
