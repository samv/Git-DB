#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "Encode.h"

char* _ber_int( int num ) {
  
}

MODULE = Git::DB::Encode PACKAGE = Git::DB::Encode
  
SV*
  encode_int
INPUT:
  int *num
	
