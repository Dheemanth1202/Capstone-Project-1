module partial_product (
    input  wire [7:0] a,         
    input  wire [7:0] b,         
    output wire [7:0] pp0,       
    output wire [7:0] pp1,       
    output wire [7:0] pp2,      
    output wire [7:0] pp3,       
    output wire [7:0] pp4,       
    output wire [7:0] pp5,       
    output wire [7:0] pp6,       
    output wire [7:0] pp7        
);


    assign pp0 = a & {8{b[0]}};
    assign pp1 = a & {8{b[1]}};
    assign pp2 = a & {8{b[2]}};
    assign pp3 = a & {8{b[3]}};
    assign pp4 = a & {8{b[4]}};
    assign pp5 = a & {8{b[5]}};
    assign pp6 = a & {8{b[6]}};
    assign pp7 = a & {8{b[7]}};

endmodule
