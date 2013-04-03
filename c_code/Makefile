CC = gcc
CFLAGS = -std=gnu99

all: main

main: main.o rsa.o util.o
	$(CC) $(CFLAGS) -o main $^

%.o: %.c *.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf *.o main
