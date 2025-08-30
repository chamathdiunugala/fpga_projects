`timescale 1ns / 1ps

module traffic_light_controller_tb;

// Clock and reset signals
reg clk;
reg rst;

// Output signals from DUT
wire [2:0] f1, f2, f3, f4;
wire [2:0] r1, r2, r3, r4;
wire [2:0] l1, l2, l3, l4;
wire [2:0] c1, c2, c3, c4;

// Instantiate the Device Under Test (DUT)
traffic_light_controller dut (
    .clk(clk),
    .rst(rst),
    .f1(f1), .f2(f2), .f3(f3), .f4(f4),
    .r1(r1), .r2(r2), .r3(r3), .r4(r4),
    .l1(l1), .l2(l2), .l3(l3), .l4(l4),
    .c1(c1), .c2(c2), .c3(c3), .c4(c4)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period (100MHz)
end

// Test sequence
initial begin
    $dumpfile("traffic_light_tb.vcd");
    $dumpvars(0, traffic_light_controller_tb);
    
    // Initialize
    rst = 0;
    #20;
    
    // Release reset and observe operation
    rst = 1;
    
    // Run simulation for enough time to see multiple state transitions
    #2000;
    
    // Test reset during operation
    rst = 0;
    #20;
    rst = 1;
    #1000;
    
    $display("Testbench completed successfully");
    $finish;
end

// Monitor to display state changes
always @(posedge clk) begin
    $display("Time: %0t | State: %s | f1:%b f2:%b f3:%b f4:%b | Count: %0d", 
             $time, dut.current_state.name(), f1, f2, f3, f4, dut.count);
end

endmodule
