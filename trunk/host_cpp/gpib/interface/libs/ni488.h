/* $Header: */
/*---------------------------------------------------------------------------*/
/* Distributed by Agilent Technologies                                       */
/*                                                                           */
/* Do not modify the contents of this file.                                  */
/*---------------------------------------------------------------------------*/
/*                                                                           */
/* Title   : AGT488.H or NI488.H                                             */
/* Date    : 02-03-2005                                                      */
/* Purpose : Include file for Agilent 488 API support                        */
/*                                                                           */
/*---------------------------------------------------------------------------*/

#ifndef NI488_H
#define NI488_H


#if defined(__cplusplus) || defined(__cplusplus__)
   extern "C" {
#endif

/*- GPIB command byte definitions -------------------------------------------*/
#define UNL 0x3f /* unlisten command */
#define UNT 0x5f /* untalk command */
#define GTL 0x01 /* goto local */
#define SDC 0x04 /* selected device clear */
#define PPC 0x05 /* parallel poll configure */
#define GET 0x08 /* group execute trigger */
#define TCT 0x09 /* take control */
#define LLO 0x11 /* local lock-out */
#define DCL 0x14 /* device clear */
#define PPU 0x15 /* parallel poll unconfigure */
#define SPE 0x18 /* serial poll enable */
#define SPD 0x19 /* serial poll disable */
#define PPE 0x60 /* parallel poll enable */
#define PPD 0x70 /* parallel poll disable */

/*- ibsta (Global status variable) bit definitions --------------------------*/
#define ERR  (1<<15) /* Error detected */
#define TIMO  (1<<14) /* Timeout occurred */
#define END  (1<<13) /* EOI or EOS detected */
#define SRQI (1<<12) /* SRQ detected by controller */
#define RQS  (1<<11) /* Device request (assert SRQ) */
#define CMPL (1<<8)  /* IO Completed */
#define LOK  (1<<7)  /* Local Lockout */
#define REM  (1<<6)  /* Remote state */
#define CIC  (1<<5)  /* Controller in Charge */
#define ATN  (1<<4)  /* Attention line asserted */
#define TACS (1<<3)  /* Talker active */
#define LACS (1<<2)  /* Listener active */
#define DTAS (1<<1)  /* Device trigger state */
#define DCAS (1<<0)  /* Device clear state */

/*- iberr (Global error variable) error definitions -------------------------*/
#define EDVR 0       /* System Error */
#define ECIC 1       /* Interface not Controller in Charge */
#define ENOL 2       /* No listeners */
#define EADR 3       /* Interface not addressed correctly */
#define EARG 4       /* Invalid argument */
#define ESAC 5       /* Interface not System Controller */
#define EABO 6       /* IO aborted */
#define ENEB 7       /* Interface not present */
#define EDMA 8       /* DMA error */
#define EOIP 10      /* Async IO operation not complete */
#define ECAP 11      /* Not capable of requested operation */
#define EFSO 12      /* File system error */
#define EBUS 14      /* Command error during device call */
#define ESTB 15      /* Serial status byte lost */
#define ESRQ 16      /* SRQ line still asserted */
#define ETAB 20      /* Return buffer is full */
#define ELCK 21      /* Address or interface is locked */
#define EARM 22      /* ibnotify callback did not rearm */
#define EHDL 23      /* Handle invalid */
#define EWIP 26      /* Wait in progress */
#define ERST 27      /* Event notification canceled on reset */
#define EPWR 28      /* Interface power loss or entered standby mode */

/*- iberr (Global error variable) warning definitions -----------------------*/
#define WCFG 24      /* Configuration warning */
#define ECFG WCFG

/*- EOS (termination character) bit definitions -----------------------------*/
#define BIN (1<<12)  /* Compare eight bits of termination character */
#define XEOS (1<<11) /* Set EOI signal with EOS byte */
#define REOS (1<<10) /* Terminate read on EOS */

/*- Timeout value definitions -----------------------------------------------*/
#define TNONE   0      /* Infinite timeout */
#define T10us   1      /* 10 uSec timeout */
#define T30us   2      /* 30 uSec timeout */
#define T100us  3      /* 100 uSec timeout */
#define T300us  4      /* 300 uSec timeout */
#define T1ms    5      /* 1 mSec timeout */
#define T3ms    6      /* 3 mSec timeout */
#define T10ms   7      /* 10 mSec timeout */
#define T30ms   8      /* 30 mSec timeout */
#define T100ms  9      /* 100 mSec timeout */
#define T300ms  10     /* 300 mSec timeout */
#define T1s     11     /* 1 sec timeout */
#define T3s     12     /* 3 sec timeout */
#define T10s    13     /* 10 sec timeout */
#define T30s    14     /* 30 sec timeout */
#define T100s   15     /* 100 sec timeout */
#define T300s   16     /* 300 sec timeout */
#define T1000s  17     /* 1000 sec timeout */

/*- ibln (detect listeners) constant definitions  ---------------------------*/
#define NO_SAD  0      /* don't query secondary addresses */
#define ALL_SAD -1     /* query secondary addresses */

/*- ibconfig constant definitions  ------------------------------------------*/
#define IbcPAD       0x0001         /* Primary address */
#define IbcSAD       0x0002         /* Secondary address */
#define IbcTMO       0x0003         /* Timeout value */
#define IbcEOT       0x0004         /* Toggle EOI with last data byte */
#define IbcPPC       0x0005         /* Parallel Poll config */
#define IbcREADDR    0x0006         /* Toggle repeat addressing */
#define IbcAUTOPOLL  0x0007         /* Toggle Auto-Serial poll */
#define IbcCICPROT   0x0008         /* Obsolete? use controller-in-charge protocol */
#define IbcIRQ       0x0009         /* Toggle use of hardware interrupts */
#define IbcSC        0x000A         /* Toggle interface System Controller state */
#define IbcSRE       0x000B         /* Toggle REN line */
#define IbcEOSrd     0x000C         /* Toggle read termination on EOS char */
#define IbcEOSwrt    0x000D         /* Toggle EOI-with-EOS char */
#define IbcEOScmp    0x000E         /* Toggle 7/8 bit compares on EOS char */
#define IbcEOSchar   0x000F         /* Set EOS char */
#define IbcPP2       0x0010         /* Local Parallel Poll configuration */
#define IbcTIMING    0x0011         /* Set TI delay for writes */
#define IbcDMA       0x0012         /* Toggle DMA use */
#define IbcReadAdjust 0x0013        /* Swap bytes during reads */
#define IbcWriteAdjust 0x0014       /* Swap bytes during writes */
#define IbcSendLLO   0x0017         /* Toggle sending LLO  */
#define IbcSPollTime 0x0018         /* Set timeout for serial polls */
#define IbcPPollTime 0x0019         /* Set parallel poll duration */
#define IbcEndBitIsNormal  0x001A   /* Remove EOS from END bit of IBSTA */
#define IbcUnAddr    0x001B         /* Toggle sending unaddressing after IO */
#define IbcSignalNumber    0x001C   /* Set Unix signal number - unsupported */
#define IbcBlockIfLocked   0x001D   /* Toggle blocking for locked intf/devs */
#define IbcHSCableLength   0x001F   /* Lenth of cable specified for HS timing */
#define IbcIst       0x0020         /* Set parallel poll individual status bit */
#define IbcRsv       0x0021         /* Set serial poll response byte */
#define IbcLON       0x0022         /* Set Listen-Only state */

/*- ibask constant definitions  ---------------------------------------------*/
#define  IbaPAD         IbcPAD
#define  IbaSAD         IbcSAD
#define  IbaTMO         IbcTMO
#define  IbaEOT         IbcEOT
#define  IbaPPC         IbcPPC
#define  IbaREADDR      IbcREADDR
#define  IbaAUTOPOLL    IbcAUTOPOLL
#define  IbaCICPROT     IbcCICPROT
#define  IbaIRQ         IbcIRQ
#define  IbaSC          IbcSC
#define  IbaSRE         IbcSRE
#define  IbaEOSrd       IbcEOSrd
#define  IbaEOSwrt      IbcEOSwrt
#define  IbaEOScmp      IbcEOScmp
#define  IbaEOSchar     IbcEOSchar
#define  IbaPP2         IbcPP2
#define  IbaTIMING      IbcTIMING
#define  IbaDMA         IbcDMA
#define  IbaReadAdjust  IbcReadAdjust
#define  IbaWriteAdjust IbcWriteAdjust
#define  IbaSendLLO     IbcSendLLO
#define  IbaSPollTime   IbcSPollTime
#define  IbaPPollTime   IbcPPollTime
#define  IbaEndBitIsNormal IbcEndBitIsNormal
#define  IbaUnAddr      IbcUnAddr
#define  IbaSignalNumber   IbcSignalNumber
#define  IbaBlockIfLocked  IbcBlockIfLocked
#define  IbaHSCableLength  IbcHSCableLength
#define  IbaIst         IbcIst
#define  IbaRsv         IbcRsv
#define  IbaLON         IbcLON
#define  IbaSerialNumber   0x0023
#define  IbaBNA         0x0200

/*- "Send" (Multi-Device function) constant definitions ---------------------*/
#define  NULLend  0x00  /* EOI not asserted with last byte sent */
#define  NLend    0x01  /* EOI and New Line character sent as last byte */
#define  DABend   0x02  /* EOI asserted with last byte sent */

/*- "Receive" (Multi-Device function) constant definitions-------------------*/
#define  STOPend  0x0100   /* terminate read when EOI is detected */

/*- iblines constant definitions --------------------------------------------*/
#define ValidEOI     (short)0x0080
#define ValidATN     (short)0x0040
#define ValidSRQ     (short)0x0020
#define ValidREN     (short)0x0010
#define ValidIFC     (short)0x0008
#define ValidNRFD    (short)0x0004
#define ValidNDAC    (short)0x0002
#define ValidDAV     (short)0x0001
#define BusEOI       (short)0x8000
#define BusATN       (short)0x4000
#define BusSRQ       (short)0x2000
#define BusREN       (short)0x1000
#define BusIFC       (short)0x0800
#define BusNRFD      (short)0x0400
#define BusNDAC      (short)0x0200
#define BusDAV       (short)0x0100

/*- ibnotify callback definition --------------------------------------------*/
typedef int (__stdcall * GpibNotifyCallback_t)(int, int, int, long, void *);

/*
/*- GPIB Address related definitions ----------------------------------------*/
/* 

/*- Address type definition -------------------------------------------------*/
typedef short Addr4882_t;

/* Create an Addr488_t from primary and secondary addresses -  --------------*/ 
#define MakeAddr(pad, sad)   ((Addr4882_t)(((pad)&0xFF) | ((sad)<<8)))

/*- Address List terminator definitions -------------------------------------*/
#ifndef NOADDR
#define NOADDR   (Addr4882_t)((unsigned short)0xFFFF)
#endif

/*- Retrieve GPIB address from Addr4882_t element ---------------------------*/
#define GetPAD(val)   ((val) & 0xFF)
#define GetSAD(val)   (((val) >> 8) & 0xFF)

/*- iblockx/ibunlockx constant definitions ----------------------------------*/
#define TIMMEDIATE -1
#define TINFINITE  -2
#define MAX_LOCKSHARENAME_LENGTH 64

#if !defined(GPIB_DIRECT_ACCESS)

/*- Global variables  -------------------------------------------------------*/
extern int ibsta;
extern int iberr;
extern int ibcnt;
extern long ibcntl;

/*- Functions to access thread-local copies of global variable --------------*/
extern int __stdcall ThreadIbsta(void);
extern int __stdcall ThreadIberr(void);
extern int __stdcall ThreadIbcnt(void);
extern int __stdcall ThreadIbcntl(void);

/*- Traditional single device function calls --------------------------------*/
#if defined(UNICODE)
   #define ibbna   ibbnaW
   #define ibfind  ibfindW
   #define ibrdf   ibrdfW
   #define ibwrtf  ibwrtfW
   #define iblockx iblockxW
#else
   #define ibbna   ibbnaA
   #define ibfind  ibfindA
   #define ibrdf   ibrdfA
   #define ibwrtf  ibwrtfA
   #define iblockx iblockxA
#endif
                       
extern int __stdcall ibask(int ud, int option, int *retVal);
extern int __stdcall ibbnaA(int ud, LPCSTR boardname);     /* Ansi version */
extern int __stdcall ibbnaW(int ud, LPCWSTR boardname);     /* Unicode version */
extern int __stdcall ibcac(int ud, int sync); 
extern int __stdcall ibclr(int ud);
extern int __stdcall ibcmd(int ud, void *commands, long count);
extern int __stdcall ibcmda(int ud, void *commands, long count);
extern int __stdcall ibconfig(int ud, int option, int setting);
extern int __stdcall ibdev(int board_index, int pad, int sad, int timeout, int eoi, int eos);
extern int __stdcall ibdiag(int ud, void *buf, long count);
extern int __stdcall ibdma(int ud, int flag);
extern int __stdcall ibexpert(int ud, int option, void *input, void *output);
extern int __stdcall ibeos(int ud, int eosmode);
extern int __stdcall ibeot(int ud, int eoimode);
extern int __stdcall ibfindA(LPCSTR boardname);            /* Ansi Version */
extern int __stdcall ibfindW(LPCWSTR boardname);           /* Unicode Version */
extern int __stdcall ibgts(int ud, int shadow_handshake);
extern int __stdcall ibist(int ud, int ist);
extern int __stdcall iblines(int ud, short *result);
extern int __stdcall ibln(int ud, int pad, int sad, short *result);
extern int __stdcall iblck(int ud, int flag, unsigned int LockWaitTime, void * reserved);
extern int __stdcall ibloc(int ud);
extern int __stdcall iblockxA(int ud, int LockWaitTime, LPCSTR name); /* Ansi Version */
extern int __stdcall iblockxW(int ud, int LockWaitTime, LPCWSTR name); /* Unicode Version */
extern int __stdcall ibnotify (int ud, int mask, GpibNotifyCallback_t callback, PVOID refData);
extern int __stdcall ibonl(int ud, int online);
extern int __stdcall ibpad(int ud, int pad);
extern int __stdcall ibpct(int ud);
extern int __stdcall ibpoke(int ud, long option, long flag);
extern int __stdcall ibppc(int ud, int configuration);
extern int __stdcall ibrd(int ud, void *buf, long count);
extern int __stdcall ibrda(int ud, void *buf, long count);
extern int __stdcall ibrdfA(int ud, LPCSTR filename);      /* Ansi Version */
extern int __stdcall ibrdfW(int ud, LPCWSTR filename);      /* Unicode Version */
extern int __stdcall ibrdkey(int ud, void *buf, int count);
extern int __stdcall ibrpp(int ud, char *ppoll_result);
extern int __stdcall ibrsc(int ud, int flag);
extern int __stdcall ibrsp(int ud, char *spoll_result);
extern int __stdcall ibrsv(int ud, int status_byte);
extern int __stdcall ibsad(int ud, int sad);
extern int __stdcall ibsic(int ud);
extern int __stdcall ibsre(int ud, int flag);
extern int __stdcall ibstop(int ud);
extern int __stdcall ibtmo(int ud, int timeout);
extern int __stdcall ibtrg(int ud);
extern int __stdcall ibunlockx(int ud);
extern int __stdcall ibwait(int ud, int mask);
extern int __stdcall ibwrt(int ud, void *buf, long count);
extern int __stdcall ibwrta(int ud, void *buf, long count);
extern int __stdcall ibwrtfA(int ud, LPCSTR filename);     /* Ansi Version    */
extern int __stdcall ibwrtfW(int ud, LPCWSTR filename);     /* Unicode Version */
extern int __stdcall ibwrtkey(int ud, void *buf, int count);

/*- GPIB-ENET calls - deprecated --------------------------------------------*/
extern int __stdcall iblock(int ud);
extern int __stdcall ibunlock(int ud);

/*- Multi-device function calls ---------------------------------------------*/
extern void __stdcall AllSpoll(int boardID, Addr4882_t *addressList, short *resultList);
extern void __stdcall DevClear(int boardID, Addr4882_t address);
extern void __stdcall DevClearList(int boardID, Addr4882_t *addressList);
extern void __stdcall EnableLocal(int boardID, Addr4882_t *addressList);
extern void __stdcall EnableRemote(int boardID, Addr4882_t *addressList);
extern void __stdcall FindLstn(int boardID, Addr4882_t *padList, short *resultList, int maxResults);
extern void __stdcall FindRQS(int boardID, Addr4882_t *addressList, short *statusByte);
extern void __stdcall PassControl(int boardID, Addr4882_t address);
extern void __stdcall PPoll(int boardID, short *result);
extern void __stdcall PPollConfig(int boardID, Addr4882_t address, int dataline, int lineSense);
extern void __stdcall PPollUnconfig(int boardID, Addr4882_t *addressList);
extern void __stdcall RcvRespMsg(int boardID, void *buf, long count, int termination);
extern void __stdcall ReadStatusByte(int boardID, Addr4882_t address, short *statusByte);
extern void __stdcall Receive(int boardID, Addr4882_t address, void *buffer, long count, int termination);
extern void __stdcall ReceiveSetup(int boardID, Addr4882_t address);
extern void __stdcall ResetSys(int boardID, Addr4882_t *addressList);
extern void __stdcall Send(int boardID, Addr4882_t address, void *buf, long count, int eotMode);
extern void __stdcall SendCmds(int boardID, void *commands, long count);
extern void __stdcall SendDataBytes(int boardID, void *buf, long count, int eotMode);
extern void __stdcall SendIFC(int boardID);
extern void __stdcall SendList(int boardID, Addr4882_t *addressList, void *buf, long count, int eotMode);
extern void __stdcall SendLLO(int boardID);
extern void __stdcall SendSetup(int boardID, Addr4882_t *addressList);
extern void __stdcall SetRWLS(int boardID, Addr4882_t *addressList);
extern void __stdcall TestSRQ(int boardID, short *result);
extern void __stdcall TestSys(int boardID, Addr4882_t *addressList, short *results);
extern void __stdcall Trigger(int boardID, Addr4882_t address);
extern void __stdcall TriggerList(int boardID, Addr4882_t *addressList); 
extern void __stdcall WaitSRQ(int boardID, short *result);

#endif /* !defined(GPIB_DIRECT_ACCESS) */

#if defined(__cplusplus) || defined(__cplusplus__)
   }
#endif

#endif   /* #ifndef NI488_H */
