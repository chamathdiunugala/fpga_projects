module led_blink (
    input  wire clk,        // 50 MHz input clock on DE2-115
    output reg  led
);

    reg [31:0] counter;

    always @(posedge clk) begin
            if (counter >= 25000000) begin
                counter <= 0;
                led     <= ~led;
            end else begin
                counter <= counter + 1;
            end
    end

endmodule
