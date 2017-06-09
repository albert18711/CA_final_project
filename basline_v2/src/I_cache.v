module I_cache(
    clk,
    rst_n,
    ICACHE_ren,
    ICACHE_wen,
    ICACHE_addr,
    ICACHE_wdata,
    ICACHE_stall,
    ICACHE_rdata,
    mem_read_I,
    mem_write_I,
    mem_addr_I,
    mem_rdata_I,
    mem_wdata_I,
    mem_ready_I
);
    
//==== input/output definition ============================
    input          clk;
    // processor interface
    input          rst_n;
    input          ICACHE_ren, ICACHE_wen;
    input   [29:0] ICACHE_addr;
    input   [31:0] ICACHE_wdata;
    output         ICACHE_stall;
    output  [31:0] ICACHE_rdata;
    // memory interface
    input  [127:0] mem_rdata_I;
    input          mem_ready_I;
    output         mem_read_I, mem_write_I;
    output  [27:0] mem_addr_I;
    output [127:0] mem_wdata_I;
    
//==== wire/reg definition ================================
	
	//output reg
	reg reg_proc_stall;
	reg [31:0] reg_proc_rdata, cur_proc_rdata;
	reg reg_mem_read, reg_mem_write;
    reg [127:0] reg_mem_wdata;
	reg [27:0] reg_mem_addr;
	//others
	wire [1:0] offset;
	wire [25:0] tag; //index's LSB + tag
	wire [2:0] index; //need for write to mem's mem_addr_I
	reg way, next_way; //2 way: 0 and 1
	wire [1:0] set; //4 sets, set = index[2:1]
	wire valid_0, valid_1;
	wire dirty;
	
	reg [3:0] LRUbit, next_LRUbit;
	//LRUbit[0] = 1, when set0's way1 is older than way0.
	//LRUbit[1] = 0, when set1's way0 is older than way1.
	
	wire TAG_SAME_0, TAG_SAME_1;

	reg [2:0] state, next_state;

	//8 blocks (2 way) 4 words + tag + valid + dirty (128+26+1+1)
	//4 sets, every set 2*(4words + tag + valid + dirty) + LRUbit
	reg [155:0] cache_way0 [0:3]; // index 0,1 in set 0
	reg [155:0] cache_way1 [0:3];
	reg [155:0] cache_block; //represent the block which is using	
	
parameter S_IDLE = 0,
		  S_READ = 1,
		  S_WRITE = 2,
		  S_WRITE_TO_MEM = 3,
		  S_READ_FROM_MEM = 4;
	
//=========================================================
assign ICACHE_stall = reg_proc_stall;
assign mem_read_I = reg_mem_read;
assign mem_write_I = reg_mem_write;
assign mem_wdata_I = reg_mem_wdata;
assign ICACHE_rdata = reg_proc_rdata;
assign mem_addr_I = reg_mem_addr;


assign offset = ICACHE_addr[1:0];
assign index = ICACHE_addr[4:2]; //use for write to mem's mem_addr_I
assign set = ICACHE_addr[4:3];
assign tag = {ICACHE_addr[2], ICACHE_addr[29:5]};
assign dirty = cache_block[154];

assign valid_0 = cache_way0[set][155];
assign valid_1 = cache_way1[set][155];

assign TAG_SAME_0 = (tag == cache_way0[set][153:128]);
assign TAG_SAME_1 = (tag == cache_way1[set][153:128]);


//==== combinational circuit ==============================
always@(*) begin
	if(~rst_n) begin
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
	if(~rst_n) begin
		reg_mem_addr = 0;
	end else if(state == S_WRITE_TO_MEM) begin
		reg_mem_addr[27:3] = cache_block[152:128]; //mem_addr_I use cache's tag
		reg_mem_addr[2:0] = index;
	end else begin
		reg_mem_addr = ICACHE_addr[29:2];
	end
end

always@(*) begin
	if(~rst_n) begin
		reg_proc_stall = 0;
	end else if((state == S_READ_FROM_MEM) || (state == S_WRITE_TO_MEM) || (state == S_IDLE)) begin
		reg_proc_stall = 1;
	end else begin
		reg_proc_stall = 0;
	end
end

always@(*) begin
	if(~rst_n) begin
		reg_mem_read = 0;
	end else if(mem_ready_I) begin
		reg_mem_read = 0;
	end else if(state == S_READ_FROM_MEM) begin
		reg_mem_read = 1;
	end else begin
		reg_mem_read = 0;
	end
end

always@(*) begin
	if(~rst_n) begin
		reg_mem_write = 0;
	end else if(mem_ready_I) begin
		reg_mem_write = 0;
	end else if(state == S_WRITE_TO_MEM) begin
		reg_mem_write = 1;
	end else begin
		reg_mem_write = 0;
	end
end

always@(*) begin
	if(~rst_n) begin
		reg_mem_wdata = 0;
	end else if((state == S_WRITE_TO_MEM) || (state == S_WRITE)) begin
		reg_mem_wdata = cache_block[127:0];
	end else begin
		reg_mem_wdata = 0; // = current data ???
	end
end

always@(*) begin
	if(~rst_n) begin
		next_way = 0;
	end else if(state == S_IDLE) begin
		if     (TAG_SAME_0 && valid_0) next_way = 0; // hit way 0 
		else if(TAG_SAME_1 && valid_1) next_way = 1; // hit way 1
		else if(LRUbit[set])		   next_way = 1; // miss, change way 1
		else 						   next_way = 0; // LRUbit = 0, miss, change way 0
	end else begin
		next_way = way;
	end
end

always@(*) begin
	if(~rst_n) begin
		next_LRUbit = 4'b0;
	end else if((state == S_READ_FROM_MEM) || (state == S_WRITE)) begin
		case(set)
			0: next_LRUbit[0] = ~way;
			1: next_LRUbit[1] = ~way;
			2: next_LRUbit[2] = ~way;
			3: next_LRUbit[3] = ~way;
			default: next_LRUbit = LRUbit;
		endcase
	end else begin
		next_LRUbit = LRUbit;
	end
end

always@(*) begin //valid, dirty
	//cache_block = cache[index];
	if(~rst_n) begin
		cache_block = 0;
	end else if(state == S_WRITE) begin
		cache_block[155] = 1;
		cache_block[154] = 1;
		case(offset)
			0: cache_block[31:0] = ICACHE_wdata;
			1: cache_block[63:32] = ICACHE_wdata;
			2: cache_block[95:64] = ICACHE_wdata;
			3: cache_block[127:96] = ICACHE_wdata;
			default: cache_block = 0; //???
		endcase
	end else if(state == S_WRITE_TO_MEM) begin
		cache_block[154] = 0;
	end else if(state == S_READ_FROM_MEM) begin
		cache_block[155] = 1;
		cache_block[153:128] = tag;
		cache_block[127:0] = mem_rdata_I; //valid = 1
	end else begin
		if(next_way) begin //way = 1
			case(index)
				0,1: cache_block = cache_way1[0];
				2,3: cache_block = cache_way1[1];
				4,5: cache_block = cache_way1[2];
				6,7: cache_block = cache_way1[3];
				default: cache_block = cache_way1[set]; //?????
			endcase
		end else begin //way = 0
			case(index)
				0,1: cache_block = cache_way0[0];
				2,3: cache_block = cache_way0[1];
				4,5: cache_block = cache_way0[2];
				6,7: cache_block = cache_way0[3];
				default: cache_block = cache_way0[set]; //?????
			endcase
		end
	end
end


/************************
TODO:
1.everything needs 2 portions.
2.add LRU bit, not yet decide how to do this part.
3.take care new reg/wire: LRUbit, way...
4."way" is not finish!!! 
*************************/


always@(*) begin
	if(~rst_n) begin
		next_state = S_IDLE;
	end else begin
		case(state)
			S_IDLE: begin
				if((TAG_SAME_0 && valid_0) || (TAG_SAME_1 && valid_1)) begin //hit
					if(ICACHE_ren) next_state = S_READ;
					else if(ICACHE_wen) next_state = S_WRITE;
					else next_state = state;
				end else begin
					if(dirty) next_state = S_WRITE_TO_MEM;
					else next_state = S_READ_FROM_MEM;
				end
			end
			S_WRITE_TO_MEM: begin
				if(mem_ready_I) next_state = S_READ_FROM_MEM;
				else next_state = state;
			end
			S_READ_FROM_MEM: begin
				if(mem_ready_I) begin
					if(ICACHE_ren) next_state = S_READ;
					else if(ICACHE_wen) next_state = S_WRITE;
				end else next_state = state;
			end
			default: next_state = S_IDLE;
		endcase
	end
end
		
//==== sequential circuit =================================
always@( posedge clk or posedge ~rst_n ) begin
    if( ~rst_n ) begin
		LRUbit <= 0;
		way <= 0;
		state <= S_IDLE;
		cur_proc_rdata <= 0;
		cache_way0[0] <= 0;
		cache_way0[1] <= 0;
		cache_way0[2] <= 0;
		cache_way0[3] <= 0;
		cache_way1[0] <= 0;
		cache_way1[1] <= 0;
		cache_way1[2] <= 0;
		cache_way1[3] <= 0;
    end
    else begin
		LRUbit <= next_LRUbit;
		way <= next_way;
		state <= next_state;
		cur_proc_rdata <= reg_proc_rdata;
		if(next_way) begin //way = 1
			case(index)
				0,1: cache_way1[0] <= cache_block;
				2,3: cache_way1[1] <= cache_block;
				4,5: cache_way1[2] <= cache_block;
				6,7: cache_way1[3] <= cache_block;
				default: cache_way1[0] <= 0; //?????
			endcase
		end else begin //way = 0
			case(index)
				0,1: cache_way0[0] <= cache_block;
				2,3: cache_way0[1] <= cache_block;
				4,5: cache_way0[2] <= cache_block;
				6,7: cache_way0[3] <= cache_block;
				default: cache_way0[0] <= 0; //?????
			endcase
		end
    end
end

endmodule
