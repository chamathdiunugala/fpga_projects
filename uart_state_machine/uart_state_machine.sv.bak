module uart_state_machine (
    input CLOCK_50,           // 50MHz clock input on DE2-115
    input GPIO,               // GPIO pin for UART RX
    input rst_n,              // Reset input
    output [4:0] LEDR,        // Red LEDs (0-3 for data, 4 for detection)
    output detected           // Detection output
);

    // UART signals
    wire [7:0] uart_data;
    wire uart_data_available;
    
    // Register to hold LED display (corrected size)
    reg [3:0] led_data = 4'h0;  // Fixed: was 8'h00, should be 4'h0
    
    // Instantiate UART receiver
    uart_rx #(
        .CLKS_PER_BIT(434)    // 115200 baud @ 50MHz
    ) uart_rx_inst (
        .clk(CLOCK_50),
        .i_rx(GPIO),
        .o_data(uart_data),
        .o_data_available(uart_data_available)
    );
    
    // Instantiate state machine (Fixed: added missing instance name)
    state_machine state_machine_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .din(uart_data[0]),
        .detect(detected)
    );
    
    // Update LEDs when new data arrives
    always_ff @(posedge CLOCK_50) begin
        if (!rst_n) begin
            led_data <= 4'h0;  // Reset condition
        end else if (uart_data_available) begin
            led_data[3] <= led_data[2];
            led_data[2] <= led_data[1];
            led_data[1] <= led_data[0];
            led_data[0] <= uart_data[0];
        end
    end
    
    // Connect to LEDs
    assign LEDR[3:0] = led_data;     // Data on lower 4 LEDs
    assign LEDR[4] = detected;       // Detection output on LED 4
endmodule

module uart_rx #(
    parameter CLKS_PER_BIT = 434 // 115200 baud @ 50 MHz
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

module state_machine (
    input  logic clk,
    input  logic rst_n,  // active-low reset
    input  logic din,    // serial input bit
    output logic detect  // goes high when "0110" detected
);

    typedef enum logic [1:0] {
        S0, // no match
        S1, // got 0
        S2, // got 01
        S3  // got 011
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next state logic & output
    always_comb begin
        next_state = current_state;
        detect     = 1'b0;

        case (current_state)
            S0: begin
                if (din == 0) next_state = S1;
                else          next_state = S0;
            end
            S1: begin
                if (din == 1) next_state = S2;
                else          next_state = S1; // stay in S1 if another 0
            end
            S2: begin
                if (din == 1) next_state = S3;
                else          next_state = S1; // restart match from 0
            end
            S3: begin
                if (din == 0) begin
                    next_state = S1; // last 0 can start new match
                    detect     = 1'b1; // sequence found
                end
                else begin
                    next_state = S0;
                end
            end
        endcase
    end

endmodule