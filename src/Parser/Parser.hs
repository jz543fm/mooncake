module Parser.Parser where

import Text.ParserCombinators.Parsec hiding (spaces)
import Text.Parsec.Char
import Parser.AST

parseProgramm = parse programmParser "MoonCake"

parseIdentifier :: Parser String
parseIdentifier = do
   head <- letter
   rest <- many (digit <|> letter)
   return $ [head] ++ rest

parseString :: Parser MCValue
parseString = do
   char '"'
   x <- many $ escapedChars <|> many1 (noneOf ['"', '\\'])
   char '"'
   return $ String (concat x)

parseInt :: Parser MCValue
parseInt = do
   sign <- option '+' (char '-')
   digits <- many1 digit
   return $ case sign of
      '+' -> (Integer . read) digits
      '-' -> (Integer . (* (-1)) . read) digits

parseBool :: Parser MCValue
parseBool = do
   bool <- (string "True") <|> (string "False")
   return $ case bool of
      "True" -> Bool True
      "False" -> Bool False

parseReferenceLiteral :: Parser Reference
parseReferenceLiteral = do
   val <- parseMCValue
   return $ Literal val

parseReferenceIdentifier :: Parser Reference
parseReferenceIdentifier = do
   id <- parseIdentifier
   return $ Identifier id

parseReference :: Parser Reference
parseReference = 
   try parseReferenceIdentifier
   <|> parseReferenceLiteral

listItemSep :: Parser ()
listItemSep = do
   spaces
   char ','
   spaces

parseList :: Parser MCValue
parseList = do
   char '['
   spaces
   items <- parseReference `sepEndBy` (try listItemSep)
   spaces
   char ']'
   return $ List items

escapedChars :: Parser String
escapedChars = do
   char '\\'
   c <- oneOf "'\\nrt"
   return $ case c of
      '\\' -> "\\"
      '\'' -> "'"
      'n' -> "\n"
      'r' -> "\r"
      't' -> "\t"

parseMCValue :: Parser MCValue
parseMCValue =
   try parseString
   <|> try parseInt
   <|> try parseBool
   <|> try parseList

parseValDeclaration :: Parser AST
parseValDeclaration = do 
   string "let "
   identifier <- parseIdentifier
   string " = "
   ref <- parseReference
   return $ ValDeclaration identifier ref

programmParser :: Parser AST
programmParser = do
   spaces
   vars <- many $ do
      var <- parseValDeclaration
      spaces
      return var
   return $ Programm vars