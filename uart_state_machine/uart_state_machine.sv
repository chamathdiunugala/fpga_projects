// Debug version - uses more LEDs to show what's happening
module uart_state_machine (
    input CLOCK_50,           // 50MHz clock input on DE2-115
    input GPIO,               // GPIO pin for UART RX
    input rst_n,              // Reset input
    output [9:0] LEDR         // Using more LEDs for debugging
);

    // UART signals
    wire [7:0] uart_data;
    wire uart_data_available;
    
    // State machine signals
    wire detect_pulse;        // Single cycle detection pulse
    reg detect_latch = 1'b0;  // Latched detection signal
    reg [1:0] sm_state_debug; // Debug: show state machine state
    
    // Register to hold LED display and delayed bit
    reg [3:0] led_data = 4'h0;
    reg delayed_bit = 1'b0;   // Delayed bit for state machine
    reg delayed_data_valid = 1'b0; // Delayed valid signal
    
    // Debug: count received bytes
    reg [7:0] byte_count = 0;
    
    // Instantiate UART receiver
    uart_rx #(
        .CLKS_PER_BIT(434)    // 115200 baud @ 50MHz
    ) uart_rx_inst (
        .clk(CLOCK_50),
        .i_rx(GPIO),
        .o_data(uart_data),
        .o_data_available(uart_data_available)
    );
    
    // Instantiate state machine (from separate file)
    state_machine_debug state_machine_inst (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .din(delayed_bit),           // Use delayed bit
        .data_valid(delayed_data_valid), // Add valid signal
        .detect(detect_pulse),
        .current_state(sm_state_debug)  // Debug output
    );
    
    // Latch the detection signal and count bytes
    always_ff @(posedge CLOCK_50) begin
        if (!rst_n) begin
            detect_latch <= 1'b0;
            byte_count <= 0;
            led_data <= 4'h0;
            delayed_bit <= 1'b0;
            delayed_data_valid <= 1'b0;
        end else begin
            // Always update delayed signals
            delayed_bit <= uart_data[0];
            delayed_data_valid <= uart_data_available;
            
            if (uart_data_available) begin
                // Update LED shift register
                led_data[3] <= led_data[2];
                led_data[2] <= led_data[1];
                led_data[1] <= led_data[0];
                led_data[0] <= uart_data[0];
                
                // Count bytes for debugging
                byte_count <= byte_count + 1;
                
                // Clear detection on new data (optional)
                detect_latch <= 1'b0;
            end else if (detect_pulse) begin
                detect_latch <= 1'b1;  // Set when pattern detected
            end
        end
    end
    
    // Connect to LEDs for debugging
    assign LEDR[3:0] = led_data;           // Bit history
    assign LEDR[4] = detect_latch;         // Detection latch
    assign LEDR[5] = detect_pulse;         // Raw detection pulse
    assign LEDR[6] = uart_data_available;  // UART data available
    assign LEDR[7] = uart_data[0];         // Current bit being processed
    assign LEDR[9:8] = sm_state_debug;     // State machine state
endmodule

// Enhanced state machine with debug output and valid signal
module state_machine_debug (
    input  logic clk,
    input  logic rst_n,
    input  logic din,
    input  logic data_valid,      // Only process when new data is valid
    output logic detect,
    output logic [1:0] current_state  // Debug: expose current state
);

    typedef enum logic [1:0] {
        S0 = 2'b00, // no match
        S1 = 2'b01, // got 0
        S2 = 2'b10, // got 01
        S3 = 2'b11  // got 011
    } state_t;

    state_t state, next_state;
    
    // Expose current state for debugging
    assign current_state = state;

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0;
        else if (data_valid)  // Only update state when new data arrives
            state <= next_state;
    end

    // Next state logic & output (only when data is valid)
    always_comb begin
        next_state = state;
        detect = 1'b0;

        if (data_valid) begin
            case (state)
                S0: begin
                    if (din == 1'b0) next_state = S1;
                    else             next_state = S0;
                end
                S1: begin
                    if (din == 1'b1) next_state = S2;
                    else             next_state = S1; // stay in S1 for consecutive 0s
                end
                S2: begin
                    if (din == 1'b1) next_state = S3;
                    else             next_state = S1; // restart from S1 if we get 0
                end
                S3: begin
                    if (din == 1'b0) begin
                        next_state = S1;     // restart from S1 (overlapping patterns)
                        detect = 1'b1;       // pattern "0110" detected!
                    end else begin
                        next_state = S0;     // go back to start if we get 1
                    end
                end
            endcase
        end else begin
            // If no new data, maintain current state and no detection
            next_state = state;
            detect = 1'b0;
        end
    end
endmodule

// Same UART module as before
module uart_rx #(
    parameter CLKS_PER_BIT = 434
)(
    input  clk,
    input  i_rx,
    output logic [7:0] o_data,
    output logic o_data_available
);

    localparam IDLE    = 2'b00;
    localparam START   = 2'b01;
    localparam RECEIVE = 2'b10;
    localparam STOP    = 2'b11;

    logic rx_buffer = 1'b1;
    logic rx = 1'b1;
    logic [1:0] state = IDLE;
    logic [31:0] counter = 0;
    logic [2:0] bit_index = 0;
    logic [7:0] data = 0;
    logic data_available = 0;

    assign o_data = data;
    assign o_data_available = data_available;

    always_ff @(posedge clk) begin
        rx_buffer <= i_rx;
        rx <= rx_buffer;
    end

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