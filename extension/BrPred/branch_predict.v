<<<<<<< HEAD
module branch_predict(
//i/p    
    clk,
    rst_n,
    iInstruction,
    izero_regE,
    iBranch_regE,
//    ibranch_addr_RegE_r,
//o/p
    obp_predict //[1] IS FLUSH_BIT, PC SHOULD EAT BPTH 2 BITS
);

input clk;
input rst_n;
input [31:0] iInstruction;
input izero_regE;
input iBranch_regE;
//input ibranch_addr_RegE_r;

output reg [1:0] obp_predict;
//output reg obp_flush;

wire beq_secc, beq_inst;
reg [1:0] bp_state, nxt_state;
reg pre_regD, pre_regE;

assign beq_secc = (iBranch_regE & izero_regE);
assign beq_inst = (iInstruction[31:26] == 6'd4);

always@ (*) begin//STATE TRANSITION
    nxt_state = bp_state;
    if(iBranch_regE) begin
        if(pre_regE == beq_secc)
            nxt_state[0] = 1;
        else if(bp_state[0] == 0)
            nxt_state[1] = ~bp_state[1];
        else
            nxt_state[0] = 0;
    end
end

always@ (*) begin//O/P CTRL
    if(beq_secc) begin
        obp_predict[1] = (pre_regE != beq_secc);
    end else if(beq_secc | beq_inst) begin
        obp_predict[0] = bp_state[1];
    end else
        obp_predict = 2'b00;
    
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        bp_state <= 2'b00;
        pre_regD <= 0;
        pre_regE <= 0;
    end else begin
        bp_state <= nxt_state;
        pre_regD <= (obp_predict[0] & ~(obp_predict[1]));
        pre_regE <= pre_regD;
    end
end
endmodule // branch_predict
=======
module branch_predict(
//i/p    
    clk,
    rst_n,
    iInstruction,
    izero_regE,
    iBranch_regE,
//    ibranch_addr_RegE_r,
//o/p
    obp_predict //[1] IS FLUSH_BIT, PC SHOULD EAT BPTH 2 BITS
);

input clk;
input rst_n;
input [31:0] iInstruction;
input izero_regE;
input iBranch_regE;
//input ibranch_addr_RegE_r;

output [1:0] obp_predict;
//output reg obp_flush;

wire beq_secc, beq_inst;
reg [1:0] bp_state, nxt_state;
reg pre_regD, pre_regE;
reg [1:0] bp_predict;

assign obp_predict = bp_predict;

assign beq_secc = (iBranch_regE & izero_regE);
assign beq_inst = (iInstruction[31:26] == 4);

always@ (*) begin//STATE TRANSITION
    nxt_state = bp_state;
    if(iBranch_regE) begin
        if(pre_regE == beq_secc)
            nxt_state[0] = 1;
        else if(bp_state[0] == 0)
            nxt_state[1] = ~bp_state[1];
        else
            nxt_state[0] = 0;
    end
end

always@ (*) begin//O/P CTRL
    if(pre_regE != beq_secc) begin
        bp_predict[1] = 1;
        bp_predict[0] = bp_state[1];
    end else if(beq_inst) begin
        bp_predict[0] = 0;
        bp_predict[0] = bp_state[1];    
    end else
        bp_predict = 2'b00;
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        bp_state <= 2'b00;
        pre_regD <= 0;
        pre_regE <= 0;
    end else begin
        bp_state <= nxt_state;
        pre_regD <= bp_predict;
        pre_regE <= pre_regD;
    end
end

endmodule

>>>>>>> origin/master
