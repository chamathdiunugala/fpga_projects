`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2025 06:42:50 PM
// Design Name: 
// Module Name: fir_filter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_filter_tb;
parameter N1 = 8;
parameter N2 = 16;
parameter N3 = 32;

reg CLK;
reg RST;
reg ENABLE;
reg [N2-1:0] input_data;

reg [N2-1:0] data[99:0];

wire [N3-1:0] output_data;
wire [N2-1:0] sampleT;

fir_filter UUT(
    .input_data(input_data),
    .output_data(output_data),
    .CLK(CLK),
    .RST(RST),
    .ENABLE(ENABLE),
    .sampleT(sampleT)
);

integer k;
integer FILE1;

always #10 CLK = ~CLK;

initial begin
    k = 0;
    $readmemb("input.data", data);
    
    FILE1 = $fopen("save.data","w");
    
    CLK =0;
    #20
    
    RST = 1'b0;
    #40
    
    RST = 1'b1;
    ENABLE = 1'b1;
    
    input_data <= data[k];
    #10
    for (k = 1; k < 100; k = k+1) begin
        @(posedge CLK);
        $fdisplay(FILE1, "%b", output_data);
        input_data <= data[k];
        if (k == 99)
        $fclose(FILE1);
    end
end

endmodule
