module control_unit(
	IR_opcode,
	IR_func,
	// ALUzero,
	Branch,
	// ALUctrl,
	MemToReg, MemRead, MemWrite,
	RegDST, RegWrite,
	Jump, ALUSrc,
	Branch_sel,
	Shift
);

input [5:0] IR_opcode;
input [5:0] IR_func;
// input ALUzero;
output reg [3:0] ALUctrl;
output reg MemToReg, MemRead, MemWrite;
output reg RegDST, RegWrite;
output reg Jump, ALUSrc;
output reg Branch
// output Branch_sel;

// reg Branch;
reg [1:0] ALUOp;

// assign Branch_sel = ALUzero & Branch;

always@ (*) begin
	if(IR_opcode == 0) ALUOp = 2'b01;
	else if(IR_opcode == 4) ALUOp = 2'b10;
	else ALUOp = 2'b00;
end


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


always @(*) begin
	if(IR_func == 0 || IR_func == 2 || IR_func == 3) Shift = 1;
end

always@ (*) begin //Jump
	if(IR_opcode == 2 || IR_opcode == 3) Jump = 1;
	else Jump = 0;
end

always@ (*) begin //Branch
	if(IR_opcode == 4) Branch = 1;
	else Branch = 0;
end

always@ (*) begin //RegDST
	if(IR_opcode == 0 && IR_func != 8) RegDST = 1;
	else RegDST = 0;
end

always@ (*) begin //MemRead
	if(IR_opcode == 35) MemRead = 1;
	else MemRead = 0;
end

always@ (*) begin //MemToReg
	if(IR_opcode == 35) MemToReg = 1;
	else MemToReg = 0;
end

always@ (*) begin //MemWrite
	if(IR_opcode == 43) MemWrite = 1;
	else MemWrite = 0;
end

always@ (*) begin //ALUSrc
	if(IR_opcode == 35 || IR_opcode == 43 || IR_opcode == 8  || IR_opcode == 10 ||
	   IR_opcode == 12 || IR_opcode == 13 || IR_opcode == 14) ALUSrc = 1;
	else ALUSrc = 0;
end

always@ (*) begin //RegWrite
	if(IR_opcode == 35 || IR_opcode == 3) RegWrite = 1;
	else if(IR_opcode == 0 && IR_func != 8) RegWrite = 1;
	else RegWrite = 0;
end

endmodule
