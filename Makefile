CXX = /usr/local/opt/llvm/bin/clang++
CXXFLAGS = -std=c++17 -g -O0 -I/usr/local/opt/llvm/include/c++/v1 -I/usr/local/opt/flex/include -fsanitize=address
OUT = babycc
OBJ = scanner.o parser.o
TESTDIR = tests
SCANNER = scanner.l
PARSER = parser.y

$(OUT):
	/usr/local/opt/flex/bin/flex scanner.l
	/usr/local/opt/bison/bin/bison --report=state --graph --report=all parser.y
	$(CXX) $(CXXFLAGS) scanner.cxx parser.cxx -o $(OUT)

build: $(OUT)

run: build
	rm -f $(TESTDIR)/*.output
	for file in $(TESTDIR)/*.c ; do cat $${file} | ./$(OUT) 2>&1 | tee $${file}.output ; done

clean:
	rm -rf *.o *.out *.cxx *.hxx *.cc *.hh *.output $(TESTDIR)/*.output *.dot *.dSYM $(OUT)

format:
	fd -a -e c -e h -e cc -e hh -e cpp -e cxx -e hpp -e hxx -x clang-format -style=file -i {}

automata: build
	cat parser.dot | dot -Tpdf | open -fa Preview 
