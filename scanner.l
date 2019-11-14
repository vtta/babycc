%option     outfile="scanner.cxx"
%option header-file="scanner.hxx"

%option c++
%option 8bit warn nodefault
%option noyywrap

%{
    #include <stdexcept>
    #include <memory>
    #include "parser.hxx"
    #include "scanner.hpp"

    // // utility macros to simplify the actions
    // #define YIELD_TOKEN(tok, val, type)     yylval->build<type>(val); \
    //                                         return yy::parser::token::T_##tok;
    #define YIELD_TOKEN(tok)                                              \
        yylval->build<std::shared_ptr<Node>>(                     \
            std::make_shared<Node>(yytext, yylloc->begin.line,    \
                                           yylloc->begin.column,  \
                                           Node::Type::tok)); \
        return yy::parser::token::T_##tok;

    #define YY_USER_ACTION yylloc->columns(yyleng);
%}

O           [0-7]
D           [0-9]
NZ          [1-9]
L           [a-zA-Z_]
A           [a-zA-Z_0-9]
H           [a-fA-F0-9]
HP          (0[xX])
E           ([Ee][+-]?{D}+)
P           ([Pp][+-]?{D}+)
FS          (f|F|l|L)
IS          (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))
CP          (u|U|L)
SP          (u8|u|U|L)
ES          (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS          [ \t\v\n\f]

TYPE        "int"|"float"

%%
%{
    // before matching any pattern, update the the current location
    yylloc->step();
%}

"/*"                        { comment(); }
"//".*                      { /* consume //-comment */ }

{HP}{H}+{IS}?               YIELD_TOKEN(INT)
{NZ}{D}*{IS}?               YIELD_TOKEN(INT)
"0"{O}*{IS}?                YIELD_TOKEN(INT)
{CP}?"'"([^'\\\n]|{ES})+"'" YIELD_TOKEN(INT)
{D}+{E}{FS}?                YIELD_TOKEN(FLOAT)
{D}*"."{D}+{E}?{FS}?        YIELD_TOKEN(FLOAT)
{D}+"."{E}?{FS}?            YIELD_TOKEN(FLOAT)
{HP}{H}+{P}{FS}?            YIELD_TOKEN(FLOAT)
{HP}{H}*"."{H}+{P}{FS}?     YIELD_TOKEN(FLOAT)
{HP}{H}+"."{P}{FS}?         YIELD_TOKEN(FLOAT)

"struct"                    YIELD_TOKEN(STRUCT)
"return"                    YIELD_TOKEN(RETURN)
"if"                        YIELD_TOKEN(IF)
"else"                      YIELD_TOKEN(ELSE)
"while"                     YIELD_TOKEN(WHILE)

{TYPE}                      YIELD_TOKEN(TYPE)
{L}{A}*                     YIELD_TOKEN(ID)

">"|"<"|">="|"<="|"=="|"!=" YIELD_TOKEN(RELOP)
";"                         YIELD_TOKEN(SEMI)
","                         YIELD_TOKEN(COMMA)
"="                         YIELD_TOKEN(ASSIGN)
"+"                         YIELD_TOKEN(PLUS)
"-"                         YIELD_TOKEN(MINUS)
"*"                         YIELD_TOKEN(STAR)
"/"                         YIELD_TOKEN(DIV)
"&&"                        YIELD_TOKEN(AND)
"||"                        YIELD_TOKEN(OR)
"."                         YIELD_TOKEN(DOT)
"!"                         YIELD_TOKEN(NOT)
"("                         YIELD_TOKEN(LP)
")"                         YIELD_TOKEN(RP)
"["                         YIELD_TOKEN(LB)
"]"                         YIELD_TOKEN(RB)
"{"                         YIELD_TOKEN(LC)
"}"                         YIELD_TOKEN(RC)
\n                          { yylloc->lines(1); }
[ \t\v\f]+                  { /* eat whitespace */ }
.                           { /* let bison handle unrecognized token */ }

%%
// Flex generates the code for `yy::scanner::lex` (see YY_DECL).
// This must be defined manually to prevent linker errors:
int yyFlexLexer::yylex() {
    throw std::logic_error(
        "yylex() exists for technical reasons and must not be used.");
}
