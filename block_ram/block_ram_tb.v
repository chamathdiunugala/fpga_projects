module block_ram_tb;

    reg clk = 0;
    reg we;
    reg [7:0] addr;
    reg [7:0] din;
    wire [7:0] dout;

    block_ram #(8, 8) uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    always #5 clk = ~clk; // 100 MHz clock

    initial begin
        // Write some values
        we = 1; addr = 8'h00; din = 8'hAA; @(posedge clk);
        we = 1; addr = 8'h01; din = 8'h55; @(posedge clk);
        we = 1; addr = 8'h02; din = 8'hFF; @(posedge clk);
        
        // Stop writing
        we = 0;
        
        // Read them back
        addr = 8'h00; @(posedge clk);
        $display("Addr 0: %h", dout);
        addr = 8'h01; @(posedge clk);
        $display("Addr 1: %h", dout);
        addr = 8'h02; @(posedge clk);
        $display("Addr 2: %h", dout);

        $stop;
    end
endmodule

