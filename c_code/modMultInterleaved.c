#include "rsa.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "util.h"

// Returns bit at x[i]
int getBit(int i, bigint * x) {
  CHUNK_T bin;
  bin = x->data[i * NCHUNKS / BI_SIZE];
  
  return (bin >> (i % CHUNK_SIZE)) & 1;
}

// Sets bit at x[i] to 1
void setBit(int i, bigint * x) {
  x->data[i * NCHUNKS / BI_SIZE] |= 1 << (i % CHUNK_SIZE);
  return;
}

// Unsets bit at x[i] to 0
void unsetBit(int i, bigint * x) {
  x->data[i * NCHUNKS / BI_SIZE] &= ~(1 << (i % CHUNK_SIZE));
  return;
}

// Performs bitwise P = P +/- I in place
int add_sub_inplace(bigint * P, bigint * I, int carry_in, int extra_bits_p) {
  int i;
  unsigned int sum = 0;
  int carry = carry_in;
  int extra_bits_out;

  for (i = 0; i < NCHUNKS; i++) {
    sum = P->data[i] + (carry_in ? (~(I->data[i])) : (I->data[i])) + carry;
    P->data[i] = sum & ((1 << CHUNK_SIZE) - 1);
    carry = (sum >> CHUNK_SIZE) & 1;
    if (carry_in) {
      carry = !carry;
    }
  }
  
  sum = (extra_bits_p & 1) + carry_in + carry;
  extra_bits_out = sum & 1;
  carry = (sum & 2) >> 1;
	
  sum = ((extra_bits_p & 2) >> 1) + carry_in + carry;
  extra_bits_out |= (sum & 1) << 1;
  carry = (sum & 2) >> 1;
	
  if (carry != carry_in) {
    printf("Sum overflow! carry = %x, extra_bits_out = %x\n", carry, extra_bits_out);
    printBigint("P = ", *P);
    exit(-1);
  }
  return extra_bits_out;
}

// Performs bitwise P = P + I in place
int add_inplace(bigint * P, bigint * I, int extra_bits_p) {
  return add_sub_inplace(P, I, 0, extra_bits_p);
}

// Returns true if P >= M
int strongly_greater(bigint * P, bigint * M){
  int i;

  for (i = NCHUNKS-1; i >= 0; i--) {
    if (P->data[i] < M->data[i]) {
      return 0;
    } else if (P->data[i] > M->data[i]) {
      return 1;
    }
  }
  
  return 1;
}

// Performs bitwise P = P - M in place
int sub_inplace(bigint * P, bigint * I, int extra_bits_p) {
  return add_sub_inplace(P, I, 1, extra_bits_p);
}

int modMultIlvd(bigint a, bigint b, bigint m, bigint *result) {
  
  // To match Montgomery FPGA paper: 
  bigint *P = result;
  bigint *X = &a;
  bigint *Y = &b;
  bigint *M = &m;
  bigint I; // ok to leave uninitialized, Xi * Y will initialize
  
  int i, j;
  int extra_bits_p = 0;
  
  // P = 0
  clearBigint(P);

  for (i = BI_SIZE - 1; i >= 0; i--) {
    // P = 2 * P
    extra_bits_p = P->data[NCHUNKS-1] >> (CHUNK_SIZE - 1);
    for (j = NCHUNKS - 1; j >= 1; j--) {
      P->data[j] = (P->data[j] << 1) + (P->data[j-1] >> (CHUNK_SIZE - 1));
    }
    P->data[0] = P->data[0] << 1;

    // I = Xi * Y
    for (j = 0; j < NCHUNKS; j++) {
      I.data[j] = Y->data[j] * getBit(i, X);
    }
    
    // P = P + I
    extra_bits_p = add_inplace(P, &I, extra_bits_p);

    // if(P >= M) P = P - M;
    if(extra_bits_p || strongly_greater(P, M)) {
      extra_bits_p = sub_inplace(P, M, extra_bits_p);
    }
   
    // if(P >= M) P = P - M;
    if(extra_bits_p || strongly_greater(P, M)) {
      extra_bits_p = sub_inplace(P, M, extra_bits_p);
    }

    if(extra_bits_p || strongly_greater(P, M)) {
      printf("P too big! extra_bits_p = %x\n", extra_bits_p);
      printBigint("P = ", *P);
      exit(-1);
    }
  }
  
  
  return SUCCESS;
 
}
