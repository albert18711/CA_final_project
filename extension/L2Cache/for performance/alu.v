//Behavior level (event-driven) 
module alu(
    ctrl,
    x,
    y,
    carry,
    out,
	zero
);
    
    input  [3:0] ctrl;
    input  [31:0] x;
    input  [31:0] y;
    output reg carry;
    output reg [31:0] out;
	output reg zero;
	
	wire [31:0] out_add, out_sub;
	wire [31:0] out_0, out_1;
	wire carry_0, carry_1;
	wire [63:0] shift_right_64;
    
// assign out_add = {x[31], x[31:0]} + {y[31], y[31:0]};
assign out_add = x + y;
assign out_0 = out_add[31:0];
assign carry_0 = out_add[32];

// assign out_sub = {x[31], x[31:0]} + (~{y[31], y[31:0]}) + 1;
assign out_sub = x - y;
assign out_1 = out_sub[31:0];
assign carry_1 = out_sub[32];

assign shift_right_64 = {y, y} >> x;

always@(*) begin
	if(ctrl == 4'b0001 && out_sub == 0) zero = 1;
	else                                zero = 0;
end

always@(*) begin
	case(ctrl)
		4'b0000: out = out_0; //add
		4'b0001: out = out_1; //sub
		4'b0010: out = x & y; //and
		4'b0011: out = x | y; //or
		4'b0100: out = (x < y)? 1: 0; //set less than
		4'b0101: out = x ^ y; //xor
		4'b0110: out = ~(x | y); //nor
		// NOTICE: $rd = $rt << shamt
		4'b0111: out = y << x; //shift left
		4'b1000: out = y >> x; //shift right
		4'b1001: out = shift_right_64[31:0]; //shift right arithmetic
		default: out = 0;
	endcase
end

always@(*) begin
	case(ctrl)
		4'b0000: carry = carry_0;
		4'b0001: carry = carry_1;
		default: carry = 0;
	endcase
end
	
endmodule
