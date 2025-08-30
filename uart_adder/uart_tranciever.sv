module uart_tranciever #(
    parameter CLKS_PER_BIT = 434    // for 115200 baud @ 50 MHz
)(
    input  logic        clk,        // 50 MHz system clock
    input  logic        rst_n,      // active-low reset
    input  logic        uart_rx,    // RX pin from Arduino Due (TX1)
    output logic        uart_tx,    // TX pin back to Arduino Due (RX1)
    output logic [7:0]  leds        // debug LEDs show cout
);

    // UART receiver
    logic [7:0] rx_data;
    logic       rx_data_available;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .i_rx(uart_rx),
        .o_data(rx_data),
        .o_data_available(rx_data_available)
    );

    // UART transmitter
    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_done;
    logic       tx_active;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .i_data_available(tx_start),
        .i_data(tx_data),
        .o_active(tx_active),
        .o_tx(uart_tx),
        .o_done(tx_done)
    );

    // Storage variables
    logic [31:0] num1;
    logic [31:0] num2;
    logic [7:0]  last_byte;

    // Number adder signals
    logic [31:0] sum;
    logic        cout;

    // Instantiate number adder
    number_adder adder_inst (
        .a(num1),
        .b(num2),
        .cin(last_byte[0]),  // Use LSB of last_byte as cin
        .sum(sum),
        .cout(cout)
    );

    // Byte counter for receiving
    logic [3:0] byte_count;  // needs to count 0–8 (9 bytes total)
    
    // Transmission control
    logic [2:0] tx_byte_count; // Counts 0–4 for cout and sum bytes
    logic       echo_pending;   // Flag to initiate echo after 9th byte

    // Main logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num1          <= 32'd0;
            num2          <= 32'd0;
            last_byte     <= 8'd0;
            byte_count    <= 4'd0;
            tx_byte_count <= 3'd0;
            leds          <= 8'd0;
            tx_start      <= 1'b0;
            tx_data       <= 8'd0;
            echo_pending  <= 1'b0;
        end else begin
            tx_start <= 1'b0;  // Default no transmit

            // Handle echo of cout and sum
            if (echo_pending && !tx_active) begin
                case (tx_byte_count)
                    3'd0: begin
                        tx_data  <= {7'b0, cout};  // Echo cout
                        tx_start <= 1'b1;
                        leds     <= {7'b0, cout};  // Show cout on LEDs
                    end
                    3'd1: begin
                        tx_data  <= sum[7:0];      // Echo sum byte 0 (LSB)
                        tx_start <= 1'b1;
                    end
                    3'd2: begin
                        tx_data  <= sum[15:8];     // Echo sum byte 1
                        tx_start <= 1'b1;
                    end
                    3'd3: begin
                        tx_data  <= sum[23:16];    // Echo sum byte 2
                        tx_start <= 1'b1;
                    end
                    3'd4: begin
                        tx_data  <= sum[31:24];    // Echo sum byte 3 (MSB)
                        tx_start <= 1'b1;
                    end
                endcase

                if (tx_byte_count == 3'd4) begin
                    tx_byte_count <= 3'd0;
                    echo_pending  <= 1'b0;  // Done with echo
                end else if (tx_start) begin
                    tx_byte_count <= tx_byte_count + 1;
                end
            end

            if (rx_data_available) begin
                case (byte_count)
                    4'd0: num1[7:0]    <= rx_data;
                    4'd1: num1[15:8]   <= rx_data;
                    4'd2: num1[23:16]  <= rx_data;
                    4'd3: num1[31:24]  <= rx_data;
                    4'd4: num2[7:0]    <= rx_data;
                    4'd5: num2[15:8]   <= rx_data;
                    4'd6: num2[23:16]  <= rx_data;
                    4'd7: num2[31:24]  <= rx_data;
                    4'd8: begin
                        last_byte    <= rx_data;
                        echo_pending <= 1'b1;      
                    end
                endcase

                if (byte_count == 4'd8) begin
                    byte_count <= 4'd0;
                end else begin
                    byte_count <= byte_count + 1;
                end
            end
        end
    end

endmodule


module uart_rx #(
    parameter CLKS_PER_BIT = 434 // 115200 baud @ 50 MHz
)(
    input  logic clk,
    input  logic rst_n,                // active-low async reset
    input  logic i_rx,                 // UART RX input
    output logic [7:0] o_data,         // received byte
    output logic o_data_available      // goes high when byte is ready
);

    typedef enum logic [1:0] {IDLE, START, RECEIVE, STOP} state_t;
    state_t state;

    // Synchronizer
    logic rx_buffer = 1'b1;
    logic rx        = 1'b1;

    // Internal registers
    logic [31:0] counter = 0;
    logic [2:0]  bit_index = 0;
    logic [7:0]  data = 0;
    logic        data_available = 0;

    assign o_data           = data;
    assign o_data_available = data_available;

    // Input synchronizer
    always_ff @(posedge clk) begin
        rx_buffer <= i_rx;
        rx        <= rx_buffer;
    end

    // UART FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            counter        <= 0;
            bit_index      <= 0;
            data_available <= 0;
            data           <= 0;
        end else begin
            case (state)
                IDLE: begin
                    counter        <= 0;
                    data_available <= 0;
                    bit_index      <= 0;
                    if (rx == 0)
                        state <= START;
                end

                START: begin
                    if (counter == (CLKS_PER_BIT - 1)/2) begin
                        if (rx == 0) begin
                            counter <= 0;
                            state   <= RECEIVE;
                        end else begin
                            counter <= 0;
                            state   <= IDLE;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                RECEIVE: begin
                    if (counter < CLKS_PER_BIT - 1) begin
                        counter <= counter + 1;
                    end else begin
                        counter           <= 0;
                        data[bit_index]   <= rx;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (counter < CLKS_PER_BIT - 1) begin
                        counter <= counter + 1;
                    end else begin
                        counter        <= 0;
                        data_available <= 1;
                        state          <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule


module uart_tx #(
    parameter CLKS_PER_BIT = 434
)(
    input  logic clk,
    input  logic rst_n,               // active-low async reset
    input  logic i_data_available,
    input  logic [7:0] i_data,
    output logic o_active,
    output logic o_tx,
    output logic o_done
);

    typedef enum logic [1:0] {IDLE, START, SEND, STOP} state_t;
    state_t state;

    logic [31:0] counter   = 0;
    logic [2:0]  bit_index = 0;
    logic [7:0]  data_byte = 0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            counter   <= 0;
            bit_index <= 0;
            o_active  <= 0;
            o_done    <= 0;
            o_tx      <= 1;
            data_byte <= 0;
        end else begin
            case (state)
                IDLE: begin
                    o_tx      <= 1;
                    o_done    <= 0;
                    counter   <= 0;
                    bit_index <= 0;

                    if (i_data_available) begin
                        o_active  <= 1;
                        data_byte <= i_data;
                        state     <= START;
                    end else begin
                        o_active <= 0;
                    end
                end

                START: begin
                    o_tx <= 0;
                    if (counter < CLKS_PER_BIT - 1) begin
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        state   <= SEND;
                    end
                end

                SEND: begin
                    o_tx <= data_byte[bit_index];
                    if (counter < CLKS_PER_BIT - 1) begin
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    o_tx <= 1;
                    if (counter < CLKS_PER_BIT - 1) begin
                        counter <= counter + 1;
                    end else begin
                        o_done   <= 1;
                        o_active <= 0;
                        state    <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

module adder(
    input  logic a, b, cin,
    output logic sum, cout
);

always_comb begin
    sum  = a ^ b ^ cin;
    cout = (a & b) | (cin & (a ^ b));
end

endmodule


module eight_bit_adder(
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic       cin,
    output logic [7:0] sum,
    output logic       cout
);

    wire [6:0] c;

    adder a1(a[0], b[0], cin,   sum[0], c[0]);
    adder a2(a[1], b[1], c[0],  sum[1], c[1]);
    adder a3(a[2], b[2], c[1],  sum[2], c[2]);
    adder a4(a[3], b[3], c[2],  sum[3], c[3]);
    adder a5(a[4], b[4], c[3],  sum[4], c[4]);
    adder a6(a[5], b[5], c[4],  sum[5], c[5]);
    adder a7(a[6], b[6], c[5],  sum[6], c[6]);
    adder a8(a[7], b[7], c[6],  sum[7], cout);

endmodule


module number_adder(
input  logic [31:0] a,
input  logic [31:0] b,
input  logic cin,
output logic [31:0] sum,
output logic cout
);

	wire [2:0] c;

	eight_bit_adder e1(a[7:0], b[7:0], cin, sum[7:0], c[0]);
	eight_bit_adder e2(a[15:8], b[15:8], c[0], sum[15:8], c[1]);
	eight_bit_adder e3(a[23:16], b[23:16], c[1], sum[23:16], c[2]);
	eight_bit_adder e4(a[31:24], b[31:24], c[2], sum[31:24], cout);

endmodule



