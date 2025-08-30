module timer(
    input  logic clk,
    input  logic rst_n,
    output logic led
);

    logic [31:0] counter;
    logic clock;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clock   <= 0;   // reset clock properly
        end
        else begin
            if (counter < 25_000_000 - 1) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 0;
                clock   <= ~clock;
            end
        end
    end

    assign led = clock;

endmodule
