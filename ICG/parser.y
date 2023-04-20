%{
	#include "quad_generation.c"
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>

	#define YYSTYPE char*

	void yyerror(char* s); 											// error handling function
	int yylex(); 													// declare the function performing lexical analysis
	extern int yylineno; 											// track the line number

	FILE* icg_quad_file;
	int temp_no = 1;
	int label_no = 1;
	char *temp_label;
%}


%token T_ID T_NUM IF ELSE

/* specify start symbol */
%start START


%%
START : STMTS	{
					printf("Valid syntax\n");
	 				YYACCEPT;										// If program fits the grammar, syntax is valid
				}
;

STMTS : STMT STMTS
		| STMT
;

STMT : IF '(' COND ')'  {
		$$ = new_label();
		quad_code_gen($3, NULL, "if", $$);
		temp_label = new_label();
		quad_code_gen(NULL, NULL, "goto", temp_label);
		quad_code_gen(NULL, NULL, "Label", $$);

}  '{' STMTS '}'  ELSE_BLOCK
	| ASSGN
;

ELSE_BLOCK : 
{
	$$ = temp_label; 
	temp_label = new_label(); 
	quad_code_gen(NULL, NULL, "goto", temp_label);
	quad_code_gen(NULL, NULL, "Label", $$);
}
ELSE {
	}'{' STMTS '}' 
{
		quad_code_gen(NULL, NULL, "Label", temp_label);
		temp_label = NULL;
}
| 
{
	if(temp_label != NULL) {
		quad_code_gen(NULL, NULL, "Label", temp_label);
	}
};

COND : E RELOP E {
	$$=new_temp(); 
	quad_code_gen($1, $3 , $2 , $$ );
}
;

RELOP : '<' {$$="<";}
	   | '>' {$$=">";}
	   | '<' '=' {$$="<=";}
	   | '>' '=' {$$=">=";}
	   | '!' '=' {$$="!=";}
	   | '=' '=' {$$="==";}
;

/* Grammar for assignment */
ASSGN : T_ID '=' E ';'	{	quad_code_gen($3,NULL,"=",$1);	}
;

/* Expression Grammar */
E : E '+' T 	{	$$ = new_temp();	quad_code_gen($1,$3,"+",$$); }
	| E '-' T 	{	$$ = new_temp();	quad_code_gen($1,$3,"-",$$); }
	| T
	;


T : T '*' F 	{	$$ = new_temp();	quad_code_gen($1,$3,"*",$$);  }
	| T '/' F 	{	$$ = new_temp();	quad_code_gen($1,$3,"/",$$);  }
	| F
	;

F : '(' E ')' 	{	$$ = $2;	}
	| T_ID
	| T_NUM
	;

%%


/* error handling function */
void yyerror(char* s)
{
	printf("Error :%s at %d \n",s,yylineno);
}
int yywrap()
{
	return 1;
}

/* main function - calls the yyparse() function which will in turn drive yylex() as well */
int main(int argc, char* argv[])
{
	icg_quad_file = fopen("icg_output.txt","w");
	yyparse();
	fclose(icg_quad_file);
	return 0;
}
