all: rsa-libgcrypt rsa-haskell

rsa-libgcrypt: rsa-libgcrypt.c
	gcc -o rsa-libgcrypt rsa-libgcrypt.c -lgcrypt

rsa_gcryraw: rsa-libgcrypt_rawdata.c
	gcc -o rsa-gcryraw rsa-libgcrypt_rawdata.c -lgcrypt

rsa-haskell: rsa-haskell.hs
	ghc -O99 --make rsa-haskell

clean:
	rm -f *.o *.hi rsa-haskell rsa-libgcrypt
