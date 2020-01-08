%output  "parser.cxx"
%defines "parser.hxx"

/* C++ parser interface */
%skeleton "lalr1.cc"
%language "c++"

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

%token END 0 "EOF"

%token <std::shared_ptr<Node>> SEMI COMMA LP RP LB RB LC RC
            ASSIGN RELOP PLUS MINUS STAR DIV AND OR DOT NOT
            TYPE STRUCT RETURN IF ELSE WHILE INT FLOAT ID

%type <std::shared_ptr<Node>> Program ExtDefList ExtDef ExtDecList
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

    std::shared_ptr<Node> ast_root = nullptr;
}

%%

/* High-level Definitions */

Program
    : ExtDefList                    {
                                        $$ = make_node(Node::Type::Program, $1);
                                        $$->position.first = @1.begin.line;
                                        ast_root = $$;
                                    }
    ;

ExtDefList
    : ExtDef ExtDefList             { $$ = make_node(Node::Type::ExtDefList, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | %empty                        { $$ = nullptr; }
    ;

ExtDef
    : Specifier ExtDecList SEMI     { $$ = make_node(Node::Type::ExtDef, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Specifier SEMI                { $$ = make_node(Node::Type::ExtDef, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | Specifier FunDec CompSt       { $$ = make_node(Node::Type::ExtDef, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    ;

ExtDecList
    : VarDec                        { $$ = make_node(Node::Type::ExtDecList, $1);
                                        $$->position.first = @1.begin.line; }
    | VarDec COMMA ExtDecList       { $$ = make_node(Node::Type::ExtDecList, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    ;


/* Specifiers */
Specifier
    : TYPE                          { $$ = make_node(Node::Type::Specifier, $1);
                                        $$->position.first = @1.begin.line; }
    | StructSpecifier               { $$ = make_node(Node::Type::Specifier, $1);
                                        $$->position.first = @1.begin.line; }
    ;

StructSpecifier
    : STRUCT OptTag LC DefList RC   { $$ = make_node(Node::Type::StructSpecifier, $1, $2, $3, $4, $5);
                                        $$->position.first = @1.begin.line; }
    | STRUCT OptTag LC error RC     { error(@4, "Valid StructSpecifier expected."); }
    | STRUCT Tag                    { $$ = make_node(Node::Type::StructSpecifier, $1, $2);
                                        $$->position.first = @1.begin.line; }
    ;

OptTag
    : ID                            { $$ = make_node(Node::Type::OptTag, $1);
                                        $$->position.first = @1.begin.line; }
    | %empty                        { $$ = nullptr; }
    ;

Tag
    : ID                            { $$ = make_node(Node::Type::Tag, $1);
                                        $$->position.first = @1.begin.line; }
    ;


/* Declarators */
VarDec
    : ID                            { $$ = make_node(Node::Type::VarDec, $1);
                                        $$->position.first = @1.begin.line; }
    | VarDec LB INT RB              { $$ = make_node(Node::Type::VarDec, $1, $2, $3, $4);
                                        $$->position.first = @1.begin.line; }
    | VarDec LB error RB            { error(@3, "Valid VarDec expected."); }
    ;

FunDec 
    : ID LP VarList RP              { $$ = make_node(Node::Type::FunDec, $1, $2, $3, $4);
                                        $$->position.first = @1.begin.line; }
    | ID LP RP                      { $$ = make_node(Node::Type::FunDec, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | ID LP error RP                { error(@3, "Valid FunDec expected."); }
    ;

VarList
    : ParamDec COMMA VarList        { $$ = make_node(Node::Type::VarList, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | ParamDec                      { $$ = make_node(Node::Type::VarList, $1);
                                        $$->position.first = @1.begin.line; }
    | ParamDec error                { error(@2, "COMMA expected."); }
    ;

ParamDec
    : Specifier VarDec              { $$ = make_node(Node::Type::ParamDec, $1, $2);
                                        $$->position.first = @1.begin.line; }
    ;


/* Statements */

CompSt 
    : LC DefList StmtList RC        { $$ = make_node(Node::Type::CompSt, $1, $2, $3, $4);
                                        $$->position.first = @1.begin.line; }
    ;

StmtList
    : Stmt StmtList                 { $$ = make_node(Node::Type::StmtList, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | %empty                        { $$ = nullptr; }
    ;

Stmt
    : Exp SEMI                      { $$ = make_node(Node::Type::Stmt, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | CompSt                        { $$ = make_node(Node::Type::Stmt, $1);
                                        $$->position.first = @1.begin.line; }
    | RETURN Exp SEMI               { $$ = make_node(Node::Type::Stmt, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | IF LP Exp RP Stmt %prec LTE   { $$ = make_node(Node::Type::Stmt, $1, $2, $3, $4, $5);
                                        $$->position.first = @1.begin.line; }
    | IF LP Exp RP Stmt ELSE Stmt   { $$ = make_node(Node::Type::Stmt, $1, $2, $3, $4, $5, $6, $7);
                                        $$->position.first = @1.begin.line; }
    | IF LP error RP                { /* error(@3, "Valid Stmt expected."); */ }
    | WHILE LP Exp RP Stmt          { $$ = make_node(Node::Type::Stmt, $1, $2, $3, $4, $5);
                                        $$->position.first = @1.begin.line; }
    | Exp error                     { /* error(@2, "Valid Stmt expected."); */ }
	| IF error                      { /* error(@2, "Valid Stmt expected."); */ }
	| WHILE error                   { /* error(@2, "Valid Stmt expected."); */ }
    | WHILE LP error RP             { /* error(@2, "Valid Stmt expected."); */ }
    ;


/*  Local Definitions */

DefList
    : Def DefList                   { $$ = make_node(Node::Type::DefList, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | %empty                        { $$ = nullptr; }
    ;

Def
    : Specifier DecList SEMI        { $$ = make_node(Node::Type::Def, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    ;

DecList
    : Dec                           { $$ = make_node(Node::Type::DecList, $1);
                                        $$->position.first = @1.begin.line; }
    | Dec COMMA DecList             { $$ = make_node(Node::Type::DecList, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    ;

Dec
    : VarDec                        { $$ = make_node(Node::Type::Dec, $1);
                                        $$->position.first = @1.begin.line; }
    | VarDec ASSIGN Exp             { $$ = make_node(Node::Type::Dec, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    ;


/* Expressions */

Exp
    : Exp ASSIGN Exp                { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp AND Exp                   { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp OR Exp                    { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp RELOP Exp                 { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp PLUS Exp                  { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp MINUS Exp                 { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp STAR Exp                  { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp DIV Exp                   { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | LP Exp RP                     { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | MINUS Exp                     { $$ = make_node(Node::Type::Exp, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | NOT Exp                       { $$ = make_node(Node::Type::Exp, $1, $2);
                                        $$->position.first = @1.begin.line; }
    | ID LP Args RP                 { $$ = make_node(Node::Type::Exp, $1, $2, $3, $4);
                                        $$->position.first = @1.begin.line; }
    | ID LP error RP                { /* error(@3, "Valid Exp expected."); */ }
    | ID LP RP                      { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp LB Exp RB                 { $$ = make_node(Node::Type::Exp, $1, $2, $3, $4);
                                        $$->position.first = @1.begin.line; }
    | Exp LB error RB               { /* error(@3, "Valid Exp expected."); */ }
    | Exp DOT ID                    { $$ = make_node(Node::Type::Exp, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | ID                            { $$ = make_node(Node::Type::Exp, $1);
                                        $$->position.first = @1.begin.line; }
    | INT                           { $$ = make_node(Node::Type::Exp, $1);
                                        $$->position.first = @1.begin.line; }
    | FLOAT                         { $$ = make_node(Node::Type::Exp, $1);
                                        $$->position.first = @1.begin.line; }
    ;

Args
    : Exp COMMA Args                { $$ = make_node(Node::Type::Args, $1, $2, $3);
                                        $$->position.first = @1.begin.line; }
    | Exp                           { $$ = make_node(Node::Type::Args, $1);
                                        $$->position.first = @1.begin.line; }
    ;

%%
void yy::parser::error(const parser::location_type &l, const std::string &m) {
    std::cerr << "Error type B at Line " << l.begin.line << ": " << m << std::endl;
}

void parse(std::istream &in, std::ostream &out) {
    yy::scanner scanner(in);
    yy::parser parser(scanner, out);
    parser.parse();
}

int main() {
    try {
        parse(std::cin, std::cout);
        if (ast_root) {
            std::cout << ast_root->to_string();
        }
    } catch (yy::parser::syntax_error &e) {
        std::cerr << e.what() << std::endl;
    }
    return 0;
}
