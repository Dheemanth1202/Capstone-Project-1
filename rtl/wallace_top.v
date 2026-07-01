module wallace_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [15:0] p,
    output reg         valid_out
);


    reg [7:0] a_reg, b_reg;
    reg       valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg     <= 8'h00;
            b_reg     <= 8'h00;
            valid_reg <= 1'b0;
        end else begin
            a_reg     <= a;
            b_reg     <= b;
            valid_reg <= valid_in;
        end
    end


    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;

    partial_product u_pp (
        .a(a_reg), .b(b_reg),
        .pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3),
        .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7)
    );


    wire [14:0] row0 = {7'b0, pp0};
    wire [14:0] row1 = {6'b0, pp1, 1'b0};
    wire [14:0] row2 = {5'b0, pp2, 2'b0};
    wire [14:0] row3 = {4'b0, pp3, 3'b0};
    wire [14:0] row4 = {3'b0, pp4, 4'b0};
    wire [14:0] row5 = {2'b0, pp5, 5'b0};
    wire [14:0] row6 = {1'b0, pp6, 6'b0};
    wire [14:0] row7 = {      pp7, 7'b0};


    wire [14:0] sum_A, car_A_raw;
    genvar k;
    generate
        for (k = 0; k < 15; k = k + 1) begin : CSA_A
            full_adder FA (.a(row0[k]), .b(row1[k]), .cin(row2[k]),
                           .sum(sum_A[k]), .cout(car_A_raw[k]));
        end
    endgenerate
    wire [15:0] car_A = {car_A_raw, 1'b0};

    wire [14:0] sum_B, car_B_raw;
    generate
        for (k = 0; k < 15; k = k + 1) begin : CSA_B
            full_adder FB (.a(row3[k]), .b(row4[k]), .cin(row5[k]),
                           .sum(sum_B[k]), .cout(car_B_raw[k]));
        end
    endgenerate
    wire [15:0] car_B = {car_B_raw, 1'b0};


    wire [15:0] sum_A16 = {1'b0, sum_A};
    wire [15:0] sum_B16 = {1'b0, sum_B};
    wire [15:0] sum_C, car_C_raw;
    generate
        for (k = 0; k < 16; k = k + 1) begin : CSA_C
            full_adder FC (.a(sum_A16[k]), .b(car_A[k]), .cin(sum_B16[k]),
                           .sum(sum_C[k]), .cout(car_C_raw[k]));
        end
    endgenerate
    wire [16:0] car_C = {car_C_raw, 1'b0};

    wire [15:0] row6_16 = {1'b0, row6};
    wire [15:0] row7_16 = {1'b0, row7};
    wire [15:0] sum_D, car_D_raw;
    generate
        for (k = 0; k < 16; k = k + 1) begin : CSA_D
            full_adder FD (.a(car_B[k]), .b(row6_16[k]), .cin(row7_16[k]),
                           .sum(sum_D[k]), .cout(car_D_raw[k]));
        end
    endgenerate
    wire [16:0] car_D = {car_D_raw, 1'b0};


    reg [15:0] sum_C_reg;
    reg [16:0] car_C_reg;
    reg [15:0] sum_D_reg;
    reg [16:0] car_D_reg;
    reg        valid_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_C_reg  <= 16'h0000;
            car_C_reg  <= 17'h00000;
            sum_D_reg  <= 16'h0000;
            car_D_reg  <= 17'h00000;
            valid_reg2 <= 1'b0;
        end else begin
            sum_C_reg  <= sum_C;
            car_C_reg  <= car_C;
            sum_D_reg  <= sum_D;
            car_D_reg  <= car_D;
            valid_reg2 <= valid_reg;
        end
    end




    wire [16:0] sum_C17 = {1'b0, sum_C_reg};
    wire [16:0] sum_D17 = {1'b0, sum_D_reg};
    wire [16:0] sum_E, car_E_raw;
    generate
        for (k = 0; k < 17; k = k + 1) begin : CSA_E
            full_adder FE (.a(sum_C17[k]), .b(car_C_reg[k]), .cin(sum_D17[k]),
                           .sum(sum_E[k]), .cout(car_E_raw[k]));
        end
    endgenerate
    wire [17:0] car_E = {car_E_raw, 1'b0};


    wire [17:0] sum_E18 = {1'b0, sum_E};
    wire [17:0] sum_F, car_F_raw;
    generate
        for (k = 0; k < 18; k = k + 1) begin : CSA_F
            full_adder FF (.a(sum_E18[k]), .b(car_E[k]), .cin(car_D_reg[k]),
                           .sum(sum_F[k]), .cout(car_F_raw[k]));
        end
    endgenerate
    wire [18:0] car_F = {car_F_raw, 1'b0};


    wire [15:0] product_comb = sum_F[15:0] + car_F[15:0];


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p         <= 16'h0000;
            valid_out <= 1'b0;
        end else begin
            p         <= product_comb;
            valid_out <= valid_reg2;
        end
    end

endmodule