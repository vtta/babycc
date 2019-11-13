%option     outfile="scanner.cxx"
%option header-file="scanner.hxx"

%option c++
%option 8bit warn nodefault
%option noyywrap

%{
    #include <stdexcept>
    #include "parser.hxx"
    #include "scanner.hpp"

    // utility macros to simplify the actions
    #define YIELD_TOKEN(tok, val, type)     yylval->build<type>(val); \
                                            return yy::parser::token::T_##tok;

    #define YY_USER_ACTION          yylloc->columns(yyleng);
%}

%%
%{
    // before matching any pattern, update the the current location
    yylloc->step();
%}

[[:digit:]]+                YIELD_TOKEN(NUM, std::atoi(yytext), int)
[-/+*()]                    return yytext[0];

\n                          { yylloc->lines(1); return yytext[0]; }
.                           { }

%%
yy::scanner::scanner(std::istream* in, std::ostream* out)
    : yyFlexLexer(in, out) { }

// Flex generates the code for `yy::scanner::lex` (see YY_DECL).

// This must be defined manually to prevent linker errors:
int yyFlexLexer::yylex() {
    throw std::logic_error(
        "The yylex() exists for technical reasons and must not be used.");
}
