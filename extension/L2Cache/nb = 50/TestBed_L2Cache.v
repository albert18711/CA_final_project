`timescale 1 ns/10 ps
`define	TestPort	30'h40      // r30
`define	BeginSymbol	32'h00000932
`define	EndSymbol	32'h00000D5D
`define	CheckNum	6'd61       // modify1 for number*2+1(CheckNum)

module	TestBed(
	clk,
	rst,
	addr,
	data,
	wen,
	error_num,
	duration,
	finish
);
	input			clk, rst;
	input	[29:0]	addr;
	input	[31:0]	data;
	input			wen;

	output	[7:0]	error_num;
	output	[15:0]	duration;
	output			finish;
	reg		[7:0]	error_num;
	reg		[15:0]	duration;
	reg				finish;
	
	reg		[31:0]	answer;

	reg		[1:0]	curstate;
	reg		[1:0]	nxtstate;
	reg		[5:0]	curaddr;
	reg		[5:0]	nxtaddr;
	reg		[7:0]	nxt_error_num;
	reg		[15:0]	nxtduration;
	
	reg				state,state_next;
		
	parameter	state_idle 	= 2'b00;
	parameter	state_check = 2'b01;
	parameter	state_report= 2'b10;	
		
	always@( posedge clk or negedge rst )						// State-DFF
	begin
		if( ~rst )
		begin
			curstate <= state_idle;
			curaddr  <= 0;
			duration <= 0;
			error_num <= 8'd255;
			
			state <= 0;
		end
		else
		begin
			curstate <= nxtstate;
			curaddr  <= nxtaddr;
			duration <= nxtduration;
			error_num <= nxt_error_num;
			
			state <= state_next;
		end
	end
			
	always@( curstate or curaddr or addr or data or wen or duration or error_num  )	// FSM for test
	begin
		finish = 1'b0;
		case( curstate )
		state_idle: 	begin
							nxtaddr = 0;
							nxtduration = 0;
							nxt_error_num = 255;	
							if( addr==`TestPort && data==`BeginSymbol && wen )
							begin
								nxt_error_num = 0;
								nxtstate = state_check;
							end	 	
							else nxtstate = state_idle;
						end
		state_check:	begin
							nxtduration = duration + 1;
							nxtaddr = curaddr;						
							nxt_error_num = error_num;	
							if( addr==`TestPort && wen && state==0 )
							begin
								nxtaddr = curaddr + 1;
								if( data != answer )
									nxt_error_num = error_num + 8'd1;
							end
							nxtstate = curstate;
							if( curaddr==`CheckNum )	
								nxtstate = state_report;
						end
		state_report:	begin
							finish = 1'b1;
							nxtaddr = curaddr;
							nxtstate = curstate;		
							nxtduration = duration;
							nxt_error_num = error_num;	
						end				
		endcase	
	end

	always@( negedge clk )						
	begin
		if(curstate == state_report) begin
			$display("--------------------------- Simulation FINISH !!---------------------------");
			if (error_num) begin 
				$display("============================================================================");
				$display("\n (T_T) FAIL!! The simulation result is FAIL!!! there were %d errors at all.\n", error_num);
				$display("============================================================================");
			end
			 else begin 
				$display("============================================================================");
				$display("\n \\(^o^)/ CONGRATULATIONS!!  The simulation result is PASS!!!\n");
				$display("============================================================================");
			end
		end
	end
	
	always@(*)begin//sub-FSM (avoid the Dcache stall condition)
		case(state)
			1'b0:begin
				if(wen)
					state_next=1;
				else
					state_next=state;				
			end
			1'b1:begin
				if(!wen)
					state_next=0;
				else
					state_next=state;	
			end
		endcase
	end
	
	
	always@( curstate  or curaddr)	// ROM for correct result
	begin
		answer = 0;
		case( curaddr )
		// modify2 for 0-514229, 514229-0, `EndSymbol
		6'd0 :answer = 32'd0;
		6'd1 :answer = 32'd1;
		6'd2 :answer = 32'd1;
		6'd3 :answer = 32'd2;
		6'd4 :answer = 32'd3;
		6'd5 :answer = 32'd5;
		6'd6 :answer = 32'd8;
		6'd7 :answer = 32'd13;
		6'd8 :answer = 32'd21;
		6'd9 :answer = 32'd34;
		6'd10 :answer = 32'd55;
		6'd11 :answer = 32'd89;
		6'd12 :answer = 32'd144;
		6'd13 :answer = 32'd233;
		6'd14 :answer = 32'd377;
		6'd15 :answer = 32'd610;
		6'd16 :answer = 32'd987;
		6'd17 :answer = 32'd1597;
		6'd18 :answer = 32'd2584;
		6'd19 :answer = 32'd4181;
		6'd20 :answer = 32'd6765;
		6'd21 :answer = 32'd10946;
		6'd22 :answer = 32'd17711;
		6'd23 :answer = 32'd28657;
		6'd24 :answer = 32'd46368;
		6'd25 :answer = 32'd75025;
		6'd26 :answer = 32'd121393;
		6'd27 :answer = 32'd196418;
		6'd28 :answer = 32'd317811;
		6'd29 :answer = 32'd514229;
		6'd30 :answer = 32'd514229;
		6'd31 :answer = 32'd317811;
		6'd32 :answer = 32'd196418;
		6'd33 :answer = 32'd121393;
		6'd34 :answer = 32'd75025;
		6'd35 :answer = 32'd46368;
		6'd36 :answer = 32'd28657;
		6'd37 :answer = 32'd17711;
		6'd38 :answer = 32'd10946;
		6'd39 :answer = 32'd6765;
		6'd40 :answer = 32'd4181;
		6'd41 :answer = 32'd2584;
		6'd42 :answer = 32'd1597;
		6'd43 :answer = 32'd987;
		6'd44 :answer = 32'd610;
		6'd45 :answer = 32'd377;
		6'd46 :answer = 32'd233;
		6'd47 :answer = 32'd144;
		6'd48 :answer = 32'd89;
		6'd49 :answer = 32'd55;
		6'd50 :answer = 32'd34;
		6'd51 :answer = 32'd21;
		6'd52 :answer = 32'd13;
		6'd53 :answer = 32'd8;
		6'd54 :answer = 32'd5;
		6'd55 :answer = 32'd3;
		6'd56 :answer = 32'd2;
		6'd57 :answer = 32'd1;
		6'd58 :answer = 32'd1;
		6'd59 :answer = 32'd0;
		6'd60 :answer = `EndSymbol;
		endcase
	end

endmodule