{
module Sygus.ParseSygus where

import Sygus.LexSygus

}

%name parse
%tokentype { Token }
%error { parseError }

%token
    num                 { TLit (LitNum $$) }
    bool                { TLit (LitBool $$) }
    lit                 { TLit $$ }
    '_'                 { TUnderscore }
    '('                 { TOpenBracket }
    ')'                 { TCloseBracket }
    ':'                 { TColon }

    -- terms
    exists              { TSymbol "exists" }
    forall              { TSymbol "forall" }
    tlet                { TSymbol "let" }

    -- features
    grammars            { TSymbol "grammars" }
    fwdDecls            { TSymbol "fwd-decls" }
    recursion           { TSymbol "recursion" }

    -- cmds 
    checkSynth          { TSymbol "check-synth" }
    constraint          { TSymbol "constraint" }
    declareVar          { TSymbol "declare-var" }
    invConstraint       { TSymbol "inv-constraint" }
    setFeature          { TSymbol "set-feature" }
    synthFun            { TSymbol "synth-fun" }
    synthInv            { TSymbol "synth-inv" }

    -- gterm
    constant            { TSymbol "Constant" }
    variable            { TSymbol "Variable" }

    symb                { TSymbol $$ }
%%

cmd :: { Cmd }
     : '(' checkSynth ')'                                           { CheckSynth }
     | '(' constraint term ')'                                      { Constraint $3 }
     | '(' declareVar symb sort ')'                                 { DeclareVar $3 $4 }
     | '(' invConstraint symb symb symb symb ')'                    { InvConstraint $3 $4 $5 $6 }
     | '(' setFeature ':' feature bool ')'                          { SetFeature $4 $5 }
     | '(' synthFun symb '(' sorted_vars ')' sort maybe_grammar_def { SynthFun $3 $5 $7 $8 } -- Gives a shift/reduce conflict
     | '(' synthInv symb '(' sorted_vars ')' maybe_grammar_def      { SynthInv $3 $5 $7 }
     -- TODO: ...

identifier :: { Identifier }
            : symb                      { ISymb $1 }
            | '(' '_' symb indexes1 ')' { Indexed $3 $4 }

indexes1 :: { [Index] }
          : indexes_rev1 { reverse $1 }

indexes_rev1 :: { [Index] }
              : indexes_rev1 index { $2:$1 }
              | index              { [$1] }

index :: { Index }
       : num  {IndNumeral $1 }
       | symb {IndSymb $1 }

sorts1 :: { [Sort] }
          : sorts_rev1 { reverse $1 }

sorts_rev1 :: { [Sort] }
            : sorts_rev1 sort { $2:$1 }
            | sort            { [$1] }

sort :: { Sort }
      : identifier                { IdentSort $1 }
      | '(' identifier sorts1 ')' { IdentSortSort $2 $3 }

terms1 :: { [Term] }
        : terms_rev1 { reverse $1 }

terms_rev1 :: { [Term] }
            : terms_rev1 term { $2:$1 }
            | term           { [$1] }

term :: { Term }
      : identifier                               { TermIdent $1 }
      | lit                                      { TermLit $1 }
      | '(' identifier terms1 ')'                { TermCall $2 $3}
      | '(' exists '(' sorted_vars1 ')' term ')' { TermExists $4 $6 }
      | '(' forall '(' sorted_vars1 ')' term ')' { TermForAll $4 $6 }
      | '(' tlet '(' var_bindings1 ')' term ')'  { TermLet $4 $6 }

bfterms1 :: { [BfTerm] }
          : bfterms_rev1 { reverse $1 }

bfterms_rev1 :: { [BfTerm] }
              : bfterms_rev1 bfterm { $2:$1 }
              | bfterm              { [$1] }

bfterm :: { BfTerm }
        : identifier { BfIdentifier $1 }
        | lit        { BfLiteral $1 }
        | '(' identifier bfterms1 ')' { BfIdentifierBfs $2 $3 }

sorted_vars1 :: { [SortedVar] }
             : sorted_vars_rev1 { reverse $1 }

sorted_vars_rev1 :: { [SortedVar] }
            : sorted_vars_rev1 sorted_var { $2:$1 }
            | sorted_var                 { [$1] }

sorted_vars :: { [SortedVar] }
             : sorted_vars_rev { reverse $1 }

sorted_vars_rev :: { [SortedVar] }
            : sorted_vars_rev sorted_var { $2:$1 }
            | {- empty -}                 { [] }

sorted_var :: { SortedVar }
            : '(' symb sort ')' { SortedVar $2 $3 }

var_bindings1 :: { [VarBinding] }
             : var_bindings_rev1 { reverse $1 }

var_bindings_rev1 :: { [VarBinding] }
            : var_bindings_rev1 var_binding { $2:$1 }
            | var_binding                   { [$1] }

var_binding :: { VarBinding }
             : '(' symb term ')' { VarBinding $2 $3 }

feature :: { Feature }
         : grammars   { Grammars }
         | fwdDecls   { FwdDecls }
         | recursion  { Recursion }

maybe_grammar_def :: { Maybe GrammarDef }
                   : grammar_def { Just $1 }
                   | {- empty -} { Nothing }

grammar_def :: { GrammarDef }
             : '(' sorted_vars1 ')' '(' grouped_rule_lists1 ')' { GrammarDef $2 $5 }

grouped_rule_lists1 :: { [GroupedRuleList] }
                    : grouped_rule_lists1 { reverse $1 }

grouped_rule_lists_rev1 :: { [GroupedRuleList] }
                        : grouped_rule_lists1 grouped_rule_list { $2:$1 }
                        | grouped_rule_list                     { [$1] }

grouped_rule_list :: { GroupedRuleList }
                   : '(' symb sort '(' gterm1 ')' ')' { GroupedRuleList $2 $3 $5 }

gterm1 :: { [GTerm] }
        : gterm_rev1 { reverse $1 }

gterm_rev1 :: { [GTerm] }
            : gterm_rev1 gterm { $2:$1 }
            | gterm            { [$1] }

gterm :: { GTerm }
       : constant sort { GConstant $2 }
       | variable sort { GVariable $2 }
       | bfterm        { GBfTerm $1 }

{
type Symbol = String

data Cmd = CheckSynth
         | Constraint Term
         | DeclareVar Symbol Sort
         | InvConstraint Symbol Symbol Symbol Symbol
         | SetFeature Feature Bool
         | SynthFun Symbol [SortedVar] Sort (Maybe GrammarDef)
         | SynthInv Symbol [SortedVar] (Maybe GrammarDef)
         deriving (Eq, Show, Read)

data Identifier = ISymb Symbol
                | Indexed Symbol [Index]
                deriving (Eq, Show, Read)

data Index = IndNumeral Integer
           | IndSymb Symbol
           deriving (Eq, Show, Read)

data Sort = IdentSort Identifier
          | IdentSortSort Identifier [Sort]
          deriving (Eq, Show, Read)

data Term = TermIdent Identifier
          | TermLit Lit
          | TermCall Identifier [Term]
          | TermExists [SortedVar] Term
          | TermForAll [SortedVar] Term
          | TermLet [VarBinding] Term
          deriving (Eq, Show, Read)

data BfTerm = BfIdentifier Identifier
            | BfLiteral Lit
            | BfIdentifierBfs Identifier [BfTerm]
            deriving (Eq, Show, Read)

data SortedVar = SortedVar Symbol Sort deriving (Eq, Show, Read)

data VarBinding = VarBinding Symbol Term deriving (Eq, Show, Read)

data Feature = Grammars
             | FwdDecls
             | Recursion
             deriving (Eq, Show, Read)

data GrammarDef = GrammarDef [SortedVar] [GroupedRuleList] deriving (Eq, Show, Read)

data GroupedRuleList = GroupedRuleList Symbol Sort [GTerm] deriving (Eq, Show, Read)

data GTerm = GConstant Sort
           | GVariable Sort
           | GBfTerm BfTerm
           deriving (Eq, Show, Read)

parseError :: [Token] -> a
parseError _ = error "Parse error."
}