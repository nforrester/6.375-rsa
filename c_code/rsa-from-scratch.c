#include <stdio.h>
#include <stdint.h>
#include <sys/time.h>
#include "rsa.h"
#include "util.h"

void timer_start(struct timeval *start) {
  gettimeofday(start, NULL);
}

void timer_poll(char *format, struct timeval *start) {
  struct timeval now, diff;
  gettimeofday(&now, NULL);
  timersub(&now, start, &diff);
  fprintf(stderr, format, diff.tv_sec, diff.tv_usec);
}

int trim(FILE *stream, char end) {
  char c;
  do {
    c = getc(stream);
    if (c == EOF) {
      return FAIL;
    }
  } while (c != end);
  return SUCCESS;
}

int main() {
  struct timeval timer;

  trim(stdin, '\n');
  trim(stdin, '\n');
  trim(stdin, '\n');
  trim(stdin, '\n');
  trim(stdin, '\n');

  bigint n, e, d, p, q, u;

  trim(stdin, '#');
  readBigint(stdin, &n);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &e);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &d);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &p);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &q);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &u);
  trim(stdin, '\n');

  trim(stdin, '\n');
  trim(stdin, '\n');
  trim(stdin, '\n');
  trim(stdin, '\n');

  bigint m, lgc, lgs;
  readBigint(stdin, &m);

  trim(stdin, '#');
  readBigint(stdin, &lgc);
  trim(stdin, '\n');

  trim(stdin, '#');
  readBigint(stdin, &lgs);

  printBigint("n = ", n);
  printBigint("e = ", e);
  printBigint("d = ", d);
  printBigint("p = ", p);
  printBigint("q = ", q);
  printBigint("u = ", u);
  printBigint("m = ", m);
  printBigint("c = ", lgc);
  printBigint("s = ", lgs);

  printf("\n");

  bigint c;
  timer_start(&timer);
  modExpt(m, e, n, &c);
  timer_poll("from-scratch Encrypt: %d.%06d    seconds\n", &timer);

  printf("encrypt test: ");
  if (equal(c, lgc)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  printBigint("c = ", c);

  printf("\n");

  bigint m2;
  timer_start(&timer);
  modExpt(c, d, n, &m2);
  timer_poll("from-scratch Decrypt: %d.%06d    seconds\n", &timer);

  printf("decrypt test: ");
  if (equal(m, m2)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  printBigint("m = ", m2);

  printf("\n");

  bigint s;
  timer_start(&timer);
  modExpt(m, d, n, &s);
  timer_poll("from-scratch Sign:    %d.%06d    seconds\n", &timer);

  printf("sign test: ");
  if (equal(s, lgs)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  printBigint("s = ", s);

  printf("\n");

  bigint v;
  timer_start(&timer);
  modExpt(s, e, n, &v);
  timer_poll("from-scratch Verify:  %d.%06d    seconds\n", &timer);

  printf("verify test: ");
  if (equal(v, m)) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  printBigint("v = ", v);
}
