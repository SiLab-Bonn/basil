#ifndef MYUTILS_H
#define MYUTILS_H 1

#include <iostream>
#include <sstream>
#include <iomanip>
#include <windows.h>
#include <stdarg.h>


#ifdef DEBUG
#define DBGOUT(s)            \
{                             \
   std::ostringstream os;    \
   os << s;                   \
   OutputDebugString( os.str().c_str() );  \
} 
#else
#define DBGOUT(...) ((void)0)
#endif

void debug_print(const char *fmt, ...);
void DebugOutLastError(LPTSTR lpszFunction);



#endif