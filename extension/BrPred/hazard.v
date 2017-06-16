module hazardDetect(
//i/p
    iRt_RegD,
    iload_RegD,
    iInstruction,
    
    iJump,
    iJR_RegE,
    iJAL,
    // izero_RegE,
    // iBranch_RegE,
    ibranch_predict,
    
    //FU_ASel,
    //FU_BSel,
//o/p
    ostall_dec,//LOADUSEDATAHAZARD
    oPCEnable,
    oflushifdec,//CONTROLHAZARD
    oflushdecex,
    oflushexmem
);

input           iJump;
input           iJR_RegE;
input [4:0]     iRt_RegD;
input [1:0]     iload_RegD;
input           iJAL;
input [31:0]    iInstruction;
// input           izero_RegE;
// input           iBranch_RegE;
input [1:0]     ibranch_predict;

output reg      ostall_dec;
output reg      oflushexmem;
output reg      oflushifdec;
output reg      oflushdecex;
output reg      oPCEnable;

// wire forward2, stall, beq_secc;
wire forward2, stall;

assign forward2 = ( iInstruction[25:11] == iRt_RegD || iInstruction[20:16] == iRt_RegD );
assign stall = ((iload_RegD == 2'b01) && forward2);
// assign beq_secc = iBranch_RegE & izero_RegE;

always@ (*) begin//D
    oPCEnable = ~stall;
    ostall_dec = stall;
end

always@ (*) begin//C

    oflushifdec = 0;
    oflushdecex = 0;
    oflushexmem = 0;

    if(iJR_RegE | ibranch_predict[1]) begin
        oflushifdec = 1;
        oflushdecex = 1;
        oflushexmem = 1;
    end
    else if(ibranch_predict[0]) begin
        oflushifdec = 1;
    end
    // if(beq_secc) begin
    //     oflushifdec = 1;
    //     oflushdecex = 1;
    //     oflushexmem = 1;
    // end
    else if(iJAL|iJump) begin
        oflushifdec = 1;
        // oflushdecex = 1;        
    end
end

endmodule // hazardDetect