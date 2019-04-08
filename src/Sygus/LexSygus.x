{
module Sygus.LexSygus ( Token (..) 
                      , Lit (..)
                      , lexSygus ) where
}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]
$symbs = [\_ \+ \- \* \& \| \! \~ \< \> \= \/ \% \? \. \$ \^]

tokens:-
    $white+                                 ;
    $digit+'.'$digit                        { TLit . LitDec }
    $digit+                                 { TLit . LitNum . read }
    true                                    { TLit . const (LitBool True) }
    false                                   { TLit . const (LitBool False) }
    \#x[$digit A-F]+                        { TLit . Hexidecimal }
    \#b[01]+                                { TLit . Binary }
    \"[$alpha $digit $symbs $white ]* \"    { TLit . LitStr . elimOpenCloseQuote }
    \_$white+                               { const TUnderscore }
    \(                                      { const TOpenBracket }
    \)                                      { const TCloseBracket }
    \:                                      { const TColon }

    [$alpha $symbs][$alpha $digit $symbs]*  { TSymbol }


{
data Token = TLit Lit
           | TUnderscore
           | TOpenBracket
           | TCloseBracket
           | TColon
           | TSymbol String

data Lit = LitNum Integer 
         | LitDec String
         | LitBool Bool
         | Hexidecimal String
         | Binary String
         | LitStr String deriving (Eq, Show, Read)

lexSygus :: String -> [Token]
lexSygus = alexScanTokens

elimOpenCloseQuote :: String -> String
elimOpenCloseQuote ('"':xs) = elimOpenCloseQuote' xs
elimOpenCloseQuote _ = error "elimOpenCloseQuote: Bad string"

elimOpenCloseQuote' :: String -> String
elimOpenCloseQuote' ('"':[]) = []
elimOpenCloseQuote' (x:xs) = x:elimOpenCloseQuote' xs
elimOpenCloseQuote' [] = error "elimOpenCloseQuote': Bad string"

}