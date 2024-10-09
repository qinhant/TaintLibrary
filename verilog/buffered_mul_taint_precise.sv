`define WIDTH 4
`define MUL_LATENCY 2
`define BUF_LATENCY 3

module MUL(
    input clk,
    input rst,
    input in_valid,
    input in_valid_t,
    input [`WIDTH-1:0] in_a,
    input in_a_t,
    input [`WIDTH-1:0] in_b,
    input in_b_t,
    output out_valid,
    output out_valid_t,
    output [`WIDTH<<1-1:0] out_result,
    output out_result_t
);

reg [`WIDTH<<1-1:0] out_result;
reg out_result_t;
reg [2:0] cnt;
reg cnt_t;
reg busy;
reg busy_t;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        busy <= 0;

        cnt_t <= 0;
        busy_t <= 0;
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

    cnt_t <= in_valid_t || busy_t || cnt_t;
    out_result_t <= in_a_t || in_b_t || out_result_t;
    busy_t <= cnt_t || in_a_t || in_b_t || busy_t;
end

assign out_valid = ((cnt == `MUL_LATENCY || in_a == 0 || in_b == 0) && busy);
assign out_valid_t = cnt_t || in_a_t || in_b_t || busy_t;


endmodule

module buffer(
    input clk,
    input rst,
    input in_valid,
    input in_valid_t,
    input [`WIDTH<<1-1:0] in_data,
    input in_data_t,
    output out_valid,
    output out_valid_t,
    output [`WIDTH<<1-1:0] out_data,
    output out_data_t
);

reg [`WIDTH-1:0] out_data;
reg out_data_t;
reg [2:0] cnt;
reg cnt_t;
reg busy;
reg busy_t;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        busy <= 0;

        cnt_t <= 0;
        busy_t <= 0;
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

    cnt_t <= in_valid_t || busy_t || cnt_t;
    out_data_t <= in_data_t || out_data_t;
    busy_t <= cnt_t || in_data_t || busy_t;
end

assign out_valid = ((cnt == `BUF_LATENCY || (in_data == 0)) && busy);
assign out_valid_t = cnt_t || in_data_t || busy_t;

endmodule


// This is the top module, it first computes the multiplication and then buffers the result
// Question: is there any information flow from the input operands to the out_valid signal?
module buffered_mul_taint(
    input clk,
    input rst,
    input in_valid,
    input in_valid_t,
    input [`WIDTH-1:0] in_a,
    input in_a_t,
    input [`WIDTH-1:0] in_b,
    input in_b_t,
    output out_valid,
    output out_valid_t,
    output [`WIDTH<<1-1:0] out_result,
    output out_result_t
);

wire mul_valid;
wire mul_valid_t;
wire [`WIDTH<<1-1:0] mul_result;
wire mul_result_t;
wire buff_valid_t;

// out_valid_t is untainted if MUL_LATENCY and BUF_LATENCY are the same
if (`MUL_LATENCY == `BUF_LATENCY) begin
    assign out_valid_t = 0;
end
else begin
    assign out_valid_t = buff_valid_t;
end

MUL mul(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in_valid_t(in_valid_t),
    .in_a(in_a),
    .in_a_t(in_a_t),
    .in_b(in_b),
    .in_b_t(in_b_t),
    .out_valid(mul_valid),
    .out_valid_t(mul_valid_t),
    .out_result(mul_result),
    .out_result_t(mul_result_t)
);

buffer buff(
    .clk(clk),
    .rst(rst),
    .in_valid(mul_valid),
    .in_valid_t(mul_valid_t),
    .in_data(mul_result),
    .in_data_t(mul_result_t),
    .out_valid(out_valid),
    .out_valid_t(buff_valid_t),
    .out_data(out_result),
    .out_data_t(out_result_t)
);

endmodule