/* this file has all of our functions! */
#include "util.h"
#include "rsa.h"

// result = b ^ e % m
int modExpt(bigint b, bigint e, bigint m, bigint *result) {
  bigint zero;
  clearBigint(zero);

  clearBigint(result);
  result->data[0] = 1;

  while (!equal(zero, e)) {
    if (e.data[0] % 2 == 1) {
      modMult(result, b, m, &result);
    }
    modMult(b, b, m, &b);
    shiftR(e, 2, &e);
  }
  return SUCCESS;
}

// a = 0
void clearBigint(bigint *a) {
  for (int i = 0; i < NCHUNKS; i++) {
    a->data[i] = 0;
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
