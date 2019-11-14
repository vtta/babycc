#pragma once

#include <iostream>
#include <memory>
#include <sstream>
#include <vector>

#include "magic_enum.hpp"

enum class SymbolType {
    Program,
    ExtDefList,
    ExtDef,
    ExtDecList,
    Specifier,
    StructSpecifier,
    OptTag,
    Tag,
    VarDec,
    FunDec,
    VarList,
    ParamDec,
    CompSt,
    StmtList,
    Stmt,
    DefList,
    Def,
    DecList,
    Dec,
    Exp,
    Args,
    INT,
    FLOAT,
    ID,
    SEMI,
    COMMA,
    ASSIGN,
    RELOP,
    PLUS,
    MINUS,
    STAR,
    DIV,
    AND,
    OR,
    DOT,
    NOT,
    TYPE,
    LP,
    RP,
    LB,
    RB,
    LC,
    RC,
    STRUCT,
    RETURN,
    IF,
    ELSE,
    WHILE
};

class Node {
public:
    using Type = SymbolType;
    std::string label;
    Type type;
    std::pair<int, int> position;
    // children is stored in reversed order
    std::vector<std::shared_ptr<Node>> children;
    Node(std::string const &label, int line_pos, int char_pos, Type type)
        : label(label), type(type), position(line_pos, char_pos) {}
    ~Node() = default;
    std::string to_string() const { return to_string("", true, true); }

protected:
    std::string to_string(std::string prefix, bool last, bool root) const {
        std::ostringstream buf;
        buf << prefix;
        if (!root) {
            buf << (last ? "└──" : "├──");
        }
        buf << magic_enum::enum_name(type) << ' ' << label << std::endl;
        for (auto i = children.rbegin(); i != children.rend(); ++i) {
            auto new_prefix = prefix;
            if (!root) {
                new_prefix += (last ? "    " : "│   ");
            }
            if (i + 1 != children.rend()) {
                buf << (*i)->to_string(new_prefix, false, false);
            } else {
                buf << (*i)->to_string(new_prefix, true, false);
            }
        }
        return buf.str();
    }
};

inline auto new_node(Node::Type type,
                     std::shared_ptr<Node> firschild = nullptr) {
    if (firschild == nullptr) {
        return std::make_shared<Node>("", 0, 0, type);
    }
    return std::make_shared<Node>("", firschild->position.first,
                                  firschild->position.second, type);
}

inline auto make_node(Node::Type type) { return new_node(type, nullptr); }
template <class H>
inline auto make_node(Node::Type type, H first) {
    auto node = new_node(type, first);
    node->children.emplace_back(first);
    return node;
}

template <class H, class... T>
inline auto make_node(Node::Type type, H first, T... children) {
    auto node = make_node(type, children...);
    node->children.emplace_back(first);
    return node;
}
