#include <iostream>
#include <string>
#include <cstring>
#include <cstdlib>
#include <iomanip>
#include <fstream>
#include <vector>
using namespace std;

//global variables
#define STR_LENGTH 50
//#define NUMOFZHUYIN 37

int get_tok(const string& str, string& tok, 
    int pos = 0, const char del = ' '){
    
    int begin = str.find_first_not_of(del, pos);
    if (begin == string::npos) { tok = ""; return begin; }
    int end = str.find_first_of(del, begin);
    tok = str.substr(begin, end - begin);
    return end;
}

bool in(const string& str, const string& tar){
    return str.find(tar) != string::npos;
}

int reg2int(const string& str){
    int rtn = 0;
    char str1[1] = {str[1]};

    switch(str[0]){
        case('0'):
            rtn = 0;
            break;
        case('v'):
            {
                if(str[1] == '0')
                    rtn = 2;
                else
                    rtn = 3;
            }
            break;
        case('a'):
            {
                if(str[1] == 't')
                    rtn = 1;
                else
                    rtn = 4 + atoi(str1);
            }
            break;
        case('t')://8~15,24~25
            {
                rtn = 8 + atoi(str1);
                if(rtn > 15)//8,9
                    rtn += 8;
            }
            break;
        case('s')://16~23
            {
                if(str[1] == 'p')
                    rtn = 29;
                else
                    rtn = 16 + atoi(str1);
            }
            break;
        case('k'):
            {
                rtn = 26 + atoi(str1);
            }
            break;
        case('g'):
            {
                if(str[1] == 'p')
                    rtn = 28;
                else
                    rtn = -1;
            }
            break;
        case('f'):
            {
                if(str[1] == 'p')
                    rtn = 30;
                else
                    rtn = -1;
            }
            break;
        case('r'):
            {
                if(str[1] == 'a')
                    rtn = 31;
                else
                    rtn = -1;
            }
            break;
        default:
            cerr<<"illegal reg: "<<str<<endl;
    }
    return rtn;
}

string dec2bin(int dec, int len){//TODO//
    string rtn = "", buf = "";
    bool min = false, inv = false;
    if(dec < 0){
        dec = dec*(-1);
        min = true;
    }

    for(int i = 0; i < len; ++i){
        if(dec%2 == 1 ^ inv)
            buf = buf + "1";
        else
            buf = buf + "0";
        
        if(dec%2 == 1 & min)
            inv = true;
        dec/=2;
    }
    for(int i = 0; i < len; ++i){
        rtn.push_back(buf[len - 1 - i]);
    }
    return rtn;
}

int HB2dex(const string& bin){
    if(bin.size() != 4)
        return -1;
    else{
        int rtn = 0;
        for(int i = 0; i < 4; ++i){
            rtn*=2;
            rtn += atoi(bin.substr(i, 1).c_str());
        }
        return rtn;
    }
}

string bin2hex(const string& bin){//4to1
    int value = HB2dex(bin);
    string rtn = "";
    switch(value){
        case 0:
            rtn = "0";
            break;
        case 1:
            rtn = "1";
            break;
        case 2:
            rtn = "2";
            break;
        case 3:
            rtn = "3";
            break;
        case 4:
            rtn = "4";
            break;
        case 5:
            rtn = "5";
            break;
        case 6:
            rtn = "6";
            break;
        case 7:
            rtn = "7";
            break;
        case 8:
            rtn = "8";
            break;
        case 9:
            rtn = "9";
            break;
        case 10:
            rtn = "a";
            break;
        case 11:
            rtn = "b";
            break;
        case 12:
            rtn = "c";
            break;
        case 13:
            rtn = "d";
            break;
        case 14:
            rtn = "e";
            break;
        case 15:
            rtn = "f";
            break;
        default:
            cerr<<"illegal hex!\n";
    }
    return rtn;
}

class Sign{
public:
    Sign(string s, int p){
        str = s;
        pos = p;
    }
    ~Sign() {}
    void print(){
        cout<<str<<", "<<pos<<endl;
    }

    string str;
    int pos;
};

class Data{
public:
    Data() {
        support_inst = "add sub and or xor nor sll sra srl slt jr jalr beq addi andi ori xori slti lw sw j jal nop";
        j_inst = "j jal";
        i_inst = "beq addi andi ori xori slti lw sw";
        r_inst = "add sub and or xor nor sll sra srl slt jr jalr";
    }
    ~Data() {}
//function
    void print();
    void read_data(char* filename);
    void resolve_data();//from assem to bin
    void write_data(char* filename);//from bin to word
//data
private:
    int find_pos(const string& sign);
    vector<string> raw_data;
    vector<string> hex_data;
    vector<Sign> sign_pool;
    string support_inst;
    string j_inst;
    string i_inst;
    string r_inst;
};

void Data::print(void){
    for(int i = 0; i < hex_data.size(); ++i){
        if(i < raw_data.size())
            cout << raw_data[i] << endl;
        cout << hex_data[i] << endl;
    }
}

void Data::read_data(char* filename){
    ifstream fs(filename);
    if(!fs)
        cout << "Fail to open:  "<< filename << ".\n";
    
    int buf_l = STR_LENGTH;
    char buf[STR_LENGTH];
    while(fs.getline(buf, buf_l)){
        raw_data.push_back(buf);
    }
    fs.close();
}

int Data::find_pos(const string& s){
    for(int i = 0; i < sign_pool.size(); ++i){
        if(sign_pool[i].str == s)
            return sign_pool[i].pos;
    }
    cerr<<"No such Sign: "<<s<<endl;
    return -1;
}

void Data::resolve_data(void){
    bool text_on = true;//false;
    int line_num = 0;
/*    
for(int i = 0; i < raw_data.size(); ++i){
    cout<<raw_data[i]<<endl;
}
*/
    for(int i = 0; i < raw_data.size(); ++i){
        string data_tmp, tok, func, text = ".text";
        int pos = 1, last_pos = 0;
        vector<string> vec_tmp;

        get_tok(raw_data[i], data_tmp, 0, '#');
        get_tok(data_tmp, data_tmp, 0, '\r');
        if((text_on == false) || data_tmp.empty()
            || (data_tmp.find(string("syscall")) != string::npos)){//PRINT
            raw_data.erase(raw_data.begin() + i);
            --i;
            continue;
        }
        if(data_tmp[0] != '\t'){    
            get_tok(data_tmp, tok, 0, ':');
            sign_pool.push_back(Sign(tok, i));
            raw_data.erase(raw_data.begin() + i);
            --i;
            continue;
        }
        while(1){
            last_pos = pos;
            pos = get_tok(data_tmp, tok, pos, ' ');
            get_tok(tok, tok, 0, ',');
            if(pos==last_pos || tok.empty()) break;
            vec_tmp.push_back(tok);
        }
//cerr<<vec_tmp[0]<<endl;
        if(vec_tmp.empty()){
            raw_data.erase(raw_data.begin() + i);
            --i;
            continue;
        }
        else if(vec_tmp[0] == "move"){
            raw_data[i] = + "\taddi " + vec_tmp[2] + ", "
                + vec_tmp[1] + ", " + "0";
        }
        else if(vec_tmp[0] == "bge"){
            raw_data[i] = "\tbeq $s7, $0, " + vec_tmp[3];
            raw_data.insert(raw_data.begin() + i, "\tslt $s7, " + 
                 vec_tmp[1] + ", " + vec_tmp[2]);
        }
        else if(vec_tmp[0] == "blt"){
            raw_data[i] = "\tbeq $s7, $s6, " + vec_tmp[3];//S6=1
            raw_data.insert(raw_data.begin() + i, "\tslt $s7, " + 
                 vec_tmp[1] + ", " + vec_tmp[2]);
            raw_data.insert(raw_data.begin() + i, "\taddi $s6, $0, 1");
        }
        else if(vec_tmp[0] == "ble"){
            raw_data[i] = "\tbeq $s7, $0, " + vec_tmp[3];
            raw_data.insert(raw_data.begin() + i, "\tslt $s7, " + 
                 vec_tmp[2] + ", " + vec_tmp[1]);
//cerr<<vec_tmp.size()<<endl;
        }
        else if(vec_tmp[0] == "bgt"){
            raw_data[i] = "\tbeq $s7, $s6, " + vec_tmp[3];//S6=1
            raw_data.insert(raw_data.begin() + i, "\tslt $s7, " + 
                 vec_tmp[2] + ", " + vec_tmp[1]);
            raw_data.insert(raw_data.begin() + i, "\taddi $s6, $0, 1");
        }
        else if(!in(support_inst, vec_tmp[0])){
//cout<<vec_tmp[0]<<endl;
            raw_data.erase(raw_data.begin() + i);
            --i;
            continue;
        }
    }
/*
cerr<<raw_data.size()<<endl;
for(int i = 0; i < raw_data.size(); ++i){
    cout<<raw_data[i]<<endl;
}
*/
//cout << sign_pool.size() <<endl;
    for(int i = 0; i < sign_pool.size(); ++i){
        for(int j = j; j < sign_pool.size(); ++j){
            if(i == j)
                continue;
            if(sign_pool[i].pos == sign_pool[j].pos){
                sign_pool[i].pos = raw_data.size();
            }
//sign_pool[i].print();
        }
//cout << i <<endl;
    }

    for(int i = 0; i < raw_data.size(); ++i){
        string data_tmp, tok, func, text = ".text";
        int pos = 1, last_pos = 0;
        vector<string> vec_tmp;

        get_tok(raw_data[i], data_tmp, 0, '#');
        get_tok(data_tmp, data_tmp, 0, '\r');

        while(1){
            last_pos = pos;
            pos = get_tok(data_tmp, tok, pos, ' ');
            get_tok(tok, tok, 0, ',');
            if(pos==last_pos || tok.empty()) break;
            vec_tmp.push_back(tok);
        }
//-------------------------transform---------------------------------
        if(vec_tmp.empty())
            continue;
        if(!in(support_inst, vec_tmp[0]))
            continue;
        
        int op, r0;
        string inst_hex = "";
        get_tok(vec_tmp[1], tok, 1);
        
        if(in(j_inst, vec_tmp[0])){//j------------------------------
            int addr;
            if(vec_tmp[0] ==  "j")
                op = 2;
            else if(vec_tmp[0] == "jal")
                op = 3;
            else
                cerr<<"illegal J-inst: "<<vec_tmp[0]<<endl;
            
            addr = find_pos(vec_tmp[1]);
            string bin_code = dec2bin(op, 6) + dec2bin(addr, 26);
            string hex_code = "";
//cerr<<raw_data[i]<<endl;
//cerr<<bin_code<<endl;
//cerr<<addr<<", "<<dec2bin(addr, 16)<<endl;
            for(int j = 0; j < 8; ++j){
                hex_code = hex_code + bin2hex(bin_code.substr(j*4, 4));
            }
            //hex_data.push_back(hex_code);
            hex_data.push_back(bin_code);
//cerr<<hex_code<<endl<<endl;
            
        }
        else if(in(r_inst, vec_tmp[0])){//r------------------------------
            int func = 0, r1 = 0, r2 = 0, shift = 0;
            bool flg_shift = false;
            op = 0;
            r0 = reg2int(tok);

            if(vec_tmp[0] ==  "add")
                func = 32;
            else if(vec_tmp[0] == "sub")
                func = 34;
            else if(vec_tmp[0] == "and")
                func = 36;
            else if(vec_tmp[0] == "or")
                func = 37;
            else if(vec_tmp[0] == "xor")
                func = 38;
            else if(vec_tmp[0] == "nor")
                func = 39;
            else if(vec_tmp[0] == "sll"){
                func = 0;
                flg_shift = true;
            }
            else if(vec_tmp[0] == "sra"){
                func = 3;
                flg_shift = true;
            }
            else if(vec_tmp[0] == "srl"){
                func = 2;
                flg_shift = true;
            }
            else if(vec_tmp[0] == "slt")
                func = 42;
            else if(vec_tmp[0] == "jr")//2
                func = 8;
            else if(vec_tmp[0] == "jalr")//3//TODO//
                func = 9;
            else
                cerr<<"illegal R-inst: "<<vec_tmp[0]<<endl;
            
            if(func == 8 || func == 9){//jr or jalr
                r1 = r0;
                r0 = 0;
            }
            else{
                get_tok(vec_tmp[2], tok, 1);
                r1 = reg2int(tok);
                if(flg_shift == true){
                    shift = atoi(vec_tmp[3].c_str());
                    r2 = r1;
                    r1 = 0;
                }
                else{
                    get_tok(vec_tmp[3], tok, 1);
                    r2 = reg2int(tok);
                }
            }    

            string bin_code = dec2bin(op, 6) + dec2bin(r1, 5) 
                + dec2bin(r2, 5) + dec2bin(r0, 5) + dec2bin(shift, 5)
                + dec2bin(func, 6);
            string hex_code = "";
//cerr<<raw_data[i]<<endl;
//cerr<<bin_code<<endl;
            for(int j = 0; j < 8; ++j){
                hex_code = hex_code + bin2hex(bin_code.substr(j*4, 4));
            }
            //hex_data.push_back(hex_code);
            hex_data.push_back(bin_code);
//cerr<<hex_code<<endl<<endl;

            
        }
        else if(in(i_inst, vec_tmp[0])){//i------------------------------
            int r1, addr;
            r0 = reg2int(tok);
            
            if(vec_tmp[0] ==  "addi")
                op = 8;
            else if(vec_tmp[0] == "andi")
                op = 12;
            else if(vec_tmp[0] == "ori")
                op = 13;
            else if(vec_tmp[0] == "xori")
                op = 14;
            else if(vec_tmp[0] == "slti")
                op = 10;
            else if(vec_tmp[0] == "beq")
                op = 4;
            else if(vec_tmp[0] == "lw")
                op = 35;
            else if(vec_tmp[0] == "sw")
                op = 43;
            else
                cerr<<"illegal I-inst: "<<vec_tmp[0]<<endl;
            
            if((op == 35)||(op == 43)){
                pos = get_tok(vec_tmp[2], tok, 0, '(');
                addr = atoi(tok.c_str());
                get_tok(vec_tmp[2], tok, pos + 1, ')');
                get_tok(tok, tok, 1);
                r1 = reg2int(tok);
            }
            else{
                if(vec_tmp.size() != 4){
                    cerr<<"illegal I-inst: "<<vec_tmp[0]<<endl;
                    continue;
                }
                get_tok(vec_tmp[2], tok, 1);
                r1 = reg2int(tok);
                if(op == 4)//TODO//
                    addr = find_pos(vec_tmp[3]) - i - 1;
                else{
                    addr = atoi(vec_tmp[3].c_str());
                }
//cerr<<addr<<endl;
            }
            string bin_code = dec2bin(op, 6) + dec2bin(r1, 5) 
                + dec2bin(r0, 5) + dec2bin(addr, 16);
            string hex_code = "";
//cerr<<raw_data[i]<<endl;
//cerr<<bin_code<<endl;
//cerr<<addr<<", "<<dec2bin(addr, 16)<<endl;
            for(int j = 0; j < 8; ++j){
                hex_code = hex_code + bin2hex(bin_code.substr(j*4, 4));
            }
            //hex_data.push_back(hex_code);
            hex_data.push_back(bin_code);
//cerr<<hex_code<<endl<<endl;
        }
        else if(vec_tmp[0] == "nop"){//TODO//
            hex_data.push_back("00000000000000000000000000000000");
            //for(int i = 0; i < 8; ++i)
            //    inst_hex = inst_hex + '0';
        }
        else
            cerr<<"no such inst!"<<endl;
            
    }
    for(int i = 0; i < 10; ++i){
        hex_data.push_back("00000000000000000000000000000000");
    }
}

void Data::write_data(char* filename){
    fstream fo;
    fo.open(filename, ios::out);
    if(!fo) cout<<"No o/p file!\n";
    for(int i = 0; i < hex_data.size(); ++i){
        fo << hex_data[i] << endl;
    }
    fo.close();
}

int main(int argc, char  **argv){

    Data data;
    data.read_data(argv[1]);
    data.resolve_data();
    data.print();
    data.write_data(argv[2]);
}

