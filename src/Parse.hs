module Parse (
    parseExpr,
    parseList,
    parseQuoted,
    parseAtom,
    parseString,
    parseFloat,
    parseInteger,
    readExpr
) where


import Text.ParserCombinators.Parsec
import Control.Arrow (left)
import Data


readExpr :: String -> Either LispError LispVal
readExpr input = left Parser (parse parseExpr "lisp" input)

parseExpr :: Parser LispVal
parseExpr = parseInteger
    <|> parseFloat
    <|> parseString
    <|> parseAtom
    <|> parseQuoted
    <|> parseList

parseList :: Parser LispVal
parseList = do
    char '('
    exprs <- parseExpr `sepBy` (skipMany1 space)
    char ')'
    return $ List exprs

parseQuoted :: Parser LispVal
parseQuoted = do
    char '\''
    expr <- parseExpr
    return $ List [Atom "quote", expr]

parseString :: Parser LispVal
parseString = do
    char '"'
    str <- many ((char '\\' >> anyChar >>= return . escapedChar) <|> noneOf "\\\"")
    char '"'
    return . String $ str

escapedChar :: Char -> Char
escapedChar 'n' = '\n'
escapedChar 'r' = '\r'
escapedChar 't' = '\t'
escapedChar '\\' = '\\'
escapedChar char = char

parseAtom :: Parser LispVal
parseAtom = do
    first <- letter <|> symbol
    rest <- many $ symbol <|> digit <|> letter
    let name = first:rest
    return $ case name of
        "#t" -> Bool True
        "#f" -> Bool False
        _    -> Atom name

symbol :: Parser Char
symbol = oneOf "!#$%&|*+-/:<=>?@^_~"

parseInteger :: Parser LispVal
parseInteger = many1 digit >>= return . Integer . read

parseFloat :: Parser LispVal
parseFloat = try $ do
    intPart <- many1 digit
    char '.'
    floatPart <- many1 digit
    return . Float . read $ (intPart ++ "." ++ floatPart)
