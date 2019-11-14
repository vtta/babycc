#pragma once

#include <iostream>
#include <memory>
#include <sstream>
#include <vector>

#include "magic_enum.hpp"

constexpr auto INDENT_WIDTH = 4;

enum class NonTerminalType {
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
    T_Args
};

enum class TerminalType {
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
    std::string label;
    std::pair<int, int> position;
    Node(std::string const &label, int line_pos, int char_pos)
        : label(label), position(line_pos, char_pos) {}
    virtual ~Node() = default;
    virtual std::string to_string(int indent = 0) const = 0;
};

class TerminalNode : public Node {
public:
    using Type = TerminalType;
    Type type;
    TerminalNode(std::string const &label, int line_pos, int char_pos,
                 Type type)
        : type(type), Node(label, line_pos, char_pos) {}
    ~TerminalNode() = default;
    std::string to_string(int indent = 0) const {
        std::stringstream buf;
        buf.str(std::string(' ', indent));
        buf << magic_enum::enum_name(type) << ' ' << label << std::endl;
        return buf.str();
    }
};

class NonTerminalNode : public Node {
public:
    using Type = NonTerminalType;
    Type type;
    std::vector<std::shared_ptr<Node>> children;
    NonTerminalNode(std::string const &label, int line_pos, int char_pos,
                    Type type)
        : type(type), Node(label, line_pos, char_pos) {}
    ~NonTerminalNode() = default;
    std::string to_string(int indent = 0) const {
        std::stringstream buf;
        buf.str(std::string(' ', indent));
        buf << magic_enum::enum_name(type) << ' ' << label << std::endl;
        for (auto const &i : children) {
            buf << i->to_string(indent + INDENT_WIDTH);
        }
        return buf.str();
    }
};

template <class H>
inline auto add_children(std::shared_ptr<NonTerminalNode> node, H first) {
    node->children.emplace_back(first);
    return node;
}
template <class H, class... T>
inline auto add_children(std::shared_ptr<NonTerminalNode> node, H first,
                         T... children) {
    node->children.emplace_back(first);
    return add_children(node, children...);
}

inline auto new_non_terminal(NonTerminalNode::Type type,
                             std::shared_ptr<Node> first_child = nullptr) {
    if (first_child == nullptr) {
        return std::make_shared<NonTerminalNode>("", 0, 0, type);
    }
    return std::make_shared<NonTerminalNode>(
        "", first_child->position.first, first_child->position.second, type);
}
inline auto make_non_terminal(NonTerminalNode::Type type) {
    return new_non_terminal(type, nullptr);
}
template <class H>
inline auto make_non_terminal(NonTerminalNode::Type type, H first) {
    return new_non_terminal(type, first);
}
template <class H, class... T>
inline auto make_non_terminal(NonTerminalNode::Type type, H first,
                              T... children) {
    return add_children(new_non_terminal(type, first), children...);
}