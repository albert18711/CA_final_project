
# coding: utf-8

# In[6]:

import sys


# In[7]:

def fibR(n):
 assert(n>0)
 if n==1 or n==2:
  return 1
 return fibR(n-1)+fibR(n-2)

def param(nb):
    m1 = nb-2
    m2 = 4*(nb-1)
    m3 = 4*nb
    return m1, m2, m3


# ### Fibonacci
#     I_mem_L2Cache
#         number = len(fib_list)+1 (0)
#         transform
#         //addi $3 $0 14   / addi r3, r0, 0x000E, r3 = 16-2
#         //addi $7 $0 003c / addi r7, r0, 0x003c, r7 = 4*(number-1)
#         //addi $7 $0 0040 / addi r7, r0, 0x0040, r7 = 4*number)    
#         to
#         //addi $3 $0 m1   
#         //addi $7 $0 m2 
#         //addi $7 $0 m3 
#      TestBed_L2Cache
#         `define	CheckNum	6'd33       
#         
#             6'd0 :	answer = 32'd0;
#             6'd1 :	answer = 32'd1;
#             6'd2 :	answer = 32'd1;
#             6'd3 :	answer = 32'd2;
#             6'd4 :	answer = 32'd3;
#             6'd5 :	answer = 32'd5;
#             6'd6 :	answer = 32'd8;
#             6'd7 :	answer = 32'd13;
#             6'd8 :	answer = 32'd21;
#             6'd9 :	answer = 32'd34;
#             6'd10:	answer = 32'd55;
#             6'd11:	answer = 32'd89;
#             6'd12:	answer = 32'd144;
#             6'd13:	answer = 32'd233;
#             6'd14:	answer = 32'd377;
#             6'd15:	answer = 32'd610;
#             6'd16:	answer = 32'd610;
#             6'd17:	answer = 32'd377;
#             6'd18:	answer = 32'd233;
#             6'd19:	answer = 32'd144;
#             6'd20:	answer = 32'd89;
#             6'd21:	answer = 32'd55;
#             6'd22:	answer = 32'd34;
#             6'd23:	answer = 32'd21;
#             6'd24:	answer = 32'd13;
#             6'd25:	answer = 32'd8;
#             6'd26:	answer = 32'd5;
#             6'd27:	answer = 32'd3;
#             6'd28:	answer = 32'd2;
#             6'd29:	answer = 32'd1;
#             6'd30:	answer = 32'd1;
#             6'd31:	answer = 32'd0;
#             6'd32:	answer = `EndSymbol;          

# In[8]:

nb = sys.argv[1]

# nb = 20
CheckNum = nb*2 + 1 #`EndSymbol

m1, m2,  m3 = param(nb)

fib_list = [0]+[fibR(i) for i in range(1,nb)]
fib_list_reverse = fib_list.copy()
fib_list_reverse.reverse()
write_list = fib_list + fib_list_reverse 


# In[9]:

TestBed_L2Cache_file = open('TestBed_L2Cache.v','w')


with open("TestBed_hasHazard.v", "r") as f:
    for line in f:
        if 'modify' in line:
            line = line.replace("33", format(CheckNum, 'd'))
        
        if 'modify2' in line: 
            line = line.replace("xxx", format(fib_list[-1], 'd'))
            TestBed_L2Cache_file.write(line)
            break
        TestBed_L2Cache_file.write(line)

for i, ans in enumerate(write_list):
    TestBed_L2Cache_file.write("\t\t6'd%d :answer = 32'd%d;\n" %(i,ans))
    
TestBed_L2Cache_file.write("\t\t6'd%d :answer = `EndSymbol;\n\t\tendcase\n\tend\n\nendmodule" %(CheckNum-1))
TestBed_L2Cache_file.close()


# In[10]:

I_mem_L2Cache_file = open('I_mem_L2Cache','w')

with open("I_mem_hasHazard", "r") as f:
    for line in f:
        if 'modify1' in line:
            # annotation
            line = line.replace("0x000e",             format(m1, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("610",                format(fib_list[-1], 'd'))
            line = line.replace("16",                 format(nb, 'd'))
            line = line.replace("14",                 format(m1, 'd')) 

            # instruction
            line = line.replace("00000_00000_001110", format(m1, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify2' in line:
            # annotation
            line = line.replace("0x03c",              format(m2, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("60",                 format(m2, 'd')) 
            
            # instruction
            line = line.replace("00000_00000_111100", format(m2, 'b').zfill(16)) # I-type operand immediate 16 bit
        elif 'modify3' in line:
            # annotation
            line = line.replace("0x0040",             format(m3, 'x').zfill(4))  # I-type operand immediate 16 bit
            line = line.replace("64",                 format(m3, 'd')) 
            
            # instruction
            line = line.replace("0000000001000000",   format(m3, 'b').zfill(16)) # I-type operand immediate 16 bit
        
        I_mem_L2Cache_file.write(line)
I_mem_L2Cache_file.close()

