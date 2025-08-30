module number_adder(
input  logic [31:0] a,
input  logic [31:0] b,
input  logic cin,
output logic [31:0] sum,
output logic cout
);

	wire [2:0] c;

	eight_bit_adder e1(a[7:0], b[7:0], cin, sum[7:0], c[0]);
	eight_bit_adder e2(a[15:8], b[15:8], c[0], sum[15:8], c[1]);
	eight_bit_adder e3(a[23:16], b[23:16], c[1], sum[23:16], c[2]);
	eight_bit_adder e4(a[31:24], b[31:24], c[2], sum[31:24], cout);

endmodule