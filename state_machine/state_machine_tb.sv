`timescale 1ns/1ps

module state_machine_tb;

    logic clk;
    logic rst_n;
    logic din;
    logic detect;

    // Instantiate DUT
    state_machine dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .detect(detect)
    );

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns period
    end

    // Task to apply one bit per clock
    task send_bit(input logic bitval);
        begin
            din = bitval;
            @(posedge clk); // wait one cycle
            $display("[%0t] din=%0b detect=%0b", $time, din, detect);
        end
    endtask

    initial begin
        // Initialize
        rst_n = 0;
        din   = 0;
        repeat (2) @(posedge clk); // hold reset for 2 cycles
        rst_n = 1;

        $display("Starting sequence detection test...");

        // Test sequence: 0 1 1 0 1 1 0 (should detect twice)
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0); // detect here
        send_bit(1);
        send_bit(1);
        send_bit(0); // detect here

        // Extra test: random bits
        send_bit(0);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0); // detect here

        $display("Test completed.");
        $finish;
    end

endmodule
