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

    void comment() {
        for (int c; (c = yyFlexLexer::yyinput()) != 0;)
            if (c == '*') {
                while ((c = yyFlexLexer::yyinput()) == '*')
                    ;
                if (c == '/') return;
                if (c == 0) break;
            }
        // std::ostringstream msg;
        // msg << "unterminated comment at row " << yylloc->begin.line
        //     << " column " << yylloc->begin.column;
        // yyFlexLexer::LexerError(msg.str());
        yyFlexLexer::LexerError("unterminated comment");
    }
};
}  // namespace yy

// utility function to append a list element to a std::vector
template <class C, class V>
C &&enlist(C &c, V &v) {
    c.push_back(std::move(v));
    return std::move(c);
}

#endif  // include-guard
