%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <string>
#include <vector>
#include "SymbolTable.h"
#include "AssemblyCode.h"
#include "Relational.h"
#include "Optimizer.h"

#define ADD_TO_DATA_SEGMENT string newTempVariable = newTemp();\
	dataSegment = extendDataSegment(dataSegment, newTempVariable);

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *logFile;
FILE *codeFile;
FILE *optimizedCodeFile;

SymbolTable *symbolTable;


string modelSegment;
string stackSegment;
string dataSegment;
string codeSegment;

bool inMain;
bool printUsed = false;

int count1 = 0;
int count2 = 0;

int line_count = 1;
int err_count = 0;
bool funcScope = false;

SymbolInfo *currentFunction;

int lastFoundReturnType;

int lastParameterID;

vector<Value> *argument_codes;

void yyerror(const char *s)
{
	fprintf(logFile, "Error at Line %d: %s\n", line_count, s);
	//write your code
}


void print(const char *msg)	{
	fprintf(logFile, "Line %d: %s\n\n", line_count, msg);
}

void print(const char *msg, const char *idName)	{
	fprintf(logFile, "Line %d: %s\n%s\n\n", line_count, msg, idName);
}

void FuncDeclarationJob(int type, SymbolInfo *symbol, vector<SymbolInfo*> *v) {
	symbol->setReturnType(type);
	symbol->setParameter(v);
	if(!symbolTable->Insert(symbol)) {
		++err_count;
		fprintf(logFile, "Error at Line %d: Multiple Declaration of Function %s\n", line_count, (symbol->getName()).c_str());
		return;
	}
	symbol->setDeclared(true);
}


void FuncDefinitionJob(int type, SymbolInfo *symbol, vector<SymbolInfo*> *v) {
	currentFunction = symbol;
	symbol->setReturnType(type);
	symbol->setParameter(v);
	symbol->setDefined(true);
	symbol->setDeclared(true);
	int size1, size2;
	size2 = v->size();
	SymbolInfo *temp = symbolTable->LookUp(symbol->getName());
	if(!temp){
	 	symbolTable->Insert(symbol);
		lastFoundReturnType = type;
	}
	else {
		if(temp->checkDefined()) { 
			fprintf(logFile, "Error at Line %d: Multiple Definition of Function %s\n", line_count, (symbol->getName()).c_str());
			++err_count;
		}
		else {
			lastFoundReturnType = temp->getReturnType();
			if(type != temp->getReturnType()) {
				fprintf(logFile, "Error at Line %d: Return Type Mismatch for Function %s\n", line_count, (symbol->getName()).c_str());
				++err_count;
			}
			vector<SymbolInfo*> stemp = temp->getParameters();
			size1 = stemp.size();
			if(size1 != size2) { 
				fprintf(logFile, "Error at Line %d: Parameter Number Mismatch between declaration and definition of Function %s\n", line_count, (symbol->getName()).c_str());
				++err_count;
			}
			else {
				for(int i = 0; i < size1; ++i) {
					if(stemp[i]->getStoredType() != (*v)[i]->getStoredType()) {
						fprintf(logFile, "Error at Line %d: Parameter type Mismatch between declaration and definition of Function %s\n", line_count, (symbol->getName()).c_str());
						++err_count;
						break;
					}	
				}
			}
		}
	}
	symbolTable->EnterScope();
	lastParameterID = symbolTable->getID();
	for(int i = 0; i < size2; ++i) {
		SymbolInfo *temp = new SymbolInfo((*v)[i]->getName(), "ID");
		temp->setStoredType((*v)[i]->getStoredType());
		symbolTable->Insert(temp);
	}
	funcScope = true;
}




%}


%error-verbose
%union { 
	int ival; float fval;  Value vc; char* str; SymbolInfo* sival; vector<int>* vi;
	vector<SymbolInfo*>* vs; string *st;
} 

%token IF FOR WHILE RETURN ASSIGNOP NOT PRINTLN
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token <vc>CONST_INT
%token <ival>INT
%token <ival>FLOAT
%token <ival>CHAR
%token <ival>VOID
%token <ival>DOUBLE
%token <vc>CONST_FLOAT
%token <vc>CONST_CHAR
%token <sival>ID
%token <str>INCOP
%token <str>DECOP
%token <str>ADDOP
%token <str>MULOP
%token <str>RELOP
%token <str>LOGICOP

%type <ival>type_specifier
%type <vs>parameter_list
%type <vs>parameters
%type <vs>declaration_list
%type <sival>variable
%type <vc>expression
%type <vc>logic_expression
%type <vc>rel_expression
%type <vc>simple_expression
%type <vc>term
%type <vc>unary_expression
%type <vc>factor
%type <vi>argument_list
%type <vi>arguments
%type <vc>expression_statement
%type <st>statement
%type <st>statements
%type <st>compound_statement
%type <st>func_definition

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%right INCOP DECOP NOT
%left RELOP LOGICOP


%%

start : program	{
		print("start : program");
		if(printUsed) codeSegment = extendCodeSegment(codeSegment, generatePrint());
		codeSegment = extendCodeSegment(codeSegment, "END MAIN\n");
		string mainCode = generateModelSegment("SMALL");
		mainCode += generateStackSegment("100H");
		mainCode += generateDataSegment(dataSegment);
		mainCode += generateCodeSegment(codeSegment);
		if(err_count == 0) {
			codeFile = fopen("code.asm", "w");
			fprintf(codeFile, "%s\n", mainCode.c_str());
			optimizedCodeFile = fopen("Code.asm", "w");
			fprintf(optimizedCodeFile, "%s\n", optimize(mainCode).c_str());
			fclose(codeFile);
			fclose(optimizedCodeFile);
		}
	}
	;

program : program unit	{
		print("program : program unit");
	} 
	| unit	{
		print("program : unit");
	}
	;
	
unit : var_declaration	{
		print("unit : var_declaration"); 	
     }
     | func_declaration	{
		print("unit : func_declaration");

     }
     | func_definition	{
     		print("unit : func_definition");
		codeSegment = extendCodeSegment(codeSegment, *$1);			
     }
     ;
     
func_declaration : type_specifier ID  LPAREN parameter_list RPAREN {FuncDeclarationJob($1, $2, $4);} SEMICOLON	{
			print("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", $2->getName().c_str());
			delete $4;
		 }
		 | type_specifier ID  LPAREN parameter_list RPAREN {FuncDeclarationJob($1, $2, $4);} error {
			++err_count;
		 }
		 ;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {FuncDefinitionJob($1, $2, $4);} compound_statement	{
			print("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement", $2->getName().c_str());
			for(int i = 0; i < $4->size(); ++i) {
				dataSegment = extendDataSegment(dataSegment, (*$4)[i]->getName() + to_string(lastParameterID));
			}
			$$ = new string(generateProc($2->getName(), *$7, $4, lastParameterID));
			delete $4;
			delete $7;
 		}
		;

parameter_list : parameters	{
			print("parameter_list : parameters");
			$$ = $1;
	       }
	       |	{
			print("parameter_list : ");
			vector<SymbolInfo*> *temp = new vector<SymbolInfo*>();
			$$ = temp;
	       }
	       ; 

 		 
parameters : parameters COMMA type_specifier ID	{
			print("parameter_list : parameter_list COMMA type_specifier ID", $4->getName().c_str());
			$$ = $1;
			if($3 != VOID_VAL) { 
				$4->setStoredType($3);
				int size = $$->size();
				for(int i = 0; i < size; ++i){
					if((*$$)[i]->getName() == $4->getName()) {
						fprintf(logFile, "Error at Line %d: Multiple %s in parameter\n", line_count, $4->getName().c_str());
						++err_count;
					}
				}
				$$->push_back($4);
			}
			else { 
				fprintf(logFile, "Error at Line %d: void variable not allowed as parameter, this is ignored\n", line_count);
				++err_count;
			} 
	   }
	   | parameters COMMA type_specifier	{
			print("parameter_list : parameter_list COMMA type_specifier");
			$$ = $1;
			SymbolInfo *stemp = new SymbolInfo("", "ID");
			if($3 != VOID_VAL) {
				stemp->setStoredType($3);	
				$$->push_back(stemp);
			}
			else { 
				fprintf(logFile, "Error at Line %d: void variable not allowed as parameter, this is ignored\n", line_count);
				++err_count;
			}
	   } 
 	   | type_specifier ID	{
			print("parameter_list : type_specifier ID", $2->getName().c_str());
			vector<SymbolInfo*> *temp = new vector<SymbolInfo*>();
			$$ = temp;
			if($1 != VOID_VAL) {
				$2->setStoredType($1);
				$$->push_back($2);
			}
			else { 
				fprintf(logFile, "Error at Line %d: void variable not allowed as parameter, this is ignored\n", line_count);
				++err_count;
			}
	   }
 	   | type_specifier	{
			print("parameter_list : type_specifier");
			vector<SymbolInfo*> *temp = new vector<SymbolInfo*>();
			$$ = temp;
			SymbolInfo *stemp = new SymbolInfo("", "ID");
			if($1 != VOID_VAL) {
				stemp->setStoredType($1);
				$$->push_back(stemp);
			}
			else { 
				fprintf(logFile, "Error at Line %d: void variable not allowed as parameter, this is ignored\n", line_count);
				++err_count;
			}
	   }
 	;
 		
compound_statement : LCURL { if(!funcScope) symbolTable->EnterScope(); else funcScope = false; } statements RCURL	{
		   	print("compound_statement : LCURL statements RCURL");
			$$ = new string(*$3);
			symbolTable->ExitScope();
			delete $3;
		   }
 		   | LCURL RCURL	{
			symbolTable->EnterScope();
			print("compound_statement : LCURL RCURL");
			$$ = new string("");
			symbolTable->ExitScope();
		   }
 		   ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON	{
			print("var_declaration : type_specifier declaration_list SEMICOLON");
			if($1 != VOID_VAL) {
				int size = $2->size();
				for(int i = 0; i < size; ++i) {
					SymbolInfo *temp = new SymbolInfo((*$2)[i]->getName(), "ID");
					temp->setStoredType($1);
					if((*$2)[i]->checkArray()){
						temp->setArraySize((*$2)[i]->getArraySize());
						temp->initializeArray();
					}
					if(!(symbolTable->Insert(temp))) {	
						++err_count;
						fprintf(logFile, "Error at Line %d: Multiple Variable Declared for %s\n", line_count, (*$2)[i]->getName().c_str());
					}
					if(temp->checkArray()) {
						dataSegment = extendDataSegment(dataSegment, temp->getName() + to_string(symbolTable->getID()), temp->getArraySize());
					}
					else {
						dataSegment = extendDataSegment(dataSegment, temp->getName() + to_string(symbolTable->getID()));
					}
				}
			}
			else {
				fprintf(logFile, "Error at Line %d: Void variable declared\n",line_count);
				++err_count;
			}
			delete $2;
		}
		| type_specifier declaration_list error	{
			++err_count;
		}
 		;
 		 
type_specifier	: INT	 { print("type_specifier : INT"); $$ = $1; }
 		| FLOAT	 { print("type_specifier : FLOAT"); $$ = $1; }
 		| VOID	 { print("type_specifier : VOID"); $$ = $1; }
 		;
 		
declaration_list : declaration_list COMMA ID {
			print("declaration_list : declaration_list COMMA ID", $3->getName().c_str());
			$$ = $1;
			$$->push_back($3);
		 }
 		 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{
			print("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $3->getName().c_str());
			$$ = $1;
			$3->setArraySize($5.iValue);
			$$->push_back($3);
		 }
 		 | ID	{
			print("declaration_list : ID", $1->getName().c_str());
			vector<SymbolInfo*> *temp = new vector<SymbolInfo*>();
			$$ = temp;
			$$->push_back($1);
		 }
 		 | ID LTHIRD CONST_INT RTHIRD	{
			print("declaration_list : ID LTHIRD CONST_INT RTHIRD", $1->getName().c_str());
			vector<SymbolInfo*> *temp = new vector<SymbolInfo*>();
			$$ = temp;
			$1->setArraySize($3.iValue);
			$$->push_back($1);
		 }
 		 ;
 		  
statements : statement	{
		print("statements : statement");
		$$ = $1;
	   }
	   | statements statement	{
		print("statements : statements statement");
		$$ = new string(*$1);
		*$$ += *$2;
		delete $1;
		delete $2;
	   }
	   ;
	   
statement : var_declaration	{
		print("statement : var_declaration");
		$$ = new string("");
	  }
	  | expression_statement	{
		print("statement : expression_statement");
		$$ = new string(*($1.code));
		delete $1.code;
		delete $1.asmSymbolName;
	  }
	  | compound_statement	{
		print("statement : compound_statement");
		$$ = new string(*$1);
		delete $1;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
		print("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		$$ = new string(generateFor(*($3.code), *($4.code), *($5.code), *$7, *($4.asmSymbolName)));
		delete $3.code;
		delete $3.asmSymbolName;
		delete $4.code;
		delete $4.asmSymbolName;
		delete $5.code;
		delete $5.asmSymbolName;
		delete $7;				
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE	{
		print("statement : IF LPAREN expression RPAREN statement");
		$$ = new string(*($3.code));
		*($$) += generateIf(*($3.asmSymbolName), *$5);
		delete $3.code;
		delete $3.asmSymbolName;
		delete $5;
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement	{
		print("statement : IF LPAREN expression RPAREN statement ELSE statement");
		$$ = new string(*($3.code));
		*($$) += generateIfElse(*($3.asmSymbolName), *$5, *$7);
		delete $3.code;
		delete $3.asmSymbolName;
		delete $5;
		delete $7;
	  }
	  | WHILE LPAREN expression RPAREN statement	{
		print("statement : WHILE LPAREN expression RPAREN statement");
		$$ = new string(generateWhile(*($3.asmSymbolName), *($3.code), *$5));
		delete $3.code;
		delete $3.asmSymbolName;
		delete $5;
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON	{
		print("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
		SymbolInfo *temp = symbolTable->LookUp($3->getName());
		if(!temp) {
			fprintf(logFile, "Error at Line %d: Undeclared Variable %s\n", line_count, $3->getName().c_str());
			++err_count;		
		}
		else {
			if(!temp->checkArray()) {
				if(temp->getStoredType() == INT_VAL) printf("%d\n", temp->getiValue());
				else if(temp->getStoredType() == FLOAT_VAL) printf("%f\n", temp->getfValue());	
			}
			else {
				int size = temp->getArraySize();
				for(int i = 0; i < size; ++i){
					if(temp->getStoredType() == INT_VAL) {
						printf("%d ", temp->getiValue(i));
					}
					else if(temp->getStoredType() == FLOAT_VAL) {
						printf("%f ", temp->getfValue(i));
					}
				}
				printf("\n");
			}
		}
		$$ = new string(generatePrintCall($3->getName() + to_string(symbolTable->getLookedUpID())));
		printUsed = true;		
	  }
	  | RETURN expression SEMICOLON	{
		print("statement : RETURN expression SEMICOLON");
		if(lastFoundReturnType != $2.type) {
			fprintf(logFile, "Error at Line %d: Proper type not returned in function definition\n", line_count);
			++err_count;		
		}
		$$ = new string(*($2.code));
		if(currentFunction->getName() != "main") {
			*$$ += generateReturn(*($2.asmSymbolName), currentFunction->getParameters(), lastParameterID);
		}
		delete $2.code;
		delete $2.asmSymbolName;
	  }
	  | PRINTLN LPAREN ID RPAREN error { ++err_count; }
	  | RETURN expression error { ++err_count; }
	  ;
	  
expression_statement : SEMICOLON	{
			print("expression_statement : SEMICOLON");
			$$.code = new string("");
		     }			
		     | expression SEMICOLON	{
			print("expression_statement : expression SEMICOLON");
			$$ = $1;
		     }
		     | expression error	{ ++err_count; }
		     ;
	  
variable : ID	{
		print("variable : ID");
		SymbolInfo *temp = symbolTable->LookUp($1->getName());
		if(!temp) {
			fprintf(logFile, "Error at Line %d: Undeclared Variable %s\n", line_count, $1->getName().c_str());
			++err_count;	
			SymbolInfo *temp1 = new SymbolInfo("", "ID");
			temp1->setValue(1);
			temp1->setStoredType(INT_VAL);
			$$ = temp1;	
		}
		else {
			if(temp->checkArray()) { 
				fprintf(logFile, "Error at Line %d: No Index on Array Variable %s\n", line_count, $1->getName().c_str());
				++err_count;
				temp->setLastUsedIndex(0);
			}
			$$ = temp;
		}
		$$->code = "";
		$$->asmSymbolName = $1->getName() + to_string(symbolTable->getLookedUpID());
	 }	
	 | ID LTHIRD expression RTHIRD	{
		print("variable : ID LTHIRD expression RTHIRD");
		SymbolInfo *temp = symbolTable->LookUp($1->getName());
		if(!temp) {
			fprintf(logFile, "Error at Line %d: Undeclared Variable %s\n", line_count, $1->getName().c_str());
			++err_count;
			SymbolInfo *temp1 = new SymbolInfo("", "ID");
			temp1->setStoredType(INT_VAL);
			temp1->setArraySize(0);
			temp1->initializeArray();
			temp1->setValue(1, 0);
			temp1->setLastUsedIndex(0);
			$$ = temp1;		
		}	
		else {
			if(temp->checkArray()){
				if($3.type == INT_VAL && $3.iValue < temp->getArraySize()) {
					temp->setLastUsedIndex($3.iValue);
					$$ = temp;
				}
				if($3.type != INT_VAL) {
					++err_count;
					fprintf(logFile, "Error at Line %d: Array index is non-integer for variable %s\n", line_count, temp->getName().c_str());
					temp->setLastUsedIndex(0);
					$$ = temp;
				}
				if($3.iValue >= temp->getArraySize()) {
					++err_count;
					fprintf(logFile, "Error at Line %d: Array index out of bound for variable %s\n", line_count, temp->getName().c_str());
					temp->setLastUsedIndex(0);
					$$ = temp;
				}
			}
			else {
				++err_count;
				fprintf(logFile, "Error at Line %d: Index on non-array variable %s\n", line_count, temp->getName().c_str());
				$$ = temp;
			}
			$$->code = *($3.code);
			$$->code += movIndexToBX(*($3.asmSymbolName));
			$$->code += "ADD BX, BX\n";
			$$->asmSymbolName = $1->getName() + to_string(symbolTable->getLookedUpID()) + "[BX]";
		}
		delete $3.code;
		delete $3.asmSymbolName;
	 }
	 ;
	 
expression : logic_expression	{
		print("expression : logic_expression");
		$$ = $1;
	   }	
	   | variable ASSIGNOP logic_expression	{
		print("expression : variable ASSIGNOP logic_expression");
		if($1->getStoredType() == $3.type){
			if(!$1->checkArray()) {
				if($3.type == INT_VAL) $1->setValue($3.iValue);
				else $1->setValue($3.fValue);
			}
			else	{
				if($3.type == INT_VAL) $1->setValue($3.iValue, $1->getLastUsedIndex());
				else $1->setValue($3.fValue, $1->getLastUsedIndex());
			}
		}
		else {
			++err_count;
			fprintf(logFile, "Error at Line %d: Type Mismatch\n", line_count);
			if(!$1->checkArray()) {
				if($1->getStoredType() == INT_VAL) $1->setValue(1);
				else $1->setValue((float)1.5);
			}
			else {
				if($1->getStoredType() == INT_VAL) $1->setValue(1, $1->getLastUsedIndex());
				else $1->setValue((float)1.5, $1->getLastUsedIndex());
			}
		}
		$$.code = new string(*($3.code));
		*($$.code) += generateMov($1->asmSymbolName, *($3.asmSymbolName));
		$$.asmSymbolName = new string($1->asmSymbolName);
		delete $3.code;
		delete $3.asmSymbolName;
	   }	
	   ;
			
logic_expression : rel_expression	{
			print("logic_expression : rel_expression");
			$$ = $1;
		 }
		 | rel_expression LOGICOP rel_expression	{
			print("logic_expression : rel_expression LOGICOP rel_expression");
			$$.type = INT_VAL;
			if(strcmp($2, "&&")) { 
				if($1.type == INT_VAL && $3.type == INT_VAL) $$.iValue = $1.iValue && $3.iValue;
				else if($1.type == INT_VAL && $3.type == FLOAT_VAL) $$.iValue = $1.iValue && $3.fValue;
				else if($1.type == FLOAT_VAL && $3.type == INT_VAL) $$.iValue = $1.fValue && $3.iValue;
				else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) $$.iValue = $1.fValue && $3.fValue;
				else {
					$$.iValue = 0;
					fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
					++err_count;
				}
			}
			else {
				if($1.type == INT_VAL && $3.type == INT_VAL) $$.iValue = $1.iValue || $3.iValue;
				else if($1.type == INT_VAL && $3.type == FLOAT_VAL) $$.iValue = $1.iValue || $3.fValue;
				else if($1.type == FLOAT_VAL && $3.type == INT_VAL) $$.iValue = $1.fValue || $3.iValue;
				else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) $$.iValue = $1.fValue || $3.fValue;
				else {
				  	$$.iValue = 0;
					fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
					++err_count;
				}
			}
			ADD_TO_DATA_SEGMENT;
			$$.code = new string(*($1.code));
			*($$.code) += *($3.code);
			*($$.code) += generateLogicop(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName), $2);
			$$.asmSymbolName = new string(newTempVariable);
			delete $1.code;
			delete $1.asmSymbolName;
			delete $3.code;
			delete $3.asmSymbolName;

		 } 	
		 ;
			
rel_expression : simple_expression	{
			print("rel_expression : simple_expression");
			$$ = $1;
	       }
	       | simple_expression RELOP simple_expression	{
			print("rel_expression : simple_expression RELOP simple_expression");
			$$.type = INT_VAL;
			if($1.type == INT_VAL && $3.type == INT_VAL) $$.iValue = relop($1.iValue, $3.iValue, $2);
			else if($1.type == INT_VAL && $3.type == FLOAT_VAL) $$.iValue = relop($1.iValue, $3.fValue, $2);
			else if($1.type == FLOAT_VAL && $3.type == INT_VAL) $$.iValue = relop($1.fValue, $3.iValue, $2);
			else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) $$.iValue = relop($1.fValue, $3.fValue, $2);
			else {
				  $$.iValue = 0;
				  fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
				  ++err_count;
			}
			ADD_TO_DATA_SEGMENT;
			$$.code = new string(*($1.code));
			*($$.code) += *($3.code);
			*($$.code) += generateRelop(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName), $2);
			$$.asmSymbolName = new string(newTempVariable);
			delete $1.code;
			delete $1.asmSymbolName;
			delete $3.code;
			delete $3.asmSymbolName;
	       }	
	       ;
				
simple_expression : term	{
			print("simple_expression : term");
			$$ = $1;
		  }
		  | simple_expression ADDOP term	{
			print("simple_expression : simple_expression ADDOP term");
			if(strcmp($2, "+") == 0) {
				if($1.type == INT_VAL && $3.type == INT_VAL) { 
					$$.iValue = $1.iValue + $3.iValue;
					$$.type = INT_VAL;
				}
				else if($1.type == INT_VAL && $3.type == FLOAT_VAL) {
					$$.fValue = $1.iValue + $3.fValue;
					$$.type = FLOAT_VAL;
				}
				else if($1.type == FLOAT_VAL && $3.type == INT_VAL) {
					$$.fValue = $1.fValue + $3.iValue;
					$$.type = FLOAT_VAL;
				}
				else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) {
					$$.fValue = $1.fValue + $3.fValue;
					$$.type = FLOAT_VAL;
				}
				else {
				  	$$.iValue = 0;
					$$.type = INT_VAL;
				  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
					++err_count;
				}
				$$.code = new string(*($1.code));
				*($$.code) += *($3.code);
				ADD_TO_DATA_SEGMENT;
				*($$.code) += generateAdd(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName));
				$$.asmSymbolName = new string(newTempVariable);
			}
			else {
				if($1.type == INT_VAL && $3.type == INT_VAL) { 
					$$.iValue = $1.iValue - $3.iValue;
					$$.type = INT_VAL;
				}
				else if($1.type == INT_VAL && $3.type == FLOAT_VAL) {
					$$.fValue = $1.iValue - $3.fValue;
					$$.type = FLOAT_VAL;
				}
				else if($1.type == FLOAT_VAL && $3.type == INT_VAL) {
					$$.fValue = $1.fValue - $3.iValue;
					$$.type = FLOAT_VAL;
				}
				else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) {
					$$.fValue = $1.fValue - $3.fValue;
					$$.type = FLOAT_VAL;
				}
				else {
				  	$$.iValue = 0;
					$$.type = INT_VAL;
				  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
					++err_count;
				}
				$$.code = new string(*($1.code));
				*($$.code) += *($3.code);
				ADD_TO_DATA_SEGMENT;
				*($$.code) += generateSub(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName));
				$$.asmSymbolName = new string(newTempVariable);
			}
			delete $1.code;
			delete $1.asmSymbolName;
			delete $3.code;
			delete $3.asmSymbolName;
		  } 
		  ;
					
term : unary_expression	{
		print("term : unary_expression");
		$$ = $1;
     }
     |  term MULOP unary_expression	{
		print("term : term MULOP unary_expression");
		if(strcmp($2, "*") == 0) {
			if($1.type == INT_VAL && $3.type == INT_VAL) { 
				$$.iValue = $1.iValue * $3.iValue;
				$$.type = INT_VAL;
			}
			else if($1.type == INT_VAL && $3.type == FLOAT_VAL) {
				$$.fValue = $1.iValue * $3.fValue;
				$$.type = FLOAT_VAL;
			}
			else if($1.type == FLOAT_VAL && $3.type == INT_VAL) {
				$$.fValue = $1.fValue * $3.iValue;
				$$.type = FLOAT_VAL;
			}
			else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) {
				$$.fValue = $1.fValue * $3.fValue;
				$$.type = FLOAT_VAL;
			}
			else {
			  	$$.iValue = 0;
				$$.type = INT_VAL;
			  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
				++err_count;
			}
			$$.code = new string(*($1.code));
			*($$.code) += *($3.code);
			ADD_TO_DATA_SEGMENT;
			*($$.code) += generateMul(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName));
			$$.asmSymbolName = new string(newTempVariable);
		}
		else if(strcmp($2, "/") == 0) {
			if($1.type == INT_VAL && $3.type == INT_VAL) { 
				if($3.iValue != 0)
					$$.iValue = $1.iValue / $3.iValue;
				/*else { 
					$$.iValue = $1.iValue;
					fprintf(logFile, "Error at Line %d: Division by zero\n", line_count);
					++err_count;
				}*/
				$$.type = INT_VAL;
			}
			else if($1.type == INT_VAL && $3.type == FLOAT_VAL) {
				if($3.fValue != 0.0) 
					$$.fValue = $1.iValue / $3.fValue;
				/*else {
					$$.fValue = $1.iValue/((float)1.0);
					fprintf(logFile, "Error at Line %d: Division by zero\n", line_count);
					++err_count;
				}*/
				$$.type = FLOAT_VAL;
			}
			else if($1.type == FLOAT_VAL && $3.type == INT_VAL) {
				if($3.iValue != 0)
					$$.fValue = $1.fValue / $3.iValue;
				/*else {
					$$.fValue = $1.fValue;
					fprintf(logFile, "Error at Line %d: Division by zero\n", line_count);
					++err_count;
				}*/
				$$.type = FLOAT_VAL;
			}
			else if($1.type == FLOAT_VAL && $3.type == FLOAT_VAL) {
				if($3.fValue != 0)
					$$.fValue = $1.fValue / $3.fValue;
				/*else {
					$$.fValue = $1.fValue;
					fprintf(logFile, "Error at Line %d: Division by zero\n", line_count);
					++err_count;
				}*/
				$$.type = FLOAT_VAL;
			}
			else {
			  	$$.iValue = 0;
				$$.type = INT_VAL;
			  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
				++err_count;
			}
			$$.code = new string(*($1.code));
			*($$.code) += *($3.code);
			ADD_TO_DATA_SEGMENT;
			*($$.code) += generateDiv(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName));
			$$.asmSymbolName = new string(newTempVariable);
		}
		else if(strcmp($2, "%") == 0) {
			if($1.type == INT_VAL && $3.type == INT_VAL) { 
				$$.type = INT_VAL;
				if($3.iValue != 0)
					$$.iValue = $1.iValue%$3.iValue;
				/*else {
					$$.iValue = 0;
					fprintf(logFile, "Error at Line %d: Division by zero\n", line_count);
					++err_count;
				}*/
			}
			
			else { 
				++err_count;
				fprintf(logFile, "Error at Line %d: Non-Integer operand on modulus operator\n",line_count);
				$$.type = INT_VAL;
				$$.iValue = -1;
			}
			$$.code = new string(*($1.code));
			*($$.code) += *($3.code);
			ADD_TO_DATA_SEGMENT;
			*($$.code) += generateMod(newTempVariable, *($1.asmSymbolName), *($3.asmSymbolName));
			$$.asmSymbolName = new string(newTempVariable);
		}
		delete $1.code;
		delete $1.asmSymbolName;
		delete $3.code;
		delete $3.asmSymbolName;
     }
     ;

unary_expression : ADDOP unary_expression	{
			print("unary_expression : ADDOP unary_expression");
			if(strcmp($1, "+") == 0) {
				$$ = $2;
			}
			else	{
				if($2.type == INT_VAL) {
					$$.type = INT_VAL;
					$$.iValue = -$2.iValue;
				}
				else if($2.type == FLOAT_VAL) {
					$$.type = FLOAT_VAL;
					$$.fValue = -$2.fValue;
				}
				else {
				  	$$.iValue = 0;
					$$.type = INT_VAL;
				  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
					++err_count;
				}
				ADD_TO_DATA_SEGMENT;
				$$.code = new string(*($2.code));
				*($$.code) += generateNeg(newTempVariable, *($2.asmSymbolName));
				$$.asmSymbolName = new string(newTempVariable);
				delete $2.code;
				delete $2.asmSymbolName;
			}
		 }
		 | NOT unary_expression	{
			print("unary_expression : NOT unary_expression");
			if($2.type == INT_VAL) {
				$$.type = INT_VAL;
				$$.iValue = !$2.iValue; 
			}
			else if($2.type == FLOAT_VAL) {
				$$.type == INT_VAL;
				$$.iValue = !$2.fValue;
			}
			else {
			  	$$.iValue = 0;
				$$.type = INT_VAL;
			  	fprintf(logFile, "Error at Line %d: Trying to calculate void\n", line_count);
				++err_count;
			}
			ADD_TO_DATA_SEGMENT;
			$$.code = new string(*($2.code));
			*($$.code) += generateNot(newTempVariable, *($2.asmSymbolName));
			$$.asmSymbolName = new string(newTempVariable);
			delete $2.code;
			delete $2.asmSymbolName;
		 }
		 | factor	{
			print("unary_expression : factor");
			$$ = $1;
		 }
		 ;
	
factor	: variable	{
		print("factor : variable");
		$$.type = $1->getStoredType();
		if(!$1->checkArray()) { 
			if($$.type == INT_VAL) $$.iValue = $1->getiValue();
			else if($$.type == FLOAT_VAL) $$.fValue = $1->getfValue();
		}
		else { 
			if($$.type == INT_VAL) $$.iValue = $1->getiValue($1->getLastUsedIndex());
			else if($$.type == FLOAT_VAL) $$.fValue = $1->getfValue($1->getLastUsedIndex());
		}
		$$.asmSymbolName = new string($1->asmSymbolName);
		$$.code = new string($1->code);
	}
	| ID LPAREN argument_list RPAREN	{
		print("factor : ID LPAREN argument_list RPAREN");
		SymbolInfo* temp = symbolTable->LookUp($1->getName());
		if(temp && temp->checkFunc()) {
			vector<SymbolInfo*> declared_arguments = temp->getParameters();
			int size1 = declared_arguments.size();
			int size2 = $3->size();
			if(size1 != size2) { 
				++err_count;
				fprintf(logFile, "Error at Line %d: Number Of Arguments don't match for function %s\n", line_count, temp->getName().c_str());
			}
			else	{
				for(int i = 0; i < size1; ++i) {
       				    if(declared_arguments[i]->getStoredType() != (*$3)[i]) {
				    ++err_count;
				    fprintf(logFile, "Error at Line %d: %dth argument mismatch in function %s\n", line_count, i+1, temp->getName().c_str());
				    break;
				  }
				}
			}
			$$.type = temp->getReturnType();
			if($$.type == INT_VAL) $$.iValue = 1;
			else if($$.type == FLOAT_VAL) $$.fValue = 1.0;
		}
		else if(temp && !temp->checkFunc()) {
			fprintf(logFile, "Error at Line %d: %s is not a function\n", line_count, temp->getName().c_str());
			++err_count;
			$$.type = INT_VAL;
			$$.iValue = 1;
		}
		else {
			++err_count;
			fprintf(logFile, "Error at Line %d: Func %s not declared\n", line_count, ($1->getName()).c_str());
			$$.type = INT_VAL;
			$$.iValue = 1;
		}
		ADD_TO_DATA_SEGMENT;
		$$.code = new string(generateFunctionCall(*argument_codes, $1->getName(), newTempVariable));
		$$.asmSymbolName = new string(newTempVariable);
		delete $3;
	}
	| LPAREN expression RPAREN	{
		print("factor : LPAREN expression RPAREN");
		$$ = $2;
	}
	| CONST_INT	{
		print("factor : CONST_INT");
		$$ = $1;
		ADD_TO_DATA_SEGMENT;		
		$$.asmSymbolName = new string(newTempVariable);
		$$.code = new string("MOV " + newTempVariable + ", " + to_string($1.iValue) + "\n");
	}
	| CONST_FLOAT	{
		print("factor : CONST_FLOAT");
		$$ = $1;
		ADD_TO_DATA_SEGMENT;		
		$$.asmSymbolName = new string(newTempVariable);
		$$.code = new string("MOV " + newTempVariable + ", " + to_string($1.fValue) + "\n");
	}
	| variable INCOP	{
		print("factor : variable INCOP");
		if(!$1->checkArray()) { 
			if($1->getStoredType() == INT_VAL) $1->setValue($1->getiValue() + 1);
			else if($1->getStoredType() == FLOAT_VAL) $1->setValue($1->getfValue() + 1);
		}
		else if($1->checkArray()) { 
			if($1->getStoredType() == INT_VAL) { 
                                int t = $1->getLastUsedIndex();
				$1->setValue($1->getiValue(t) + 1, t);
			}
			else if($1->getStoredType() == FLOAT_VAL) {
				int t = $1->getLastUsedIndex();
				$1->setValue($1->getfValue(t) + 1, t);
			}
		}
		ADD_TO_DATA_SEGMENT;
		$$.code = new string($1->code);
		*($$.code) += generateIncop($1->asmSymbolName);
		$$.asmSymbolName = new string($1->asmSymbolName);		
	}
	| variable DECOP	{
		print("factor : variable DECOP");
		if(!$1->checkArray()) { 
			if($1->getStoredType() == INT_VAL) $1->setValue($1->getiValue() - 1);
			else if($1->getStoredType() == FLOAT_VAL) $1->setValue($1->getfValue() - 1);
		}
		else if($1->checkArray()) { 
			if($1->getStoredType() == INT_VAL) { 
                                int t = $1->getLastUsedIndex();
				$1->setValue($1->getiValue(t) - 1, t);
			}
			else if($1->getStoredType() == FLOAT_VAL) {
				int t = $1->getLastUsedIndex();
				$1->setValue($1->getfValue(t) - 1, t);
			}
		}
		ADD_TO_DATA_SEGMENT;
		$$.code = new string($1->code);
		*($$.code) += generateDecop($1->asmSymbolName);
		$$.asmSymbolName = new string($1->asmSymbolName);
		delete $1;
	}
	;

argument_list : arguments {
			print("argument_list : arguments");
			$$ = $1;
	      }
	      |	{
			print("argument_list : ");
			vector<int> *temp = new vector<int>();
			$$ = temp;
			argument_codes = new vector<Value>();
	      }
	
arguments : arguments COMMA logic_expression	{
			print("argument_list : argument_list COMMA logic_expression");			
			$$ = $1;
			$$->push_back($3.type);
			argument_codes->push_back($3);
	      }
	      | logic_expression	{
			print("argument_list : logic_expression");
			vector<int> *temp = new vector<int>();
			$$ = temp;
			$$->push_back($1.type);
			argument_codes = new vector<Value>();
			argument_codes->push_back($1);
	      }
     	      ;
 

%%


int main(int argc,char *argv[])
{

	if(argc == 1) { 
		printf("Please provide input file");
		return 0;
	}
	symbolTable = new SymbolTable(30);
	logFile = fopen("Log.txt", "w");
	yyin = fopen(argv[1], "r");
	//yyin = stdin;
	yyparse();
	
	fprintf(logFile, "Line Count: %d\n", line_count);
	fprintf(logFile, "Error Count: %d\n", err_count);
	fclose(logFile);
	
	return 0;
}



