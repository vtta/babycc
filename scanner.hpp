#ifndef __SCANNER_HPP__INCLUDED__
#define __SCANNER_HPP__INCLUDED__

#undef yyFlexLexer
#include <FlexLexer.h>

#include <utility>

#include "parser.hxx"

// Tell flex which function to define
#undef YY_DECL
#define YY_DECL                                             \
    int yy::scanner::lex(yy::parser::semantic_type *yylval, \
                         yy::parser::location_type *yylloc)

namespace yy {
class scanner : public yyFlexLexer {
public:
    scanner() = delete;

    explicit scanner(std::istream &in = std::cin, std::ostream &out = std::cout)
        : yyFlexLexer(&in, &out) {}

    int lex(parser::semantic_type *yylval, parser::location_type *yylloc);
};
}  // namespace yy

// utility function to append a list element to a std::vector
template <class C, class V>
C &&enlist(C &c, V &v) {
    c.push_back(std::move(v));
    return std::move(c);
}

#endif  // include-guard
