module Main

import Syntax;
import AST;
import ParseTree;
import IO;
import Set;

// Recibe la ruta de un archivo .txt y retorna el arbol de parseo concreto
Tree parseFile(loc source) {
    return parse(#start[Module], source);
}

// Recibe un string con codigo VeriLang y retorna el arbol de parseo
Tree parseString(str src) {
    return parse(#start[Module], src);
}

// Construye el AST (AModule) a partir del arbol de parseo concreto
AModule buildAST(loc source) {
    Tree t = parseFile(source);
    return buildModule(t.top);
}

// ── Module ────────────────────────────────────────────────────────────────────
AModule buildModule((Module)`defmodule <ID name> <Import* imports> <Component* comps> end`) {
    return aModule(
        "<name>",
        [ buildImport(i) | i <- imports ],
        [ buildComponent(c) | c <- comps ]
    );
}

// ── Import ────────────────────────────────────────────────────────────────────
AImport buildImport((Import)`using <ID modName>`) {
    return aImport("<modName>");
}

// ── Component ─────────────────────────────────────────────────────────────────
AComponent buildComponent((Component)`<Space s>`)         = aSpace(buildSpace(s));
AComponent buildComponent((Component)`<OperatorDef op>`)  = aOperator(buildOperatorDef(op));
AComponent buildComponent((Component)`<ExpressionDef e>`) = aExpression(buildExpressionDef(e));
AComponent buildComponent((Component)`<RuleDef r>`)       = aRule(buildRuleDef(r));
AComponent buildComponent((Component)`<VariableDef v>`)   = aVariable(buildVariableDef(v));

// ── Space ─────────────────────────────────────────────────────────────────────
ASpace buildSpace((Space)`defspace <ID name> <SpaceSub sub> end`)
    = aSpace("<name>", buildSpaceSub(sub));
ASpace buildSpace((Space)`defspace <ID name> end`)
    = aSpaceNoSub("<name>");

ASpaceSub buildSpaceSub((SpaceSub)`\< <ID parentName>`)
    = aSubtype("<parentName>");

// ── OperatorDef ───────────────────────────────────────────────────────────────
AOperatorDef buildOperatorDef((OperatorDef)`defoperator <Name n> : <OperatorType t> <Attributes attrs> end`)
    = aOperatorDef(buildName(n), buildOperatorType(t), buildAttributes(attrs));
AOperatorDef buildOperatorDef((OperatorDef)`defoperator <Name n> : <OperatorType t> end`)
    = aOperatorDef(buildName(n), buildOperatorType(t), []);

AOperatorType buildOperatorType((OperatorType)`<ID first> <OperatorNext* chain>`)
    = aOpChain("<first>", [ "<nx.nextId>" | nx <- chain ]);

str buildName((Name)`<Operator op>`) = "<op>";
str buildName((Name)`<ID id>`)       = "<id>";

list[AAttribute] buildAttributes((Attributes)`[ <Attribute+ attrs> ]`)
    = [ buildAttribute(a) | a <- attrs ];

AAttribute buildAttribute((Attribute)`<ID key> <AttributeValue val>`)
    = aAttr("<key>", buildAttributeValue(val));
AAttribute buildAttribute((Attribute)`<ID key>`)
    = aAttrNoVal("<key>");

AAttributeValue buildAttributeValue((AttributeValue)`: <IntLiteral n>`)
    = aIntVal(toInt("<n>"));
AAttributeValue buildAttributeValue((AttributeValue)`: <FloatLiteral f>`)
    = aFloatVal(toReal("<f>"));
AAttributeValue buildAttributeValue((AttributeValue)`: <ID id>`)
    = aIdVal("<id>");
AAttributeValue buildAttributeValue((AttributeValue)`: <Operator op>`)
    = aOpVal("<op>");

// ── ExpressionDef ─────────────────────────────────────────────────────────────
AExpressionDef buildExpressionDef((ExpressionDef)`defexpression <ExpressionBody body> end`)
    = aExpressionDef(buildExpressionBody(body));

AExpressionBody buildExpressionBody(Tree t) {
    if (amb(set[Tree] alts) := t) {
        return buildExpressionBody(getOneFrom(alts));
    }
    fail;
}

AExpressionBody buildExpressionBody(
    (ExpressionBody)`( <Quantifier q> <ID var> in <ID dom> . <ExpressionBody body> )`)
    = aQuantified("<q>", "<var>", "<dom>", buildExpressionBody(body));
AExpressionBody buildExpressionBody(
    (ExpressionBody)`( <Expression left> <Operator op> <Expression right> )`)
    = aBinary(buildExpression(left), "<op>", buildExpression(right));
AExpressionBody buildExpressionBody(
    (ExpressionBody)`( <Name func> <ExpressionList args> )`)
    = aFunctionCall(buildName(func), buildExpressionList(args));
AExpressionBody buildExpressionBody(
    (ExpressionBody)`<Expression expr> <ID id> <ExpressionBody rest>`)
    = aExprId(buildExpression(expr), "<id>", buildExpressionBody(rest));
AExpressionBody buildExpressionBody(
    (ExpressionBody)`<Expression expr> <Operator op> <ExpressionBody rest>`)
    = aExprOp(buildExpression(expr), "<op>", buildExpressionBody(rest));
AExpressionBody buildExpressionBody(
    (ExpressionBody)`<Expression expr>`)
    = aSimpleExpr(buildExpression(expr));

list[AExpression] buildExpressionList((ExpressionList)`<Expression* exprs>`)
    = [ buildExpression(e) | e <- exprs ];

AExpression buildExpression((Expression)`( <ExpressionBody body> )`)
    = aNested(buildExpressionBody(body));
AExpression buildExpression((Expression)`<ID id>`)
    = aIdentifier("<id>");
AExpression buildExpression((Expression)`<IntLiteral n>`)
    = aIntNumber(toInt("<n>"));
AExpression buildExpression((Expression)`<FloatLiteral f>`)
    = aFloatNumber(toReal("<f>"));

// ── RuleDef ───────────────────────────────────────────────────────────────────
ARuleDef buildRuleDef(
    (RuleDef)`defrule ( <RuleOperator left> ) -\> ( <RuleOperator right> ) end`)
    = aRuleDef(buildRuleOperator(left), buildRuleOperator(right));

ARuleOperator buildRuleOperator((RuleOperator)`<Name name> <Parameter* params>`)
    = aRuleOp(buildName(name), [ buildParameter(p) | p <- params ]);

AParameter buildParameter((Parameter)`( <RuleOperator op> )`) = aNestedParam(buildRuleOperator(op));
AParameter buildParameter((Parameter)`<ID id>`)               = aIdParam("<id>");
AParameter buildParameter((Parameter)`<IntLiteral n>`)        = aIntParam(toInt("<n>"));

// ── VariableDef ───────────────────────────────────────────────────────────────
AVariableDef buildVariableDef((VariableDef)`defvar <VariableList vars> end`)
    = aVariableDef(buildVariableList(vars));

list[AVarDecl] buildVariableList((VariableList)`<{VariableDecl ","}+ decls>`)
    = [ buildVarDecl(d) | d <- decls ];

AVarDecl buildVarDecl((VariableDecl)`<ID name> : <ID varType>`)
    = aVarDecl("<name>", "<varType>");

// ── Entry point ───────────────────────────────────────────────────────────────
int main(int testArgument=0) {
    println("VeriLang parser ready.");
    println("Use parseFile(|file:///path/to/program.txt|) to parse a file.");
    println("Use buildAST(|file:///path/to/program.txt|) to get the AST.");
    return testArgument;
}
