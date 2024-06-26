/* per-machine configuration. this file is automatically generated. */
module ode.config;

/* standard system headers */
private import core.stdc.stdio;
private import core.stdc.stdlib;
private import core.stdc.math;
private import core.stdc.stdarg;
//import core.stdc.malloc;
//import core.stdc.float;

extern(C):

/* is this a pentium on a gcc-based platform? */
/* #define PENTIUM 1 -- not a pentium */

/* integer types (we assume int >= 32 bits) */
alias char int8;
alias ubyte uint8;
alias short int16;
alias ushort uint16;
alias int int32;
alias uint uint32;

/* an integer type that we can safely cast a pointer to and
 * from without loss of bits.
 */
alias uint intP;

/* select the base floating point type */
//const int dSINGLE = 1;

/* the floating point infinity */
//const float dInfinity = FLT_MAX;

/* available functions */
/*
alias copysignf copysign;
alias copysign _copysign;
alias snprintf _snprintf;
alias vsnprintf _vsnprintf;
*/
