#pragma once

#include <iostream>
#include <memory>
#include <sstream>
#include <vector>

#include "magic_enum.hpp"

enum class SymbolType {
    T_Program,
    T_ExtDefList,
    T_ExtDef,
    T_ExtDecList,
    T_Specifier,
    T_StructSpecifier,
    T_OptTag,
    T_Tag,
    T_VarDec,
    T_FunDec,
    T_VarList,
    T_ParamDec,
    T_CompSt,
    T_StmtList,
    T_Stmt,
    T_DefList,
    T_Def,
    T_DecList,
    T_Dec,
    T_Exp,
    T_Args,
    T_INT,
    T_FLOAT,
    T_ID,
    T_SEMI,
    T_COMMA,
    T_ASSIGN,
    T_RELOP,
    T_PLUS,
    T_MINUS,
    T_STAR,
    T_DIV,
    T_AND,
    T_OR,
    T_DOT,
    T_NOT,
    T_TYPE,
    T_LP,
    T_RP,
    T_LB,
    T_RB,
    T_LC,
    T_RC,
    T_STRUCT,
    T_RETURN,
    T_IF,
    T_ELSE,
    T_WHILE
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
    std::string to_string(std::string prefix = "", bool last = true,
                          bool root = true) const {
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

template <class H>
inline auto add_children(std::shared_ptr<Node> node, H first) {
    node->children.emplace_back(first);
    return node;
}
template <class H, class... T>
inline auto add_children(std::shared_ptr<Node> node, H first, T... children) {
    node->children.emplace_back(first);
    return add_children(node, children...);
}

inline auto new_node(Node::Type type,
                     std::shared_ptr<Node> first_child = nullptr) {
    if (first_child == nullptr) {
        return std::make_shared<Node>("", 0, 0, type);
    }
    return std::make_shared<Node>("", first_child->position.first,
                                  first_child->position.second, type);
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
