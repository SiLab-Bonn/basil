#include "myutils.h"
using namespace std;

void debug_print(const char *fmt, ...)
{
	va_list args;
  int     len;
  char    *str;

  va_start(args, fmt);
  len = _vscprintf( fmt, args )+ 1; // _vscprintf doesn't count terminating '\0'
	len ++; // add line feed
  str = (char*)malloc( len * sizeof(char) );
  vsprintf(str, fmt, args);
	str[len-1] = '\r';
  va_end(args);

  OutputDebugString(str);
	free (str);
}



void DebugOutLastError(LPTSTR lpszFunction) 
{ 
    // Retrieve the system error message for the last-error code

    LPVOID lpMsgBuf;
		std::stringstream lpDisplayBuf;
    DWORD dw = GetLastError(); 

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process

		lpDisplayBuf << lpszFunction << ": ERROR " << " (" << (int)dw  << ") "<< (char*)lpMsgBuf; 
		OutputDebugString(lpDisplayBuf.str().c_str());

    LocalFree(lpMsgBuf);
		return;
}