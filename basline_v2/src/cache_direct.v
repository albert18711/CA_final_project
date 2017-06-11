module cache(
    clk,
    proc_reset,
    proc_read,
    proc_write,
    proc_addr,
    proc_wdata,
    proc_stall,
    proc_rdata,
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    
//==== input/output definition ============================
    input          clk;
    // processor interface
    input          proc_reset;
    input          proc_read, proc_write;
    input   [29:0] proc_addr;
    input   [31:0] proc_wdata;
    output         proc_stall;
    output  [31:0] proc_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output         mem_read, mem_write;
    output  [27:0] mem_addr;
    output [127:0] mem_wdata;
    
//==== wire/reg definition ================================
	
	//output reg
	reg reg_proc_stall;
	reg [31:0] reg_proc_rdata, cur_proc_rdata;
	reg reg_mem_read, reg_mem_write;
    reg [127:0] reg_mem_wdata;
	reg [27:0] reg_mem_addr;
	//others
	wire [1:0] offset;
	wire [26:0] tag;
	wire [2:0] index;
	wire valid;
	wire dirty;
	
	wire TAG_SAME;

	reg [2:0] state, next_state;
	
	reg [154:0] cache [0:7]; //8 blocks 4 words + tag + valid + dirty (128+25+1+1)
	reg [154:0] cache_block;
	
	
parameter S_IDLE = 0,
		  S_READ = 1,
		  S_WRITE = 2,
		  S_WRITE_TO_MEM = 3,
		  S_READ_FROM_MEM = 4;
	
//=========================================================
assign proc_stall = reg_proc_stall;
assign mem_read = reg_mem_read;
assign mem_write = reg_mem_write;
assign mem_wdata = reg_mem_wdata;
assign proc_rdata = reg_proc_rdata;
assign mem_addr = reg_mem_addr;

//assign cache_block = cache[index]; //but cache_block is a reg ???


assign offset = proc_addr[1:0];
assign index = proc_addr[4:2];
assign tag = proc_addr[29:5];
assign dirty = cache_block[153];
assign valid = cache_block[154];

assign TAG_SAME = (tag == cache_block[152:128]);




//==== combinational circuit ==============================
always@(*) begin
	if(proc_reset) begin
		reg_proc_rdata = 0;
	end else if(state == S_READ) begin
		case(offset)
			0: reg_proc_rdata = cache_block[31:0];
			1: reg_proc_rdata = cache_block[63:32];
			2: reg_proc_rdata = cache_block[95:64];
			3: reg_proc_rdata = cache_block[127:96];
			default: reg_proc_rdata = cur_proc_rdata;
		endcase
	end else begin
		reg_proc_rdata = cur_proc_rdata; //????????
	end
end

always@(*) begin
	if(proc_reset) begin
		reg_mem_addr = 0;
	end else if(state == S_WRITE_TO_MEM) begin
		reg_mem_addr[27:3] = cache_block[152:128]; //mem_addr use cache's tag
		reg_mem_addr[2:0] = index;
	end else begin
		reg_mem_addr = proc_addr[29:2];
	end
end

always@(*) begin
	if(proc_reset) begin
		reg_proc_stall = 0;
	end else if((next_state == S_READ_FROM_MEM) || (next_state == S_WRITE_TO_MEM) || (state == S_READ_FROM_MEM)) begin
		reg_proc_stall = 1;
	end else begin
		reg_proc_stall = 0;
	end
end

always@(*) begin
	if(proc_reset) begin
		reg_mem_read = 0;
	end else if(mem_ready) begin
		reg_mem_read = 0;
	end else if(state == S_READ_FROM_MEM) begin
		reg_mem_read = 1;
	end else begin
		reg_mem_read = 0;
	end
end

always@(*) begin
	if(proc_reset) begin
		reg_mem_write = 0;
	end else if(mem_ready) begin
		reg_mem_write = 0;
	end else if(state == S_WRITE_TO_MEM) begin
		reg_mem_write = 1;
	end else begin
		reg_mem_write = 0;
	end
end

always@(*) begin
	if(proc_reset) begin
		reg_mem_wdata = 0;
	end else if(state == S_WRITE_TO_MEM) begin //XXX S_WRITE
		reg_mem_wdata = cache_block[127:0];
	end else begin
		reg_mem_wdata = 0; // = current data ???
	end
end

always@(*) begin //valid, dirty
	cache_block = cache[index];
	if(proc_reset) begin
		/*cache[0] = 0;
		cache[1] = 0;
		cache[2] = 0;
		cache[3] = 0;
		cache[4] = 0;
		cache[5] = 0;
		cache[6] = 0;
		cache[7] = 0;*/
		cache_block = 0;
	end else if(state == S_IDLE) begin
		case(index)
			0: cache_block = cache[0];
			1: cache_block = cache[1];
			2: cache_block = cache[2];
			3: cache_block = cache[3];
			4: cache_block = cache[4];
			5: cache_block = cache[5];
			6: cache_block = cache[6];
			7: cache_block = cache[7];
			default: cache_block = cache[index]; //?????
		endcase
	end else if(state == S_WRITE) begin
		cache_block[154] = 1;
		cache_block[153] = 1;
		case(offset)
			0: cache_block[31:0] = proc_wdata;
			1: cache_block[63:32] = proc_wdata;
			2: cache_block[95:64] = proc_wdata;
			3: cache_block[127:96] = proc_wdata;
			default: cache_block = 0; //???
		endcase
	end else if(state == S_WRITE_TO_MEM) begin
		cache_block[153] = 0;
	end else if(state == S_READ_FROM_MEM) begin
		cache_block[154] = 1;
		//cache_block[153] = 1;
		cache_block[152:128] = tag;
		cache_block[127:0] = mem_rdata; //dirty = 1, valid = 1
	end else begin
		cache_block[154:0] = cache[index]; //???????????????
	end
end


/************************
TODO:
1.add output register. (mem_read, mem_write...)
2.continue state "write".(only finish read now)
3.every output/reg should be take care.
  => dirty, valid, cache[][], mem_wdata......
*************************/


always@(*) begin
	if(proc_reset) begin
		next_state = S_IDLE;
	end else begin
		case(state)
			S_IDLE, S_READ, S_WRITE: begin
				if(proc_read || proc_write) begin
					if((TAG_SAME_0 && valid_0) || (TAG_SAME_1 && valid_1)) begin //hit
						if(proc_read) next_state = S_READ;
						else if(proc_write) next_state = S_WRITE;
						else next_state = state;
					end else begin
						if(((next_way == 0) && dirty_0) || (next_way) && dirty_1) next_state = S_WRITE_TO_MEM;
						else next_state = S_READ_FROM_MEM;
					end
				end else begin
					next_state = state;
				end
			end
			S_WRITE_TO_MEM: begin
				if(mem_ready) next_state = S_READ_FROM_MEM;
				else next_state = state;
			end
			S_READ_FROM_MEM: begin
				if(mem_ready) begin
					if(proc_read) next_state = S_READ;
					else if(proc_write) next_state = S_WRITE;
				end else next_state = state;
			end
			default: next_state = state;
		endcase
	end
end
		
//==== sequential circuit =================================
always@( posedge clk or posedge proc_reset ) begin
    if( proc_reset ) begin
		state <= S_IDLE;
		cur_proc_rdata <= 0;
		cache[0] <= 0;
		cache[1] <= 0;
		cache[2] <= 0;
		cache[3] <= 0;
		cache[4] <= 0;
		cache[5] <= 0;
		cache[6] <= 0;
		cache[7] <= 0;
    end
    else begin
		state <= next_state;
		cur_proc_rdata <= reg_proc_rdata;
		case(index)
			0: cache[0] <= cache_block;
			1: cache[1] <= cache_block;
			2: cache[2] <= cache_block;
			3: cache[3] <= cache_block;
			4: cache[4] <= cache_block;
			5: cache[5] <= cache_block;
			6: cache[6] <= cache_block;
			7: cache[7] <= cache_block;
			default: cache[index] <= 0; //?????
		endcase
    end
end

endmodule
