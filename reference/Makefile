all: rsa-libgcrypt rsa-haskell

rsa-libgcrypt: rsa-libgcrypt.c
	gcc -o rsa-libgcrypt rsa-libgcrypt.c -lgcrypt

rsa-haskell: rsa-haskell.hs
	ghc -O99 --make rsa-haskell

clean:
	rm *.o *.hi rsa-haskell rsa-libgcrypt
