						nop
Main:                   addi    r30,r0, 0x0932  
						jal     OutputTestPort      		// Indicate that simulation begin
						jal     FibunacciSeries     		
						jal     BubbleSort          		
						addi    r30,r0, 0x0D5D      		
						jal     OutputTestPort      		// Indicate that simulation finish
						j		Trap
OutputTestPort:         sw      r30, r0, 0x0100     		// put output value in r30
						jr      r31                 		// jump back to caller
FibunacciSeries:        add     r29,r31,r0          		
						addi    r3, r0, 0x000e      		// r3==14                 ( modify1 for 0-610(number:16) r3 = 16-2 = 14 ) 
						addi    r1, r0, 0x0000      		// r1==0, t==0
						addi    r2, r0, 0x0001      		// r2==1, t==1
						addi    r4, r0, 0x0000      		// 0x0000 store f(0)
						sw      r1, r4, 0x0000      		
						addi    r4, r4, 0x0004      		// increment of r4 by 4
						sw      r2, r4, 0x0000      		// 0x0004 store f(1)
						add     r30,r1, r0  
						jal     OutputTestPort
						add     r30,r2, r0  
						jal     OutputTestPort
FibunacciLoop:          beq     r3, r0, FibunacciLoopExit   
						addi    r4, r4, 0x0004  
						add     r5, r2, r1          		// r5 become f(t+1)
						add     r1, r2, r0          		// replace r1 by r2, f(t)
						add     r2, r5, r0          		// replace r2 by r5, f(t+1)
						sw      r2, r4, 0x0000      		// store r2, f(t+1)
						addi    r3, r3, 0xffff      		// r3 = r3 - 1 
						add     r30,r2, r0          		// output fibunacci series
						jal     OutputTestPort      		
						j       FibunacciLoop       		
						sub     r2, r2, r2          		// never be executed
						sub     r1, r1, r1          		// never be executed    
FibunacciLoopExit:      jr      r29                 		
BubbleSort:             add     r29,r31,r0          		
						addi    r7, r0, 0x003c      		// from 3c to 0, 60~0     ( modify2 for r7 = 4*(number-1) = 60 )   
BubbleOutLoop:          beq     r7, r0, BubbleOutLoopExit                   
						add     r1, r0, r0          		// from 0 to r7         
BubbleInLoop:           beq     r1, r7, BubbleInLoopExit   	// r1 for source address                               
						lw      r3, r1, 0x0000             	// r3 for temp value 1, r3=MEM[r1]                     
						lw      r4, r1, 0x0004		       	// r4 for temp value 2, r4=MEM[r1+4]  
						slt     r5, r3, r4                 	// r5 for flag: r4 < r3 ? 32'd1: 32'd0
						beq     r5, r0, SwapExit           	// r7 for finished bound              
Swap:                   sw      r4, r1, 0x0000
						sw      r3, r1, 0x0004
SwapExit:               add     r1, r1, 0x0004
						j       BubbleInLoop
BubbleInLoopExit:       sub     r7, r7, 0x0004
						j       BubbleOutLoop
BubbleOutLoopExit:      add     r1, r0, r0
						addi    r7, r0, 0x0040                                        ( modify3 for r7 = 4*number = 64 )
OutputSortedSeries:     beq     r1, r7, BubbleSortExit
						lw      r30,r1, 0x0000
						addi    r1, r1, 0x0004
						jal     OutputTestPort
						j       OutputSortedSeries      
BubbleSortExit:         jr      r29
Trap:                   j		Trap
						nop