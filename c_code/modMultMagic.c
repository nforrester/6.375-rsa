/* modMultMagic.c 
* 
*
*/
#include "rsa.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "util.h"

//#define DEBUG
const uint32_t UPPER_MASK=  0xFFFF0000;
const uint32_t LOWER_MASK = 0x0000FFFF;

typedef struct {
  uint32_t data[2*NCHUNKS];
} dblbigint;

int mult(bigint a, bigint b, dblbigint *result){
  dblbigint res_tmp = {0};
  int i, j;
  
  for (i = 0; i < NCHUNKS; i++){
    for(j = 0; j < NCHUNKS; j++){
      res_tmp.data[i+j] = (uint32_t)a.data[i] * (uint32_t)b.data[j];
      #ifdef DEBUG
      if(a.data[i]!=0 && b.data[j] != 0)
        printf("res_tmp[%d] = %x * %x = %x\n", 
               i+j, a.data[i], b.data[j], res_tmp.data[i+j]);
      #endif
    }
  }

  // perform carry routine

  for(i = 0; i < NCHUNKS*2-1; i++){
    #ifdef DEBUG
    printf("Before Carry: res[%d]=%x \t  res[%x]=%x \n",
           i+1, res_tmp.data[i+1], i, res_tmp.data[i]);
    #endif
    // carry routine
    res_tmp.data[i+1] += (res_tmp.data[i]) >> 8*sizeof(CHUNK_T); 

    // store lower half only
    result[0].data[i] = (uint32_t)(LOWER_MASK &  res_tmp.data[i]);
    
    #ifdef DEBUG
    printf("res_tmp[%d] = %x \t\t result[%d] = %x \n\n", (i+1),
           res_tmp.data[i+1],i,result[0].data[i]);
    #endif
  }

  return SUCCESS;
}

//return TRUE if a > b
int greaterThan (int* a, int* b) {
  for (int i = NCHUNKS-1; i >= 0; i++){
    #ifdef DEBUG
    printf("a[%d]=%x\tb[%d]=%x\n",i,a[i],i,b[i]);
    #endif
    if(a[i] == b[i] && a[i] == 0) continue;

    if(a[i] > b[i]){

      return TRUE;
    }else {
      return FALSE;
    }
  }
  return FALSE; // error 
}

// a % b = r
int modulo(bigint a, bigint b, bigint *result){
  int32_t num [NCHUNKS] = {0};
  int32_t den [NCHUNKS] = {0};
  int32_t tmp [NCHUNKS] = {0};
  int32_t q;
  int i, j, ptr;
  int res_shifts = 0;
  
  int a_msb = NCHUNKS-1, b_msb = NCHUNKS-1;
  while(a.data[a_msb]==0)a_msb--;
  while(b.data[b_msb]==0)b_msb--;
  #ifdef DEBUG
  printf("initial msb: a_msb = %d \t b_msb= %d \n", a_msb, b_msb);
  #endif
  for(i = 0; i < NCHUNKS; i++){
    num[i] = a.data[i];
    den[i] = b.data[i];
  }


  #ifdef DEBUG
  printf("\nBegining division routine\n");
  #endif
  // begin division routine
  int msb = NCHUNKS-1;

    
  for(ptr = 0; ptr < NCHUNKS; ptr++){
    a_msb = NCHUNKS-1;
    while(num[a_msb]==0  && a_msb>0)a_msb--;
    int offset = a_msb - b_msb;

    q =(int) num[a_msb]/den[b_msb];
    if( q == 0) break;   
    #ifdef DEBUG
    printf("q = %x / %x = %x\n", num[a_msb], den[b_msb], q);
    #endif
      
    for(i = 0; i < NCHUNKS; i++){
      tmp[i+offset] = den[i]*q;
      if ((i+offset)== (NCHUNKS-1)) break;
      #ifdef DEBUG
      if(tmp[i+offset]) 
        printf("tmp[%d] = %x\n",i+offset, tmp[i+offset]);
      #endif
    }
          
    for(i = 0; i < NCHUNKS; i ++){
      num[i] -= tmp[i];
      #ifdef DEBUG
      if(num[i])
        printf("new num[%d] = %x\n", i, num[i]);
      #endif
    }

  }
      
  for(i = 0; i < NCHUNKS; i++){
    result[0].data[i] = num[i];
    #ifdef DEBUG
    if(num[i]) 
      printf("result[%d]=%d\n",i, num[i]);
    #endif 
  }

  return SUCCESS;
}

// a % b = r
int dblmodulo(dblbigint a, bigint b, bigint *result){
  int32_t num [NCHUNKS] = {0};
  int32_t den [NCHUNKS] = {0};
  int32_t tmp [NCHUNKS] = {0};
  int32_t q;
  int i, j, ptr;
  int res_shifts = 0;
  
  int a_msb = NCHUNKS-1, b_msb = NCHUNKS-1;
  while(a.data[a_msb]==0)a_msb--;
  while(b.data[b_msb]==0)b_msb--;
  #ifdef DEBUG
  printf("initial msb: a_msb = %d \t b_msb= %d \n", a_msb, b_msb);
  #endif
  for(i = 0; i < NCHUNKS; i++){
    num[i] = a.data[i];
    den[i] = b.data[i];
  }


  #ifdef DEBUG
  printf("\nBegining division routine\n");
  #endif
  // begin division routine
  int msb = NCHUNKS-1;

    
  for(ptr = 0; ptr < NCHUNKS; ptr++){
    a_msb = NCHUNKS-1;
    while(num[a_msb]==0  && a_msb>0)a_msb--;
    int offset = a_msb - b_msb;

    q =(int) num[a_msb]/den[b_msb];
    if( q == 0) break;   
    #ifdef DEBUG
    printf("q = %x / %x = %x\n", num[a_msb], den[b_msb], q);
    #endif
      
    for(i = 0; i < NCHUNKS; i++){
      tmp[i+offset] = den[i]*q;
      if ((i+offset)== (NCHUNKS-1)) break;
      #ifdef DEBUG
      if(tmp[i+offset]) 
        printf("tmp[%d] = %x\n",i+offset, tmp[i+offset]);
      #endif
    }
          
    for(i = 0; i < NCHUNKS; i ++){
      num[i] -= tmp[i];
      #ifdef DEBUG
      if(num[i])
        printf("new num[%d] = %x\n", i, num[i]);
      #endif
    }

  }
      
  for(i = 0; i < NCHUNKS; i++){
    result[0].data[i] = num[i];
    #ifdef DEBUG
    if(num[i]) 
      printf("result[%d]=%d\n",i, num[i]);
    #endif 
  }

  return SUCCESS;
}

int writeDblbigint(FILE *stream, dblbigint a) {
  return writeBIData(stream, (CHUNK_T*)a.data, 2 * NCHUNKS);
}

// result = (a * b )% m = (a % m) * (b % m) % m
int modMultMagic(bigint a, bigint b, bigint m, bigint *result){
  dblbigint tmp={0};
  bigint a_tmp={0}, b_tmp={0};

  // a % m
  modulo(a, m, &a_tmp);   
  printf("a mod m = ");
  writeBigint(stdout,a_tmp);
  printf("\n");

  // b % m
  modulo(b, m, &b_tmp);
  printf("b mod m = ");
  writeBigint(stdout,b_tmp);
  printf("\n");

  mult(a_tmp, b_tmp, &tmp);
  printf("(a mod m)*(b mod m)= ");
  writeDblbigint(stdout,tmp);
  printf("\n");

  dblmodulo(tmp, m, result);
  printf("(a mod m)*(b mod m) mod m= ");
  printf("\n");
    
  return SUCCESS;
}
