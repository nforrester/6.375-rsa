import Data.Maybe
import Data.Bits
import qualified Numeric as N
import Control.Monad.State

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

type Document  = Integer
type Signature = Integer

sign :: PrivateKey -> Document -> Signature
sign PriK{priN = n, priD = d} m = powMod m d n

verify :: PublicKey -> Document -> Signature -> Bool
verify PubK{pubN = n, pubE = e} m s = m == powMod s e n

-- The naive implementation of this would be:
-- powMod b e m = b ^ e `mod` m
-- However, this is way, way more efficient:
-- http://en.wikipedia.org/wiki/Modular_exponentiation#Right-to-left_binary_method
powMod :: Integer -> Integer -> Integer -> Integer
powMod b e m = pm b e 1
  where pm _ 0 c = c                   -- when e == 0, then return c
        pm b' e' c =                   -- On each iteration:
          pm (b' * b' `mod` m)         -- bNew = b^2 % m
             (e' `shiftR` 1)           -- eNew = e >> 1
             $ if ((e' `mod` 2) == 1)  -- if the low bit of e is 1
                 then (c * b' `mod` m) --   then cNew = c * b % m
                 else c                --   else cNew = c

----------------------------------------------------
-- The main function, where we read the output of --
---- rsa-libgcrypt, and check the calculations -----
----------------------------------------------------

main = (getContents >>=) $ evalStateT $ do
  pubK <- stsk readPubK
  priK <- stsk readPriK
  plainText <- stsk readHex
  cipherTextCheck <- stsk readCipherText
  decryptedCheck <- stsk readHex
  signatureCheck <- stsk readSignature
  verificationCheck <- liftM (("Signature GOOD!" ==) . head . lines . trimSpace) $ get

  let cipherText   = encrypt pubK plainText
      decrypted    = decrypt priK cipherText
      signature    = sign priK plainText
      verification = verify pubK plainText signature

  liftIO $ do
    putStrLn "Public Key:"
    print pubK
    putStrLn "\nPrivate Key:"
    print priK
    putStrLn "\nPlain Text:"
    putStrLn $ showHex plainText
    putStrLn "\nCipher Text:"
    putStrLn $ showHex cipherText
    putStrLn "\nDecrypted Plain Text:"
    putStrLn $ showHex decrypted
    putStrLn "\nSignature:"
    putStrLn $ showHex signature
    if verification
      then putStrLn "\nSignature GOOD!"
      else putStrLn "\nSignature BAD!"

    if cipherText   == cipherTextCheck &&
       decrypted    == decryptedCheck  &&
       signature    == signatureCheck  &&
       verification == verificationCheck
      then putStrLn "Test PASSED: results match libgcrypt."
      else putStrLn "Test FAILED: results DO NOT match libgcrypt."

----------------------------------------------
-- The rest of the code is just for reading --
-------- the output of rsa-libgcrypt ---------
----------------------------------------------

data SExp = SL [SExp]
          | SS String
          | SI Integer
          deriving Show

isSpace = flip elem " \n\t"
trimSpace = dropWhile isSpace

isNotThing = flip elem ") \n\t"
splitThing = span (not . isNotThing)

readSExp :: String -> Maybe (SExp, String)
readSExp input = if null trimmed
                   then Nothing
                   else Just $ case head trimmed
                               of '(' -> let (items, unread) = readSL $ tail trimmed
                                         in (SL items, unread)
                                  '#' -> (SI $ fst $ readHex $ init $ tail $ this, others)
                                  _ -> (SS this, others)
  where trimmed = trimSpace input
        (this, others) = splitThing trimmed
        readSL (')':unread) = ([], unread)
        readSL str = let (this, more) = fromJust $ readSExp str
                         (rest, unread) = readSL $ trimSpace more
                        in (this:rest, trimSpace unread)

readPubK :: String -> (PublicKey, String)
readPubK string = (pubK, rest)
  where (sExp, rest) = fromJust $ readSExp string
        SL [SS "public-key"
           , SL [SS "rsa"
                , SL [SS "n", SI n]
                , SL [SS "e", SI e]]] = sExp
        pubK = PubK{ pubN = n
                   , pubE = e }

readPriK :: String -> (PrivateKey, String)
readPriK string = (priK, rest)
  where (sExp, rest) = fromJust $ readSExp string
        SL [SS "private-key"
           , SL [SS "rsa"
                , SL [SS "n", SI n]
                , SL [SS "e", SI e]
                , SL [SS "d", SI d]
                , SL [SS "p", SI p]
                , SL [SS "q", SI q]
                , SL [SS "u", SI u]]] = sExp
        priK = PriK{ priN = n
                   , priE = e
                   , priD = d
                   , priP = p
                   , priQ = q
                   , priU = u }

readCipherText :: String -> (Integer, String)
readCipherText string = (cipherText, rest)
  where (sExp, rest) = fromJust $ readSExp string
        SL [SS "enc-val"
           , SL [SS "rsa"
                , SL [SS "a", SI cipherText]]] = sExp

readSignature :: String -> (Integer, String)
readSignature string = (signature, rest)
  where (sExp, rest) = fromJust $ readSExp string
        SL [SS "sig-val"
           , SL [SS "rsa"
                , SL [SS "s", SI signature]]] = sExp

skipLine = unlines . tail . lines . trimSpace
readHex = head . N.readHex
showHex = flip N.showHex ""

stsk r = do
  (val, rest) <- liftM (r . skipLine) $ get
  put rest
  return val
