#include <string>
#include <vector>
#include "ValueClass.h"
using namespace std;


int labelCount = 0;
int tempCount = 0;


string newLabel() {
	string lb = "@L";
	lb += to_string(labelCount);
	labelCount++;
	return lb;
}

string newTemp() {
	string t = "@t";
	t += to_string(tempCount);
	tempCount++;
	return t;
}


string generateModelSegment(string modelName) {
	return ".MODEL " + modelName + "\n\n\n";
}

string generateStackSegment(string stackSize) {
	return ".STACK " + stackSize + "\n\n\n";
}

string generateDataSegment(string previousDataSegment) {
	return ".DATA\n" + previousDataSegment + "\n\n\n";
}

string generateCodeSegment(string previousCodeSegment) {
	return ".CODE\nMOV AX, @DATA\nMOV DS, AX\n" + previousCodeSegment + "\n\n\n";
}


string extendDataSegment(string previous, string newVariable) {
	string temp = newVariable + " DW ?\n";
	return previous + temp; 
}


string extendDataSegment(string previous, string newVariable, int arraySize) {
	string temp = newVariable + " DW " + to_string(arraySize) + " DUP (?)\n";
	return previous + temp;
}

string extendCodeSegment(string previous, string newCode) {
	return previous + newCode;
}


string generateIncop(string variable) {
	string temp = "INC " + variable + "\n";
	return temp;
}


string generateDecop(string variable) {
	string temp = "DEC " + variable + "\n";
	return temp;
}



string generateNot(string destination, string source) {
	//string temp = "PUSH AX\n";
	string temp = "MOV AX, " + source + "\n";
	temp += "MOV " + destination + ", AX\n";
	temp += "NOT " + destination + "\n";
	//temp += "POP AX\n";
	return temp;
}



string generateNeg(string destination, string source) {
	//string temp = "PUSH AX\n";
	string temp = "MOV AX, " + source + "\n";
	temp += "MOV " + destination + ", AX\n";
	temp += "NEG " + destination + "\n";
	//temp += "POP AX\n";
	return temp;
}


string generateAdd(string destination, string source1, string source2) {
	string temp = "MOV AX, " + source1 + "\n";
	temp += "ADD AX, " + source2 + "\n";
	temp += "MOV " + destination + ", AX\n";
	return temp;
}

string generateSub(string destination, string source1, string source2) {
	string temp = "MOV AX, " + source1 + "\n";
	temp += "SUB AX, " + source2 + "\n";
	temp += "MOV " + destination + ", AX\n";
	return temp;
}

string movIndexToBX(string index_variable) {
	string temp = "MOV BX, " + index_variable + "\n";
	return temp;
}

string generateMul(string destination, string source1, string source2) {
	string temp = "MOV AX, " + source1 + "\n";
	temp += "IMUL " + source2 + "\n";
	temp += "MOV " + destination + ", AX\n";
	return temp; 
}



string generateDiv(string destination, string source1, string source2) {
	string temp = "MOV AX, " + source1 + "\n";
	temp += "MOV BX, " + source2 + "\n";
	temp += "IDIV BL\n";
	temp += "XOR AH, AH\n";
	temp += "MOV " + destination + ", AX\n";
	return temp; 
}




string generateMod(string destination, string source1, string source2) {
	string temp = "MOV AX, " + source1 + "\n";
	temp += "MOV BX, " + source2 + "\n";
	temp += "IDIV BL\n";
	temp += "MOV AL, AH\n";
	temp += "XOR AH, AH\n";
	temp += "MOV " + destination + ", AX\n";
	return temp; 
}




string generateRelop(string destination, string source1, string source2, char *relop) {
	string temp = "MOV AX, " + source1 + "\n"; 
	temp += "CMP AX, " + source2 + "\n";
	string label1 = newLabel();
	string label2 = newLabel();	
	if(strcmp(relop, "<") == 0) {
		temp += "JL " + label1 + "\n";
	}
	else if(strcmp(relop, "<=") == 0) {
		temp += "JLE " + label1 + "\n";
	}
	else if(strcmp(relop, ">") == 0) {
		temp += "JG " + label1 + "\n";
	} 
	else if(strcmp(relop, ">=") == 0) {
		temp += "JGE " + label1 + "\n";
	}
	else if(strcmp(relop, "==") == 0) {
		temp += "JE " + label1 + "\n";
	}
	else {
		temp += "JNE " + label1 + "\n";
	}
	temp += "MOV " + destination + ", 0\n";
	temp += "JMP " + label2 + "\n";
	temp += label1 + ":\n";
	temp += "MOV " + destination + ", 1\n";
	temp += label2 + ":\n";
	return temp;
}



string generateLogicop(string destination, string source1, string source2, char *logicop) {
	string label1 = newLabel();
	string label2 = newLabel();	
	string label3 = newLabel();			
	string temp = "CMP " + source1 + ", 0\n";	
	if(strcmp(logicop, "&&") == 0) {
		temp += "JE " + label2 + "\n";
		temp += "CMP " + source2 + ", 0\n";
		temp += "JNE " + label1 + "\n";
	}
	else {
		temp += "JNE " + label1 + "\n";
		temp += "CMP " + source2 + ", 0\n";
		temp += "JE " + label2 + "\n";
	}
	temp += label2 + ":\n";
	temp += "MOV " + destination + ", 0\n";
	temp += "JMP " + label3 + "\n";
	temp += label1 + ":\n";
	temp += "MOV " + destination + ", 1\n";
	temp += label3 + ":\n";
	return temp;
}


string generateMov(string destination, string source) {
	string temp = "MOV AX, " + source + "\n";
	temp += "MOV " + destination + ", AX\n";
	return temp;
}


string generateIf(string tempVariable, string codeInsideIf) {
	string label = newLabel();
	string temp = "CMP " + tempVariable + ", 0\n";
	temp += "JE " + label + "\n";
	temp += codeInsideIf;
	temp += label + ":\n";
	return temp;
}


string generateIfElse(string tempVariable, string codeInsideIf, string codeInsideElse) {
	string label1 = newLabel();
	string label2 = newLabel();
	string temp = "CMP " + tempVariable + ", 0\n";
	temp += "JE " + label1 + "\n";
	temp += codeInsideIf;
	temp += "JMP " + label2 + "\n";
	temp += label1 + ":\n";
	temp += codeInsideElse;
	temp += label2 + ":\n";
	return temp;
}



string generateWhile(string tempVariable, string compareExpressionCode, string codeInsideWhile) {
	string label1 = newLabel();
	string label2 = newLabel();
	string temp = label1 + ":\n";
	temp += compareExpressionCode; 
	temp += "CMP " + tempVariable + ", 0\n";
	temp += "JE " + label2 + "\n";
	temp += codeInsideWhile;
	temp += "JMP " + label1 + "\n";
	temp += label2 + ":\n";
	return temp;
}



string generateFor(string expr1, string expr2, string expr3, string codeInsideFor, string tempVariable) {
	string label1 = newLabel();
	string label2 = newLabel();
	string temp = expr1;
	temp += label1 + ":\n";
	temp += expr2;
	temp += "CMP " + tempVariable + ", 0\n";
	temp += "JE " + label2 + "\n";
	temp += codeInsideFor;
	temp += expr3;
	temp += "JMP " + label1 + "\n";
	temp += label2 + ":\n";
	return temp;	
}





string generateProc(string procName, string procCodes, vector<SymbolInfo*> *param_list, int lastParameterID) {
	string temp;	
	int i = 0;
	if(procName == "main") {
		temp = "MAIN PROC\n";
		temp += procCodes;
		temp += "MOV AH, 4CH\nINT 21H\n";
		temp += "MAIN ENDP\n";
		return temp;
	}
	else {
		temp = procName + " PROC\n";
		for(int j = 0; j < param_list->size(); ++j) {
			temp += "PUSH " + (*param_list)[j]->getName() + to_string(lastParameterID) + "\n";
		}
		temp += "PUSH BP\n";
		temp += "MOV BP, SP\n";
		for(int k = param_list->size() - 1, q = 0; k >= 0; --k, q++) {
			temp += "MOV AX, [BP+" + to_string(4 + 2*param_list->size() + 2*k) + "]\n";
			temp += "MOV " + (*param_list)[q]->getName() + to_string(lastParameterID) + ", AX\n";
		}
		temp += procCodes;
		temp += procName + " ENDP\n";
	}
	return temp;
}




string generateReturn(string variable, vector<SymbolInfo*> param_list, int lastParameterID) {
	string temp = "MOV CX, " + variable + "\n";
	temp += "POP BP\n";
	for(int j = 0; j < param_list.size(); ++j) {
		temp += "POP " + param_list[j]->getName() + to_string(lastParameterID) + "\n";
	}
	temp += "RET " + to_string(param_list.size()*2) + "\n";
	return temp;
}



string generateFunctionCall(vector<Value> arguments, string procName, string returnVariable) {
	string temp;
	for(int i = 0; i < arguments.size(); ++i) {
		temp += *(arguments[i].code);
	}
	for(int i = 0; i < arguments.size(); ++i) {
		temp += "PUSH " + *(arguments[i].asmSymbolName) + "\n";
	}
	temp += "CALL " + procName + "\n";
	temp += "MOV " + returnVariable + ", CX\n";
	return temp;
}


string generatePrintCall(string variable) {
	string temp = "MOV AX, " + variable + "\n";
	temp += "CALL OUTDEC\n";
	return temp;
}



string generatePrint() {
	string temp = "OUTDEC PROC\n";
	temp += "PUSH AX\nPUSH BX\nPUSH CX\nPUSH DX\n";
	temp += "OR AX, AX\n";
	temp += "JGE @END_IF1\n";
	temp += "PUSH AX\n";
	temp += "MOV DL, '-'\n";
	temp += "MOV AH, 2\n";
	temp += "INT 21H\n";
	temp += "POP AX\n";
	temp += "NEG AX\n";
	temp += "@END_IF1:\n";
	temp += "XOR CX, CX\n";
	temp += "MOV BX, 10\n";
	temp += "@REPEAT1:\n";
	temp += "XOR DX, DX\n";
	temp += "DIV BX\n";
	temp += "PUSH DX\n";
	temp += "INC CX\n";
	temp += "OR AX, AX\n";
	temp += "JNE @REPEAT1\n";
	temp += "MOV AH, 2\n";
	temp += "@PRINT_LOOP:\n";
	temp += "POP DX\n";
	temp += "OR DL, 30H\n";
	temp += "INT 21H\n";
	temp += "LOOP @PRINT_LOOP\n";
	temp += "MOV AH, 2\n";
	temp += "MOV DL, 0DH\n";
	temp += "INT 21H\n";
	temp += "MOV DL, 0AH\n";
	temp += "INT 21H\n";
	temp += "POP DX\nPOP CX\nPOP BX\nPOP AX\n";
	temp += "RET\n";
	temp += "OUTDEC ENDP\n";
	return temp;
}


























