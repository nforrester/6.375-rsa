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

  printf("The following two lines should be identical:\n");
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

  bigint n, e, d, p, q, u;
  readBigint(stream, &n);
  readBigint(stream, &e);
  readBigint(stream, &d);
  readBigint(stream, &p);
  readBigint(stream, &q);
  readBigint(stream, &u);

  printf("equal() test: ");
  if (!equal(meaningOfLifeTheUniverseAndEverything, num[5]) &&
       equal(num[7], num[7]) &&
       equal(n, n) &&
      !equal(p, q)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }

  printf("Ari's silly test\n");
  bigint a =num[8], b = num[8], c=num[9];
  printf("input operands: ");
  writeBigint(stdout,a); printf("\t");
  writeBigint(stdout,b); printf("\t");
  writeBigint(stdout,c); printf("\n\n");
  modMultMagic(a,b, c,&tmp);
  printf("\n\nresult: \t");
  writeBigint(stdout, tmp);
  printf("\n");


}
