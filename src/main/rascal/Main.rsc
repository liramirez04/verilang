module Main

import Syntax;
import AST;
import Parser;
import Checker;
import Evaluator;
import ParseTree;
import IO;
import Set;
import String;



// Construye el AST (AModule) a partir del arbol de parseo concreto
AModule buildAST(loc source) {
    Tree t = parseFile(source);
    return buildModule(t.top);
}

// Construye el AST directamente desde un String
AModule buildASTFromString(str src) {
    Tree t = parseString(src);
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
    = aSpaceWithSub("<name>", buildSpaceSub(sub));
ASpace buildSpace((Space)`defspace <ID name> end`)
    = aSpaceNoSub("<name>");

ASpaceSub buildSpaceSub((SpaceSub)`\< <ID parentName>`)
    = aSubtype("<parentName>");

// ── OperatorDef ───────────────────────────────────────────────────────────────
AOperatorDef buildOperatorDef((OperatorDef)`defoperator <Name n> : <OperatorType t> <Attributes attrs> end`)
    = aOperatorDef(buildName(n), buildOperatorType(t), buildAttributes(attrs));
AOperatorDef buildOperatorDef((OperatorDef)`defoperator <Name n> : <OperatorType t> end`)
    = aOperatorDef(buildName(n), buildOperatorType(t), []);

str buildNextId((OperatorNext)`-\> <ID id>`) = "<id>";

AOperatorType buildOperatorType((OperatorType)`<ID first> <OperatorNext+ chain>`)
    = aOpChain("<first>", [ buildNextId(nx) | nx <- chain ]);

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
    if (t is quantified) {
        return aQuantified("<t.quantifier>", "<t.variable>", "<t.domain>", buildExpressionBody(t.body));
    }
    else if (t is functionCall) {
        return aFunctionCall(buildName(t.func), buildExpressionList(t.args));
    }
    else if (t is binary) {
        return aBinary(buildExpression(t.left), "<t.op>", buildExpression(t.right));
    }
    else if (t is exprId) {
        return aExprId(buildExpression(t.expr), "<t.id>", buildExpressionBody(t.rest));
    }
    else if (t is exprOp) {
        return aExprOp(buildExpression(t.expr), "<t.op>", buildExpressionBody(t.rest));
    }
    else if (t is simpleExpr) {
        return aSimpleExpr(buildExpression(t.expr));
    }
    throw "Unexpected ExpressionBody: <t>";
}

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
AExpression buildExpression((Expression)`<BoolLiteral b>`)
    = aBoolLiteral("<b>" == "true");
AExpression buildExpression((Expression)`<CharLiteral c>`)
    = aCharLiteral("<c>");
AExpression buildExpression((Expression)`<StringLiteral s>`)
    = aStringLiteral("<s>");

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


void runFile(loc source) {
    println("==================================================");
    println("  Procesando: <source>");
    println("==================================================");

    // 1. Parsear
    println("\n[1] Parseando archivo...");
    Tree pt = parseFile(source);
    println("    -- Parseo exitoso.");

    // 2. Construir AST
    println("[2] Construyendo AST...");
    AModule ast = buildModule(pt.top);
    println("    -- AST construido.");

    // 3. Type check con TypePal
    println("[3] Verificando tipos con TypePal...");
    TModel tm = typeCheck(pt);
    
    if (size(tm.messages) > 0) {
        println("    -- Se encontraron <size(tm.messages)> mensaje(s):");
        for (msg <- tm.messages) {
            println("       ! <msg>");
        }
    } else {
        println("    -- Sin errores de tipo.");
    }

    // 4. Evaluar/imprimir resultado
    println("[4] Resultado del programa:\n");
    evalModule(ast);
    println("");
}

// ── Entry point ───────────────────────────────────────────────────────────────
int main(int testArgument=0) {
    println("╔══════════════════════════════════════════════════════════════╗");
    println("║           VeriLang - Proyecto 3: Sistema de Tipos           ║");
    println("╚══════════════════════════════════════════════════════════════╝\n");

    list[loc] tests = [
        |project://verilang/test/set.vl|,
        |project://verilang/test/setTheory.vl|,
        |project://verilang/test/dashTest.vl|,
        |project://verilang/test/existence.vl|,
        |project://verilang/test/hard4.vl|,
        |project://verilang/test/typeError.vl|,
        |project://verilang/test/edgeEmpty.vl|,
        |project://verilang/test/edgeLiterals.vl|,
        |project://verilang/test/edgeMultiError.vl|,
        |project://verilang/test/edgePrimitives.vl|,
        |project://verilang/test/edgeNested.vl|
    ];

    for (t <- tests) {
        try {
            runFile(t);
        } catch ParseError(loc l): {
            println("  ERROR DE PARSEO en <l>");
        } catch e: {
            println("  ERROR: <e>");
        }
    }

    println("\n==================================================");
    println("  Todas las pruebas finalizaron.");
    println("==================================================");
    return testArgument;
}
