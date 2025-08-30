
module uart_rx #(
    parameter CLKS_PER_BIT = 5208   // For 9600 baud @ 50 MHz clock: 50e6/9600 ? 5208
)(
    input  wire       clk,              // System clock
    input  wire       i_rx,             // Serial RX line
    output reg [7:0]  o_data,           // Received byte
    output reg        o_data_available  // Strobe: High when new byte is ready
);

    // FSM states
    localparam [2:0] 
        IDLE    = 3'b000,
        START   = 3'b001,
        DATA    = 3'b010,
        STOP    = 3'b011,
        CLEANUP = 3'b100;

    // Input buffering (double-register to avoid metastability)
    reg rx_sync1 = 1'b1;
    reg rx_sync2 = 1'b1;

    always @(posedge clk) begin
        rx_sync1 <= i_rx;
        rx_sync2 <= rx_sync1;
    end

    // Internal registers
    reg [2:0] state      = IDLE;
    reg [12:0] counter   = 0;       // enough bits to count up to CLKS_PER_BIT
    reg [2:0] bit_index  = 0;       // tracks which bit (0-7) is being received
    reg [7:0] rx_shift   = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                o_data_available <= 1'b0;
                counter <= 0;
                bit_index <= 0;
                if (rx_sync2 == 1'b0)  // Start bit detected
                    state <= START;
            end

            START: begin
                if (counter == (CLKS_PER_BIT/2)) begin
                    if (rx_sync2 == 1'b0) begin
                        counter <= 0;
                        state <= DATA;
                    end else begin
                        state <= IDLE;  // False start, go back
                    end
                end else begin
                    counter <= counter + 1;
                end
            end

            DATA: begin
                if (counter < CLKS_PER_BIT-1) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    rx_shift[bit_index] <= rx_sync2; // sample bit
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                if (counter < CLKS_PER_BIT-1) begin
                    counter <= counter + 1;
                end else begin
                    o_data <= rx_shift;
                    o_data_available <= 1'b1;  // one-cycle strobe
                    counter <= 0;
                    state <= CLEANUP;
                end
            end

            CLEANUP: begin
                state <= IDLE;  // wait for next byte
            end

            default: state <= IDLE;
        endcase
    end
endmodule
