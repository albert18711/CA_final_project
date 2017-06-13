module ALUControl(
iIR_func,
iALUOp,
iJAL,
oALUctrl,
oJR
);

input  	   [5:0] iIR_func; //funct_RegD
input  	   [3:0] iALUOp;   //ALUOp_RegD
input 	         iJAL;
output reg [3:0] oALUctrl; //alu_op
output       	 oJR;      //JR

assign oJR = (iALUOp == 01 && iIR_func == 4'b1000)? 1 : 0;

always@ (*) begin
	if(iALUOp == 2'b00) oALUctrl = 0;
	else if(iALUOp == 2'b10) oALUctrl = 1; // beq
	else if(iALUOp == 2'b01) begin
		case(iIR_func)
			6'b100000: oALUctrl = 0; //add
			6'b100010: oALUctrl = 1; //sub
			6'b100100: oALUctrl = 2; //and
			6'b100101: oALUctrl = 3; //or
			6'b101010: oALUctrl = 4; //set less than
			6'b100110: oALUctrl = 5; //xor
			6'd39	 : oALUctrl = 6; //nor
			6'd0	 : oALUctrl = 7; //shift left
			6'd2	 : oALUctrl = 8; //shift right
			6'd3 	 : oALUctrl = 9; //shift right arithmetic
			default: oALUctrl = 0;
		endcase
	end
	else if(iALUOp == 2'b11) begin // I type
		case (iIR_func) // actually is OP-field
			
			default : oALUctrl = 0;
		endcase
	end
end

endmodule
