
/* port of ColumnFormat abstraction / lookup table
 */

int to_row_varint_word( char*buf, word_int val );
int to_io_varint_word( int fd, word_int val );
int to_row_varint_char( char*buf, char* bigint );

int to_row_varuint_word( char*buf, word_uint val );
int to_io_varuint_word( int fd, word_uint val );
int to_row_varuint_char( char*buf, char* bigint );

int to_row_float_double( char*buf, double val );
int to_io_float_double( int fd, double val );

int to_row_bytes( char*buf, char* val );
int to_io_bytes( int fd, char* val );

int to_row_decimal_double( char* buf, double val );
int to_row_decimal_char( char* buf, char* bignum );

int to_row_rational_int( char* buf, int numerator, int denominator );
int to_row_rational_char( char* buf, char* bigrat );

int to_row_false_void(char* buf) { return 0 }
int to_row_true_void(char* buf) { return 0 }
int to_row_null_void(char* buf) { return 0 }

int to_row_lob_void(char* buf, char* sha1);

