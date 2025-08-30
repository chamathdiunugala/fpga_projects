module pipelined_adder(
input  logic [31:0] a,
input  logic [31:0] b,
input  logic cin,
output logic [31:0] sum,
output logic cout,
input clk, rst
);

wire [2:0] c;
wire [23:0] s;
logic [7:0] a1, a2, a3;
logic [7:0] b1, b2, b3, b4;
logic [7:0] c1, c2, c3, c4, c5;
logic [7:0] d1, d2, d3, d4, d5, d6;
logic r1, r2, r3;

eight_bit_adder e1(a[7:0], b[7:0], cin, s[7:0], c[0]);
eight_bit_adder e2(b1, b2, r1, s[15:8], c[1]);
eight_bit_adder e3(c3, c4, r2, s[23:16], c[2]);
eight_bit_adder e4(d5, d6, r3, sum[31:24], cout);

always_ff@(posedge clk or negedge rst)
begin
	if (!rst)
	begin
		a1<=0; a2<=0; a3<=0;
		r1<=0; r2<=0; r3<=0;
		b1<=0; b2<=0; b3<=0; b4<=0;
		c1<=0; c2<=0; c3<=0; c4<=0; c5<=0;
		d1<=0; d2<=0; d3<=0; d4<=0; d5<=0; d6<=0;
	end
	else
	begin
		a1 <= s[7:0];
		a2 <= a1;
		a3 <= a2;
		
		b1 <= a[15:8];
		b2 <= b[15:8];
		r1 <= c[0];
		b3 <= s[15:8];
		b4 <= b3;
		
		c1 <= a[23:16];
		c2 <= b[23:16];
		r2 <= c[1];
		c3 <= c1;
		c4 <= c2;
		c5 <= s[23:16];

		d1 <= a[31:24];
		d2 <= b[31:24];
		r3 <= c[2];
		d3 <= d1;
		d4 <= d2;
		d5 <= d3;
		d6 <= d4;
		
		sum[7:0] <= a3;
		sum[15:8] <= b4;
		sum[23:16] <= c5;
	end
end
		
endmodule