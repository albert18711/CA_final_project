`include "alu.v"
`include "register_file.v"
`include "mainControl.v"
`include "ALUControl.v"
`include "hazard.v"
`include "forward.v"
`include "branch_predict.v"

module MIPS_Pipeline (
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
		DCACHE_rdata

		);

/////////////////////////////////////////////////////////////////////
///// input & output ////////////////////////////////////////////////

//---- control interface ------------------------------------------//
    input clk;
    input rst_n;
//---- I cache ----------------------------------------------------//
    output ICACHE_ren;
    output ICACHE_wen;
    output [29:0] ICACHE_addr;
    output [31:0] ICACHE_wdata;
    input  ICACHE_stall;
    input  [31:0] ICACHE_rdata;
//---- D cache ----------------------------------------------------//
    output DCACHE_ren;
    output DCACHE_wen;
    output [29:0] DCACHE_addr;
    output [31:0] DCACHE_wdata;
    input  DCACHE_stall;
    input  [31:0] DCACHE_rdata;

/////////////////////////////////////////////////////////////////////
//// reg and wire ///////////////////////////////////////////////////

//========== IF ===================================================//
    reg  [1:0]  PCSrc;
    reg  [31:0] PC_r, PC_w;
    reg  [31:0] PCPlus4;
    reg  [31:0] branch_addr;
    reg  [31:0] jump_addr;

    wire [31:0] target_address;
    reg  [31:0] PCPlus4_RegF_r;
    wire [31:0] PCPlus4_RegF_w;
    reg  [31:0] IR_RegF_r;
    wire [31:0] IR_RegF_w;
    wire [31:0] addr_in;
//========== ID ===================================================//
    wire [1:0]  ALUOp;
    wire        MemWrite;
    wire [1:0]  MemToReg;
    wire        RegWrite;
    wire        Branch;
    wire        ExtOp;
    wire        Jump;
    wire [1:0]  RegDst;
    wire        JAL;
    wire        JR;

    wire [1:0]  branch_predict;
    // wire [31:0] IR_RegF;
    wire        wen;
    wire        flushifdec;
    wire        flushdecex;
    wire        flushexmem;
    wire        PCEnable;
    wire        stall_dec;

    wire [4:0]  shamt;
    wire [15:0] immediate;
    wire [31:0] ExtOut;

    wire [4:0]  Rt;
    wire [4:0]  Rs;
    wire [4:0]  Rd;

    wire [31:0] A, B;

    // wire [31:0] branch_addr;

    reg         Branch_RegD_r, Branch_RegD_w;
    reg         RegWrite_RegD_r, RegWrite_RegD_w;
    reg  [1:0]  MemToReg_RegD_r, MemToReg_RegD_w;
    reg         MemWrite_RegD_r, MemWrite_RegD_w;
    reg  [3:0]  ALUOp_RegD_r, ALUOp_RegD_w;
    // wire [5:0]  funct_RegD;
    reg  [5:0]  funct_RegD_r;
    wire [5:0]  funct_RegD_w;
    reg  [31:0] A_RegD_r;
    wire [31:0] A_RegD_w;
    reg  [31:0] B_RegD_r;
    wire [31:0] B_RegD_w;
    reg         ALUSrc_RegD_r, ALUSrc_RegD_w;
    reg  [31:0] ExtOut_RegD_r;
    wire [31:0] ExtOut_RegD_w;
    reg  [4:0]  wsel_RegD_r, wsel_RegD_w;
    reg  [4:0]  Rs_RegD_r;
    wire [4:0]  Rs_RegD_w;
    reg  [4:0]  Rt_RegD_r;
    wire [4:0]  Rt_RegD_w;
    reg         JAL_RegD_r;
    wire        JAL_RegD_w;
    reg         JR_RegD_r;
    wire        JR_RegD_w;
    reg  [31:0] branch_addr_RegD_r;
    wire [31:0] branch_addr_RegD_w;

//========== EXE ==================================================//
    wire [1:0]  FU_ASel;
    wire [1:0]  FU_BSel;

    wire [3:0]  alu_op;
    wire        zero;
    wire [31:0] alu_out;

    reg  [31:0] ALU_in_A;
    wire [31:0] ALU_in_B;

    reg  [31:0] B_FUSel;

    // wire        Branch_RegE;
    reg         Branch_RegE_r;
    wire        Branch_RegE_w;
    // wire        RegWrite_RegE;
    reg         RegWrite_RegE_r;
    wire        RegWrite_RegE_w;
    reg  [1:0]  MemToReg_RegE_r;
    wire [1:0]  MemToReg_RegE_w;
    reg         MemWrite_RegE_r;
    wire        MemWrite_RegE_w;
    // wire        zero_RegE;
    reg         zero_RegE_r;
    wire        zero_RegE_w;
    // wire        JR_RegE;
    reg         JR_RegE_r;
    wire        JR_RegE_w;
    reg  [31:0] alu_out_RegE_r;
    wire [31:0] alu_out_RegE_w;
    reg  [31:0] B_RegE_r;
    wire [31:0] B_RegE_w; // after FU_BSel
    // reg  [31:0] ExtOut_RegE_r; // replace with branch_addr
    // wire [31:0] ExtOut_RegE_w;
    // wire [4:0]  wsel_RegE;
    reg  [4:0]  wsel_RegE_r;
    wire [4:0]  wsel_RegE_w;
    reg  [31:0] branch_addr_RegE_r;
    wire [31:0] branch_addr_RegE_w;
    
//========== EXE ==================================================//
    wire [31:0] data_out;
    reg  [31:0] WriteData;

    reg  [1:0]  MemToReg_RegM_r;
    wire [1:0]  MemToReg_RegM_w;
    reg  [31:0] data_out_RegM_r;
    wire [31:0] data_out_RegM_w;
    reg  [31:0] alu_out_RegM_r;
    wire [31:0] alu_out_RegM_w;
    // wire        RegWrite_RegM;
    reg         RegWrite_RegM_r;
    wire        RegWrite_RegM_w;
    // wire [4:0]  wsel_RegM;
    reg  [4:0]  wsel_RegM_r;
    wire [4:0]  wsel_RegM_w;

/////////////////////////////////////////////////////////////////////
///// architecture by stage /////////////////////////////////////////

//========== wire alias ===========================================//
//// NOTICE: use _r as submodule input seems work as well
    // assign IR_RegF     = IR_RegF_r;
    // assign Rt_RegD     = Rt_RegD_r;
    // assign Branch_RegE = Branch_RegE_r;
    // assign zero_RegE   = zero_RegE_r;

    // assign RegWrite_RegM = RegWrite_RegM_r;
    // assign wsel_RegM     = wsel_RegM_r;
    // assign Rs_RegD = Rs_RegD_r;
    // assign Rt_RegD = Rt_RegD_r;
//========== IF ===================================================//
// wen handle
    assign wen = ~(ICACHE_stall == 1 || DCACHE_stall == 1);
// PCSrcLogic: i/p {JR_regE_r, zero_regE_r, Branch_sel, Jump}
    always @(*) begin
        // if(zero_RegE_r & Branch_RegE_r)  PCSrc = 2'b01;
        if(branch_predict[0] | branch_predict[1])   PCSrc = 2'b01;
        else if(Jump)                               PCSrc = 2'b10;
        else if(JR_RegE_r)                          PCSrc = 2'b11;
        else                                        PCSrc = 2'b00;
    end

// PC_Mux
    always @(*) begin
        case (PCSrc)
            2'b00: PC_w = PCPlus4;
            2'b01: PC_w = branch_addr;
            2'b10: PC_w = jump_addr;
            2'b11: PC_w = alu_out_RegE_r;
            default : PC_w = PC_r;
        endcase
        // if(~PCEnable) PC_w = PC_r;
    end

// PC
    assign addr_in = PC_r;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            PC_r <= 0;
        end else if(~PCEnable | ~wen) begin
            PC_r <= PC_r;
        end else begin
            PC_r <= PC_w;
        end
    end

// nextPCCalc: i/p {target_address, ExOut_RegE, addr_in}
    assign target_address = IR_RegF_r[25:0];
	always @(*) begin
		PCPlus4     = addr_in + 4;
		branch_addr = (branch_predict[1])? branch_addr_RegE_r : branch_addr_RegD_w;
		jump_addr   = {PC_r[31:28], target_address, 2'b00};
	end

// I Cache
    assign ICACHE_addr = PC_r[31:2];
    assign ICACHE_wen = 0;
    assign ICACHE_ren = 1;

//========== IF_ID register =======================================//
    // assign IR_RegF_w = (wen)? ICACHE_rdata : IR_RegF_r;
    // assign PCPlus4_RegF_w = (wen)? PCPlus4 : PCPlus4_RegF_r;

    assign IR_RegF_w = ICACHE_rdata;
    assign PCPlus4_RegF_w = PCPlus4;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            IR_RegF_r      <= 0;
            PCPlus4_RegF_r <= 0;
        end else if(~wen | stall_dec) begin
            IR_RegF_r <= IR_RegF_r; // wen = 0, keep old value
            PCPlus4_RegF_r <= PCPlus4_RegF_r;
        end else if(flushifdec) begin
            IR_RegF_r      <= 0;
            PCPlus4_RegF_r <= 0;
        end else begin
            IR_RegF_r <= IR_RegF_w;
            PCPlus4_RegF_r <= PCPlus4_RegF_w;
        end
    end

//========== ID ===================================================//
// Hazard Detectioin Unit
    hazardDetect hDect (
            .iInstruction(IR_RegF_r),
            .iJAL(JAL),
            .iJump(Jump),
            .iJR_RegE(JR_RegE_r),
            .iRt_RegD(Rt_RegD_r),
            .iload_RegD(MemToReg_RegD_r),
            // .izero_RegE(zero_RegE_r),
            // .iBranch_RegE(Branch_RegE_r),
            .ibranch_predict(branch_predict),
            .oflushifdec(flushifdec),
            .oflushdecex(flushdecex),
            .oflushexmem(flushexmem),
            .oPCEnable(PCEnable),
            .ostall_dec(stall_dec)
        );

// mainControl
    mainControl mCtrl(
            .iIR_opcode(IR_RegF_r[31:26]),
            .iIR_func(IR_RegF_r[5:0]),
            .oBranch(Branch),
            .oALUOp(ALUOp),
            .oExtOp(ExtOp),
            .oJump(Jump),
            .oMemWrite(MemWrite),
            .oRegWrite(RegWrite),
            .oMemToReg(MemToReg),
            .oALUSrc(ALUSrc),
            .oRegDST(RegDst),
            .oJAL(JAL),
            .oJR(JR)
        );

// branch_predict
    branch_predict bPred (
            //i/p    
                .clk(clk),
                .rst_n(rst_n),
                .iInstruction(IR_RegF_r),
                .izero_regE(zero_RegE_r),
                .iBranch_regE(Branch_RegE_r),
            //    ibranch_addr_RegE_r,
            //o/p
                .obp_predict(branch_predict) //[1] IS FLUSH_BIT, PC SHOULD EAT BPTH 2 BITS
        );


// mCtrl to ID/EXE MUX
    always @(*) begin
        if(~stall_dec) begin
            ALUOp_RegD_w    = ALUOp;
            MemWrite_RegD_w = MemWrite;
            MemToReg_RegD_w = MemToReg;
            RegWrite_RegD_w = RegWrite;
            Branch_RegD_w   = Branch;
            ALUSrc_RegD_w   = ALUSrc;
        end else begin
            ALUOp_RegD_w    = 0;
            MemWrite_RegD_w = 0;
            MemToReg_RegD_w = 0;
            RegWrite_RegD_w = 0;
            Branch_RegD_w   = 0;
            ALUSrc_RegD_w   = 0;
        end
    end

// extender
    assign shamt     = IR_RegF_r[10:6];
    assign immediate = IR_RegF_r[15:0];
    assign ExtOut    = (ExtOp)? {{27{shamt[4]}}, shamt} : {{16{immediate[15]}}, immediate};

// Rt & Rs
    assign Rs = IR_RegF_r[25:21];
    assign Rt = IR_RegF_r[20:16];
    assign Rd = IR_RegF_r[15:11];
    always @(*) begin
        case (RegDst)
            2'b00: wsel_RegD_w = Rt;
            2'b01: wsel_RegD_w = Rd;
            2'b10: wsel_RegD_w = 31; // for jal
            2'b11: wsel_RegD_w = Rs; // for sll
            default : wsel_RegD_w = wsel_RegD_r;
        endcase
    end

// registerFile
    register_file Register(
        .Clk(clk),
        .rst(rst_n),
        .WEN(RegWrite_RegM_r),
        .RW(wsel_RegM_r),
        .busW(WriteData),
        .RX(Rs),
        .RY(Rt),
        .busX(A),
        .busY(B)
    );

// branch_addr
    // assign branch_addr = PCPlus4_RegF_r + ExtOut;
//========== ID_EXE register ======================================//
    assign funct_RegD_w       = (ALUOp == 2'b11)? IR_RegF_r[31:26] : IR_RegF_r[5:0]; // can use ExtOut instead
    assign Rs_RegD_w          = Rs;
    assign Rt_RegD_w          = Rt;
    assign A_RegD_w           = (JAL)? PCPlus4_RegF_r : A;
    assign B_RegD_w           = B;
    assign ExtOut_RegD_w      = ExtOut;
    assign JAL_RegD_w         = JAL;
    assign JR_RegD_w          = JR;
    assign branch_addr_RegD_w = PCPlus4_RegF_r + {{14{immediate[15]}}, immediate, 2'b00};
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            Branch_RegD_r       <= 0;
            RegWrite_RegD_r     <= 0;
            MemToReg_RegD_r     <= 0;
            MemWrite_RegD_r     <= 0;
            ALUOp_RegD_r        <= 0;
            funct_RegD_r        <= 0;
            A_RegD_r            <= 0;
            ALUSrc_RegD_r       <= 0;
            ExtOut_RegD_r       <= 0;
            B_RegD_r            <= 0;
            wsel_RegD_r         <= 0;
            Rs_RegD_r           <= 0;
            Rt_RegD_r           <= 0;
            JAL_RegD_r          <= 0;
            JR_RegD_r           <= 0;
            branch_addr_RegD_r  <= 0;
        end else if(~wen) begin
            Branch_RegD_r       <= Branch_RegD_r;
            RegWrite_RegD_r     <= RegWrite_RegD_r;
            MemToReg_RegD_r     <= MemToReg_RegD_r;
            MemWrite_RegD_r     <= MemWrite_RegD_r;
            ALUOp_RegD_r        <= ALUOp_RegD_r;
            funct_RegD_r        <= funct_RegD_r;
            A_RegD_r            <= A_RegD_r;
            ALUSrc_RegD_r       <= ALUSrc_RegD_r;
            ExtOut_RegD_r       <= ExtOut_RegD_r;
            B_RegD_r            <= B_RegD_r;
            wsel_RegD_r         <= wsel_RegD_r;
            Rs_RegD_r           <= Rs_RegD_r;
            Rt_RegD_r           <= Rt_RegD_r;
            JAL_RegD_r          <= JAL_RegD_r; 
            JR_RegD_r           <= JR_RegD_r;
            branch_addr_RegD_r  <= branch_addr_RegD_r;
        end else if(flushdecex) begin
            Branch_RegD_r       <= 0;
            RegWrite_RegD_r     <= 0;
            MemToReg_RegD_r     <= 0;
            MemWrite_RegD_r     <= 0;
            ALUOp_RegD_r        <= 0;
            funct_RegD_r        <= 0;
            A_RegD_r            <= 0;
            ALUSrc_RegD_r       <= 0;
            ExtOut_RegD_r       <= 0;
            B_RegD_r            <= 0;
            wsel_RegD_r         <= 0;
            Rs_RegD_r           <= 0;
            Rt_RegD_r           <= 0;
            JAL_RegD_r          <= 0;
            JR_RegD_r           <= 0;
            branch_addr_RegD_r  <= 0;
        end else begin
            Branch_RegD_r       <= Branch_RegD_w;
            RegWrite_RegD_r     <= RegWrite_RegD_w;
            MemToReg_RegD_r     <= MemToReg_RegD_w;
            MemWrite_RegD_r     <= MemWrite_RegD_w;
            ALUOp_RegD_r        <= ALUOp_RegD_w;
            funct_RegD_r        <= funct_RegD_w;
            A_RegD_r            <= A_RegD_w;
            ALUSrc_RegD_r       <= ALUSrc_RegD_w;
            ExtOut_RegD_r       <= ExtOut_RegD_w;
            B_RegD_r            <= B_RegD_w;
            wsel_RegD_r         <= wsel_RegD_w;
            Rs_RegD_r           <= Rs_RegD_w;
            Rt_RegD_r           <= Rt_RegD_w;
            JAL_RegD_r          <= JAL_RegD_w;
            JR_RegD_r           <= JR_RegD_w;
            branch_addr_RegD_r  <= branch_addr_RegD_w;
        end
    end

//========== EXE ==================================================//
// forwarding unit4

    ForwardUnit FUnit (
            .iRs_RegD(Rs_RegD_r),
            .iRt_RegD(Rt_RegD_r),
            .iwsel_RegE(wsel_RegE_r),
            .iRegWrite_RegE(RegWrite_RegE_r),
            .iwsel_RegM(wsel_RegM_r),
            .iRegWrite_RegM(RegWrite_RegM_r),
            .oFU_ASel(FU_ASel),
            .oFU_BSel(FU_BSel)
        );

// ALUControl
    ALUControl ALUCtrl (
            .iALUOp(ALUOp_RegD_r),
            .iIR_func(funct_RegD_r),
            .iJAL(JAL_RegD_r),
            // .oJR(JR),
            .oALUctrl(alu_op)
        );

// ALU_in_A mux
    always @(*) begin
        case (FU_ASel)
            2'b00: ALU_in_A = A_RegD_r;
            2'b01: ALU_in_A = WriteData;
            2'b10: ALU_in_A = alu_out_RegE_r;
            default : ALU_in_A = 0;
        endcase
    end

// ALU_in_B mux
    assign ALU_in_B = (ALUSrc_RegD_r)? B_FUSel : ExtOut_RegD_r;
    always @(*) begin
        case (FU_BSel)
            2'b00: B_FUSel = B_RegD_r;
            2'b01: B_FUSel = WriteData;
            2'b10: B_FUSel = alu_out_RegE_r;
            default : B_FUSel = 0;
        endcase
    end

// ALU
    alu ALU(
        .ctrl(alu_op),
        .x(ALU_in_A),
        .y(ALU_in_B),
        .carry(),
        .out(alu_out),
        .zero(zero)
    );

//========== EXE_MEM register =====================================//
    // assign JR_RegE         = JR_RegE_r;
    assign Branch_RegE_w        = Branch_RegD_r;
    // assign Branch_RegE          = Branch_RegE_r;
    assign zero_RegE_w          = zero;
    // assign zero_RegE            = zero_RegE_r;
    assign JR_RegE_w            = JR_RegD_r;
    assign MemToReg_RegE_w      = MemToReg_RegD_r;
    assign MemWrite_RegE_w      = MemWrite_RegD_r;
    assign alu_out_RegE_w       = alu_out;
    assign B_RegE_w             = B_FUSel;
    // assign ExtOut_RegE_w        = {ExtOut_RegD_r[15:2], 2'b0};
    assign RegWrite_RegE_w      = RegWrite_RegD_r;
    assign wsel_RegE_w          = wsel_RegD_r;
    assign branch_addr_RegE_w   = branch_addr_RegD_r;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            Branch_RegE_r       <= 0;
            zero_RegE_r         <= 0;
            JR_RegE_r           <= 0;
            MemToReg_RegE_r     <= 0;
            MemWrite_RegE_r     <= 0;
            alu_out_RegE_r      <= 0;
            B_RegE_r            <= 0;
            // ExtOut_RegE_r       <= 0;
            RegWrite_RegE_r     <= 0;
            wsel_RegE_r         <= 0;
            branch_addr_RegE_r  <= 0;
        end else if(~wen) begin
            Branch_RegE_r       <= Branch_RegE_r;
            zero_RegE_r         <= zero_RegE_r;
            JR_RegE_r           <= JR_RegE_r;
            MemToReg_RegE_r     <= MemToReg_RegE_r;
            MemWrite_RegE_r     <= MemWrite_RegE_r;
            alu_out_RegE_r      <= alu_out_RegE_r;
            B_RegE_r            <= B_RegE_r;
            // ExtOut_RegE_r       <= ExtOut_RegE_r;
            RegWrite_RegE_r     <= RegWrite_RegE_r;
            wsel_RegE_r         <= wsel_RegE_r;
            branch_addr_RegE_r  <= branch_addr_RegE_r;
        end else if(flushexmem) begin
            Branch_RegE_r       <= 0;
            zero_RegE_r         <= 0;
            JR_RegE_r           <= 0;
            MemToReg_RegE_r     <= 0;
            MemWrite_RegE_r     <= 0;
            alu_out_RegE_r      <= 0;
            B_RegE_r            <= 0;
            // ExtOut_RegE_r       <= 0;
            RegWrite_RegE_r     <= 0;
            wsel_RegE_r         <= 0;
            branch_addr_RegE_r  <= 0;
        end else begin
            Branch_RegE_r       <= Branch_RegE_w;
            zero_RegE_r         <= zero_RegE_w;
            JR_RegE_r           <= JR_RegE_w;
            MemToReg_RegE_r     <= MemToReg_RegE_w;
            MemWrite_RegE_r     <= MemWrite_RegE_w;
            alu_out_RegE_r      <= alu_out_RegE_w;
            B_RegE_r            <= B_RegE_w;
            // ExtOut_RegE_r       <= ExtOut_RegE_w;
            RegWrite_RegE_r     <= RegWrite_RegE_w;
            wsel_RegE_r         <= wsel_RegE_w;
            branch_addr_RegE_r  <= branch_addr_RegE_w;
        end
    end

//========== MEM ==================================================//
// D Cache
    assign DCACHE_wdata = B_RegE_r;
    assign data_out     = DCACHE_rdata;
    assign DCACHE_addr = alu_out_RegE_r[31:2];
    assign DCACHE_wen = MemWrite_RegE_r;
    assign DCACHE_ren = MemToReg_RegE_r; // MemToReg == MemRead

//========== MEM_WB register ======================================//
    assign MemToReg_RegM_w = MemToReg_RegE_r;
    assign data_out_RegM_w = data_out;
    assign alu_out_RegM_w  = alu_out_RegE_r;
    assign wsel_RegM_w     = wsel_RegE_r;
    assign RegWrite_RegM_w = RegWrite_RegE_r;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            MemToReg_RegM_r <= 0;
            data_out_RegM_r <= 0;
            alu_out_RegM_r  <= 0;
            wsel_RegM_r     <= 0;
            RegWrite_RegM_r <= 0;
        end else if(~wen) begin
            MemToReg_RegM_r <= MemToReg_RegM_r;
            data_out_RegM_r <= data_out_RegM_r;
            alu_out_RegM_r  <= alu_out_RegM_r;
            wsel_RegM_r     <= wsel_RegM_r;
            RegWrite_RegM_r <= RegWrite_RegM_r;            
        end else begin
            MemToReg_RegM_r <= MemToReg_RegM_w;
            data_out_RegM_r <= data_out_RegM_w;
            alu_out_RegM_r  <= alu_out_RegM_w;
            wsel_RegM_r     <= wsel_RegM_w;
            RegWrite_RegM_r <= RegWrite_RegM_w;
        end
    end

//========== WB ===================================================//
// MemToReg MUX
    always @(*) begin
        // case (MemToReg_RegM_r)
        //     2'b00: WriteData = alu_out_RegM_r;
        //     2'b01: WriteData = data_out_RegM_r;
        //     2'b10: WriteData = PCPlus4;
        //     default : /* default */;
        // endcase
        WriteData = 0;
        case (MemToReg_RegM_r)
            2'b00: WriteData = alu_out_RegM_r;
            2'b01: WriteData = data_out_RegM_r;
            2'b10: WriteData = alu_out_RegM_r;
            default : /* default */;
        endcase
    end
    // always @(*) begin
    //     if(MemToReg_RegM_r) alu_out_RegM_w;
    //     else                data_out_RegM_r;
    // end

//========== WB ===================================================//
// debug
    // always @(*) begin
    //     // if(wsel_RegM_r == 29 && RegWrite_RegM_r == 1) begin
    //     //     $display("write to $29, addr = %d", PC_r);
    //     //     $display("value = %h", WriteData);
    //     // end
    //     // if(JR && Rs == 29) begin
    //     //     $display("JR to $29, addr = %h", ICACHE_addr);
    //     //     $display("value = %h", A);
    //     // end
    //     if(Branch_RegE_r == 1 && zero_RegE_r == 1) begin
    //         $display("Branch to %d", branch_addr_RegE_r[31:2]);
    //     end
    // end


endmodule