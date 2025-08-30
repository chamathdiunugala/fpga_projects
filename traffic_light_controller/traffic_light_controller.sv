module traffic_light_controller(
	input clk, rst,
	output reg [2:0]f1,
	output reg [2:0]f2,
	output reg [2:0]f3,
	output reg [2:0]f4,
	
	output reg [2:0]r1,
	output reg [2:0]r2,
	output reg [2:0]r3,
	output reg [2:0]r4,
	
	output reg [2:0]l1,
	output reg [2:0]l2,
	output reg [2:0]l3,
	output reg [2:0]l4,
	
	output reg [2:0]c1,
	output reg [2:0]c2,
	output reg [2:0]c3,
	output reg [2:0]c4
);

parameter red = 3'b100, yellow = 3'b010, green = 3'b001;

typedef enum{
	initialize,
	
	s1_red,
	s1_yellow_up,
	s1_yellow_down,	
	s1_green,
	
	s2_red,
	s2_yellow_up,
	s2_yellow_down,
	s2_green,
	
	s3_red,
	s3_yellow_up,
	s3_yellow_down,
	s3_green,
	
	s4_red,
	s4_yellow_up,
	s4_yellow_down,
	s4_green,
	
	s5_red,
	s5_yellow_up,
	s5_yellow_down,
	s5_green,
	
	s6_red,
	s6_yellow_up,
	s6_yellow_down,
	s6_green
} traffic_light_t;

reg [5:0] count;
reg [19:0] day_time;
traffic_light_t current_state;

always_ff@(posedge clk or negedge rst) 
begin
	if(!rst)
	begin
		count <= 0;
		current_state <= initialize;
	end
	else
	begin 
		count <= count + 1;
		day_time <= day_time + 1;
		if (day_time > 500)
		begin
		day_time <= 0;
		end
		
		case(current_state)
		initialize:
		if (count > 2)
			begin
			current_state <= s1_yellow_down;
			count <= 1;
			end
			
		s1_yellow_down:
		if (count > 0)
			begin
			current_state <= s1_green;
			count <= 1;
			end
			
		s1_green:
		if (count > 10 && (day_time > 250 && day_time < 350) )
			begin
			current_state <= s1_yellow_up;
			count <= 1;
			end
			
		else if (count > 20)
			begin
			current_state <= s1_yellow_up;
			count <= 1;
			end
			
		s1_yellow_up:
		if (count > 2)
			begin
			current_state <= s1_red;
			count <= 1;
			end
			
		s1_red:
		if (count > 1)
			begin
			current_state <= s2_yellow_down;
			count <= 1;
			end
			
		s2_yellow_down:
		if (count > 1)
			begin
			current_state <= s2_green;
			count <= 1;
			end
			
		s2_green:
		if (count > 10)
			begin
			current_state <= s2_yellow_up;
			count <= 1;
			end
			
		s2_yellow_up:
		if (count > 2)
			begin
			current_state <= s2_red;
			count <= 1;
			end
			
		s2_red:
		if (count > 1)
			begin
			current_state <= s3_yellow_down;
			count <= 1;
			end
			
		s3_yellow_down:
		if (count > 1)
			begin
			current_state <= s3_green;
			count <= 1;
			end
			
		s3_green:
		if (count > 10)
			begin
			current_state <= s3_yellow_up;
			count <= 1;
			end
			
		s3_yellow_up:
		if (count > 2)
			begin
			current_state <= s3_red;
			count <= 1;
			end
			
		s3_red:
		if (count > 1)
			begin
			current_state <= s4_yellow_down;
			count <= 1;
			end
			
		s4_yellow_down:
		if (count > 1)
			begin
			current_state <= s4_green;
			count <= 1;
			end
			
		s4_green:
		if (count > 10)
			begin
			current_state <= s4_yellow_up;
			count <= 1;
			end
			
		s4_yellow_up:
		if (count > 2)
			begin
			current_state <= s4_red;
			count <= 1;
			end
			
		s4_red:
		if (count > 1)
			begin
			current_state <= s5_yellow_down;
			count <= 1;
			end
			
		s5_yellow_down:
		if (count > 1)
			begin
			current_state <= s5_green;
			count <= 1;
			end
			
		s5_green:
		if (count > 10)
			begin
			current_state <= s5_yellow_up;
			count <= 1;
			end
			
		s5_yellow_up:
		if (count > 2)
			begin
			current_state <= s5_red;
			count <= 1;
			end
			
		s5_red:
		if (count > 1)
			begin
			current_state <= s6_yellow_down;
			count <= 1;
			end
			
		s6_yellow_down:
		if (count > 1)
			begin
			current_state <= s6_green;
			count <= 1;
			end
			
		s6_green:
		if (count > 10)
			begin
			current_state <= s6_yellow_up;
			count <= 1;
			end
			
		s6_yellow_up:
		if (count > 2)
			begin
			current_state <= s6_red;
			count <= 1;
			end
			
		s6_red:
		if (count > 1)
			begin
			current_state <= s1_yellow_down;
			count <= 1;
			end
		endcase
	end
end	
			
always_comb
begin
   {f1, f2, f3, f4, r1, r2, r3, r4, l1, l2, l3, l4, c1, c2, c3, c4} = {16{red}};

	case(current_state)
		initialize, s1_red, s3_red, s4_red, s6_red:
		begin
		{f1, f2, f3, f4, r1, r2, r3, r4, l1, l2, l3, l4, c1, c2, c3, c4} = {16{red}};
		end
		
		s1_yellow_down, s1_yellow_up:
		begin
		{f1, f3} = {2{yellow}};
		end
		
		s1_green:
		begin
		{f1, f3, c2, c4} = {4{green}};
		end
		
		s2_yellow_down:
		begin
		{l2, l4, l3, r3} = {4{yellow}};
		end
		
		s2_yellow_up:
		begin
		{l2, r3} = {2{yellow}};
		{l4, l3} = {2{green}};
		end
		
		s2_green:
		begin
		{l2, l4, l3, r3} = {4{green}};
		end
		
		s3_yellow_down:
		begin
		{l1, r4} = {2{yellow}};
		{l3, l4} = {2{green}};
		end
		
		s2_red:
		begin
		{l3, l4} = {2{green}};
		end
		
		s5_red:
		begin
		{l1, l2} = {2{green}};
		end
		
		s3_green:
		begin
		{l1, l3, l4, r4} = {4{green}};
		end
		
		s3_yellow_up:
		begin
		{l1, l3, l4, r4} = {4{yellow}};
		end
		
		s4_yellow_down, s4_yellow_up:
		begin
		{f2, f4} = {2{yellow}};
		end
		
		s4_green:
		begin
		{c1, c3, f2, f4} = {4{green}};
		end
		
		s5_yellow_up:
		begin
		{l4, r1} = {2{green}};
		{l2, l1} = {2{green}};
		end
		
		s5_green:
		begin
		{l2, l1, l4, r1} = {4{green}};
		end
		
		s5_yellow_down:
		begin
		{l2, l1, l4, r1} = {4{yellow}};
		end
		
		s6_yellow_down:
		begin
		{l3, r2} = {2{yellow}};
		{l1, l2} = {2{green}};
		end
		
		s6_yellow_up:
		begin
		{l1, l3, l2, r2} = {4{yellow}};
		end
		
		s6_green:
		begin
		{l1, l3, l2, r2} = {4{green}};
		end
	endcase
end
endmodule