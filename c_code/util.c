#include <stdio.h>
#include <stdint.h>
#include "rsa.h"
#include "util.h"
#include <ctype.h>

char *hex_chars = "0123456789abcdef";

// returns TRUE if c is in the string "0123456789abcdef"
int isHexChar(char c) {
  for (int i = 0; i < 0x10; i++) {
    if (c == hex_chars[i]) {
      return TRUE;
    }
  }
  return FALSE;
}

// Reads a nibble in hex
uint8_t readHexChar(char c) {
  uint8_t i;
  for (i = 0; i < 0x10; i++) {
    if (c == hex_chars[i]) {
      return i;
    }
  }
  return i;
}

/* Reads a bigint (written in hex) from stream.
 * Discards all non-hex characters before the bigint.
 * After finding a hex character, it reads until
 * it has read enough to fill a bigint, or until
 * it encounters the first non-hex character, or EOF.
 * If EOF is encountered before a hex character is
 * encountered, returns FAIL. Otherwise returns SUCCESS.
 * Leading zeros are discarded unless all digits are 0.
 *
 * Assumes CHUNK_SIZE and BI_SIZE are multiples of 4
 */
int readBigint(FILE *stream, bigint *result) {
  char string[BI_SIZE / 4];
  char c;
  int nchars = 0;
  int startedReading = FALSE;
  int seenNonZero = FALSE;
  do {
    c = tolower(getc(stream));
    if (!startedReading && isHexChar(c)) {
      startedReading = TRUE;
    }
    if (startedReading && isHexChar(c) && (seenNonZero || c != '0')) {
      seenNonZero = TRUE;
      string[nchars] = c;
      nchars++;
    } else if (c == EOF && !startedReading) {
      return FAIL;
    }
  } while (!startedReading || (nchars < BI_SIZE / 4 && isHexChar(c)));

  clearBigint(result);
  if (seenNonZero) {
    int chunk = 0;
    int bit = 0;
    int nibble;
    for (int i = nchars - 1; i >= 0; i--) {
      nibble = readHexChar(string[i]);
      result->data[chunk] |= nibble << bit;
      bit += 4;
      if (bit >= CHUNK_SIZE) {
        bit = 0;
        chunk++;
      }
    }
  }
  return SUCCESS;
}

// Writes a bigint to stream
int writeBigint(FILE *stream, bigint a) {
  return writeBIData(stream, a.data, NCHUNKS);
}

#define writeBIDataMacro(fun_name_param, type_param, chunk_size_param) \
  int fun_name_param(FILE *stream, type_param *data, size_t nChunks) { \
    int firstChunk = TRUE; \
    for (int i = nChunks - 1; i >= 0; i--) { \
      if (!firstChunk || data[i] != 0) { \
        if(firstChunk) { \
          if(0 > fprintf(stream, "%x", data[i])) { \
            return FAIL; \
          } \
        } else { \
          if(0 > fprintf(stream, "%0*x", chunk_size_param / 4, data[i])) { \
            return FAIL; \
          } \
        } \
        firstChunk = FALSE; \
      } \
    } \
    if (firstChunk) { \
      if(0 > fprintf(stream, "0")) { \
        return FAIL; \
      } \
    } \
    return SUCCESS; \
  }

// Writes the data of a bigint to a stream
writeBIDataMacro(writeBIData, CHUNK_T, CHUNK_SIZE)

// Writes the data of a dblbigint to a stream
writeBIDataMacro(writeDBIData, uint32_t, CHUNK_SIZE)
