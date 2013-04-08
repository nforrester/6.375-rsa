CC = gcc 
CFLAGS = -std=gnu99 -g

all: main rsa-from-scratch

main: main.o rsa.o util.o modMultMagic.o modMultNaive.o modMultInterleaved.o
	$(CC) $(CFLAGS) -o main $^

rsa-from-scratch: rsa-from-scratch.o rsa.o util.o modMultMagic.o modMultNaive.o modMultInterleaved.o
	$(CC) $(CFLAGS) -o rsa-from-scratch $^

%.o: %.c *.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf *.o main rsa-from-scratch
