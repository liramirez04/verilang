module RunnerJson

import Syntax;
import AST;
import Main;
import Checker;
import ParseTree;
import Message;
import IO;
import Set;
import List;
import String;

// ── JSON utilities ────────────────────────────────────────────────────────────

str esc(str s) =
    replaceAll(replaceAll(replaceAll(replaceAll(
        s, "\\", "\\\\"), "\"", "\\\""), "\n", "\\n"), "\t", "\\t");

str jsonArr(list[str] items) =
    "[<intercalate(", ", ["\"<esc(i)>\"" | i <- items])>]";

str jsonResult(
    bool success,
    str modName,
    bool parseOk,
    bool tcOk,
    bool semOk,
    list[str] tcErrs,
    list[str] semErrs,
    list[str] output,
    str err,
    str codigoFormateado,
    str resumen
) =
    "{\"success\":<success>,"
    + "\"module\":\"<esc(modName)>\","
    + "\"parseOk\":<parseOk>,"
    + "\"typeCheckOk\":<tcOk>,"
    + "\"semanticOk\":<semOk>,"
    + "\"typeErrors\":<jsonArr(tcErrs)>,"
    + "\"semanticErrors\":<jsonArr(semErrs)>,"
    + "\"output\":<jsonArr(output)>,"
    + "\"error\":\"<esc(err)>\","
    + "\"codigoFormateado\":\"<esc(codigoFormateado)>\","
    + "\"resumen\":\"<esc(resumen)>\"}";

// ── Resumen del AST como lista de strings ─────────────────────────────────────

list[str] summarize(AModule m) {
    list[str] lines = [];

    if (size(m.imports) > 0) {
        lines += "Imports: " + intercalate(", ", [imp.modName | imp <- m.imports]);
    }

    list[str] spaces    = [];
    list[str] operators = [];
    list[str] variables = [];
    int nExpressions    = 0;
    int nRules          = 0;

    for (comp <- m.comps) {
        switch (comp) {
            case aSpace(aSpaceWithSub(name, aSubtype(parent))):
                spaces += "<name> \< <parent>";
            case aSpace(aSpaceNoSub(name)):
                spaces += name;
            case aOperator(aOperatorDef(name, aOpChain(first, chain), _)):
                operators += "<name>: <first>" + intercalate("", [" -\> <t>" | t <- chain]);
            case aVariable(aVariableDef(decls)):
                for (aVarDecl(vname, vtype) <- decls) variables += "<vname>: <vtype>";
            case aExpression(_): nExpressions += 1;
            case aRule(_):       nRules       += 1;
        }
    }

    if (size(spaces) > 0)    lines += "Spaces [<size(spaces)>]: " + intercalate(", ", spaces);
    if (size(operators) > 0) lines += "Operators [<size(operators)>]: " + intercalate(", ", operators);
    if (size(variables) > 0) lines += "Variables: " + intercalate(", ", variables);
    if (nExpressions > 0)    lines += "Expressions: <nExpressions>";
    if (nRules > 0)          lines += "Rules: <nRules>";

    return lines;
}

// ── Punto de entrada (llamado por la app Kotlin) ──────────────────────────────

void main(list[str] args) {
    // Leer el archivo fuente
    str src;
    try {
        loc file = isEmpty(args)
            ? |project://verilang/test/set.vl|
            : (startsWith(args[0], "/") ? |file:///| + args[0] : |cwd:///| + args[0]);
        src = readFile(file);
    } catch e: {
        println(jsonResult(false, "", false, false, false, [], [], [],
            "No se pudo leer el archivo: <e>", "", ""));
        return;
    }

    // Parsing
    Tree cst;
    try {
        cst = parse(#start[Module], src, allowAmbiguity=true);
    } catch ParseError(loc at): {
        println(jsonResult(false, "", false, false, false, [], [], [],
            "Error de parsing en <at>", "", ""));
        return;
    } catch e: {
        println(jsonResult(false, "", false, false, false, [], [], [],
            "Error de parsing: <e>", "", ""));
        return;
    }

    // Construcción del AST
    AModule ast;
    try {
        ast = buildModule(cst.top);
    } catch e: {
        println(jsonResult(false, "", true, false, false, [], [], [],
            "Error construyendo AST: <e>", "", ""));
        return;
    }

    str modName = ast.name;

    // Resumen: nombre del módulo e imports (lista de módulos)
    str resumen = "Módulo: <modName>";
    if (size(ast.imports) > 0) {
        resumen += " | Importa: " + intercalate(", ", [imp.modName | imp <- ast.imports]);
    }

    // Verificación de nombres con TypePal (Checker)
    list[str] tcErrs = [];
    bool tcOk = true;
    try {
        TModel tm = typeCheck(cst);
        tcErrs = ["<msg> (en <at>)" | error(str msg, loc at) <- toList(tm.messages)];
        tcOk   = isEmpty(tcErrs);
    } catch e: {
        tcErrs = ["Error en verificación de nombres: <e>"];
        tcOk   = false;
    }

    // Output: resumen de componentes del módulo
    list[str] output = summarize(ast);

    println(jsonResult(tcOk, modName, true, tcOk, tcOk, tcErrs, [], output, "", "", resumen));
}
