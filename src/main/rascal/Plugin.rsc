module Plugin

import IO;
import ParseTree;
import util::LanguageServer;
import util::Reflective;

import Syntax;
import Parser;
import Checker;


Language verilangLang = language(pathConfig(srcs=[|project://verilang/src/main/rascal|]), "VeriLang", "vl", "Plugin", "contribs");

Summary verilangSummarizer(loc l, start[Module] input) {
    try {
        TModel tm = typeCheck(input.top);
        return summary(l,
            messages = tm.messages,
            definitions = tm.useDef
        );
    } catch value e: {
        println("TypePal error: <e>");
        return summary(l);
    }
}

set[LanguageService] contribs() = {
    parser(start[Module] (str program, loc src) {
        return parseVeriLang(program, src);
    }),
    summarizer(verilangSummarizer)
};

void main() {
    registerLanguage(verilangLang);
    println("Lenguaje VeriLang registrado exitosamente en el IDE.");
    println("Ahora los archivos con extension .vl tendran Syntax Highlighting y verificacion de tipos.");
}
