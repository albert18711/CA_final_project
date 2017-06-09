module MIPS_Pipeline(
// control interface
		clk, 
		rst_n,
//----------I cache interface-------		
		ICACHE_ren,
		ICACHE_wen,
		ICACHE_addr,
		ICACHE_wdata,
		ICACHE_stall,
		ICACHE_rdata,
//----------D cache interface-------
		DCACHE_ren,
		DCACHE_wen,
		DCACHE_addr,
		DCACHE_wdata,
		DCACHE_stall,
		DCACHE_rdata,
	);

//---------control interface-------	
	input clk;
	input rst_n;

//---------I cache interface-------
	output ICACHE_ren;
	output ICACHE_wen;
	output reg [29:0] ICACHE_addr;
	output reg [31:0] ICACHE_wdata;
	input ICACHE_stall;
	input [31:0] ICACHE_rdata;

//---------D cache interface-------	
	output DCACHE_ren;
	output DCACHE_wen;
	output reg [29:0] DCACHE_addr;
	output [31:0] DCACHE_wdata;
	input DCACHE_stall;
	input [31:0] DCACHE_rdata;

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
	.ALUzero(ALUzero_regE_r),
	.ALUctrl(ALUctrl),
	.MemToReg(MemToReg), .MemRead(MemRead), .MemWrite(MemWrite),
	.RegDST(RegDST), .RegWrite(RegWrite),
	.Jump(Jump), .ALUSrc(ALUSrc),
	.Branch_sel(Branch_sel),
	.Shift(Shift)
);



assign IR_opcode = IR_regD_r[31:26];
assign IR_func = IR_regD_r[5:0];

assign Reg_R1 = IR_regD_r[25:21];
assign Reg_R2 = IR_regD_r[20:16];
assign Reg_W = (jal_sel)? 31: temp_Reg_W;
assign temp_Reg_W = (RegDST == 0) ? IR_regD_r[20:16] : IR_regD_r[15:11];

assign SignExtend = {{16{IR_regD_r[15]}}, {IR_regD_r[15:0]}};

assign ALUin1 = ReadData1;
assign ALUin2 = (ALUSrc == 0) ? ReadData2 : SignExtend;

assign RF_writedata = WriteData;

assign jr_sel = (IR_opcode == 0 && IR_func == 8)? 1: 0;
assign jal_sel = (IR_opcode == 3)? 1: 0;

//==== combinational part =================================

// reg IF/ID
always @(*) begin
	IR_regD_w = ICACHE_rdata;
end

// PC_next (series) PC_in => IR_addr
always@ (*) begin
	if(~rst_n) PCnext = 0;
	else PCnext = IR_addr + 4;
end

always@ (*) begin // address handling
	if(~rst_n) begin
		JumpAddr = 0;
		BranchAddr = 0;
		A = 0;
		in = 0; //for nWave
	end
	else begin
		JumpAddr = {PCnext[31:28], IR_regD_r[25:0], 2'b0};
		BranchAddr = PCnext + {{14{IR_regD_r[15]}}, IR_regD_r[15:0], 2'b0};
		A = ALUresult[8:2];
		in = ReadDataMem; //for nWave
	end
end

always@ (*) begin // PC MUX
	if(~rst_n) PCin = 0;
	else if(Jump) PCin = JumpAddr;
	else if(Branch_sel) PCin = BranchAddr;
	else if(jr_sel) PCin = ReadData1;
	else PCin = PCnext;
end





always@ (*) begin // write back MUX
	if(~rst_n) WriteData = 0;
	else if(jal_sel) WriteData = PCnext;
	else WriteData = (MemToReg == 1) ? ReadDataMem : ALUresult;
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


//==== sequential part ====================================
always@ (posedge clk) begin
	if(~rst_n) IR_addr <= 0;
	else IR_addr <= PCin;
end

//=========================================================
endmodule