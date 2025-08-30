`timescale 1ns/1ps

module number_adder_tb;

    // Testbench signals
    logic [31:0] a, b;
    logic cin;
    logic [31:0] sum;
    logic cout;

    // Instantiate DUT
    number_adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        $display("       a        b   cin |   sum     cout");
        $display("------------------------------------------");

        // Test 1: 0 + 0 + 0
        a = 32'h00000000; b = 32'h00000000; cin = 0; #10;
        $display("%h  %h   %b  |  %h     %b", a, b, cin, sum, cout);

        // Test 2: 5 + 3 + 0
        a = 32'h00000005; b = 32'h00000003; cin = 0; #10;
        $display("%h  %h   %b  |  %h     %b", a, b, cin, sum, cout);

        // Test 3: 200 + 100 + 0
        a = 32'd2000000000; b = 32'd3000000000; cin = 0; #10;
        $display("%h  %h   %b  |  %h     %b", a, b, cin, sum, cout);

        // Test 4: 255 + 1 + 0 (overflow expected)
        a = 32'hFFFFFFFF; b = 32'h00000001; cin = 0; #10;
        $display("%h  %h   %b  |  %h     %b", a, b, cin, sum, cout);

        // Test 5: Random values with cin=1
        a = 32'hAB; b = 32'hCD; cin = 1; #10;
        $display("%h  %h   %b  |  %h     %b", a, b, cin, sum, cout);

        $finish;
    end

endmodule

