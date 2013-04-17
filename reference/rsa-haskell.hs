import Data.Maybe
import Data.Bits
import qualified Numeric as N
import Control.Monad.State
import System.Clock
import Text.Printf
import System.IO
import Text.ParserCombinators.Parsec hiding ((<|>), many)
import Control.Applicative

---------------------------------------
-- Here is the implementation of RSA --
---------------------------------------

data PublicKey = PubK { pubN :: Integer
                      , pubE :: Integer }
                 deriving Show

data PrivateKey = PriK { priN :: Integer
                       , priE :: Integer
                       , priD :: Integer
                       , priP :: Integer
                       , priQ :: Integer
                       , priU :: Integer }
                  deriving Show

type PlainText  = Integer
type CipherText = Integer

encrypt :: PublicKey -> PlainText -> CipherText
encrypt PubK{pubN = n, pubE = e} m = powMod m e n

decrypt :: PrivateKey -> CipherText -> PlainText
decrypt PriK{priN = n, priD = d} c = powMod c d n

encrypt' :: PublicKey -> PlainText -> CipherText
encrypt' PubK{pubN = n, pubE = e} m = powMod' m e n

decrypt' :: PrivateKey -> CipherText -> PlainText
decrypt' PriK{priN = n, priD = d} c = powMod' c d n

type Document  = Integer
type Signature = Integer

sign :: PrivateKey -> Document -> Signature
sign PriK{priN = n, priD = d} m = powMod m d n

verify :: PublicKey -> Document -> Signature -> Bool
verify PubK{pubN = n, pubE = e} m s = m == powMod s e n

sign' :: PrivateKey -> Document -> Signature
sign' PriK{priN = n, priD = d} m = powMod' m d n

verify' :: PublicKey -> Document -> Signature -> Bool
verify' PubK{pubN = n, pubE = e} m s = m == powMod' s e n

-- The naive implementation of this would be:
-- powMod b e m = b ^ e `mod` m
-- However, this is way, way more efficient:
-- http://en.wikipedia.org/wiki/Modular_exponentiation#Right-to-left_binary_method
powMod :: Integer -> Integer -> Integer -> Integer
powMod b e m = pm b e 1
  where pm _ 0 c = c                   -- when e == 0, then return c
        pm b' e' c =                   -- On each iteration:
          pm (modMult b' b' m)         -- bNew = b^2 % m
             (e' `shiftR` 1)           -- eNew = e >> 1
             $ if ((e' `mod` 2) == 1)  -- if the low bit of e is 1
                 then (modMult c b' m) --   then cNew = c * b % m
                 else c                --   else cNew = c

powMod' :: Integer -> Integer -> Integer -> Integer
powMod' b e m = pm b e 1
  where pm _ 0 c = c                     -- when e == 0, then return c
        pm b' e' c =                     -- On each iteration:
          pm ((b' * b') `mod` m)         -- bNew = b^2 % m
             (e' `shiftR` 1)             -- eNew = e >> 1
             $ if ((e' `mod` 2) == 1)    -- if the low bit of e is 1
                 then ((c * b') `mod` m) --   then cNew = c * b % m
                 else c                  --   else cNew = c

modMult :: Integer -> Integer -> Integer -> Integer
modMult x y m = mm 0 $ reverse $ bits x
  where mm p [] = p
        mm p xi = let p1 = p `shiftL` 1
                      i = if (head xi)
                            then y
                            else 0
                      p2 = p1 + i
                      p3 = if (p2 >= m)
                             then p2 - m
                             else p2
                      p4 = if (p3 >= m)
                             then p3 - m
                             else p3
                  in mm p4 (tail xi)

bits :: Integer -> [Bool]
bits 0 = []
bits x = ((x `mod` 2) == 1):(bits $ x `shiftR` 1)

----------------------------------------------------
-- The main function, where we read the output of --
---- rsa-libgcrypt, and check the calculations -----
----------------------------------------------------

main = do
  parsed <- liftM (parse input "Standard Input") getContents
  case parsed of
     Left e -> error $ "Parse error at: " ++ (show e)
     Right ( pubK
           , priK
           , plainText
           , cipherTextCheck
           , decryptedCheck
           , signatureCheck
           , verificationCheck) -> do
      let cipherText   = encrypt pubK plainText
          decrypted    = decrypt priK cipherText
          signature    = sign priK plainText
          verification = verify pubK plainText signature

          cipherText'   = encrypt' pubK plainText
          decrypted'    = decrypt' priK cipherText
          signature'    = sign' priK plainText
          verification' = verify' pubK plainText signature

      putStrLn "Public Key:"
      print pubK
      putStrLn "\nPrivate Key:"
      print priK
      putStrLn "\nPlain Text:"
      putStrLn $ showHex plainText
      putStrLn "\nCipher Text:"
      timer <- startTimer
      putStrLn $ showHex cipherText
      pollTimer "haskell-ilvd Encrypt: %d.%09d seconds\n" timer
      putStrLn "\nDecrypted Plain Text:"
      timer <- startTimer
      putStrLn $ showHex decrypted
      pollTimer "haskell-ilvd Decrypt: %d.%09d seconds\n" timer
      putStrLn "\nSignature:"
      timer <- startTimer
      putStrLn $ showHex signature
      pollTimer "haskell-ilvd Sign:    %d.%09d seconds\n" timer
      timer <- startTimer
      if verification
        then putStrLn "\nSignature GOOD!"
        else putStrLn "\nSignature BAD!"
      pollTimer "haskell-ilvd Verify:  %d.%09d seconds\n" timer

      if cipherText   == cipherTextCheck &&
         decrypted    == decryptedCheck  &&
         signature    == signatureCheck  &&
         verification == verificationCheck
        then putStrLn "Test PASSED: results match libgcrypt."
        else putStrLn "Test FAILED: results DO NOT match libgcrypt."

      timer <- startTimer
      putStrLn $ showHex cipherText'
      pollTimer "haskell-ntve Encrypt: %d.%09d seconds\n" timer
      putStrLn "\nDecrypted Plain Text:"
      timer <- startTimer
      putStrLn $ showHex decrypted'
      pollTimer "haskell-ntve Decrypt: %d.%09d seconds\n" timer
      putStrLn "\nSignature:"
      timer <- startTimer
      putStrLn $ showHex signature'
      pollTimer "haskell-ntve Sign:    %d.%09d seconds\n" timer
      timer <- startTimer
      if verification'
        then putStrLn "\nSignature GOOD!"
        else putStrLn "\nSignature BAD!"
      pollTimer "haskell-ntve Verify:  %d.%09d seconds\n" timer

      if cipherText'   == cipherTextCheck &&
         decrypted'    == decryptedCheck  &&
         signature'    == signatureCheck  &&
         verification' == verificationCheck
        then putStrLn "Test PASSED: results match libgcrypt."
        else putStrLn "Test FAILED: results DO NOT match libgcrypt."

----------------------------------------------
-------------- Timing functions --------------
----------------------------------------------

tsDiff :: TimeSpec -> TimeSpec -> TimeSpec
tsDiff (TimeSpec s1 n1) (TimeSpec s2 n2) = TimeSpec sd nd
  where s1' = fromIntegral s1 :: Integer
        n1' = fromIntegral n1 :: Integer
        s2' = fromIntegral s2 :: Integer
        n2' = fromIntegral n2 :: Integer
        t1 = s1' * 1000000000 + n1'
        t2 = s2' * 1000000000 + n2'
        td = t1 - t2
        (sd', nd') = td `divMod` 1000000000
        sd = fromIntegral sd'
        nd = fromIntegral nd'

printTS :: String -> TimeSpec -> IO ()
printTS format (TimeSpec s n) = hPrintf stderr format s n

startTimer :: IO TimeSpec
startTimer = getTime Monotonic

pollTimer :: String -> TimeSpec -> IO ()
pollTimer format before = do
  now <- getTime Monotonic
  printTS format $ tsDiff now before

----------------------------------------------
-- The rest of the code is just for parsing --
-------- the output of rsa-libgcrypt ---------
----------------------------------------------

data SExp = SL [SExp]
          | SS String
          | SI Integer
          deriving Show

sexp = list <|> int <|> str
list = fmap SL $ char '(' *> spaces *> many (sexp <* spaces) <* char ')'
int = fmap (SI . readHex) $ char '#' *> some hexDigit <* char '#'
str = fmap SS $ some $ letter <|> char '-'

pubK = do
  string "Public Key:"
  spaces
  SL [SS "public-key"
     , SL [ SS "rsa"
          , SL [SS "n", SI n]
          , SL [SS "e", SI e]]] <- sexp
  spaces
  return $ PubK{ pubN = n
               , pubE = e }

priK = do
  string "Private Key:"
  spaces
  SL [SS "private-key"
     , SL [ SS "rsa"
          , SL [SS "n", SI n]
          , SL [SS "e", SI e]
          , SL [SS "d", SI d]
          , SL [SS "p", SI p]
          , SL [SS "q", SI q]
          , SL [SS "u", SI u]]] <- sexp
  spaces
  return $ PriK{ priN = n
               , priE = e
               , priD = d
               , priP = p
               , priQ = q
               , priU = u }

ciphertext = do
  string "Cipher Text:"
  spaces
  SL [SS "enc-val"
     , SL [ SS "rsa"
          , SL [SS "a", SI a]]] <- sexp
  spaces
  return a

signature = do
  string "Signature:"
  spaces
  SL [SS "sig-val"
     , SL [ SS "rsa"
          , SL [SS "s", SI s]]] <- sexp
  spaces
  return s

plaintext = do
  string "Plain Text:"
  spaces
  liftM readHex $ some hexDigit <* spaces

decrypted = do
  string "Decrypted Plain Text:"
  spaces
  liftM readHex $ some hexDigit <* spaces

options a b = liftM (a ==) $ (try $ string a) <|> string b
verification = options "Signature GOOD!" "Signature BAD!"

readHex = fst . head . N.readHex
showHex = flip N.showHex ""

input = do
  spaces
  publicKey <- pubK
  privateKey <- priK
  plainText <- plaintext
  cipherText <- ciphertext
  decryptedPlainText <- decrypted
  sign <- signature
  verified <- verification
  return ( publicKey
         , privateKey
         , plainText
         , cipherText
         , decryptedPlainText
         , sign
         , verified)
