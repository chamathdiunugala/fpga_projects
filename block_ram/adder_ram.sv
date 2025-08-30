module adder_ram #(
    parameter int N = 10   
)(
    input  logic clk,
    input  logic rst_n,
	 output logic led
);

    logic [31:0] ram_a   [0:N-1];
    logic [31:0] ram_b   [0:N-1];
    logic [32:0] ram_exp [0:N-1];  

    logic [$clog2(N)-1:0] addr;
    logic [31:0] a_reg, b_reg;
    logic cin_reg;
    logic [31:0] sum_wire;
    logic cout_wire;
    logic pass;   

    typedef enum logic [1:0] { S_IDLE, S_READ, S_CHECK } state_t;
    state_t state;

    number_adder uut (
        .a   (a_reg),
        .b   (b_reg),
        .cin (cin_reg),
        .sum (sum_wire),
        .cout(cout_wire)
    );
	 
	 logic clock;
	 
	 timer timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .led(clock)    // use divided clock as "clock"
    );

    always_ff @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            addr    <= '0;
            state   <= S_IDLE;
            a_reg   <= '0;
            b_reg   <= '0;
            cin_reg <= 1'b0;
            pass    <= 1'b1;  
        end else begin
            case (state)
                S_IDLE: begin
                    addr  <= 0;
                    state <= S_READ;
                end

                S_READ: begin
                    a_reg   <= ram_a[addr];
                    b_reg   <= ram_b[addr];
                    cin_reg <= 1'b0;  
                    state   <= S_CHECK;
                end

                S_CHECK: begin
                    if ({cout_wire, sum_wire} != ram_exp[addr])
                        pass <= 1'b0; 

                    if (addr == N-1)
                        addr <= 0;
                    else
                        addr <= addr + 1;

                    state <= S_READ;
                end
            endcase
        end
    end

    // --- Initialize input memories with test data and expected results ---
    initial begin
        // Test vectors and golden results
        ram_a[0] = 32'h0000_0001; ram_b[0] = 32'h0000_0002; ram_exp[0] = 33'h0000_0003;
        ram_a[1] = 32'h0000_00AA; ram_b[1] = 32'h0000_00BB; ram_exp[1] = 33'h0000_0165;
        ram_a[2] = 32'h1234_5678; ram_b[2] = 32'h1111_2222; ram_exp[2] = 33'h2345_789A;
        ram_a[3] = 32'hFFFF_FFFF; ram_b[3] = 32'h0000_0001; ram_exp[3] = 33'h1_0000_0000;
        ram_a[4] = 32'hAAAA_AAAA; ram_b[4] = 32'h5555_5555; ram_exp[4] = 33'hFFFF_FFFF;
        ram_a[5] = 32'hDEAD_BEEF; ram_b[5] = 32'h0000_0001; ram_exp[5] = 33'hDEAD_BEF0;
        ram_a[6] = 32'h0F0F_0F0F; ram_b[6] = 32'hF0F0_F0F0; ram_exp[6] = 33'hFFFF_FFFF;
        ram_a[7] = 32'h1357_9BDF; ram_b[7] = 32'h2468_ACED; ram_exp[7] = 33'h37C0_48CC;
        ram_a[8] = 32'h8000_0000; ram_b[8] = 32'h8000_0000; ram_exp[8] = 33'h1_0000_0000;
        ram_a[9] = 32'h7FFF_FFFF; ram_b[9] = 32'h0000_0001; ram_exp[9] = 33'h8000_0000;
    end
	 
	 assign led = pass;

endmodule

