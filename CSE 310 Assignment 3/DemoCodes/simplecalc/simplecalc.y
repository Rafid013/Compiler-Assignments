
%{
#include <stdio.h>
#include <stdlib.h>
#define YYSTYPE double      /* yyparse() stack type */

void yyerror(char *s){
	printf("%s\n",s);
}

int yylex(void);

%}

%token NEWLINE NUMBER PLUS MINUS SLASH ASTERISK LPAREN RPAREN


%%
input:              /* empty string */
    | input line
    ;
line: NEWLINE
    | expr NEWLINE           { printf("\t%.10g\n",$1); }
    ;
expr: expr PLUS term         { $$ = $1 + $3;printf("6\n"); }
    | expr MINUS term        { $$ = $1 - $3; }
    | term	{printf("5\n");}
    ;
term: term ASTERISK factor   { $$ = $1 * $3; printf("3\n");}
    | term SLASH factor      { $$ = $1 / $3; }
    | factor {printf("4\n");}
    ;
factor:  LPAREN expr RPAREN  { $$ = $2;printf("2\n"); }
      | NUMBER {$$ = $1; printf("1\n");}
      ;
%%

main()
{
    yyparse();
    exit(0);
}
