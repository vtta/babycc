# babycc

A toy parser which can handle a subset of C programming language.

## Prerequisite

- Bison 3.2 or newer (for the more friendly C++ API)
- Clang 6.0 or newer (for C++17 support)
- If you are using a Mac, you can simply install them using `brew install llvm bison` and then set the necessary `PATH` enviroment variable. 
- Optional
  - Clang-format
  - fd (a nice tool written in Rust, the language of the future! If you haven't heard about them, you should definitely check them out!)
  - Graphviz (for visualizing the viable prefix automata)

## How to use

Simply type `make run` in project root directory, the output of each test case would be put alongside the test source file, you can find them in `tests` folder. 

## Useful links

- [Bison with real C++](https://coldfix.eu/2015/05/16/bison-c++11/)

- [C11 lex specification](http://www.quut.com/c/ANSI-C-grammar-l-2011.html#lex_rule_for_comment)

- [C11 yacc grammar](http://www.quut.com/c/ANSI-C-grammar-y-2011.html)

- [A simple flex example](https://pandolia.net/tinyc/ch8_flex.html)

- [A simple bison example](https://pandolia.net/tinyc/ch13_bison.html)

  