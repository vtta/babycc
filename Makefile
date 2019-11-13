CXX = clang++
CXXFLAGS = -std=c++17 -g -O0 -I/usr/local/opt/llvm/include/c++/v1 -I/usr/local/opt/flex/include
OUT = babycc
OBJ = scanner.o parser.o
SCANNER = scanner.l
PARSER = parser.y

build: $(OUT)

run: $(OUT)
	./$(OUT) < tests/0.c

clean:
	rm -f *.o *.out *.cxx *.hxx *.cc *.hh *.output $(OUT)

format:
	fd -a -e c -e h -e cc -e hh -e cpp -e cxx -e hpp -e hxx -x clang-format -style=file -i {}

$(OUT): clean
	flex scanner.l
	bison parser.y
	$(CXX) $(CXXFLAGS) scanner.cxx parser.cxx -o $(OUT)
