module ALUControl(
IR_func,
ALUOp,
ALUctrl,
JR
);

input [5:0] IR_func;  //funct_RegD
input [3:0] ALUOp;    //ALUOp_RegD
output [5:0] ALUctrl; //alu_op
output JR;            //JR

assign JR = (IR_func == 4'b1000)? 1 : 0;

always@ (*) begin
	if(ALUOp == 2'b00) ALUctrl = 0;
	else if(ALUOp == 2'b10) ALUctrl = 1;
	else if(ALUOp == 2'b01) begin
		case(IR_func)
			6'b100000: ALUctrl = 0; //add
			6'b100010: ALUctrl = 1; //sub
			6'b100100: ALUctrl = 2; //and
			6'b100101: ALUctrl = 3; //or
			6'b101010: ALUctrl = 4; //set less than
			6'b100110: ALUctrl = 5; //xor
			6'd39	 : ALUctrl = 6; //nor
			6'd0	 : ALUctrl = 7; //shift left
			6'd2	 : ALUctrl = 8; //shift right
			6'd3 	 : ALUctrl = 9; //shift right arithmetic
			default: ALUctrl = 0;
		endcase
	end
	else ALUctrl = 0;
end

endmodule
