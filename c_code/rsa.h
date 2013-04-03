/* rsa.h
*
* This headerfile will define the function interfaces...tbd
*/

#define SUCCESS 0
#define FAIL 1

#define TRUE 1
#define FALSE 0

#define BI_SIZE 1024 // must be a multiple of 4
#define CHUNK_T uint16_t
#define CHUNK_SIZE (8*sizeof(CHUNK_T)) // must be a multiple of 4
#define NCHUNKS BI_SIZE / CHUNK_SIZE

typedef struct {
  CHUNK_T data[NCHUNKS];
} bigint;

// result = a * b % m = (a % m) * (b % m) % m
int modMultNaive(bigint a, bigint b, bigint m, bigint *result);
int modMultIlvd(bigint a, bigint b, bigint m, bigint *result);
int modMultMagic(bigint a, bigint b, bigint m, bigint *result);

// whichever implementation is best
#define modMult modMultDummy

// result = a << s
int shiftL(bigint a, unsigned int s, bigint *result);

// result = a >> s
int shiftR(bigint a, unsigned int s, bigint *result);

// result = b ^ e % m
int modExpt(bigint b, bigint e, bigint m, bigint *result);

// a == b
int equal(bigint a, bigint b);

// a = 0
void clearBigint(bigint *a);

// result = a
void assign(bigint a, bigint *result);
