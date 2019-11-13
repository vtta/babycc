%output  "parser.cxx"
%defines "parser.hxx"

/* C++ parser interface */
%skeleton "lalr1.cc"

/* require bison version */
%require  "3.0"

/* add parser members */
%parse-param  {yy::scanner* scanner} {std::stringstream* po}

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
    #include <stdexcept>
    #include <string>
    #include <sstream>

    #include "ast.hpp"
    #include "location.hh"

    namespace yy {
        class scanner;
    };

    void parse(const std::vector<std::string>&, std::stringstream*);
}

/* inserted near top of source file */
%code {
    #include <iostream>     // cerr, endl
    #include <utility>      // move
    #include <string>
    #include <sstream>

    #include "scanner.hpp"

    using std::move;

    #undef yylex
    #define yylex scanner->lex

    // utility function to append a list element to a std::vector
    template <class T, class V>
    T&& enlist(T& t, V& v)
    {
        t.push_back(move(v));
        return move(t);
    }
}

%%

S   :   S E '\n'        { *po << "ans = " << $2 << std::endl; }
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
void yy::parser::error(const parser::location_type& l, const std::string& m)
{
    throw yy::parser::syntax_error(l, m);
}

// Example how to use the parser to parse a vector of lines:
void parse(std::stringstream *out)
{
        yy::scanner scanner(&std::cin);
        yy::parser parser(&scanner, out);
        try {
            int result = parser.parse();
            if (result != 0) {
                // Not sure if this can even happen
                throw std::runtime_error("Unknown parsing error");
            }
        }
        catch (yy::parser::syntax_error& e) {
            // improve error messages by adding location information:
            int col = e.location.begin.column;
            int len = 1 + e.location.end.column - col;
            // TODO: The reported location is not entirely satisfying. Any
            // chances for improvement?
            std::ostringstream msg;
            msg << e.what() << "\n"
                << " col " << col << ":\n\n"
                << "    " << std::string(col-1, ' ') << std::string(len, '^');
            throw yy::parser::syntax_error(e.location, msg.str());
        }
}

int main() {
    std::stringstream str;
    parse(&str);
    std::cout << str.str() << std::endl;
    return 0;
}
