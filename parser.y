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

%define api.value.type variant
%define api.token.prefix {T_}
%token                  END     0   "end of file"

%token <std::string>    STR
%token <int>            NUM

%type <int> E

%left '+' '-'
%left '*' '/'

%start S

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

S   :   S E '\n'        { out << "ans = " << $2 << std::endl; }
    |   %empty          { /* empty */ }
    ;

E   :   E '+' E         { $$ = $1 + $3; }
    |   E '-' E         { $$ = $1 - $3; }
    |   E '*' E         { $$ = $1 * $3; }
    |   E '/' E         { $$ = $1 / $3; }
    |   NUM             { $$ = $1; }
    |   '(' E ')'       { $$ = $2; }
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