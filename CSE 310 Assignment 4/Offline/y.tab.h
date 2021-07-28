/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    IF = 258,
    FOR = 259,
    WHILE = 260,
    RETURN = 261,
    ASSIGNOP = 262,
    NOT = 263,
    PRINTLN = 264,
    LPAREN = 265,
    RPAREN = 266,
    LCURL = 267,
    RCURL = 268,
    LTHIRD = 269,
    RTHIRD = 270,
    COMMA = 271,
    SEMICOLON = 272,
    CONST_INT = 273,
    INT = 274,
    FLOAT = 275,
    CHAR = 276,
    VOID = 277,
    DOUBLE = 278,
    CONST_FLOAT = 279,
    CONST_CHAR = 280,
    ID = 281,
    INCOP = 282,
    DECOP = 283,
    ADDOP = 284,
    MULOP = 285,
    RELOP = 286,
    LOGICOP = 287,
    LOWER_THAN_ELSE = 288,
    ELSE = 289
  };
#endif
/* Tokens.  */
#define IF 258
#define FOR 259
#define WHILE 260
#define RETURN 261
#define ASSIGNOP 262
#define NOT 263
#define PRINTLN 264
#define LPAREN 265
#define RPAREN 266
#define LCURL 267
#define RCURL 268
#define LTHIRD 269
#define RTHIRD 270
#define COMMA 271
#define SEMICOLON 272
#define CONST_INT 273
#define INT 274
#define FLOAT 275
#define CHAR 276
#define VOID 277
#define DOUBLE 278
#define CONST_FLOAT 279
#define CONST_CHAR 280
#define ID 281
#define INCOP 282
#define DECOP 283
#define ADDOP 284
#define MULOP 285
#define RELOP 286
#define LOGICOP 287
#define LOWER_THAN_ELSE 288
#define ELSE 289

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 136 "Parser.y" /* yacc.c:1909  */
 
	int ival; float fval;  Value vc; char* str; SymbolInfo* sival; vector<int>* vi;
	vector<SymbolInfo*>* vs; string *st;

#line 127 "y.tab.h" /* yacc.c:1909  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
