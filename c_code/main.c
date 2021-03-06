#include <stdio.h>
#include <stdint.h>
#include "rsa.h"
#include "util.h"

/* For now all this does is test some functions, for debugging.
 * It will probably be completely replaced at a later date.
 */

int main() {

  FILE *stream = fopen("testdata", "r");

  printf("0 to 16 in hex: ");
  bigint num[0x11];
  for (int i = 0; i < 0x11; i++) {
    readBigint(stream, &num[i]);
    writeBigint(stdout, num[i]);
    printf(" ");
  }
  printf("\n");

  printf("\nThe following two lines should be identical:\n");
  printf("1 2 4 8 10 20 40 80 100 200 2000 800000000 1 0\n");
  int shifts[11] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 22};
  int totalShift = 0;
  bigint tmp;
  assign(num[1], &tmp);
  writeBigint(stdout, tmp);
  printf(" ");
  fflush(stdout);
  for (int i = 0; i < 11; i++) {
    shiftL(tmp, shifts[i], &tmp);
    writeBigint(stdout, tmp);
    printf(" ");
    fflush(stdout);
    totalShift += shifts[i];
  }
  shiftR(tmp, totalShift, &tmp);
  writeBigint(stdout, tmp);
  printf(" ");
  shiftR(tmp, 1, &tmp);
  writeBigint(stdout, tmp);
  printf("\n");

  bigint meaningOfLifeTheUniverseAndEverything;
  readBigint(stream, &meaningOfLifeTheUniverseAndEverything);

  modMult(num[6], num[7], meaningOfLifeTheUniverseAndEverything, &tmp);
  printBigint("\nsimple test: 6 * 7 % 42 = ", tmp);

  modMult(num[6], num[9], meaningOfLifeTheUniverseAndEverything, &tmp);
  printBigint("\nsimple test: 6 * 9 % 42 = ", tmp);

  modMult(num[2], num[3], num[5], &tmp);
  printBigint("\nsimple test: 2 * 3 % 5 = ", tmp);

  modExpt(num[5], num[3], meaningOfLifeTheUniverseAndEverything, &tmp);
  printBigint("\nsimple test: 5 ^ 3 % 42 = ", tmp);

  bigint n, e, d, p, q, u;
  readBigint(stream, &n);
  readBigint(stream, &e);
  readBigint(stream, &d);
  readBigint(stream, &p);
  readBigint(stream, &q);
  readBigint(stream, &u);

  printf("\nequal() test: ");
  if (!equal(meaningOfLifeTheUniverseAndEverything, num[5]) &&
       equal(num[7], num[7]) &&
       equal(n, n) &&
      !equal(p, q)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }

  bigint maxBI, pq;
  bigintMax(&maxBI);

  printf("\nmaxBI = ");
  writeBigint(stdout, maxBI);
  printf("\n\nHere is an RSA private key:");
  printf("\n\nn = ");
  writeBigint(stdout, n);
  printf("\n\ne = ");
  writeBigint(stdout, e);
  printf("\n\nd = ");
  writeBigint(stdout, d);
  printf("\n\np = ");
  writeBigint(stdout, p);
  printf("\n\nq = ");
  writeBigint(stdout, q);
  printf("\n\nu = ");
  writeBigint(stdout, u);
  printf("\n\n");
  modMult(p, q, maxBI, &pq);
  printf("\n\np * q mod maxBI = ");
  writeBigint(stdout, pq);
  printf("\n\nThe following statement should be true: ");
  printf("\nn == p * q mod maxBI");
  printf("\nis it? ");
  if (equal(n, pq)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
    printf("\nn  = ");
    writeBigint(stdout, n);
    printf("\npq = ");
    writeBigint(stdout, pq);
  }

  printf("\n\nSHITS AND GIGGLES:\n");
  bigint m, c, m2;
  readBigint(stream, &m);

  printf("\nm = ");
  writeBigint(stdout, m);
  printf("\n\n");
  modExpt(m, e, n, &c);
  printf("\n\nm ^ e mod n = c = ");
  writeBigint(stdout, c);
  printf("\n\n");
  modExpt(c, d, n, &m2);
  printf("\n\nc ^ d mod n = m = ");
  writeBigint(stdout, m2);

  printf("\n\nIs the plaintext equal to the deciphered ciphertext? ");
  if (equal(m,m2)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
    printf("\nm  = ");
    writeBigint(stdout, m);
    printf("\nm2 = ");
    writeBigint(stdout, m2);
  }

  /*printf("\nAri's silly test\n");
  bigint a =num[3], b = num[8], c=num[7];
  printf("input operands: ");
  writeBigint(stdout,a); printf("\t");
  writeBigint(stdout,b); printf("\t");
  writeBigint(stdout,c); printf("\n\n");
  modMultMagic(a,b, c,&tmp);
  printf("\n\nresult: \t");
  writeBigint(stdout, tmp);
  printf("\n");
*/

}
