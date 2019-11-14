CXX = clang++
CXXFLAGS = -std=c++17 -g -O0 -I/usr/local/opt/llvm/include/c++/v1 -I/usr/local/opt/flex/include -fsanitize=address
OUT = babycc
OBJ = scanner.o parser.o
SCANNER = scanner.l
PARSER = parser.y

$(OUT):
	flex scanner.l
	bison --graph --report=all parser.y
	$(CXX) $(CXXFLAGS) scanner.cxx parser.cxx -o $(OUT)

build: $(OUT)

run: build
	./$(OUT) < tests/3.c

clean:
	rm -f *.o *.out *.cxx *.hxx *.cc *.hh *.output *.dot $(OUT)

format:
	fd -a -e c -e h -e cc -e hh -e cpp -e cxx -e hpp -e hxx -x clang-format -style=file -i {}

automata: build
	cat parser.dot | dot -Tpdf | open -fa Preview 
