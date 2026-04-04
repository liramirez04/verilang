module Syntax

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];
lexical WhitespaceAndComment = [\ \t\n\r] | @category="Comment" "#" ![\n]* $;

start syntax Module
    = moduleDef: 'defmodule' ID moduleName Import* imports Component* comps 'end';

syntax Import
    = importDef: 'using' ID importedModule;

syntax Component
    = space:         Space
    | operatorDef:   OperatorDef
    | expressionDef: ExpressionDef
    | ruleDef:       RuleDef
    | variableDef:   VariableDef;

syntax Space
    = spaceDef: 'defspace' ID name SpaceSub? sub 'end';

syntax SpaceSub
    = subtype: '\<' ID parentName;

syntax OperatorDef
    = operatorDef: 'defoperator' Name name ':' OperatorType operatorType Attributes? attrs 'end';

syntax OperatorType
    = opChain: ID firstType OperatorNext* chain;

syntax OperatorNext
    = nextType: '-\>' ID nextId;

syntax Attributes
    = attrs: '[' Attribute+ attrList ']';

syntax Attribute
    = attr: ID key AttributeValue? value;

syntax AttributeValue
    = intValue:   ':' IntLiteral n
    | floatValue: ':' FloatLiteral f
    | idValue:    ':' ID id
    | opValue:    ':' Operator op;

syntax ExpressionDef
    = expressionDef: 'defexpression' ExpressionBody body 'end';

syntax ExpressionBody
    = quantified:   '(' Quantifier quantifier ID variable 'in' ID domain '.' ExpressionBody body ')'
    | binary:       '(' Expression left Operator op Expression right ')'
    | functionCall: '(' Name func ExpressionList args ')'
    > exprId:       Expression expr ID id ExpressionBody rest
    > exprOp:       Expression expr Operator op ExpressionBody rest
    > simpleExpr:   Expression expr;

syntax ExpressionList
    = exprList: Expression* exprs;

syntax Expression
    = nested:      '(' ExpressionBody body ')'
    | identifier:  ID id
    | intNumber:   IntLiteral n
    | floatNumber: FloatLiteral f;

syntax Quantifier
    = forall: 'forall'
    | exists: 'exists';

syntax RuleDef
    = ruleDef: 'defrule' '(' RuleOperator left ')' '-\>' '(' RuleOperator right ')' 'end';

syntax RuleOperator
    = ruleOp: Name name Parameter* params;

syntax Parameter
    = nestedParam: '(' RuleOperator op ')'
    | idParam:     ID id
    | intParam:    IntLiteral n;

syntax VariableDef
    = variableDef: 'defvar' VariableList vars 'end';

syntax VariableList
    = varList: {VariableDecl ","}+ decls;

syntax VariableDecl
    = varDecl: ID varName ':' ID varType;

syntax Name
    = opName: Operator op
    | idName: ID id;

syntax Operator
    = mult:    '*'
    | div:     '/'
    | minus:   '-'
    | plus:    '+'
    | power:   '**'
    | modOp:   '%'
    | lt:      '\<'
    | gt:      '\>'
    | lte:     '\<='
    | gte:     '\>='
    | neq:     '\<\>'
    | eq:      '='
    | and:     'and' !>> [a-zA-Z0-9\-]
    | or:      'or'  !>> [a-zA-Z0-9\-]
    | neg:     'neg' !>> [a-zA-Z0-9\-]
    | implies: '-\>'
    | inOp:    'in'  !>> [a-zA-Z0-9\-]
    | arrow:   '=\>'
    | equiv:   '≡'
    | emptySet:'∅';

lexical FloatLiteral = [0-9]+ "." [0-9]+;
lexical IntLiteral   = [0-9]+ !>> [0-9.];

lexical ID = ([a-zA-Z][a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-]) \ Reserved;

keyword Reserved
    = "defmodule"
    | "using"
    | "defspace"
    | "defoperator"
    | "defexpression"
    | "defrule"
    | "defvar"
    | "forall"
    | "exists"
    | "end"
    | "in"
    | "and"
    | "or"
    | "neg"
    | "if"
    | "cond"
    | "for";
