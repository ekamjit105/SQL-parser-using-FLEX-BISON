%{

/*
Submitted by - Ekamjit Singh 
Roll Number  - 2019CSC1001
*/

#include<stdio.h>
#include<stdlib.h>
#include<string>
extern int yylex();
extern void yyerror(std::string);
%}

// the different types of tokens we want to return
%union{
int int_val;
double double_val;
char* char_val;
}


// list the different tokens of each type

%token<int_val> NUMBER OPR EQUALS LBR RBR VARIABLE CHARSET SEMICOLON


// indicate which of the below nodes is the root of the parse tree
%start lines 

%%

lines: 	expr	

expr: 	expr OPR expr 				
	|	LBR expr RBR 					
	|	VARIABLE			
	|	NUMBER				
	;
