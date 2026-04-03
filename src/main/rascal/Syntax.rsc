module Syntax

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];
lexical WhitespaceAndComment = [\ \t\n\r] | @category="Comment" "#" ![\n]* $;

start syntax Module
    = moduleDef: 'defmodule' ID moduleName Import* Component* 'end';

syntax Import
    = importDef: 'using' ID importedModule ;

syntax Component
    = space: Space 
    | operator: Operator 
    | expression: Expression 
    | rule: Rule 
    | variable: Variable ;

syntax Space
    = spaceDef: 'defspace' ID name SpaceSub? parent 'end' ;

syntax SpaceSub
    = subtype: '<' ID parentName ;

syntax Operator
    = operatorDef: 'defoperator' Name name ':' OperatorType operatorType Attributes? attrs 'end' ;

syntax OperatorType
    = opChain: ID firstType OperatorNext* ;

syntax OperatorNext
    = nextType: '->' ID nextType ;

syntax Attributes
    = attrs: '[' Attribute+ attrList ']' ;

syntax Attribute
    = attr: ID key AttributeValue? value ;

syntax AttributeValue
    = numValue: ':' Number | idValue: ':' ID | opValue: ':' Operator ;

syntax ExpressionDef
    = expressionDef: 'defexpression' ExpressionBody body 'end' ;

syntax ExpressionBody
    = quantified: '(' Quantifier ID variable 'in' ID domain '.' ExpressionBody body ')'
    | binary: '(' ExpressionBody left Operator op ExpressionBody right ')'
    | functionCall: '(' Name func ExpressionList args ')'
    | exprId: Expression ID ExpressionBody
    | exprOp: Expression Operator ExpressionBody
    | simpleExpr: Expression
    ;

syntax ExpressionList
    = exprList: Expression* ;

syntax Expression
    = nested: '(' ExpressionBody ')'
    | namedExpr: Name ExpressionList
    | identifier: ID
    | number: Number
    ;

syntax Quantifier
    = forall: 'forall' | exists: 'exists' ;

syntax RuleDef
    = ruleDef: 'defrule' '(' RuleOperator left ')' '->' '(' RuleOperator right ')' 'end' ;

syntax RuleOperator
    = ruleOp: Name name Parameter* ;

syntax Parameter
    = nestedParam: '(' RuleOperator ')'
    | idParam: ID
    | numParam: Number
    ;

syntax VariableDef
    = variableDef: 'defvar' VariableList vars 'end' ;

syntax VariableList
    = vars: VariableDecl (',' VariableDecl)* ;

syntax VariableDecl
    = varDecl: ID varName ':' ID varType ;

syntax Name
    = opName: Operator | idName: ID ;

syntax Operator
    = mult: '*'
    | div: '/'
    | minus: '-'
    | plus: '+'
    | power: '**'
    | mod: '%'
    | lt: '<'
    | gt: '>'
    | lte: '<='
    | gte: '>='
    | neq: '<>'
    | eq: '='
    | and: 'and'
    | or: 'or'
    | neg: 'neg'
    | implies: '->'
    | inOp: 'in'
    | equiv: '≡'
    | arrow: '=>'
    ;

lexical Number = [0-9]+ ("." [0-9]+)?;
lexical ID = ([a-zA-Z][a-zA-Z0-9_\-]* !>> [a-zA-Z0-9_\-]) \ Reserved;

keyword Reserved =
      "defmodule"
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