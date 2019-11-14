%output  "parser.cxx"
%defines "parser.hxx"

/* C++ parser interface */
%skeleton "lalr1.cc"

/* require bison version */
%require  "3.2"

/* add parser members */
%parse-param  {yy::scanner& scanner} {std::ostream& out}

/* call yylex with a location */
%locations

/* increase usefulness of error messages */
%define parse.error verbose

/* assert correct cleanup of semantic value objects */
%define parse.assert
%define parse.trace

%define api.value.type variant
%define api.token.prefix {T_}

%token                  END     0   "EOF"

%token <std::shared_ptr<TerminalNode>> SEMI COMMA LP RP LB RB LC RC
            ASSIGN RELOP PLUS MINUS STAR DIV AND OR DOT NOT
            TYPE STRUCT RETURN IF ELSE WHILE INT FLOAT ID

%type <std::shared_ptr<NonTerminalNode>> Program ExtDefList ExtDef ExtDecList
            Specifier StructSpecifier OptTag Tag VarDec FunDec
            VarList ParamDec CompSt StmtList Stmt DefList Def DecList
            Dec Exp Args

%right ASSIGN
%left OR AND RELOP PLUS MINUS STAR DIV LP RP LB RB DOT

/* lower than else, eliminate the ambiguity of else */
%nonassoc LTE
%nonassoc ELSE

%start Program

/* inserted near top of header + source file */
%code requires {
    #include <sstream>
    #include <stdexcept>
    #include <string>
    #include <vector>

    #include "ast.hpp"
    #include "location.hh"

    namespace yy {
        class scanner;
    };

    void parse(std::istream &in, std::ostream &out);
}

/* inserted near top of source file */
%code {
    #include <iostream>
    #include <sstream>
    #include <string>

    #include "scanner.hpp"

    #undef yylex
    #define yylex scanner.lex
}

%%

/* High-level Definitions */

Program
    : ExtDefList                    {
                                        $$ = make_non_terminal(NonTerminalNode::Type::T_Program, $1);
                                        std::cout << $$->to_string() << std::endl;
                                    }
    ;

ExtDefList
    : ExtDef ExtDefList             { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDefList, $1, $2); }
    | %empty                        { $$ = nullptr; }
    ;

ExtDef
    : Specifier ExtDecList SEMI     { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDef, $1, $2, $3); }
    | Specifier SEMI                { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDef, $1, $2); }
    | Specifier FunDec CompSt       { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDef, $1, $2, $3); }
    ;

ExtDecList
    : VarDec                        { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDecList, $1); }
    | VarDec COMMA ExtDecList       { $$ = make_non_terminal(NonTerminalNode::Type::T_ExtDecList, $1, $2, $3); }
    ;


/* Specifiers */
Specifier
    : TYPE                          { $$ = make_non_terminal(NonTerminalNode::Type::T_Specifier, $1); }
    | StructSpecifier               { $$ = make_non_terminal(NonTerminalNode::Type::T_Specifier, $1); }
    ;

StructSpecifier
    : STRUCT OptTag LC DefList RC   { $$ = make_non_terminal(NonTerminalNode::Type::T_StructSpecifier, $1, $2, $3, $4, $5); }
    | STRUCT Tag                    { $$ = make_non_terminal(NonTerminalNode::Type::T_StructSpecifier, $1, $2); }
    ;

OptTag
    : ID                            { $$ = make_non_terminal(NonTerminalNode::Type::T_OptTag, $1); }
    | %empty                        { $$ = nullptr; }
    ;

Tag
    : ID                            { $$ = make_non_terminal(NonTerminalNode::Type::T_Tag, $1); }
    ;


/* Declarators */

VarDec
    : ID                            { $$ = make_non_terminal(NonTerminalNode::Type::T_VarDec, $1); }
    | VarDec LB INT RB              { $$ = make_non_terminal(NonTerminalNode::Type::T_VarDec, $1, $2, $3, $4); }
    ;

FunDec 
    : ID LP VarList RP              { $$ = make_non_terminal(NonTerminalNode::Type::T_FunDec, $1, $2, $3, $4); }
    | ID LP RP                      { $$ = make_non_terminal(NonTerminalNode::Type::T_FunDec, $1, $2, $3); }
    ;

VarList
    : ParamDec COMMA VarList        { $$ = make_non_terminal(NonTerminalNode::Type::T_VarList, $1, $2, $3); }
    | ParamDec                      { $$ = make_non_terminal(NonTerminalNode::Type::T_VarList, $1); }
    ;

ParamDec
    : Specifier VarDec              { $$ = make_non_terminal(NonTerminalNode::Type::T_ParamDec, $1, $2); }
    ;


/* Statements */

CompSt 
    : LC DefList StmtList RC        { $$ = make_non_terminal(NonTerminalNode::Type::T_CompSt, $1, $2, $3, $4); }
    ;

StmtList
    : Stmt StmtList                 { $$ = make_non_terminal(NonTerminalNode::Type::T_StmtList, $1, $2); }
    | %empty                        { $$ = nullptr; }
    ;

Stmt
    : Exp SEMI                      { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1, $2); }
    | CompSt                        { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1); }
    | RETURN Exp SEMI               { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1, $2, $3); }
    | IF LP Exp RP Stmt %prec LTE   { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1, $2, $3, $4, $5); }
    | IF LP Exp RP Stmt ELSE Stmt   { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1, $2, $3, $4, $5, $6, $7); }
    | WHILE LP Exp RP Stmt          { $$ = make_non_terminal(NonTerminalNode::Type::T_Stmt, $1, $2, $3, $4, $5); }
    ;


/*  Local Definitions */

DefList
    : Def DefList                   { $$ = make_non_terminal(NonTerminalNode::Type::T_DefList, $1, $2); }
    | %empty                        { $$ = nullptr; }
    ;

Def
    : Specifier DecList SEMI        { $$ = make_non_terminal(NonTerminalNode::Type::T_Def, $1, $2, $3); }
    ;

DecList
    : Dec                           { $$ = make_non_terminal(NonTerminalNode::Type::T_DecList, $1); }
    | Dec COMMA DecList             { $$ = make_non_terminal(NonTerminalNode::Type::T_DecList, $1, $2, $3); }
    ;

Dec
    : VarDec                        { $$ = make_non_terminal(NonTerminalNode::Type::T_Dec, $1); }
    | VarDec ASSIGN Exp             { $$ = make_non_terminal(NonTerminalNode::Type::T_Dec, $1, $2, $3); }
    ;


/* Expressions */

Exp
    : Exp ASSIGN Exp                { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp AND Exp                   { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp OR Exp                    { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp RELOP Exp                 { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp PLUS Exp                  { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp MINUS Exp                 { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp STAR Exp                  { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp DIV Exp                   { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | LP Exp RP                     { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | MINUS Exp                     { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2); }
    | NOT Exp                       { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2); }
    | ID LP Args RP                 { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3, $4); }
    | ID LP RP                      { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | Exp LB Exp RB                 { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3, $4); }
    | Exp DOT ID                    { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1, $2, $3); }
    | ID                            { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1); }
    | INT                           { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1); }
    | FLOAT                         { $$ = make_non_terminal(NonTerminalNode::Type::T_Exp, $1); }
    ;

Args
    : Exp COMMA Args                { $$ = make_non_terminal(NonTerminalNode::Type::T_Args, $1, $2, $3); }
    | Exp                           { $$ = make_non_terminal(NonTerminalNode::Type::T_Args, $1); }
    ;

%%
void yy::parser::error(const parser::location_type &l, const std::string &m) {
    throw yy::parser::syntax_error(l, m);
}

void parse(std::istream &in, std::ostream &out) {
    yy::scanner scanner(in);
    yy::parser parser(scanner, out);
    try {
        if (parser.parse() != 0) {
            throw std::runtime_error("unknown parsing error");
        }
    } catch (yy::parser::syntax_error &e) {
        std::ostringstream msg;
        msg << e.what() << " at row " << e.location.begin.line << " column "
            << e.location.begin.column;
        throw yy::parser::syntax_error(e.location, msg.str());
    }
}

int main() {
    try {
        parse(std::cin, std::cout);
    } catch (yy::parser::syntax_error &e) {
        std::cerr << e.what() << std::endl;
    }
    return 0;
}