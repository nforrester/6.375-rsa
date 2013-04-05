#include "rsa.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// Returns bit at x[i]
int getBit(int i, bigint * x) {
  CHUNK_T bin;
  bin = x->data[(int) floor((float) i/NCHUNKS)];
  
  return (bin >> (i % 16) & 1);
}

// Sets bit at x[i] to 1
void setBit(int i, bigint * x) {
  x->data[(int) floor((float) i/NCHUNKS)] |= 1 << i;
  return;
}

// Unsets bit at x[i] to 0
void unsetBit(int i, bigint * x) {
  x->data[(int) floor((float) i/NCHUNKS)] &= ~(1 << i);
  return;
}

// Performs bitwise P = P + I in place
void add_inplace(bigint * P, bigint * I) {
  int i;
  int sum = 0;
  
  for (i = 0; i < NCHUNKS; i++) {
    sum = getBit(i, P) + getBit(i, I);
  
    if(sum == 0) {
	    unsetBit(i, P);
    } else if(sum < 2) {
	    setBit(i, P);
    } else {
	    setBit(i, P);
	
  	  if(i == 1023) {
  		  printf("Sum overflow");
  		  exit(-1);
  	  }
  	
  	  setBit(i + 1, P);
    }
  }
}

// Returns true if P >= M
int strongly_greater(bigint * P, bigint * M){
  int i;

  for (i = NCHUNKS-1; i >= 0; i--) {
    if(getBit(i, P) < getBit(i, M)) {
      return 0;
    }
  }
  
  return 1;
}

// Performs bitwise P = P - M in place
void sub_inplace(bigint * P, bigint * I) {
  int i;
  int sum = 0;
   
  for (i = BI_SIZE - 1; i >= 0; i--) {
    sum = getBit(i, P) + getBit(i, I);
  if(sum == 0) {
    unsetBit(i, P);
  } else if(sum < 2) {
    setBit(i, P);
  } else {
    setBit(i, P);
  
    if(i == 1023) {
      printf("Sum overflow");
      return;
    }
     
    setBit(i + 1, P);
  }
 }
}

int modMultIlvd(bigint a, bigint b, bigint m, bigint *result) {
  
  // To match Montgomery FPGA paper: 
  bigint *P = result;
  bigint *X = &a;
  bigint *Y = &b;
  bigint *M = &m;
  bigint I; // ok to leave uninitialized, Xi * Y will initialize
  
  int i, j;
  
  // P = 0
  for (i = 0; i < NCHUNKS; i++) {
    P->data[i] = 0;
  }

  for (i = BI_SIZE - 1; i >= 0; i--) {
    // P = 2 * P
    for (j = 0; j < NCHUNKS; j++) {
      P->data[j] = P->data[j] << 1;
    }

    // I = Xi * Y
    for (j = 0; j < NCHUNKS; j++) {
      I.data[(int) floor((float) j/NCHUNKS)] = Y->data[(int) floor((float) j/NCHUNKS)] * getBit(i, X);
    }
    
    // P = P + I
    for (j = 0; j < NCHUNKS; j++) {
      add_inplace(P, &I);
    }    

    // if(P >= M) P = P - M;
    if(strongly_greater(P, M)) {
      sub_inplace(P, M);
    }
   
    // if(P >= M) P = P - M;
    if(strongly_greater(P, M)) {
      sub_inplace(P, M);
    }
    
  }
  
  
  return SUCCESS;
 
}