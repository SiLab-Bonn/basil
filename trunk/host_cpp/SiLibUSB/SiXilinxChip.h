//---------------------------------------------------------------------------
#ifndef XilinxChipH
#define XilinxChipH
//---------------------------------------------------------------------------
#ifdef WIN32
  #include <windows.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string>

//--- xilinx configuration USB 1.1 Board ---
#define XP_PROG  0x01  // port c, bit 0
#define XP_DONE  0x02  // port c, bit 1
#define XP_INIT  0x08  // port c, bit 3
#define XP_CS1   0x80  // port c, bit 7

//--- xilinx configuration USB 2.0 Card ---
#define XP_CS1_FX   0x10  // port A, bit 4
#define XP_RDWR_FX  0x08  // port A, bit 3
#define XP_BUSY_FX  0x04  // port A, bit 2
#define XP_PROG_FX  0x02  // port A, bit 1
#define XP_DONE_FX  0x01  // port A, bit 0
//#define XP_INIT_FX  0x08  // port A, bit 3

// disable this line if you want to see Error Message Boxes!
#define AVOID_MSG_BOX

typedef struct _BITSTREAM
{
	unsigned char dummy; // 11111111
	unsigned char lengthcount3; // 0010 preamble + lengthcount[23-20]
	unsigned char lengthcount2; // lengthcount[19-12]
	unsigned char lengthcount1; // lengthcount[11-4]
	unsigned char lengthcount0; // lengthcount[3-0] + 1111 postamble
	unsigned char *data;
	int  lengthcount;
	int  size;
} BIT_STREAM, *PBIT_STREAM;

typedef struct _HEADERSTRING
{
	char index[1];
	int  length;
	char data[64];
} HEADER_STRING, *PHEADER_STRING;

class TXilinxChip{
public:
	TXilinxChip(int ctrlType);
	~TXilinxChip();
	FILE *bitfile;
	HEADER_STRING name;
	HEADER_STRING type;
	HEADER_STRING date;
	HEADER_STRING time;
	BIT_STREAM    bitstream;
	bool DownloadXilinx(std::string fname);

	bool ReadBitStream(const char *filename);

	bool ReadHeaderString(PHEADER_STRING phs);
	// virtuals:
	virtual bool InitXilinxConfPort() = 0;
	virtual bool SetXilinxConfPin(unsigned char pin, unsigned char data) = 0;
	virtual bool GetXilinxConfPin(unsigned char pin) = 0;
	virtual bool WriteXilinxConfData(unsigned char *data, int length) = 0;
	virtual bool SetXilinxConfByte(unsigned char data) = 0;
	virtual unsigned char GetXilinxConfByte(void) = 0;

	unsigned char xp_cs1;
	unsigned char xp_rdwr;
	unsigned char xp_busy;
	unsigned char xp_prog;
	unsigned char xp_done;
	unsigned char xp_init;
private:
	int ControllerType;
protected:
};
#endif

