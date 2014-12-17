#include "SiXilinxChip.h"
#include "SiUSBDevice.h"

TXilinxChip::TXilinxChip(int cType)
{
	ControllerType = cType;

	if (ControllerType == FX2) {
		xp_cs1  = XP_CS1_FX;
		xp_rdwr = XP_RDWR_FX;
		xp_busy = XP_BUSY_FX;
		xp_prog = XP_PROG_FX;
		xp_done = XP_DONE_FX;
	} else {
		xp_cs1  = XP_CS1;
		xp_init = XP_INIT;
		xp_prog = XP_PROG;
		xp_done = XP_DONE;
	}
}

TXilinxChip::~TXilinxChip()
{
}

bool 
TXilinxChip::ReadBitStream(const char *filename)
{
	char filepreamble[10];
	bool isNormalMode;
	bool isExpressMode;
	bool isSelectMapMode;
	int  datastart = 0;
	char tbuf[4];
	char textbuffer[255];
	int nBytes;

	/* expected file header to check bit file versions */
	const unsigned char FILE_PREAMBLE_V21[] =
	{0x0a, 0x09, 0x0f, 0xf0, 0x0f, 0xf0, 0x0f, 0xf0, 0x0f, 0xf0, 0x00, 0x01};
	const unsigned char FILE_PREAMBLE_V23[] =
	{0x00, 0x09, 0x0f, 0xf0, 0x0f, 0xf0, 0x0f, 0xf0, 0x0f, 0xf0, 0x00, 0x01};

	/* data preamble marks beginning of configuration data */
	const unsigned char DATA_PREAMBLE_NORMALMODE[]  = {0xff, 0x20};
	const unsigned char DATA_PREAMBLE_EXPRESSMODE[] = {0xff, 0xff, 0xf2};
	const unsigned char DATA_PREAMBLE_SELECTMAP[] = {0xff, 0xff, 0xff, 0xff};
	
	*(name.index) = 'a';
	*(type.index) = 'b';
	*(date.index) = 'c';
	*(time.index) = 'd';

	if ((bitfile = fopen(filename, "rb")) == NULL) {
		sprintf(textbuffer, "File %s not found!", filename);
#ifndef AVOID_MSG_BOX
		ShowLastError(NULL, textbuffer, "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
		return false;
	}

	fread(filepreamble, 1, sizeof(filepreamble), bitfile);

	// check version
	if (strncmp(filepreamble, (const char *) FILE_PREAMBLE_V21, sizeof(filepreamble)) != 0 && // ver. 2.1
		strncmp(filepreamble, (const char *) FILE_PREAMBLE_V23, sizeof(filepreamble)) != 0 )  // ver. 2.3
	{
#ifndef AVOID_MSG_BOX
		ShowLastError(NULL, "Wrong file format!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
		fclose(bitfile);
		return false;
	}
	/* LUNUX DEBUG
	for (int ii=0;ii< sizeof(filepreamble); ii++) 
	printf(" %d =  %x (v21=%x) (v23=%x) \n",ii
	,filepreamble[ii],FILE_PREAMBLE_V21[ii],FILE_PREAMBLE_V23[ii]);
	*/

	/* read header information about the lca file */
	if (!(ReadHeaderString(&name) && ReadHeaderString(&type) &&
		ReadHeaderString(&date) && ReadHeaderString(&time))) {

#ifndef AVOID_MSG_BOX
		ShowLastError(NULL, "Wrong file format!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
		fclose(bitfile);

		return false;
	}

	/* look for beginning of config data (data preamble) */
	do {
		datastart = ftell(bitfile);                 // current position in file

		if ((fread(tbuf, sizeof(tbuf), 1, bitfile) == 0) || datastart > 300) {
#ifndef AVOID_MSG_BOX
			ShowLastError(NULL, "Preamble not found!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
			fclose(bitfile);
			return false;
		}

		fseek(bitfile, 1 - sizeof(tbuf) , SEEK_CUR);   // n steps forward (1-n) steps back

		isNormalMode     = !strncmp(tbuf, (const char *) DATA_PREAMBLE_NORMALMODE, 2);
		isExpressMode    = !strncmp(tbuf, (const char *) DATA_PREAMBLE_EXPRESSMODE, 3);
		isSelectMapMode  = !strncmp(tbuf, (const char *) DATA_PREAMBLE_SELECTMAP, sizeof(DATA_PREAMBLE_SELECTMAP));
	}
	while (!isNormalMode && !isExpressMode && !isSelectMapMode);

	// rewind file to the entry point of the config data
	// and read data preamble to see how much data we have (length count)
	fseek(bitfile, datastart, SEEK_SET);


	//---- XILINX configuration structure  *NORMAL MODE* --------
	//
	//       11111111              - 8 dummy bits 0xff
	//       0010                  - preamble     0x2
	//       [24 bit lengthcount]  - configuration stream length
	//       1111                  - dummy bits   0xf
	//       start of config data...
	//
	//       5 unsigned char data header
	//-----------------------------------------------------------

	//---- XILINX configuration structure  *EXPRESS MODE* --------
	//       (for SPARTAN XL only)
	//
	//       1111111111111111      - 16 fill bits 0xffff
	//       11110010              - preamble     0xf2
	//       [24 bit lengthcount]  - configuration stream length
	//       11010010              - field check  0xd2
	//       start of config data...
	//
	//       7 unsigned char data header
	//-----------------------------------------------------------


	//---- XILINX configuration structrure  *SELECTMAP MODE* ----
	//       (for SPARTAN IIE an SPARTAN 3)
	//
	//     [24 bit lenghtcount]   - configuration stream lenght in bytes
	//     0xffffffff             - fill bits
	//     configuration data...
	//
	//------------------------------------------------------------

	if (isExpressMode) {
		// start with reading dummy unsigned char, preamble and length information
		fread(&(bitstream.dummy)       , 1, 1, bitfile);
		fread(&(bitstream.dummy)       , 1, 1, bitfile);
		fread(&(bitstream.dummy)       , 1, 1, bitfile);
		fread(&(bitstream.lengthcount2), 1, 1, bitfile);
		fread(&(bitstream.lengthcount1), 1, 1, bitfile);
		fread(&(bitstream.lengthcount0), 1, 1, bitfile);
		// calculate length count (number of *bits*)
		bitstream.lengthcount = (bitstream.lengthcount2 << 16) +
			(bitstream.lengthcount1 << 8)  +
			bitstream.lengthcount0;
		bitstream.lengthcount =  bitstream.lengthcount & 0xffffff;
		// count in bytes (calculated from file size because express mode adds
		// extra conig bit which are not included in lengthcount

		bitstream.size = bitstream.lengthcount/8 + 1;    //   27632

		// rewind once again to read the whole config data array
		fseek(bitfile, datastart - 1, SEEK_SET);

		// allocate memory for config data
		bitstream.data = (unsigned char *) malloc(bitstream.size);
		nBytes = fread(bitstream.data, 1, bitstream.size, bitfile);
		fclose(bitfile);
		if (nBytes != bitstream.size) 
			return false;

		return true;
	} else {
		if (isNormalMode) {
			// start with reading dummy unsigned char, preamble and length information
			fread(&(bitstream.dummy)       , 1, 1, bitfile);
			fread(&(bitstream.lengthcount3), 1, 1, bitfile);
			fread(&(bitstream.lengthcount2), 1, 1, bitfile);
			fread(&(bitstream.lengthcount1), 1, 1, bitfile);
			fread(&(bitstream.lengthcount0), 1, 1, bitfile);
			// calculate length count (number of *bits*)
			bitstream.lengthcount = (bitstream.lengthcount3 << 24) +
				(bitstream.lengthcount2 << 16) +
				(bitstream.lengthcount1 << 8)  +
				bitstream.lengthcount0;
			bitstream.lengthcount = (bitstream.lengthcount >> 4) & 0xffffff;
			// count in bytes
			bitstream.size = bitstream.lengthcount/8;

			// rewind once again to read the whole config data array
			fseek(bitfile, datastart - 1, SEEK_SET);

			// allocate memory for config data
			bitstream.data = (unsigned char *) malloc(bitstream.size);
			nBytes = fread(bitstream.data, 1, bitstream.size, bitfile);
			fclose(bitfile);
			if (nBytes != bitstream.size)
				return false;

			return true;
		} else {
			if (isSelectMapMode) {
				// rewind 3 bytes to read lenght information
				fseek(bitfile, datastart - 3, SEEK_SET);
				fread(&(bitstream.lengthcount2), 1, 1, bitfile);
				fread(&(bitstream.lengthcount1), 1, 1, bitfile);
				fread(&(bitstream.lengthcount0), 1, 1, bitfile);
				bitstream.size = (bitstream.lengthcount2 << 16) +
					(bitstream.lengthcount1 << 8)  +
					bitstream.lengthcount0;

				// rewind once again to read the whole config data array
				fseek(bitfile, datastart, SEEK_SET);

				// allocate memory for config data
				bitstream.data = (unsigned char *) malloc(bitstream.size);
				nBytes = fread(bitstream.data, 1, bitstream.size, bitfile);
				fclose(bitfile);
				if (nBytes != bitstream.size) {
					return false;
				}

				return true;
			}
		}
	}

	return false;
}

bool
TXilinxChip::ReadHeaderString(PHEADER_STRING phs)
{
	char index;
	int nBytes;
	unsigned char dummy;

	do {
		nBytes = fread(&index, 1, 1, bitfile);
		if (nBytes == 0)
		{
#ifndef AVOID_MSG_BOX
			ShowLastError(NULL, "Unexpected end of file!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
			return false;
		}
	}  while (strncmp(&index, phs->index, 1));

	fseek(bitfile, SEEK_CUR, 1); /* skipp NULL char */

	nBytes = fread(&dummy, 1, 1, bitfile);
	phs->length = dummy;

	if (nBytes == 0) {
#ifndef AVOID_MSG_BOX
		ShowLastError(NULL, "Unexpected end of file!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
		return false;
	}

	nBytes = fread(&(phs->data), phs->length, 1, bitfile);

	if (nBytes == 0) {
#ifndef AVOID_MSG_BOX
		ShowLastError(NULL, "Unexpected end of file!", "TXilinxChip::ReadBitstream", MB_OK | MB_ICONEXCLAMATION);
#endif
		return false;
	}
	return true;
}

/*
 * pin functions for download
 *
 *    signal    dir    func
 *    INIT     read    signals ready(1)/error(0)
 *    PROG     write   clear config data, active low
 *    DONE     read    device active, active high
 *    CS1      write   selects express config mode, active high
 */
bool
TXilinxChip::DownloadXilinx(std::string filename)
{
	/* Read bitstream */
	if (!ReadBitStream((char*)filename.c_str())) {
		free (bitstream.data);

		return false;
	}

	/* Set up port lines */
	if (!InitXilinxConfPort()) 
	{
		free (bitstream.data);
		return false;
	}

	if (ControllerType == FX2) 
	{
		unsigned char conf_reg = 0;

		/* enable write */
		conf_reg |=  xp_cs1;      // cs_b = 1
		conf_reg &= ~xp_rdwr;     // write_b = 0
		conf_reg |=  xp_prog;     // prog_b = 1

		SetXilinxConfByte(conf_reg);

		/* prog_b = 0 assert for at least 500ns */
		conf_reg |=  xp_cs1;   // cs_b = 1
		conf_reg &= ~xp_rdwr;  // write_b = 0
		conf_reg &= ~xp_prog;  // prog_b = 0

		SetXilinxConfByte(conf_reg);

		/* prog_b = 1 */
		conf_reg |=  xp_cs1;   // cs_b = 1
		conf_reg &= ~xp_rdwr;  // write_b = 0
		conf_reg |=  xp_prog;  // prog_b = 1

		SetXilinxConfByte(conf_reg);

		/* cs_b = 0 */
		conf_reg &= ~xp_cs1;   // cs_b = 0
		conf_reg &= ~xp_rdwr;  // write_b = 0
		conf_reg |=  xp_prog;  // prog_b = 1

		SetXilinxConfByte(conf_reg);

		if (!WriteXilinxConfData(bitstream.data, bitstream.size)) 
		{
			free (bitstream.data);
			return false;
		}

#ifdef WIN32
		Sleep(10); 
#else
		usleep(10000);  // checkit !!
#endif

		/* cs_b = 1 */
		conf_reg |=  xp_cs1;   // cs_b = 1
		conf_reg &=  ~xp_rdwr;  // write_b = 0
		conf_reg |=  xp_prog;  // prog_b = 1

		SetXilinxConfByte(conf_reg);

		// write_b = 1 (default condition)
		conf_reg |=  xp_cs1;   // cs_b = 1
		conf_reg |=  xp_rdwr;  // write_b = 1
		conf_reg |=  xp_prog;  // prog_b = 1

		SetXilinxConfByte(conf_reg);
	} 
	else // non FX2 device
	{
		/* reset device, clear config data */
		SetXilinxConfPin(xp_prog, 0);
		SetXilinxConfPin(xp_prog, 1);

#ifdef WIN32
		Sleep(100);
#else
		usleep(100000);
#endif

		/* check if device is ready to accept data */
		if(GetXilinxConfPin(xp_init) != 1) 
		{
			free (bitstream.data);
			return false;
		}

		/* select express download mode */
		SetXilinxConfPin(xp_cs1, 1);

		/* now send the data */
		if (!WriteXilinxConfData(bitstream.data, bitstream.size)) 
		{
			free (bitstream.data);
			return false;
		}

		/* de-select express download mode */
		SetXilinxConfPin(xp_cs1, 0);
	}

	/* check if device has become active */
	if (GetXilinxConfPin(xp_done) != 1) {
		free (bitstream.data);
		return false;
	}

	free (bitstream.data);
	return true;
}
