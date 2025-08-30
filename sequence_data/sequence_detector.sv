module sequence_detector (
    input  logic clk,
    input  logic rst_n,
    output logic [1:0] led
);

    logic detect;
    logic led_on;

    // test sequence for simulation
    logic [49:0] test_sequence = 50'b10101100101011001010001011011010100011010101010011;
    logic [5:0]  count = 0;
    logic [31:0] time_on = 0;
	 logic [49:0] dout_sequence = 50'b00000001000000010000000010001000000001000100000000;

    // Instantiate the FSM
    state_machine state_machine_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(test_sequence[count]),
        .detect(detect)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count   <= 0;
            led_on  <= 0;
            time_on <= 0;
        end else begin
            // sequence test feeder
            if (count < 50)
                count <= count + 1;
            else
                count <= 0;

            // LED one-second timer
            if (led_on) begin
                if (time_on < 50_000_000 - 1) begin  // 1 second at 50 MHz
                    time_on <= time_on + 1;
                end else begin
                    led_on  <= 0;
                    time_on <= 0;
                end
            end else begin
                led_on <= 0;
            end

            // Start LED timer when detect pulse occurs
            if (detect != dout_sequence[count]) begin
                led_on  <= 1;
                time_on <= 0;
            end
        end
    end
	 
	 assign led[0] = led_on;
	 assign led[1] = detect;
endmodule