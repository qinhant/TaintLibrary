`define WIDTH 4
`define MUL_LATENCY 2
`define BUF_LATENCY 2

module MUL(
    input clk,
    input rst,
    input in_valid,
    input [`WIDTH-1:0] in_a,
    input [`WIDTH-1:0] in_b,
    output out_valid,
    output [`WIDTH<<1-1:0] out_result
);
reg [`WIDTH<<1-1:0] out_result;
reg [2:0] cnt;
reg busy;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        busy <= 0;
    end else begin
    if (in_valid && !busy) begin
        cnt <= 1;
        out_result <= in_a * in_b;
    end 
    // If the operand is 0, then the multiplication takes 1 cycle, otherwise it takes multiple cycles
    else if ((cnt == `MUL_LATENCY || in_a == 0 || in_b == 0) && busy) begin
        busy <= 0;
    end
    else if (busy) begin
        cnt <= cnt + 1;
    end
    end
end

assign out_valid = ((cnt == `MUL_LATENCY || in_a == 0 || in_b == 0) && busy);


endmodule

module buffer(
    input clk,
    input rst,
    input in_valid,
    input [`WIDTH<<1-1:0] in_data,
    output out_valid,
    output [`WIDTH<<1-1:0] out_data
)

reg [`WIDTH-1:0] out_data;
reg [2:0] cnt;
reg busy;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        busy <= 0;
    end else begin
    if (in_valid && !busy) begin
        cnt <= 1;
        out_data <= in_data;
    end 
    // If the input data is not 0, then the buffer takes 1 cycle, otherwise it takes multiple cycles
    else if ((cnt == `BUF_LATENCY || (in_data != 0)) && busy) begin
        busy <= 0;
    end
    else if (busy) begin
        cnt <= cnt + 1;
    end
    end
end

assign out_valid = ((cnt == `BUF_LATENCY || (in_data == 0)) && busy);

endmodule


// This is the top module, it first computes the multiplication and then buffers the result
// Question: is there any information flow from the input operands to the out_valid signal?
module buffered_mul(
    input clk,
    input rst,
    input in_valid,
    input [`WIDTH-1:0] in_a,
    input [`WIDTH-1:0] in_b,
    output out_valid,
    output [`WIDTH<<1-1:0] out_result
);

wire mul_valid;
wire [`WIDTH<<1-1:0] mul_result;


MUL mul(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in_a(in_a),
    .in_b(in_b),
    .out_valid(mul_valid),
    .out_result(mul_result)
);

buffer buf(
    .clk(clk),
    .rst(rst),
    .in_valid(mul_valid),
    .in_data(mul_result),
    .out_valid(out_valid),
    .out_data(out_result)
);

endmodule