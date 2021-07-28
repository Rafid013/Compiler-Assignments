%option noyywrap


%x STRING
%x COMMENT_WITH_STAR
%x NORMAL_MULTILINE_COMMENT
%x FINISHING_COMMENT


%{
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <string>
#include <cctype>
#include "SymbolTable.cpp"
#include "y.tab.h"
using namespace std;
int line_count = 1;
int err_count = 0;
string multilineStr_log;
string multilineStr_token;
string multilineComment;
FILE *logFile;
FILE *tokenFile;
int line_state;
SymbolTable symbolTable(10);

char getEscapeChar(char *str){
	if(str[2] == 'n') return '\n';
	else if(str[2] == 't') return '\t';
	else if(str[2] == '\\') return '\\';
	else if(str[2] == '\"') return '\"';
	else if(str[2] == 'a') return '\a';
	else if(str[2] == 'f') return '\f';
	else if(str[2] == 'r') return '\r';
	else if(str[2] == 'b') return '\b';
	else if(str[2] == 'v') return '\v';
	else if(str[2] == '0') return '\0';
}

char* toUpperStr(const char *str){
	int size = strlen(str);
	char *retStr = new char[size];
	strcpy(retStr, str);
	for(int i = 0; retStr[i] != '\0'; ++i){
		retStr[i] = toupper(retStr[i]);
	}
	return retStr;
}


char* getRealString(const char *str){
	int size = strlen(str);
	int i = 0, j = 0;
	char *retStr = new char[size];
	for(i = 0, j = 0; str[i] != '\0'; ++i, ++j){
		if(str[i] == '\\'){
			++i;
			if(str[i] == 'n') retStr[j] = '\n';
			else if(str[i] == 't') retStr[j] = '\t';
			else if(str[i] == '\\') retStr[j] = '\\';
			else if(str[i] == '\"') retStr[j] = '\"';
			else if(str[i] == 'a') retStr[j] = '\a';
			else if(str[i] == 'f') retStr[j] = '\f';
			else if(str[i] == 'r') retStr[j] = '\r';
			else if(str[i] == 'b') retStr[j] = '\b';
			else if(str[i] == 'v') retStr[j] = '\v';
			else if(str[i] == '0') retStr[j] = '\0';
			else retStr[j] = str[i];		
		}
		else retStr[j] = str[i];	
	}
	retStr[j] = '\0';
	return retStr;
}

char* removeSlashNewline(const char *str){
	int size = strlen(str);
	char *retStr = new char[size];
	strcpy(retStr, str);
	retStr[size - 2] = '\0';
	return retStr;
}

char* removeNewline(const char *str){
	int size = strlen(str);
	char *retStr = new char[size];
	strcpy(retStr, str);
	retStr[size - 1] = '\0';
	return retStr;
}

%}

WHITESPACE	[ \t\f\r\v]+
LETTER	[a-zA-Z]
DIGIT	[0-9]
NEWLINE	\n
ALPHANUMERIC	[a-zA-Z0-9]
KEYWORD	if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue
ESC_CHAR [nt\\\"afrbv0]
NOT_NEWLINE [^\n]

%%

{NEWLINE}	{ line_count++; }

{KEYWORD}	{ 
	fprintf(tokenFile, "<%s> ", toUpperStr(yytext));
	fprintf(logFile, "Line no %d: TOKEN <%s> Lexeme %s found\n\n", line_count, toUpperStr(yytext), yytext);
}

{DIGIT}+	{ 
	fprintf(tokenFile, "<CONST_INT, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <CONST_INT> Lexeme %s found\n\n", line_count, yytext);
	if(symbolTable.Insert(yytext, "CONST_INT"))
		symbolTable.PrintAllScopeTableFile(logFile);
}

{DIGIT}*\.{DIGIT}+((E|e)[+-]?{DIGIT}+)?	{
	fprintf(tokenFile, "<CONST_FLOAT, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n\n", line_count, yytext);
	if(symbolTable.Insert(yytext, "CONST_FLOAT"))
		symbolTable.PrintAllScopeTableFile(logFile);
}

'\\{ESC_CHAR}'	{
	fprintf(tokenFile, "<CONST_CHAR, %c> ", getEscapeChar(yytext));
	fprintf(logFile, "Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n\n", line_count, yytext);
	if(symbolTable.Insert(yytext, "CONST_CHAR"))
		symbolTable.PrintAllScopeTableFile(logFile);
}

'[^'\n\t\r\v]?|'\\'	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Unfinished Character %s\n\n", line_count, yytext);	
}

''	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Empty character constant %s\n\n", line_count, yytext);
}

'.'	{
	fprintf(tokenFile, "<CONST_CHAR, %c> ", yytext[1]);
	fprintf(logFile, "Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n\n", line_count, yytext);
	if(symbolTable.Insert(yytext, "CONST_CHAR"))
		symbolTable.PrintAllScopeTableFile(logFile);
}

"++"|"--"	{
	fprintf(tokenFile, "<INCOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <INCOP> Lexeme %s found\n\n", line_count, yytext);
}

"+"|"-"	{
	fprintf(tokenFile, "<ADDOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <ADDOP> Lexeme %s found\n\n", line_count, yytext);
}

"*"|"/"|"%"	{
	fprintf(tokenFile, "<MULOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <MULOP> Lexeme %s found\n\n", line_count, yytext);
}

"<"|"<="|">"|">="|"=="|"!="	{
	fprintf(tokenFile, "<RELOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <RELOP> Lexeme %s found\n\n", line_count, yytext);
}

"="	{
	fprintf(tokenFile, "<ASSIGNOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n\n", line_count, yytext);
}

"&&"|"||"	{
	fprintf(tokenFile, "<LOGICOP, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <LOGICOP> Lexeme %s found\n\n", line_count, yytext);
}

"!"	{
	fprintf(tokenFile, "<NOT, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <NOT> Lexeme %s found\n\n", line_count, yytext);
}

"("	{
	fprintf(tokenFile, "<LPAREN, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <LPAREN> Lexeme %s found\n\n", line_count, yytext);	
}

")"	{
	fprintf(tokenFile, "<RPAREN, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <RPAREN> Lexeme %s found\n\n", line_count, yytext);
}

"{"	{
	fprintf(tokenFile, "<LCURL, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <LCURL> Lexeme %s found\n\n", line_count, yytext);
}	


"}"	{
	fprintf(tokenFile, "<RCURL, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <RCURL> Lexeme %s found\n\n", line_count, yytext);
}

"["	{
	fprintf(tokenFile, "<LTHIRD, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <LTHIRD> Lexeme %s found\n\n", line_count, yytext);
}

"]"	{
	fprintf(tokenFile, "<RTHIRD, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <RTHIRD> Lexeme %s found\n\n", line_count, yytext);
}

","	{
	fprintf(tokenFile, "<COMMA, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <COMMA> Lexeme %s found\n\n", line_count, yytext);
}

";"	{
	fprintf(tokenFile, "<SEMICOLON, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n\n", line_count, yytext);
}

({LETTER}|"_")({ALPHANUMERIC}|"_")*	{
	fprintf(tokenFile, "<ID, %s> ", yytext);
	fprintf(logFile, "Line no %d: TOKEN <ID> Lexeme %s found\n\n", line_count, yytext);
	if(symbolTable.Insert(yytext, "ID"))
		symbolTable.PrintAllScopeTableFile(logFile);
}

\"[^\n\"]*\"	{
	fprintf(tokenFile, "<STRING, %s> ", getRealString(yytext));
	fprintf(logFile, "Line no %d: TOKEN <STRING> Lexeme %s found\n\n", line_count, yytext);
}

\"	{ 
	BEGIN STRING;
	line_state = line_count;
	multilineStr_log.append(yytext);
	multilineStr_token.append(yytext); 
}

<STRING>[^\n\"]*\\{NEWLINE}	{
	multilineStr_log.append(yytext);
	multilineStr_token.append(removeSlashNewline(yytext));
	line_count++;
}

<STRING>[^\n\"]*\"	{
	multilineStr_log.append(yytext);
	multilineStr_token.append(yytext);	
	fprintf(tokenFile, "<STRING, %s> ", getRealString(multilineStr_token.c_str()));
	fprintf(logFile, "Line no %d: TOKEN <STRING> Lexeme %s found\n\n", line_state, multilineStr_log.c_str());
	multilineStr_log.clear();
	multilineStr_token.clear();
	BEGIN INITIAL;
}

<STRING>[^\n\"]*{NEWLINE}	{
	++err_count;
	++line_count;
	multilineStr_log.append(removeNewline(yytext));
	fprintf(logFile, "Error at Line no %d: Unfinished string %s\n\n", line_state, multilineStr_log.c_str());
	multilineStr_log.clear();
	multilineStr_token.clear();
	BEGIN INITIAL;
}

"//"[^\\\n]*((\\)+[^\\\n]+)*{NEWLINE}	{
	fprintf(logFile, "Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n", line_count, removeNewline(yytext));
	line_count++;
}

"//"	{ 
	BEGIN NORMAL_MULTILINE_COMMENT;
	line_state = line_count;
	multilineComment.append(yytext);
}

<NORMAL_MULTILINE_COMMENT>[^\\\n]*((\\)+[^\\\n]+)*(\\)+{NEWLINE} {
	multilineComment.append(yytext);
	line_count++;
}

<NORMAL_MULTILINE_COMMENT>[^\\\n]*((\\)+[^\\\n]+)*{NEWLINE}	{
	multilineComment.append(removeNewline(yytext));
	fprintf(logFile, "Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n", line_state, multilineComment.c_str());
	multilineComment.clear();
	line_count++;
	BEGIN INITIAL;
}

"/*"	{
	BEGIN COMMENT_WITH_STAR;
	line_state = line_count;
	multilineComment.append(yytext);
}

<FINISHING_COMMENT>"/"	{
	multilineComment.append(yytext);
	fprintf(logFile, "Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n", line_state, multilineComment.c_str());
	multilineComment.clear();
	BEGIN INITIAL;
}

<FINISHING_COMMENT><<EOF>>	{
	fprintf(logFile, "Error at Line no %d: Unfinished comment %s\n\n", line_state, multilineComment.c_str());
	++err_count;
	multilineComment.clear();
	BEGIN INITIAL;
}

<FINISHING_COMMENT>[^\/\n]	{ 
	multilineComment.append(yytext);
	BEGIN COMMENT_WITH_STAR;
}

<FINISHING_COMMENT>{NEWLINE}	{
	multilineComment.append(yytext);
	line_count++;
	BEGIN COMMENT_WITH_STAR;
}

<COMMENT_WITH_STAR>"*"	{
	multilineComment.append(yytext);
	BEGIN FINISHING_COMMENT;
}

<COMMENT_WITH_STAR><<EOF>>	{
	fprintf(logFile, "Error at Line no %d: Unfinished comment %s\n\n", line_state, multilineComment.c_str());
	++err_count;
	multilineComment.clear();
	BEGIN INITIAL;
}

<COMMENT_WITH_STAR>[^*\n]*	{
	multilineComment.append(yytext);
}

<COMMENT_WITH_STAR>{NEWLINE}	{
	multilineComment.append(yytext);
	line_count++;
}

{DIGIT}*\.{DIGIT}+(\.{DIGIT}+)+	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Too many decimal points %s\n\n", line_count, yytext);
}

{DIGIT}*(\.{DIGIT}+)?(E|e)[+-]?{DIGIT}+\.{DIGIT}+	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Ill formed number %s\n\n", line_count, yytext);
}

{DIGIT}+({ALPHANUMERIC}|"_")+	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Invalid Prefix on Identifier %s\n\n", line_count, yytext);
}

'.(.)+'	{
	++err_count;
	fprintf(logFile, "Error at Line no %d: Multi character constant %s\n\n", line_count, yytext);
}

{WHITESPACE}	{}

.	{
	fprintf(logFile, "Error at Line no %d: Unrecognized Character %s\n\n", line_count, yytext);
	++err_count;
}

%%







