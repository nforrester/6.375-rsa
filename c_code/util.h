/* util.h
 *
 * This header file defines function interfaces that
 * aren't really relevant to RSA, but are still needed.
 */

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
int readBigint(FILE *stream, bigint *result);

// Writes a bigint to stream
int writeBigint(FILE *stream, bigint a);

// Writes the data of a bigint to stream
int writeBIData(FILE *stream, CHUNK_T *data, size_t nChunks);

// returns TRUE if c is in the string "0123456789abcdef"
int isHexChar(char c);

// Reads a nibble in hex
uint8_t readHexChar(char c);
