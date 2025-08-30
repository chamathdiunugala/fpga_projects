`timescale 1ns / 1ps

module fir_filter(
    input  wire signed [N2-1:0] input_data,
    input  wire CLK,
    input  wire RST,
    input  wire ENABLE,
    output wire signed [N3-1:0] output_data,
    output wire signed [N2-1:0] sampleT
);

    parameter N1 = 8;   // number of taps (coefficients)
    parameter N2 = 16;  // input data bit size
    parameter N3 = 32;  // output data bit size

    // filter coefficients (replace with real ones later)
    wire signed [N1-1:0] b [0:7];
    assign b[0] = 8'b00010000;
    assign b[1] = 8'b00010000;
    assign b[2] = 8'b00010000;
    assign b[3] = 8'b00010000;
    assign b[4] = 8'b00010000;
    assign b[5] = 8'b00010000;
    assign b[6] = 8'b00010000;
    assign b[7] = 8'b00010000;

    // shift register for past samples
    reg signed [N2-1:0] samples [0:6];

    // accumulator for filter output
    reg signed [N3-1:0] output_data_reg;

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            output_data_reg <= 0;
            samples[0] <= 0;
            samples[1] <= 0;
            samples[2] <= 0;
            samples[3] <= 0;
            samples[4] <= 0;
            samples[5] <= 0;
            samples[6] <= 0;
        end 
        else if (ENABLE) begin
            // FIR computation
            output_data_reg <= b[0] * input_data
                             + b[1] * samples[0]
                             + b[2] * samples[1]
                             + b[3] * samples[2]
                             + b[4] * samples[3]
                             + b[5] * samples[4]
                             + b[6] * samples[5]
                             + b[7] * samples[6];

            // shift register update
            samples[0] <= input_data;
            samples[1] <= samples[0];
            samples[2] <= samples[1];
            samples[3] <= samples[2];
            samples[4] <= samples[3];
            samples[5] <= samples[4];
            samples[6] <= samples[5];
        end
    end

    assign output_data = output_data_reg;
    assign sampleT = input_data; // latest input sample

endmodule
