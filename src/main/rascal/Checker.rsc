module Checker

import Syntax;
import ParseTree;
extend analysis::typepal::TypePal;

// ═══════════════════════════════════════════════════════════════════════════════
// Definiciones de tipos para TypePal
// ═══════════════════════════════════════════════════════════════════════════════
data AType
    = intType()
    | boolType()
    | charType()
    | stringType()
    | spaceType(str name)
    | operatorType(str name)
    | unknownType()
    ;

str prettyAType(intType())          = "Int";
str prettyAType(boolType())         = "Bool";
str prettyAType(charType())         = "Char";
str prettyAType(stringType())       = "String";
str prettyAType(spaceType(name))    = name;
str prettyAType(operatorType(name)) = "operator <name>";
str prettyAType(unknownType())      = "unknown";

// Convierte un nombre de espacio al AType correspondiente
AType nameToAType(str name) {
    switch (name) {
        case "Int":    return intType();
        case "Bool":   return boolType();
        case "Char":   return charType();
        case "String": return stringType();
        default:       return spaceType(name);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Roles de identificadores
// ═══════════════════════════════════════════════════════════════════════════════
data IdRole
    = spaceId()
    | operatorId()
    | variableId()
    ;

// ═══════════════════════════════════════════════════════════════════════════════
// Configuracion de TypePal
// ═══════════════════════════════════════════════════════════════════════════════
TypePalConfig vlConfig() = tconfig();

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: Module (punto de entrada)
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (Module) `defmodule <ID name> <Import* imports> <Component* comps> end`, Collector c) {
    c.enterScope(current);
    // Tipos primitivos predefinidos (Int, Bool, Char, String)
    c.define("Int", spaceId(), current, defType(intType()));
    c.define("Bool", spaceId(), current, defType(boolType()));
    c.define("Char", spaceId(), current, defType(charType()));
    c.define("String", spaceId(), current, defType(stringType()));
    for (comp <- comps) {
        collect(comp, c);
    }
    c.leaveScope(current);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: Component (despacho a cada tipo)
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (Component) `<Space s>`, Collector c) {
    collect(s, c);
}

void collect(current: (Component) `<OperatorDef op>`, Collector c) {
    collect(op, c);
}

void collect(current: (Component) `<ExpressionDef e>`, Collector c) {
    collect(e, c);
}

void collect(current: (Component) `<RuleDef r>`, Collector c) {
    collect(r, c);
}

void collect(current: (Component) `<VariableDef v>`, Collector c) {
    collect(v, c);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: Space
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (Space) `defspace <ID name> <SpaceSub? sub> end`, Collector c) {
    str spaceName = "<name>";
    // No redefinir tipos primitivos (ya estan predefinidos)
    if (spaceName notin {"Int", "Bool", "Char", "String"}) {
        c.define(spaceName, spaceId(), name, defType(spaceType(spaceName)));
    }
    for (s <- sub) {
        collect(s, c);
    }
}

void collect(current: (SpaceSub) `\< <ID parentName>`, Collector c) {
    c.use(parentName, {spaceId()});
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: OperatorDef
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (OperatorDef) `defoperator <Name n> : <OperatorType t> <Attributes? attrs> end`, Collector c) {
    str opName = "<n>";
    c.define(opName, operatorId(), current, defType(operatorType(opName)));
    collect(t, c);
}

void collect(current: (OperatorType) `<ID first> <OperatorNext+ chain>`, Collector c) {
    c.use(first, {spaceId()});
    for (nx <- chain) {
        collect(nx, c);
    }
}

void collect(current: (OperatorNext) `-\> <ID nextId>`, Collector c) {
    c.use(nextId, {spaceId()});
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: VariableDef
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (VariableDef) `defvar <VariableList vars> end`, Collector c) {
    collect(vars, c);
}

void collect(current: (VariableList) `<{VariableDecl ","}+ decls>`, Collector c) {
    for (d <- decls) {
        collect(d, c);
    }
}

void collect(current: (VariableDecl) `<ID varName> : <ID varType>`, Collector c) {
    AType vtype = nameToAType("<varType>");
    c.define("<varName>", variableId(), varName, defType(vtype));
    c.use(varType, {spaceId()});
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: ExpressionDef y ExpressionBody
// Usamos "is" en vez de concrete syntax patterns para evitar ambiguedades
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (ExpressionDef) `defexpression <ExpressionBody body> end`, Collector c) {
    collect(body, c);
}

void collect(ExpressionBody current, Collector c) {
    if (current is quantified) {
        c.enterScope(current);
        c.define("<current.variable>", variableId(), current.variable, defType(unknownType()));
        c.use(current.domain, {spaceId()});
        collect(current.body, c);
        c.leaveScope(current);
    }
    else if (current is binary) {
        collect(current.left, c);
        collect(current.right, c);
    }
    else if (current is functionCall) {
        Name fn = current.func;
        if (fn is idName) {
            c.use(fn.id, {operatorId()});
        }
        collect(current.args, c);
    }
    else if (current is exprId) {
        collect(current.expr, c);
        c.use(current.id, {operatorId(), variableId()});
        collect(current.rest, c);
    }
    else if (current is exprOp) {
        collect(current.expr, c);
        collect(current.rest, c);
    }
    else if (current is simpleExpr) {
        collect(current.expr, c);
    }
}

// ExpressionList
void collect(ExpressionList current, Collector c) {
    for (e <- current.exprs) {
        collect(e, c);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: Expression
// ═══════════════════════════════════════════════════════════════════════════════
void collect(Expression current, Collector c) {
    if (current is nested) {
        collect(current.body, c);
    }
    else if (current is identifier) {
        c.use(current.id, {variableId(), operatorId(), spaceId()});
    }
    else if (current is intNumber) {
        c.fact(current, intType());
    }
    else if (current is floatNumber) {
        c.fact(current, intType());
    }
    else if (current is boolValue) {
        c.fact(current, boolType());
    }
    else if (current is charValue) {
        c.fact(current, charType());
    }
    else if (current is stringValue) {
        c.fact(current, stringType());
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recoleccion: RuleDef
// ═══════════════════════════════════════════════════════════════════════════════
void collect(current: (RuleDef) `defrule ( <RuleOperator left> ) -\> ( <RuleOperator right> ) end`, Collector c) {
    collect(left, c);
    collect(right, c);
}

void collect(RuleOperator current, Collector c) {
    Name nm = current.name;
    if (nm is idName) {
        c.use(nm.id, {operatorId()});
    }
    for (p <- current.params) {
        collect(p, c);
    }
}

void collect(Parameter current, Collector c) {
    if (current is nestedParam) {
        collect(current.op, c);
    }
    else if (current is idParam) {
        c.use(current.id, {variableId()});
    }
    // intParam: nada que verificar
}

// ═══════════════════════════════════════════════════════════════════════════════
// Punto de entrada para el type checking
// ═══════════════════════════════════════════════════════════════════════════════
public TModel typeCheck(Tree pt) {
    if (pt has top) pt = pt.top;
    return collectAndSolve(pt, config = vlConfig());
}
