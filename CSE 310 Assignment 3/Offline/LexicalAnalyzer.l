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
#include "SymbolTable.h"

#include "y.tab.h"
using namespace std;


extern YYSTYPE yylval;
extern FILE *logFile;
extern FILE *errorFile;

void yyerror(char *);

extern int line_count;
extern int err_count;
string multilineStr_log;
string multilineStr_token;
string multilineComment;

int line_state;







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
KEYWORD	if|for|do|int|float|void|default|else|while|char|double|return|continue
ESC_CHAR [nt\\\"afrbv0]
NOT_NEWLINE [^\n]

%%

{NEWLINE}	{ line_count++; }

"if"	{ return IF; }

"for"	{ return FOR; }

"int"	{ 
	yylval.ival = INT_VAL;
	return INT; 
}

"float"	{ 
	yylval.ival = FLOAT_VAL;	
	return FLOAT; 
}

"void"	{ 
	yylval.ival = VOID_VAL;	
	return VOID; 
}

"else"	{ return ELSE; }

"while" { return WHILE; }

"return" { return RETURN; }

"println"	{ return PRINTLN; }

{DIGIT}+	{ 
	yylval.vc.iValue = atoi(yytext);
	yylval.vc.type = INT_VAL;
	return CONST_INT;
}

{DIGIT}*\.{DIGIT}+((E|e)[+-]?{DIGIT}+)?	{
	yylval.vc.fValue = atof(yytext);
	yylval.vc.type = FLOAT_VAL;
	return CONST_FLOAT;
}

'\\{ESC_CHAR}'	{
	return CONST_CHAR;
}

'[^'\n\t\r\v]?|'\\'	{
	++err_count;
	fprintf(errorFile, "Error at Line no %d: Unfinished Character %s\n\n", line_count, yytext);	
}

''	{
	++err_count;
	fprintf(errorFile, "Error at Line no %d: Empty character constant %s\n\n", line_count, yytext);
}

'.'	{
	return CONST_CHAR;
}

"++"	{
	yylval.str = new char[3];
	strcpy(yylval.str, yytext);
	return INCOP;
}

"--"	{
	yylval.str = new char[3];
	strcpy(yylval.str, yytext);
	return DECOP;
}

"+"|"-"	{
	yylval.str = new char[2];
	strcpy(yylval.str, yytext);
	return ADDOP;
}

"*"|"/"|"%"	{
	yylval.str = new char[2];
	strcpy(yylval.str, yytext);
	return MULOP;
}

"<"|"<="|">"|">="|"=="|"!="	{
	yylval.str = new char[3];
	strcpy(yylval.str, yytext);
	return RELOP;
}

"="	{
	return ASSIGNOP;
}

"&&"|"||"	{
	yylval.str = new char[3];
	strcpy(yylval.str, yytext);
	return LOGICOP;
}

"!"	{
	return NOT;
}

"("	{
	return LPAREN;	
}

")"	{
	return RPAREN;
}

"{"	{
	return LCURL;
}	


"}"	{
	return RCURL;
}

"["	{
	return LTHIRD;
}

"]"	{
	return RTHIRD;
}

","	{
	return COMMA;
}

";"	{
	return SEMICOLON;
}

({LETTER}|"_")({ALPHANUMERIC}|"_")*	{
	SymbolInfo *symbolInfo = new SymbolInfo(yytext, "ID");
	yylval.sival = symbolInfo;
	return ID;
}

\"[^\n\"]*\"	{
	return STRING;
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
	multilineStr_log.clear();
	multilineStr_token.clear();
	BEGIN INITIAL;
	return STRING;
}

<STRING>[^\n\"]*{NEWLINE}	{
	++err_count;
	++line_count;
	multilineStr_log.append(removeNewline(yytext));
	fprintf(errorFile, "Error at Line no %d: Unfinished string %s\n\n", line_state, multilineStr_log.c_str());
	multilineStr_log.clear();
	multilineStr_token.clear();
	BEGIN INITIAL;
	return STRING;
}

"//"[^\\\n]*((\\)+[^\\\n]+)*{NEWLINE}	{
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
	multilineComment.clear();
	BEGIN INITIAL;
}

<FINISHING_COMMENT><<EOF>>	{
	fprintf(errorFile, "Error at Line no %d: Unfinished comment %s\n\n", line_state, multilineComment.c_str());
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
	fprintf(errorFile, "Error at Line no %d: Unfinished comment %s\n\n", line_state, multilineComment.c_str());
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
	fprintf(errorFile, "Error at Line no %d: Too many decimal points %s\n\n", line_count, yytext);
}

{DIGIT}*(\.{DIGIT}+)?(E|e)[+-]?{DIGIT}+\.{DIGIT}+	{
	++err_count;
	fprintf(errorFile, "Error at Line no %d: Ill formed number %s\n\n", line_count, yytext);
}

{DIGIT}+({ALPHANUMERIC}|"_")+	{
	++err_count;
	fprintf(errorFile, "Error at Line no %d: Invalid Prefix on Identifier %s\n\n", line_count, yytext);
}

'.(.)+'	{
	++err_count;
	fprintf(errorFile, "Error at Line no %d: Multi character constant %s\n\n", line_count, yytext);
}

{WHITESPACE}	{}

.	{
	fprintf(errorFile, "Error at Line no %d: Unrecognized Character %s\n\n", line_count, yytext);
	++err_count;
}

%%





