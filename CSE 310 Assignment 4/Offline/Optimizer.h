#include <string>
#include <vector>
#include <sstream>
using namespace std;


vector<string> split(const string &s) {
    stringstream ss(s);
    string item;
    vector<string> tokens;
    while (getline(ss, item)) {
        tokens.push_back(item);
    }
    return tokens;
}


string optimize(string code) {
	string str1, str2, optimizedCode = "";
	vector<string> lines = split(code);
	int line_count = lines.size();
	for(int i = 0, j = 1; j < line_count;) {
		str1 = lines[i];
		str2 = lines[j];
		if(str1.substr(0, 3) == "MOV" && str2.substr(0, 3) == "MOV") {
			int position1 = str1.find(",");
			int position2 = str2.find(",");
			string str1_op1 = str1.substr(4, position1 - 4);
			string str1_op2 = str1.substr(position1 + 2);
			string str2_op1 = str2.substr(4, position2 - 4);
			string str2_op2 = str2.substr(position2 + 2);
			if(str1_op1 == str2_op2 && str1_op2 == str2_op1) {
				++j;
				if(j >= line_count) optimizedCode += str1 + "\n";
			}
			else {
				optimizedCode += str1 + "\n";
				i = j;
				++j;
				if(j >= line_count) optimizedCode += str2 + "\n";
			}
		}
		else if(str2.substr(0, 3) == "MOV") {
			optimizedCode += str1 + "\n";
			++i;
			++j;
			if(j >= line_count) optimizedCode += str2 + "\n";
		}
		else {
			optimizedCode += str1 + "\n";
			i = j;
			++j;
			if(j >= line_count) optimizedCode += str2 + "\n";
		}	
	}
	return optimizedCode;
}













