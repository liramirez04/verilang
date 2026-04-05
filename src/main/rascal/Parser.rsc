module Parser

import Syntax;
import ParseTree;

public start[Module] parseVeriLang(str src, loc origin) = parse(#start[Module], src, origin, allowAmbiguity=true);
public start[Module] parseVeriLang(loc origin) = parse(#start[Module], origin, allowAmbiguity=true);

public Tree parseFile(loc source) = parse(#start[Module], source, allowAmbiguity=true);
public Tree parseString(str src) = parse(#start[Module], src, allowAmbiguity=true);
