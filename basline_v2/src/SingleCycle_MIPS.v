// Single Cycle MIPS
//=========================================================
// Input/Output Signals:
// positive-edge triggered         clk
// active low asynchronous reset   rst_n
// instruction memory interface    IR_addr, IR
// output for testing purposes     RF_writedata  
//=========================================================
// Wire/Reg Specifications:
// control signals             MemToReg, MemRead, MemWrite, 
//                             RegDST, RegWrite, Branch, 
//                             Jump, ALUSrc, ALUOp
// ALU control signals         ALUctrl
// ALU input signals           ALUin1, ALUin2
// ALU output signals          ALUresult, ALUzero
// instruction specifications  r, j, jal, jr, lw, sw, beq
// sign-extended signal        SignExtend
// MUX output signals          MUX_RegDST, MUX_MemToReg, 
//                             MUX_Src, MUX_Branch, MUX_Jump
// registers input signals     Reg_R1, Reg_R2, Reg_W, WriteData 
// registers                   Register
// registers output signals    ReadData1, ReadData2
// data memory contral signals CEN, OEN, WEN
// data memory output signals  ReadDataMem
// program counter/address     PCin, PCnext, JumpAddr, BranchAddr
//=========================================================

`include "alu.v"
`include "register_file.v"
`include "control_unit.v"

module SingleCycle_MIPS( 
    clk,
    rst_n,
    IR_addr,
    IR,
    RF_writedata,
    ReadDataMem,
    CEN,
    WEN,
    A,
    ReadData2,
    OEN
);

//==== in/out declaration =================================
    //-------- processor ----------------------------------
    input         clk, rst_n;
    input  [31:0] IR;
    output reg [31:0] IR_addr;
	output [31:0] RF_writedata;
    //-------- data memory --------------------------------
    input  [31:0] ReadDataMem;  // read_data from memory
    output reg    CEN;  // chip_enable, 0 when you read/write data from/to memory
    output reg    WEN;  // write_enable, 0 when you write data into SRAM & 1 when you read data from SRAM
    output reg [6:0] A;  // address
    output [31:0] ReadData2;  // write_data to memory
    output        OEN;  // output_enable, 0

//==== reg/wire declaration ===============================

	reg [31:0] in;
	
	wire [4:0] Reg_R1, Reg_R2, Reg_W, temp_Reg_W;
	wire [31:0] ReadData1;
	reg [31:0] WriteData;
	wire [31:0] SignExtend;
	wire [31:0] ALUin1, ALUin2, ALUresult;
	wire [3:0] ALUctrl;
	wire ALUzero;
	
	wire MemToReg, MemRead, MemWrite;
	wire RegDST, RegWrite;
	wire Jump, ALUSrc, ALUOp;
	wire Branch_sel;
	
	reg [31:0] PCin, PCnext, JumpAddr, BranchAddr;
	
	wire [5:0] IR_opcode, IR_func;
	
	wire jr_sel, jal_sel;
	
//==== submodule ==========================================

alu ALU(
    .ctrl(ALUctrl),
    .x(ALUin1),
    .y(ALUin2),
    .carry(),
    .out(ALUresult),
	.zero(ALUzero)
);

register_file Register(
    .Clk(clk),
	.rst(rst_n),
    .WEN(RegWrite),
    .RW(Reg_W),
    .busW(WriteData),
    .RX(Reg_R1),
    .RY(Reg_R2),
    .busX(ReadData1),
    .busY(ReadData2)
);

control_unit CTRL(
	.IR_opcode(IR_opcode),
	.IR_func(IR_func),
	.ALUzero(ALUzero),
	.ALUctrl(ALUctrl),
	.MemToReg(MemToReg), .MemRead(MemRead), .MemWrite(MemWrite),
	.RegDST(RegDST), .RegWrite(RegWrite),
	.Jump(Jump), .ALUSrc(ALUSrc),
	.Branch_sel(Branch_sel)
);

assign OEN = 0;

assign IR_opcode = IR[31:26];
assign IR_func = IR[5:0];

assign Reg_R1 = IR[25:21];
assign Reg_R2 = IR[20:16];
assign Reg_W = (jal_sel)? 31: temp_Reg_W;
assign temp_Reg_W = (RegDST == 0) ? IR[20:16] : IR[15:11];

assign SignExtend = {{16{IR[15]}}, {IR[15:0]}};

assign ALUin1 = ReadData1;
assign ALUin2 = (ALUSrc == 0) ? ReadData2 : SignExtend;

assign RF_writedata = WriteData;

assign jr_sel = (IR_opcode == 0 && IR_func == 8)? 1: 0;
assign jal_sel = (IR_opcode == 3)? 1: 0;

//==== combinational part =================================
always@ (*) begin // address handling
	if(~rst_n) begin
		JumpAddr = 0;
		BranchAddr = 0;
		A = 0;
		in = 0; //for nWave
	end
	else begin
		JumpAddr = {PCnext[31:28], IR[25:0], 2'b0};
		BranchAddr = PCnext + {{14{IR[15]}}, IR[15:0], 2'b0};
		A = ALUresult[8:2];
		in = ReadDataMem; //for nWave
	end
end

always@ (*) begin // write back MUX
	if(~rst_n) WriteData = 0;
	else if(jal_sel) WriteData = PCnext;
	else WriteData = (MemToReg == 1) ? ReadDataMem : ALUresult;
end
	
always@ (*) begin // PC MUX
	if(~rst_n) PCin = 0;
	else if(Jump) PCin = JumpAddr;
	else if(Branch_sel) PCin = BranchAddr;
	else if(jr_sel) PCin = ReadData1;
	else PCin = PCnext;
end

// chip control
always@ (*) begin
	if(~rst_n) CEN = 1;
	else if(MemRead == 1 || MemWrite == 1) CEN = 0;
	else CEN = 1;
end

always@ (*) begin
	if(~rst_n) WEN = 0;
	else if(MemWrite == 1) WEN = 0;
	else if(MemRead == 1) WEN = 1;
	else WEN = 0;
end
// PC_next (series) PC_in => IR_addr
always@ (*) begin
	if(~rst_n) PCnext = 0;
	else PCnext = IR_addr + 4;
end

//==== sequential part ====================================
always@ (posedge clk) begin
	if(~rst_n) IR_addr <= 0;
	else IR_addr <= PCin;
end

//=========================================================
endmodule
