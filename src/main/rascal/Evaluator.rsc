module Evaluator

import AST;
import IO;
import String;
import List;

// ═══════════════════════════════════════════════════════════════════════════════
// Evaluar/imprimir un modulo VeriLang completo
// ═══════════════════════════════════════════════════════════════════════════════
public void evalModule(AModule m) {
    println("╔══════════════════════════════════════════════════════════════╗");
    println("║  Modulo: <m.name>");
    println("╚══════════════════════════════════════════════════════════════╝");
    println("");

    // Imports
    if (size(m.imports) > 0) {
        println("  Imports:");
        for (imp <- m.imports) {
            println("    - <imp.modName>");
        }
        println("");
    }

    // Recorrer componentes
    for (comp <- m.comps) {
        evalComponent(comp);
    }

    println("══════════════════════════════════════════════════════════════");
}

// ═══════════════════════════════════════════════════════════════════════════════
// Evaluar cada tipo de componente
// ═══════════════════════════════════════════════════════════════════════════════
void evalComponent(aSpace(s))      = evalSpace(s);
void evalComponent(aOperator(op))  = evalOperator(op);
void evalComponent(aExpression(e)) = evalExpressionDef(e);
void evalComponent(aRule(r))       = evalRule(r);
void evalComponent(aVariable(v))   = evalVarDef(v);

// ── Space ────────────────────────────────────────────────────────────────────
void evalSpace(aSpaceWithSub(name, aSubtype(parent))) {
    println("  [Espacio] <name> \< <parent>");
}

void evalSpace(aSpaceNoSub(name)) {
    println("  [Espacio] <name>");
}

// ── Operator ─────────────────────────────────────────────────────────────────
void evalOperator(aOperatorDef(name, aOpChain(first, chain), attrs)) {
    str typeChain = first;
    for (t <- chain) {
        typeChain += " -\> <t>";
    }

    str attrsStr = "";
    if (size(attrs) > 0) {
        list[str] attrParts = [];
        for (a <- attrs) {
            switch (a) {
                case aAttr(key, aIntVal(n)):   attrParts += "<key>: <n>";
                case aAttr(key, aFloatVal(f)): attrParts += "<key>: <f>";
                case aAttr(key, aIdVal(id)):   attrParts += "<key>: <id>";
                case aAttr(key, aOpVal(op)):   attrParts += "<key>: <op>";
                case aAttrNoVal(key):          attrParts += key;
            }
        }
        attrsStr = " [<intercalate(", ", attrParts)>]";
    }

    println("  [Operador] <name> : <typeChain><attrsStr>");
}

// ── Variable ─────────────────────────────────────────────────────────────────
void evalVarDef(aVariableDef(decls)) {
    list[str] parts = [];
    for (aVarDecl(name, vtype) <- decls) {
        parts += "<name> : <vtype>";
    }
    println("  [Variables] <intercalate(", ", parts)>");
}

// ── Rule ─────────────────────────────────────────────────────────────────────
void evalRule(aRuleDef(left, right)) {
    println("  [Regla] (<ppRuleOp(left)>) -\> (<ppRuleOp(right)>)");
}

str ppRuleOp(aRuleOp(name, params)) {
    str result = name;
    for (p <- params) {
        result += " <ppParam(p)>";
    }
    return result;
}

str ppParam(aIdParam(id))         = id;
str ppParam(aIntParam(n))         = "<n>";
str ppParam(aNestedParam(op))     = "(<ppRuleOp(op)>)";

// ── Expression ───────────────────────────────────────────────────────────────
void evalExpressionDef(aExpressionDef(body)) {
    println("  [Expresion] <ppExprBody(body)>");
}

str ppExprBody(aQuantified(q, var, dom, body))
    = "(<q> <var> in <dom> . <ppExprBody(body)>)";
str ppExprBody(aBinary(left, op, right))
    = "(<ppExpr(left)> <op> <ppExpr(right)>)";
str ppExprBody(aFunctionCall(func, args))
    = "(<func> <intercalate(" ", [ppExpr(a) | a <- args])>)";
str ppExprBody(aExprId(expr, id, rest))
    = "<ppExpr(expr)> <id> <ppExprBody(rest)>";
str ppExprBody(aExprOp(expr, op, rest))
    = "<ppExpr(expr)> <op> <ppExprBody(rest)>";
str ppExprBody(aSimpleExpr(expr))
    = ppExpr(expr);

str ppExpr(aNested(body))      = "(<ppExprBody(body)>)";
str ppExpr(aIdentifier(id))    = id;
str ppExpr(aIntNumber(n))      = "<n>";
str ppExpr(aFloatNumber(f))    = "<f>";
str ppExpr(aBoolLiteral(b))    = b ? "true" : "false";
str ppExpr(aCharLiteral(c))    = c;
str ppExpr(aStringLiteral(s))  = s;
