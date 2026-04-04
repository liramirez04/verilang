module AST

// ── Module ────────────────────────────────────────────────────────────────────
data AModule
    = aModule(str name, list[AImport] imports, list[AComponent] comps);

// ── Import ────────────────────────────────────────────────────────────────────
data AImport
    = aImport(str modName);

// ── Component ─────────────────────────────────────────────────────────────────
data AComponent
    = aSpace(ASpace s)
    | aOperator(AOperatorDef op)
    | aExpression(AExpressionDef e)
    | aRule(ARuleDef r)
    | aVariable(AVariableDef v);

// ── Space ─────────────────────────────────────────────────────────────────────
data ASpace
    = aSpaceWithSub(str name, ASpaceSub sub)
    | aSpaceNoSub(str name);

data ASpaceSub
    = aSubtype(str parentName);

// ── Operator definition ───────────────────────────────────────────────────────
data AOperatorDef
    = aOperatorDef(str name, AOperatorType opType, list[AAttribute] attrs);

data AOperatorType
    = aOpChain(str firstType, list[str] chain);

data AAttribute
    = aAttr(str key, AAttributeValue val)
    | aAttrNoVal(str key);

data AAttributeValue
    = aIntVal(int n)
    | aFloatVal(real f)
    | aIdVal(str id)
    | aOpVal(str op);

// ── Expression definition ─────────────────────────────────────────────────────
data AExpressionDef
    = aExpressionDef(AExpressionBody body);

data AExpressionBody
    = aQuantified(str quantifier, str variable, str domain, AExpressionBody body)
    | aBinary(AExpression left, str op, AExpression right)
    | aFunctionCall(str func, list[AExpression] args)
    | aExprId(AExpression expr, str id, AExpressionBody rest)
    | aExprOp(AExpression expr, str op, AExpressionBody rest)
    | aSimpleExpr(AExpression expr);

data AExpression
    = aNested(AExpressionBody body)
    | aIdentifier(str id)
    | aIntNumber(int n)
    | aFloatNumber(real f);

// ── Rule definition ───────────────────────────────────────────────────────────
data ARuleDef
    = aRuleDef(ARuleOperator left, ARuleOperator right);

data ARuleOperator
    = aRuleOp(str name, list[AParameter] params);

data AParameter
    = aNestedParam(ARuleOperator op)
    | aIdParam(str id)
    | aIntParam(int n);

// ── Variable definition ───────────────────────────────────────────────────────
data AVariableDef
    = aVariableDef(list[AVarDecl] decls);

data AVarDecl
    = aVarDecl(str varName, str varType);
