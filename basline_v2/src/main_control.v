module mainControl(
IR_opcode,
IR_func,
ALUOp,
MemToReg, MemWrite,
RegDST, RegWrite,
Jump, ALUSrc,
Branch
);

input [5:0] IR_opcode; //opcode
input [5:0] IR_func;   //funct
output reg [3:0] ALUOp;
output reg [1:0] MemToReg;
output reg MemWrite;
output reg [1:0] RegDST;
output reg RegWrite;
output reg Jump, ALUSrc;
output reg Branch;

always@ (*) begin //ALUOp
	if(IR_opcode == 0) ALUOp = 4'b0001;
	else if(IR_opcode == 4) ALUOp = 4'b0010;
	else ALUOp = 4'b0000;
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

always@ (*) begin //MemToReg
	if(IR_opcode == 35) 	MemToReg = 2'b00; // lw
	else if(IR_opcode == 3) MemToReg = 2'b10; // jal/jalr
	else 					MemToReg = 2'b00; // R type
end

always@ (*) begin //MemWrite
	if(IR_opcode == 43) MemWrite = 1;
	else MemWrite = 0;
end

always@ (*) begin //ALUSrc
	if(IR_opcode == 35 || IR_opcode == 43) ALUSrc = 1;
	else ALUSrc = 0;
end

always@ (*) begin //RegWrite
	if(IR_opcode == 35 || IR_opcode == 3) RegWrite = 1;
	else if(IR_opcode == 0 && IR_func != 8) RegWrite = 1;
	else RegWrite = 0;
end

endmodule
