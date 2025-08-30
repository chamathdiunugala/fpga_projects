module uart (
    input CLOCK_50,           // 50MHz clock input on DE2-115
    input GPIO,               // GPIO pin for UART RX
    output [8:0] LEDR        // Red LEDs
);

    // UART signals
    wire [7:0] uart_data;
    wire uart_data_available;
    
    // Register to hold LED display
    reg [7:0] led_data = 8'h00;
    
    // Instantiate UART receiver
    uart_rx #(
        .CLKS_PER_BIT(434)    // 115200 baud @ 50MHz
    ) uart_rx_inst (
        .clk(CLOCK_50),
        .i_rx(GPIO),
        .o_data(uart_data),
        .o_data_available(uart_data_available)
    );
    
    // Update LEDs when new data arrives
    always_ff @(posedge CLOCK_50) begin
        if (uart_data_available) begin
            led_data <= uart_data;
        end
    end
    
    // Connect to LEDs
    assign LEDR[7:0] = led_data;           // Data on lower 8 LEDs
    assign LEDR[8] = uart_data_available;  // Data available directly to LED 8
endmodule

module uart_rx #(
    parameter CLKS_PER_BIT = 434 // 115200 baud @ 50 MHz - FIXED: added default value
)(
    input  clk,                  // system clock
    input  i_rx,                 // UART RX input
    output logic [7:0] o_data,   // received byte
    output logic o_data_available // goes high when byte is ready
);

    // State encoding
    localparam IDLE    = 2'b00;
    localparam START   = 2'b01;
    localparam RECEIVE = 2'b10;
    localparam STOP    = 2'b11;

    // Synchronizer
    logic rx_buffer = 1'b1;
    logic rx = 1'b1;

    // Internal registers
    logic [1:0] state = IDLE;
    logic [31:0] counter = 0;
    logic [2:0] bit_index = 0;
    logic [7:0] data = 0;
    logic data_available = 0;

    assign o_data = data;
    assign o_data_available = data_available;

    // Input synchronizer
    always_ff @(posedge clk) begin
        rx_buffer <= i_rx;
        rx        <= rx_buffer;
    end

    // UART FSM
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                counter <= 0;
                data_available <= 0;
                bit_index <= 0;
                if (rx == 0) begin
                    state <= START;
                end else begin
                    state <= IDLE;
                end
            end

            START: begin
                if (counter == (CLKS_PER_BIT - 1)/2) begin
                    if (rx == 0) begin
                        counter <= 0;
                        state <= RECEIVE;
                    end else begin
                        counter <= 0;
                        state <= IDLE;
                    end
                end else begin
                    counter <= counter + 1;
                    state <= START;
                end
            end

            RECEIVE: begin
                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 1;
                    state <= RECEIVE;
                end else begin
                    counter <= 0;
                    data[bit_index] <= rx;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                        state <= RECEIVE;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 1;
                    state <= STOP;
                end else begin
                    counter <= 0;
                    data_available <= 1;
                    state <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end

endmodule