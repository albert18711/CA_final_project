module mainControl(
	iIR_opcode,
	iIR_func,
	oALUOp,
	oMemToReg, oMemWrite,
	oRegDST, oRegWrite,
	oJump, oALUSrc,
	oBranch,
	oExtOp,
	oJAL,
	oJR
);

input [5:0] iIR_opcode; //opcode
input [5:0] iIR_func;   //funct
output reg [1:0] oALUOp;
output reg [1:0] oMemToReg;
output reg oMemWrite;
output reg [1:0] oRegDST;
output reg oRegWrite;
output reg oJump, oALUSrc;
output reg oBranch;
output reg oExtOp;
output reg oJAL;
output reg oJR;

always @(*) begin // JAL
	if(iIR_opcode == 3) oJAL = 1;
	else 				oJAL = 0;
end

always @(*) begin // shift -> ExtOp = 1
	if(iIR_opcode == 0 && (iIR_func == 0 || iIR_func == 2 || iIR_func == 3))
		oExtOp = 1;
	else
		oExtOp = 0; 
end

always@ (*) begin //ALUOp
	if(iIR_opcode == 0) oALUOp = 2'b01; // R type
	else if(iIR_opcode == 8  || iIR_opcode == 12 || iIR_opcode == 13 ||
		    iIR_opcode == 14 || iIR_opcode == 10) oALUOp = 2'b01; // I type 
	else if(iIR_opcode == 4) oALUOp = 2'b10;
	else oALUOp = 2'b00;
end

always@ (*) begin //Jump
	if(iIR_opcode == 2 || iIR_opcode == 3) oJump = 1;
	else oJump = 0;
end

always@ (*) begin //Branch
	if(iIR_opcode == 4) oBranch = 1;
	else oBranch = 0;
end

always@ (*) begin //RegDST
	if(iIR_opcode == 0) 	 oRegDST = 2'b01;
	else if(iIR_opcode == 3) oRegDST = 2'b10;
	else 					 oRegDST = 2'b00;
end

always@ (*) begin //MemToReg // NOTICE: we modify here.
	if(iIR_opcode == 35) 	 oMemToReg = 2'b01; // lw
	else if(iIR_opcode == 3) oMemToReg = 2'b10; // jal/jalr
	else 					 oMemToReg = 2'b00; // R type
end

always@ (*) begin //MemWrite
	if(iIR_opcode == 43) oMemWrite = 1; // sw
	else 				 oMemWrite = 0;
end

always@ (*) begin //ALUSrc
	if(iIR_opcode == 35 || iIR_opcode == 43 || iIR_opcode == 8  || iIR_opcode == 10 ||
	   iIR_opcode == 12 || iIR_opcode == 13 || iIR_opcode == 14)
		oALUSrc = 0; //
	else if(iIR_opcode == 0 && (iIR_func == 0 || iIR_func == 3 || iIR_func == 6))
		oALUSrc = 0; // sll, srl, sra
 	else
 		oALUSrc = 1;
end

always@ (*) begin //RegWrite
	if(iIR_opcode == 35 || iIR_opcode == 3  || iIR_opcode == 8 ||
	   iIR_opcode == 12 || iIR_opcode == 13 || iIR_opcode == 14)
		oRegWrite = 1;
	else if(iIR_opcode == 0 && iIR_func != 8) oRegWrite = 1;
	else if(iIR_opcode == 0 && (iIR_func == 0 || iIR_func == 3 || iIR_func == 6))
		oRegWrite = 1; // sll, srl, sra
	else
		oRegWrite = 0;
end

always @(*) begin // JR
	if(iIR_opcode == 0 && iIR_func == 8) oJR = 1;
	else 								 oJR = 0;
end

endmodule
