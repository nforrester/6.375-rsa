/* this file has all of our functions! */
#include <stdio.h>
#include <stdint.h>
#include "rsa.h"
#include "util.h"

// result = b ^ e % m
int modExpt(bigint b, bigint e, bigint m, bigint *result) {
  bigint zero, bTmp, rTmp, eTmp;
  clearBigint(&zero);

  clearBigint(result);
  result->data[0] = 1;

  while (!equal(zero, e)) {
   printf("b = ");
   writeBigint(stdout,b);
   printf("\n");

    if (e.data[0] % 2 == 1) {
      modMult(*result, b, m, &rTmp);
      *result = rTmp;
    }
    modMult(b, b, m, &bTmp);
    b = bTmp;
    shiftR(e, 2, &eTmp);
    e = eTmp;
  }
  return SUCCESS;
}

// a = 0
void clearBigint(bigint *a) {
  for (int i = 0; i < NCHUNKS; i++) {
    a->data[i] = 0;
  }
}

// a = 0xFFFFFFFFFFFFFFFFF... (the maximum possible bigint).
void bigintMax(bigint *a) {
  CHUNK_T maxChunk = 0;
  for (int i = 0; i < CHUNK_SIZE; i++) {
    maxChunk <<= 1;
    maxChunk++;
  }
  for (int i = 0; i < NCHUNKS; i++) {
    a->data[i] = maxChunk;
  }
}

// a == b
int equal(bigint a, bigint b) {
  for (int i = 0; i < NCHUNKS; i++) {
    if (a.data[i] != b.data[i]) {
      return FALSE;
    }
  }
  return TRUE;
}

// result = a
void assign(bigint a, bigint *result) {
  for (int i = 0; i < NCHUNKS; i++) {
    result->data[i] = a.data[i];
  }
}

// result = a << s
int shiftL(bigint a, unsigned int s, bigint *result) {
  long shiftChunks = s / CHUNK_SIZE;
  long shiftBits   = s % CHUNK_SIZE;

  for (int i = 0; i < NCHUNKS; i++) {
    if (i - shiftChunks >= 0) {
      result->data[i] = a.data[i - shiftChunks];
      result->data[i] <<= shiftBits;
      if (i - shiftChunks - 1 >= 0) {
        result->data[i] |= a.data[i - shiftChunks - 1] >> (CHUNK_SIZE - shiftBits);
      }
    } else {
      result->data[i] = 0;
    }
  }

  return SUCCESS;
}

// result = a >> s
int shiftR(bigint a, unsigned int s, bigint *result) {
  long shiftChunks = s / CHUNK_SIZE;
  long shiftBits   = s % CHUNK_SIZE;

  for (int i = 0; i < NCHUNKS; i++) {
    if (i + shiftChunks < NCHUNKS) {
      result->data[i] = a.data[i + shiftChunks];
      result->data[i] >>= shiftBits;
      if (i + shiftChunks + 1 < NCHUNKS) {
        result->data[i] |= a.data[i + shiftChunks + 1] << (CHUNK_SIZE - shiftBits);
      }
    } else {
      result->data[i] = 0;
    }
  }

  return SUCCESS;
}

int modMultDummy(bigint a, bigint b, bigint m, bigint *result) {
	// placeholder, so that it will compile
}
