module adder_test(
    input  logic clk,
    input  logic rst_n,
    output logic led,
    output logic time_count
);

    logic clock;
    logic [31:0] num_a, num_b, sum;
    logic cin, cout;
    logic [4:0] count;

    // Generate slower clock
    timer timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .led(clock)    // use divided clock as "clock"
    );

    // DUT
    number_adder number_adder_inst (
        .a(num_a),
        .b(num_b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    // Generate test vectors
    always_ff @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            num_a <= 32'b0;
            num_b <= 32'b0;
            cin   <= 1'b0;
        end else begin
            if (count < 20) begin
                count <= count + 1;
                num_a <= num_b + count * 8'b10111010;
                num_b <= num_a + count * 8'b11010110;
                cin   <= ~cin;
            end else begin
                count <= 0;
            end
        end
    end

    // Compare DUT output against expected result
 always_ff @(posedge clock or negedge rst_n) begin
    if (!rst_n) begin
        led <= 0;
    end else begin
        if ({cout, sum} != (num_a + num_b))
            led <= 0;   // error
        else
            led <= 1;   // OK
    end
end

	 
	 assign time_count = clock;

endmodule
