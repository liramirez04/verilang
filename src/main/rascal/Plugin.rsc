module Plugin

import IO;
import ParseTree;
import util::LanguageServer;

import Syntax;
import Parser;


Language verilangLang = language(pathConfig(srcs=[|project://verilang/src/main/rascal|]), "VeriLang", "vl", "Plugin", "contribs");

set[LanguageService] contribs() = {
    parser(start[Module] (str program, loc src) {
        return parseVeriLang(program, src);
    })
};

void main() {
    registerLanguage(verilangLang);
    println("Lenguaje VeriLang registrado exitosamente en el IDE.");
    println("Ahora los archivos con extension .vl tendran Syntax Highlighting.");
}
