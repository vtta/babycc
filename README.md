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

