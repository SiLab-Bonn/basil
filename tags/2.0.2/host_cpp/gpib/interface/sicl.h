/* Copyright 1992-2005 Agilent Technologies Inc.  All Rights Reserved. */
/*
 * Agilent Standard Instrument Control Library
 *
 * This file conforms to the Agilent SICL Spec as specified in I_SICL_REVISION.
 *
 * #define's used (can be #defined by user):
 *   STD_SICL - Disallows non-standard constructs
 *
 * #define's used (not typically set by user)
 *   SICL_H - Prevents multiple inclusion
 *   SICL_NOPROTO - Don't include function prototypes
 *   
 */

/*
 * Make sure this file is only included once
 */
#if !defined(SICL_H)
#define SICL_H

/*
 * determine which OS we are compiling on
 * Don't use #elif here, some bug in std cpp on hpux. DTS ISLxx14032
 */
#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__)
#define _SICL_WIN32
#if !defined(__BORLANDC__)
#define _SICL_VXI_D64
#endif
#else
#if defined(__MSDOS__)||defined(MSDOS)||defined(_MSDOS)||defined(_WINDOWS)
#define _MS_DOS_WIN
#endif
#endif

#if defined(__hpux)
#define _SICL_HPUX
#if defined(__cplusplus)
#define volatile
#endif
#endif
#if defined(__Lynx__) && defined(__68k__)
#define _SICL_LYNX_BE
#endif
#if defined(__Lynx__) && defined(__x86__)
#define _SICL_LYNX_LE
#define _SICL_LYNX_FA			/* This is for Lynx on Fantasia */
#endif
#if defined(linux)
#if (__BYTE_ORDER == __LITTLE_ENDIAN)
#define _SICL_LINUX_LE
#elif (__BYTE_ORDER == __BIG_ENDIAN) /* (__BYTE_ORDER == __LITTLE_ENDIAN) */
#define _SICL_LINUX_BE
#endif /* (__BYTE_ORDER == __LITTLE_ENDIAN) */
#endif

/*
 * define out Windows specific keywords if not compiling for Windows
 */
#if !defined(_MS_DOS_WIN)
#define _near
#define _far
#define _huge
#define _pascal
#define _export
#endif


/*
 * define SICLAPI, SICLAPIV, and SICLCALLBACK appropriately
 */
#if defined(_SICL_WIN32)
#define SICLAPI __cdecl
#define SICLAPIV __cdecl
#define SICLCALLBACK __cdecl
#else
#if defined(_MS_DOS_WIN)
#define SICLCALLBACK _far _pascal _export
#define SICLAPI _far _pascal
#define SICLAPIV _far __cdecl
#else
#define SICLAPI
#define SICLAPIV
#define SICLCALLBACK
#endif
#endif


/*
 * Support levels:
 */
#define I_SICL_REVISION 43  /* Agilent SICL Revision 4.3 */
#define I_SICL_LEVEL 3      /* Support Level */
#define I_SICL_FMTIO        /* Support Formatted I/O */
#define I_SICL_GPIB         /* Support GP-IB */
#define I_SICL_VXI          /* Support VXI */
#define I_SICL_LAN          /* Support LAN */
#define I_SICL_RS232        /* Support RS-232 */
#define I_SICL_GPIO         /* Support GPIO */
#define I_SICL_MSIB         /* Support MSIB */
#define I_SICL_USB          /* Support USB */

/*
 * The following is needed for functions that require va_list in the
 * prototypes.
 */
#if defined(I_SICL_FMTIO)
#include <stdarg.h>
#endif

/*
 * Definition of INST:
 */
typedef int INST;

/*
 * session types
 */
#define I_SESS_INTF      1
#define I_SESS_DEV       2
#define I_SESS_CMDR      3
#define I_SESS_SERVANT   4

/*
 * interface types
 */
#define  I_INTF_NONE    0
#define I_INTF_GPIB     1
#define I_INTF_VXI      2
#define I_INTF_RS232    3
#define I_INTF_GPIO     4
/* 5 is reserved -- don't use */
#define I_INTF_USRDEF   6
/* 7 is reserved -- don't use */
#define I_INTF_MSIB     8
#define I_INTF_LAN      9
#define I_INTF_1394    10
#define I_INTF_SOCKET  11
#define I_INTF_USB     12
#define I_INTF_LANINST 13
#define I_INTF_RSIB    14

/*
 * iread termination conditions
 */
#define I_TERM_MAXCNT      1
#define I_TERM_CHR         2
#define I_TERM_END         4

/*
 * ixtrig 'which' values.  Note:  different interface types may have
 * overlapping constants.  However, don't overlap them until it is required.
 */
#define I_TRIG_STD         0x00000001L
#define I_TRIG_ALL         0xffffffffL
#define I_TRIG_TTL0        0x00001000L
#define I_TRIG_TTL1        0x00002000L
#define I_TRIG_TTL2        0x00004000L
#define I_TRIG_TTL3        0x00008000L
#define I_TRIG_TTL4        0x00010000L
#define I_TRIG_TTL5        0x00020000L
#define I_TRIG_TTL6        0x00040000L
#define I_TRIG_TTL7        0x00080000L
#define I_TRIG_ECL0        0x00100000L
#define I_TRIG_ECL1        0x00200000L
#define I_TRIG_ECL2        0x00400000L
#define I_TRIG_ECL3        0x00800000L
#define I_TRIG_EXT0        0x01000000L
#define I_TRIG_EXT1        0x02000000L
#define I_TRIG_EXT2        0x04000000L
#define I_TRIG_EXT3        0x08000000L
#define I_TRIG_CLK0        0x10000000L
#define I_TRIG_CLK1        0x20000000L
#define I_TRIG_CLK2        0x40000000L
#define I_TRIG_CLK10       0x80000000L
#define I_TRIG_CLK100      0x00000800L
#define I_TRIG_SERIAL_DTR  0x00000400L
#define I_TRIG_SERIAL_RTS  0x00000200L
#define I_TRIG_GPIO_CTL0   0x00000100L
#define I_TRIG_GPIO_CTL1   0x00000080L

/*
 * ihint values
 */
#define  I_HINT_DONTCARE   0
#define  I_HINT_USEDMA     1
#define  I_HINT_USEPOLL    2
#define  I_HINT_USEINTR    3
#define  I_HINT_SYSTEM     4
#define  I_HINT_IO         5

/*
 * isetintr values
 */
/* 1-15 are interface independant */
#define I_INTR_OFF        0 /* Turn off interrupts */
#define I_INTR_INTFACT    1
#define I_INTR_INTFDEACT  2
#define I_INTR_TRIG       3
#define I_INTR_STB        4
#define I_INTR_DEVCLR     5

/* 16-31 are interface specific */
/* VXI Interrupts */
#define I_INTR_VXI_SIGNAL        16
#define I_INTR_VXI_SYSRESET      17
#define I_INTR_VXI_VME           18
#define I_INTR_VXI_LLOCK         19
#define I_INTR_VXI_UKNSIG        20
#define I_INTR_VXI_VMESYSFAIL    21
#define I_INTR_VME_IRQ1          22
#define I_INTR_VME_IRQ2          23
#define I_INTR_VME_IRQ3          24
#define I_INTR_VME_IRQ4          25
#define I_INTR_VME_IRQ5          26
#define I_INTR_VME_IRQ6          27
#define I_INTR_VME_IRQ7          28
#define I_INTR_ANY_SIG           29
/* GP-IB Interrupts */
#define I_INTR_GPIB_IFC          16
#define I_INTR_GPIB_PPOLLCONFIG  17
#define I_INTR_GPIB_REMLOC       18
#define I_INTR_GPIB_GET          20
#define I_INTR_GPIB_TLAC         21

#define I_INTR_GPIB_MAX          21  // Ensure this value == largest GPIB INTR

/* RS-232 Interrupts */
#define I_INTR_SERIAL_DAV        16
#define I_INTR_SERIAL_MSL        17
#define I_INTR_SERIAL_BREAK      18
#define I_INTR_SERIAL_ERROR      19
#define I_INTR_SERIAL_TEMT       20
#define I_INTR_SERIAL_MCL        21
/* GP-IO Interrupts */
#define I_INTR_GPIO_EIR          16
#define I_INTR_GPIO_RDY          17
/* MSIB Interrupts */
#define I_INTR_MSIB_END_RECEIVED 22
#define I_INTR_MSIB_LINK_BROKEN  23
/* USB488 Interrupts */
#define I_INTR_USB               24
/* 32 maximum isetintr values */
#define I_INTR_MAX               32

/*
 * Swap Constants
 *
 * NOTE:  The byte ordering constants are more than OS dependant,
 * but also dependant on the computer it is implemented on.  (i.e.
 * UNIX has been implemented on INTEL machines and Motorola machines.)
 * If your machine is not identified here, you must be porting our
 * code.  You need to create a constant that uniquely identifies
 * your OS and machine and define the correct ordering macro.  For
 * long term support, submit a DTS, with explicite instruction
 * describing the enhancement for you system.
 */
#if defined(_MS_DOS_WIN) || defined(_SICL_WIN32) || defined(_SICL_LYNX_LE) || defined (_SICL_LINUX_LE)
   /* Little Endian */
#define I_ORDER_LE
#undef  I_ORDER_BE
#endif

#if defined(_SICL_HPUX) || defined(_SICL_LYNX_BE) || defined(_SICL_LINUX_BE)
   /* Big Endian */
#undef  I_ORDER_LE
#define I_ORDER_BE
#endif

/* ivxibusstatus values */
#define I_VXI_BUS_TRIGGER         0
#define I_VXI_BUS_LADDR           1
#define I_VXI_BUS_SERVANT_AREA    2
#define I_VXI_BUS_NORMOP          3
#define I_VXI_BUS_CMDR_LADDR      4
#define I_VXI_BUS_MAN_ID          5
#define I_VXI_BUS_MODEL_ID        6
#define I_VXI_BUS_PROTOCOL        7
#define I_VXI_BUS_XPROT           8
#define I_VXI_BUS_SHM_SIZE        9
#define I_VXI_BUS_SHM_ADDR_SPACE 10
#define I_VXI_BUS_SHM_PAGE       11
#define I_VXI_BUS_VXIMXI         12
#define I_VXI_BUS_TRIGSUPP       13

/* igpibbusstatus values */
#define I_GPIB_BUS_REM         1
#define I_GPIB_BUS_SRQ         2
#define I_GPIB_BUS_NDAC        3
#define I_GPIB_BUS_SYSCTLR     4
#define I_GPIB_BUS_ACTCTLR     5
#define I_GPIB_BUS_TALKER      6
#define I_GPIB_BUS_LISTENER    7
#define I_GPIB_BUS_ADDR        8
#define I_GPIB_BUS_LINES       9

#define I_GPIB_T1DELAY_MIN   350
#define I_GPIB_T1DELAY_MAX  2400
   
/* values for igpioctrl and igpiostat */
#define  I_GPIO_AUX         1
#define  I_GPIO_CTRL        2
#define  I_GPIO_DATA        3
#define  I_GPIO_INFO        4
#define  I_GPIO_SET_PCTL    5
#define  I_GPIO_STAT        6
#define  I_GPIO_READ_EOI    7
#define  I_GPIO_TEST_ONLY   8
#define  I_GPIO_POLARITY    9
#define  I_GPIO_READ_CLK   10
#define  I_GPIO_PCTL_DELAY 11

/* 
 * Note that I_GPIO_CHK_PSTS and I_GPIO_AUTO_HDSK are safely overloaded
 * an igpioctrl request value and a bit mask for I_GPIO_INFO.  This is
 * OK because their values (16 and 32) do not conflict with any other
 * defined igpioctrl values.
 */

#define  I_GPIO_CTRL_CTL0  0x01
#define  I_GPIO_CTRL_CTL1  0x02

#define  I_GPIO_STAT_STI0  0x01
#define  I_GPIO_STAT_STI1  0x02
#define  I_GPIO_EIR        0x04
#define  I_GPIO_PSTS       0x08
#define  I_GPIO_CHK_PSTS   0x10
#define  I_GPIO_AUTO_HDSK  0x20
#define  I_GPIO_ENH_MODE   0x40
#define  I_GPIO_READY      0x80
#define  I_GPIO_EOI_NONE   0x10000

/* RS-232 values */
/* STATUS AND CONTROL CONST  */
#define I_SERIAL_BAUD          1
#define I_SERIAL_PARITY        2
#define I_SERIAL_STOP          3
#define I_SERIAL_WIDTH         4
#define I_SERIAL_FLOW_CTRL     5
#define I_SERIAL_MSL           6
#define I_SERIAL_STAT          7
#define I_SERIAL_RESET         9
#define I_SERIAL_READ_EOI     10
#define I_SERIAL_WRITE_EOI    11
#define I_SERIAL_DUPLEX       12
#define I_SERIAL_READ_BUFSZ   13
#define I_SERIAL_READ_DAV     14
#define I_SERIAL_IN_DISCARD   15
#define I_SERIAL_OUT_DISCARD  16
#define I_SERIAL_XON_CHAR     17
#define I_SERIAL_XOFF_CHAR    18
#define I_SERIAL_REPLACE_CHAR 19

/* SERIAL duplex modes */
#define I_SERIAL_DUPLEX_HALF  0x0001
#define I_SERIAL_DUPLEX_FULL  0x0002

/* SERIAL UART STATUS */
#define I_SERIAL_DAV          0x0001
#define I_SERIAL_OVERFLOW     0x0002
#define I_SERIAL_PARERR       0x0004
#define I_SERIAL_FRAMING      0x0008
#define I_SERIAL_BREAK        0x0010
#define I_SERIAL_TEMT         0x0020

/* FLOW CONTROL CONST  */
#define I_SERIAL_FLOW_NONE    0
#define I_SERIAL_FLOW_XON     1
#define I_SERIAL_FLOW_RTS_CTS 2
#define I_SERIAL_FLOW_DTR_DSR 3

/* SERIAL MODEM STATUS LINES  */
#define I_SERIAL_DCD       0x0001
#define I_SERIAL_DSR       0x0002
#define I_SERIAL_CTS       0x0004
#define I_SERIAL_RI        0x0008
#define I_SERIAL_D_DCD     0x0010
#define I_SERIAL_D_DSR     0x0020
#define I_SERIAL_D_CTS     0x0040
#define I_SERIAL_TERI      0x0080

/* SERIAL MODEM CONTROL LINES */
#define I_SERIAL_RTS       0x1000
#define I_SERIAL_DTR       0x2000

/* SERIAL PARITY VALUES  */
#define I_SERIAL_PAR_NONE     0
#define I_SERIAL_PAR_EVEN     1
#define I_SERIAL_PAR_ODD      2
#define I_SERIAL_PAR_MARK     3
#define I_SERIAL_PAR_SPACE    4
#define I_SERIAL_PAR_IGNORE   5

/* SERIAL STOP-BIT VALUES */
#define I_SERIAL_STOP_1       1
#define I_SERIAL_STOP_2       2

/* SERIAL CHARACTER WIDTH  */
#define I_SERIAL_CHAR_5       5
#define I_SERIAL_CHAR_6       6
#define I_SERIAL_CHAR_7       7
#define I_SERIAL_CHAR_8       8

/* EOI support (used with the I_SERIAL_*_EOI command) */
#define I_SERIAL_EOI_CHR      0x100
#define I_SERIAL_EOI_NONE     0x200
#define I_SERIAL_EOI_BIT8     0x400
#define I_SERIAL_EOI_BREAK    0x800

/*
 * MSIB error types (for imsibseterror)
 */
#define I_MSIB_PERMANENTERR      0
#define I_MSIB_TRANSIENTERR      1

/*
 * MSIB commands (for imsibcmd)
 */
#define I_MSIB_CMD_NULL                 0x0000
#define I_MSIB_CMD_END                  0x0001
#define I_MSIB_CMD_SEND_CAPABILITY      0x0002
#define I_MSIB_CMD_RETURN_TO_LOCAL      0x0006
#define I_MSIB_CMD_LOCK_LINK            0x0007
#define I_MSIB_CMD_UNLOCK_LINK          0x0008
#define I_MSIB_CMD_LIGHT_ACTIVE         0x0009
#define I_MSIB_CMD_UNLIGHT_ACTIVE       0x000A
#define I_MSIB_CMD_ERROR_OCCURRED       0x000B
#define I_MSIB_CMD_ERRORS_CLEARED       0x000C
#define I_MSIB_CMD_SEND_STATUS          0x0010
#define I_MSIB_CMD_SEND_ERRORS          0x0011
#define I_MSIB_CMD_SEND_MODULE_ID       0x0012
#define I_MSIB_CMD_SEND_MANUFACTURER    0x0013
#define I_MSIB_CMD_SEND_TIME            0x0014
#define I_MSIB_CMD_LINK_REMOTE          0x0015
#define I_MSIB_CMD_LINK_LOCAL           0x0016
#define I_MSIB_CMD_SEND_MODEL_NUMBER    0x0017
#define I_MSIB_CMD_SEND_SERIAL_NUMBER   0x0018
#define I_MSIB_CMD_SEND_FIRMWARE_REV    0x0019
#define I_MSIB_CMD_STATUS               0x0600
#define I_MSIB_CMD_SET_IEEE_ADDRESS     0x0700

/* USB values */
/* STATUS AND CONTROL CONST  */
#define I_USB_RW_PROTOCOL     1
#define I_USB_FLUSH_STB_QUEUE 2

/* I_USB_RW_PROTOCOL setting / result values */
#define I_USB_RW_PROT_NORMAL  0
#define I_USB_RW_PROT_VENDOR  1
#define I_USB_RW_PROT_RAW     2

/*
 * imap 'mapspace' values
 */
#define I_MAP_A16     0x0000
#define I_MAP_A24     0x0001
#define I_MAP_A32     0x0002
#define I_MAP_VXIDEV  0x0003
#define I_MAP_EXTEND  0x0004
#define I_MAP_INTFREG 0x0005
#define I_MAP_SHARED  0x0006
#define I_MAP_AM      0x8000
/*
 *  For E1489 MXI
 */
#define I_MAP_A16_L             0x0007
#define I_MAP_A16_D32           I_MAP_A16_L  
#define I_MAP_A24_L             0x0008
#define I_MAP_A24_D32           I_MAP_A24_L  
#define I_MAP_A24_BLK           0x0009
#define I_MAP_A24_BLK_L         0x000a
#define I_MAP_A32_L             0x000b
#define I_MAP_A32_D32           I_MAP_A32_L  
#define I_MAP_A32_BLK           0x000c
#define I_MAP_A32_BLK_L         0x000d
#define I_MAP_A16_SM            0x000e  /* MXI supervisory mode access */
#define I_MAP_A24_SM            0x000f  /* MXI supervisory mode access */
#define I_MAP_A32_SM            0x0010  /* MXI supervisory mode access */
#define I_MAP_A16_SM_L          0x0011  /* MXI SM D32 */
#define I_MAP_A16_SM_D32        I_MAP_A16_SM_L
#define I_MAP_A24_SM_L          0x0012  /* MXI SM D32 */
#define I_MAP_A24_SM_D32        I_MAP_A24_SM_L
#define I_MAP_A32_SM_L          0x0013  /* MXI SM D32 */
#define I_MAP_A32_SM_D32        I_MAP_A32_SM_L

/*
 * Protocols
 */
#define I_PROTOCOL_1394_IICP488  1
#define I_PROTOCOL_USB_SCPI      2

/*
 * Error Codes
 */
#define I_ERR_NOERROR        0
#define I_ERR_SYNTAX         1
#define I_ERR_SYMNAME        2
#define I_ERR_BADADDR        3
#define I_ERR_BADID          4
#define I_ERR_PARAM          5
#define I_ERR_NOCONN         6
#define I_ERR_NOPERM         7
#define I_ERR_NOTSUPP        8
#define I_ERR_NORSRC         9
#define I_ERR_NOINTF        10
#define I_ERR_LOCKED        11
#define I_ERR_NOLOCK        12
#define I_ERR_BADFMT        13
#define I_ERR_DATA          14
#define I_ERR_TIMEOUT       15
#define I_ERR_OVERFLOW      16
#define I_ERR_IO            17
#define I_ERR_OS            18
#define I_ERR_BADMAP        19
#define I_ERR_NODEV         20
#define I_ERR_INVLADDR      21
#define I_ERR_NOTIMPL       22
#define I_ERR_ABORTED       23
#define I_ERR_BADCONFIG     24
#define I_ERR_NOCMDR        25
#define I_ERR_VERSION       26
#define I_ERR_NESTEDIO      27
#define I_ERR_BUSY          28
#define I_ERR_CONNEXISTS    29
#define I_ERR_BUSERR        30
#define I_ERR_BUSERR_RETRY  31
#define I_ERR_BADREMADDR	 32
#define I_ERR_HOSTNOTFOUND  33
#define I_ERR_PROTOCOLNSUP  34
#define I_ERR_ONCRPCNSUP    35
#if !defined(STD_SICL)
#define I_ERR_INTERNAL     128
#define I_ERR_INTERRUPT    129
#define I_ERR_UNKNOWNERR   130
#define I_ERR_NOTLISTENER  131
#define I_ERR_NOTTALKER    132
#endif

/*
 * These are the buffer sizes for formatted I/O.  These will become
 * a part of standard sicl.
 * NOTE:  These numbers are tuned for HP-UX performance.
 */
#define I_READ_BUF_SZ       4096
#define I_WRITE_BUF_SZ       128

#define I_BUF_READ          0x01
#define I_BUF_WRITE         0x02
#define I_BUF_DISCARD_READ  0x04
#define I_BUF_DISCARD_WRITE 0x08
#define I_BUF_WRITE_END     0x10

/*
 * Define bitmask positions for the lu_info flags element
 */
#define I_LUINFO_FLAG_HIDDEN 0x00000001
#define I_LUINFO_FLAG_IGNORE 0x00000002

   /*
    * LU info structure
    * Only some of these fields are documented in SICL, others are
    * documented in TULIP.
    */
   typedef struct lu_info {
      long logical_unit;     /* Documented:  SICL/TULIP (hwconfig.cf) */
      char symname[32];      /* Documented:  SICL/TULIP (hwconfig.cf) */
      char cardname[32];     /* Documented:  SICL/TULIP (xxx_getentry) */
      long filler;           /* Filler - Needed for backward compatability */
      long intftype;         /* Documented:  SICL/TULIP (xxx_getentry) */
      long location;         /* Documented:  TULIP      (hwconfig.cf) */
      long busaddr;          /* Documented:  TULIP      (hwconfig.cf) */
      char _far * hwarg[16]; /* Documented: TULIP    (hwconfig.cf) */
      char visaname[32];     /* interface name used for VISA */
      long flags;            /* bitmask of interface flags */
      long filler2[3];       /* Filler - Needed for future expansion  */
   } lu_info;

   /*
    * ivxirminfo structure
    */
   struct vxiinfo {
      /* Device Identification */
      short laddr;                 /* Logical Address */
      char name[16];               /* Symbolic Name */
      char manuf_name[16];         /* Manufacturer Name */
      char model_name[16];         /* Model Name */
      unsigned short man_id;       /* Manufacturer ID */
      unsigned short model;        /* Model Code */
      unsigned short devclass;     /* Device Class */
      
      /* Self Test Status */
      short selftest;              /* 1=PASSED, 0=FAILED */
      
      /* Location of Device */
      short cage_num;              /* Cardcage Number */
      short slot;                  /* slot number, -1 is unknown, -2 is MXI */
      
      /* Device Information */
      unsigned short protocol;     /* Value of protocol register */
      unsigned short x_protocol;   /* Results of Read Protocol WS command */
      unsigned short servant_area; /* Value of servant area */
      
      /* Memory Information */
      /* page size is 256 bytes for A24 and 64K bytes for A32 */
      unsigned short addrspace;    /* 24=A24, 32=A32, 0=none */
      unsigned short memsize;      /* Amount of memory in pages */
      unsigned short memstart;     /* Start of memory in pages */
      
      /* Misc. Information */
      short slot0_laddr;           /* LADDR of slot 0 device, -1 if unknown */
      short cmdr_laddr;            /* LADDR of commander, -1 if top level */
      
      /* Interrupt Information */
      short int_handler[8];        /* List of interrupt handlers */
      short interrupter[8];        /* List of interrupters */
      
      short fill[10];              /* Unused */
   };

   /*
    * vxiinfo structure values
    */
#define I_VXI_DEVCLASS_MEMORY    0x0000
#define I_VXI_DEVCLASS_EXTENDED  0x4000
#define I_VXI_DEVCLASS_MSGBASED  0x8000
#define I_VXI_DEVCLASS_REGBASED  0xc000


   typedef struct {
      unsigned short     command;
      unsigned long      mapHandle;
      unsigned long      address;
      unsigned long      parm1;
      unsigned long      parm2;
   } ivximacroelem;

#define I_VXI_MACRO_DELAY          (0x0001)
#define I_VXI_MACRO_POLLSTAT16     (0x0002)
#define I_VXI_MACRO_POKE8          (0x0003)
#define I_VXI_MACRO_POKE16         (0x0004)
#define I_VXI_MACRO_POKE32         (0x0005)
#define I_VXI_MACRO_READMODWRITE16 (0x0006)
#define I_VXI_MACRO_PEEK8          (0x0007)
#define I_VXI_MACRO_PEEK16         (0x0008)
#define I_VXI_MACRO_PEEK32         (0x0009)
#define I_VXI_MACRO_SESSION        (0xfffe)
#define I_VXI_MACRO_END            (0xffff)

   struct msibinfo {
      char capability[127];    /* response to SEND CAPABILITY command */
      char capability_length;  /* capability may contain NULL bytes */
      /* the rest are NULL-terminated strings */
      char module_id[128];     /* response to SEND MODULE ID */
      char mfg_id[128];        /* response to SEND MANUFACTURER ID */
      char model_number[128];  /* response to SEND MODEL NUMBER */
      char serial_number[128]; /* response to SEND SERIAL NUMBER */
      char firmware_rev[128];  /* response to SEND FIRMWARE REVISION */
   };

/* USB definitions */
typedef struct {
   /* From USBTMC Specification Table 37 - GET_CAPABILITIES */
   unsigned char  status;
   unsigned char  reserved1;
   unsigned short bcdUSBTMC;
   unsigned char  intfCapabilities;
   unsigned char  devCapabilities;
   unsigned char  reservedTMC[6];
   /* From USBTMC USB488 Subclass Specification Table 8 */
   unsigned short bcdUSB488;
   unsigned char  intf488Capabilities;
   unsigned char  dev488Capabilities;
   unsigned char  reservedSUB[8];
} usbcapinfo;

/* Masks for intfCapabilities */
#define I_USB_INTFCAP_LISTENONLY_MASK 0x1
#define I_USB_INTFCAP_TALKONLY_MASK   0x2
#define I_USB_INTFCAP_IPULSE_MASK     0x4

/* Mask for devCapabilities */
#define I_USB_DEVCAP_BULK_IN_MASK     0x1

/* Masks for intf488Capabilities */
#define I_USB_INTF488CAP_TRIG_MASK    0x1
#define I_USB_INTF488CAP_REN_MASK     0x2
#define I_USB_INTF488CAP_4882_MASK    0x4

/* Mask for dev488Capabilities */
#define I_USB_DEV488CAP_DT1_MASK      0x1
#define I_USB_DEV488CAP_RL1_MASK      0x2
#define I_USB_DEV488CAP_SR1_MASK      0x4
#define I_USB_DEV488CAP_SCPI_MASK     0x8

typedef struct {
   /* From USBTMC Specification Table 40 - Device Descriptor */
   unsigned char  bLength;             /* 0x12 */
   unsigned char  bDescriptorType;
   unsigned short bcdUSB; 
   unsigned char  bDeviceClass;
   unsigned char  bDeviceSubClass;
   unsigned char  bDeviceProtocol;
   unsigned char  bMaxPacketSize0;
   unsigned short idVendor;
   unsigned short idProduct;
   unsigned short bcdDevice;
   unsigned char  iManufacturer;
   unsigned char  iProduct;
   unsigned char  iserialNumber;
   unsigned char  bNumConfigurations;
   unsigned char  interfaceNumber;
   /* Return actual device strings along with the USB device descriptor */
            char  manufNameStr[128];
            char  productNameStr[128];
            char  serialNumberStr[128];
} usbinfo;

/* Non-Standard SICL Defines */
#if !defined(STD_SICL)
   /* Trace defines */
#define  trace_off    0
#define  trace_user   1
#define  trace_inout  2
#define  trace_action 3
#define  trace_detail 4
#define trace_xdetail 5
   /* Configuration file defines */
   /* Bus types (int bustype): */
#define  I_BUS_INT   0  /* Internal Bus */
#define  I_BUS_ISA   1  /* ISA Bus */
#define  I_BUS_EISA  2  /* EISA Bus */
#define  I_BUS_DIO   3  /* DIO I/II Bus */
#define  I_BUS_VME   4  /* VME Bus */
#define I_BUS_USRLND 5  /* Userland driver */
#define  I_BUS_PCI   6  /* PCI Bus */
   /* Bus types -- USE I_BUS_*, not these!!! (int bustype): */
/*
 * These are also defined in pilconfig.h.  If you change these
 * you MUST also change the matching ones in pilconfig.h.
 */
#if !defined(CFG_BUS_INT)
#define  CFG_BUS_INT    I_BUS_INT
#define  CFG_BUS_CORE   I_BUS_INT
#define  CFG_BUS_ISA    I_BUS_ISA
#define  CFG_BUS_EISA   I_BUS_EISA
#define  CFG_BUS_DIO    I_BUS_DIO
#define  CFG_BUS_VME    I_BUS_VME
#define  CFG_BUS_USRLND I_BUS_USRLND
#define  CFG_BUS_PCI    I_BUS_PCI
/* Interface types -- USE I_INTF_*, not these!!! (int intftype): */
#define  CFG_INTF_HPIB    I_INTF_GPIB    /* GPIB Interface */
#define  CFG_INTF_VXI     I_INTF_VXI     /* VXI Interface */
#define  CFG_INTF_RS232   I_INTF_RS232   /* RS-232 Interface */
#define  CFG_INTF_GPIO    I_INTF_GPIO    /* GPIO Interface */
#define  CFG_INTF_DIL     5              /* DIL Interface */
#define  CFG_INTF_USRDEF  I_INTF_USRDEF  /* User-defined Interface type */
#define  CFG_INTF_LANINST I_INTF_LANINST /* LAN Instrument Interface type */
#define  CFG_INTF_RSIB    I_INTF_RSIB    /* RSIB Instrument Interface type */
#endif
#endif

#if ! defined(SICL_NOPROTO)

/* See if C++ or not */
#if defined(__cplusplus)
   extern "C" {
#endif

#if defined(__STDC__) || defined(__cplusplus) || defined(_MS_DOS_WIN) || defined (_SICL_WIN32)

/* Version Information */
int SICLAPI iversion(int _far *siclversion,int _far *implversion);
int SICLAPI idrvrversion(INST id,int _far *specversion,int _far *implversion);

/* Open/Close */
INST SICLAPI iopen(char _far *addr);
int SICLAPI iclose(INST id);
INST SICLAPI igetintfsess(INST id);

/* Write/Read */
int SICLAPI iwrite (
   INST id,
   char _far *buf,
   unsigned long datalen,
   int endi,
   unsigned long _far *actual
);
int SICLAPI iread (
   INST id,
   char _far *buf,
   unsigned long bufsize,
   int _far *reason,
   unsigned long _far *actual
);
int SICLAPI itermchr(INST id,int tchr);
int SICLAPI igettermchr(INST id,int _far *tchr);

/* Formatted I/O */
int SICLAPIV iprintf (INST id, const char _far *fmt, ...);
int SICLAPIV ivprintf (INST id, const char _far *fmt, va_list ap);
int SICLAPIV isprintf (char _far *user_buf, const char _far *fmt, ...);
int SICLAPIV isvprintf (char _far *user_buf, const char _far *fmt, va_list ap);

int SICLAPIV iscanf (INST id, const char _far *fmt, ...);
int SICLAPIV ivscanf (INST id, const char _far *fmt, va_list ap);
int SICLAPIV isscanf (char _far *user_buf, const char _far *fmt, ...);
int SICLAPIV isvscanf (char _far *user_buf, const char _far *fmt, va_list ap);

int SICLAPIV ipromptf (
   INST id, 
   const char _far *writefmt, 
   const char _far *readfmt, 
   ...
);
int SICLAPIV ivpromptf (
   INST id, 
   const char _far *writefmt, 
   const char _far *readfmt, 
   va_list ap
);

int SICLAPI ifwrite (
   INST id, 
   char _far *buf, 
   unsigned long datalen, 
   int end, 
   unsigned long _far *actualcnt
);
int SICLAPI ifread (
   INST id, 
   char _far *buf, 
   unsigned long bufsize, 
   int _far *reason, 
   unsigned long _far *actualcnt
);

int SICLAPI iflush (INST id, int mask);
int SICLAPI isetbuf (INST id, int mask, int size);
int SICLAPI isetubuf (INST id, int mask, int size, char _far *buf);

/* Device/Interface Control */
int SICLAPI iclear(INST id);
int SICLAPI iabort(INST id);
int SICLAPI ilocal (INST id);
int SICLAPI iremote (INST id);
int SICLAPI ireadstb(INST id,unsigned char _far *stb);
int SICLAPI itrigger(INST id);
int SICLAPI ixtrig(INST id,unsigned long which);
int SICLAPI ihint(INST id,int hint);

/* Commander Sessions */
int SICLAPI isetstb(INST id, unsigned char stb);

/* Service Requests */
typedef void (SICLCALLBACK *srqhandler_t)(INST);
int SICLAPI ionsrq(INST id,srqhandler_t shdlr);
int SICLAPI igetonsrq(INST id, srqhandler_t _far *shdlr);

/* Interrupts */
typedef void (SICLCALLBACK *intrhandler_t)(INST,long,long);
int SICLAPI ionintr(INST id,intrhandler_t ihdlr);
int SICLAPI igetonintr(INST id, intrhandler_t _far * ihdlr);
int SICLAPI isetintr(INST id,int intnum,long secval);

/* Asynchronous Events Control */
int SICLAPI iintroff(void);
int SICLAPI iintron(void);
int SICLAPI iwaithdlr(long timeout);

/* Locking */
int SICLAPI ilock(INST id);
int SICLAPI iunlock(INST id);
int SICLAPI isetlockwait(INST id,int flag);
int SICLAPI igetlockwait(INST id,int _far *flag);

/* Timeouts */
int SICLAPI itimeout(INST id,long tval);
int SICLAPI igettimeout(INST id,long _far *tval);

/* Misc. Functions */
int SICLAPI igetaddr(INST id,char _far * _far *addr);
int SICLAPI isetdata(INST id,void _far *data);
int SICLAPI igetdata(INST id,void _far * _far *data);
int SICLAPI igetintftype(INST id,int _far *pdata);
int SICLAPI igetsesstype(INST id,int _far *pdata);
int SICLAPI igetdevaddr(INST id,int _far *prim, int _far *sec);
int SICLAPI igetlu(INST id, int _far *lu);
int SICLAPI ibeswap(char _far *addr,unsigned long length,int datasize);
int SICLAPI ileswap(char _far *addr,unsigned long length,int datasize);
int SICLAPI iswap(char _far *addr,unsigned long length,int datasize);
int SICLAPI igetlulist(int _far * _far *list);
int SICLAPI igetluinfo(int lu,struct lu_info _far *result);
int SICLAPI igetgatewaytype(INST id,int _far *pdata);
void SICLAPI siclExplicitlyLoaded();
void SICLAPI ionexitclose();

/* Error Handling */
typedef void (SICLCALLBACK *errorproc_t)(INST,int);
int SICLAPI ionerror(errorproc_t);
int SICLAPI igetonerror(errorproc_t _far *);
void SICLCALLBACK I_ERROR_EXIT(INST,int);
void SICLCALLBACK I_ERROR_NO_EXIT(INST,int);
int SICLAPI igeterrno (void);
char _far * SICLAPI igeterrstr (int);
void SICLAPI icauseerr (INST id, int errcode, int flag);

/* RS-232 specific functions */
int SICLAPI iserialmclctrl (INST id, int sline, int state);
int SICLAPI iserialmclstat (INST id, int sline, int _far *state);
int SICLAPI iserialctrl (INST id, int request, unsigned long setting);
int SICLAPI iserialstat (INST id, int request, unsigned long _far *result);
int SICLAPI iserialbreak (INST id);

/* VXI Specific functions */
   int SICLAPI ivxibusstatus(INST id,int request,unsigned long _far *result);
   int SICLAPI ivxiwaitnormop(INST id);
   int SICLAPI ivxitrigon(INST id,unsigned long which);
   int SICLAPI ivxitrigoff(INST id,unsigned long which);
   int SICLAPI ivxitrigroute(INST id,unsigned long in_which,unsigned long out_which);
   int SICLAPI ivxigettrigroute(INST id,unsigned long which,unsigned long _far *route);
   int SICLAPI ivxiws(INST id,unsigned short wscmd,unsigned short _far *wsresp,unsigned short _far *rpe);
   int SICLAPI ivxiservants(INST id,int maxnum,int _far *list);
   int SICLAPI ivxirminfo(INST id,int laddr, struct vxiinfo _far *info);

#if defined(_MS_DOS_WIN) || defined(_SICL_WIN32)
   int  SICLAPI igetvberrbase (short *);
   int  SICLAPI isetvberrbase (short);
   void SICLAPI ibpoke(unsigned volatile char _far *addr, unsigned char value);
   void SICLAPI iwpoke(unsigned volatile short _far *addr,unsigned short value);
   void SICLAPI ilpoke(unsigned volatile long _far *addr, unsigned long value);
   unsigned char SICLAPI ibpeek(unsigned volatile char _far *addr);
   unsigned short SICLAPI iwpeek(unsigned volatile short _far *addr);
   unsigned long SICLAPI ilpeek(unsigned volatile long _far *addr);
#endif

/* new map/peek/poke/move routines */
   unsigned long SICLAPI imapx(INST id, int mapspace, unsigned int pagestart, unsigned int pagecnt);
   int SICLAPI iunmapx(INST id, unsigned long handle, int mapspace, unsigned int pagestart, unsigned int pagecnt);
   int SICLAPI iderefptr(INST id, unsigned long handle, unsigned char *value);
   int SICLAPI ipeekx8( INST id, unsigned long handle, unsigned long offset, unsigned char  *value);
   int SICLAPI ipeekx16(INST id, unsigned long handle, unsigned long offset, unsigned short *value);
   int SICLAPI ipeekx32(INST id, unsigned long handle, unsigned long offset, unsigned long  *value);
   int SICLAPI ipokex8( INST id, unsigned long handle, unsigned long offset, unsigned char  value);
   int SICLAPI ipokex16(INST id, unsigned long handle, unsigned long offset, unsigned short value);
   int SICLAPI ipokex32(INST id, unsigned long handle, unsigned long offset, unsigned long  value);
#if defined (_SICL_VXI_D64)
   int SICLAPI ipeekx64(INST id, unsigned long handle, unsigned long offset, unsigned __int64 *value);
   int SICLAPI ipokex64(INST id, unsigned long handle, unsigned long offset, unsigned __int64 value);
#endif
   int SICLAPI iblockmovex(INST id,
                      unsigned long src_handle,
                      unsigned long src_offset,
                      int           src_width,
                      int           src_increment,
                      unsigned long dest_handle,
                      unsigned long dest_offset,
                      int           dest_width,
                      int           dest_increment,
                      unsigned long cnt,
                      int           swap
                     );
   int SICLAPI ivximacro(INST id, ivximacroelem macro[], int size);

/* GP-IB Specific functions */
   int SICLAPI igpibbusstatus (INST id, int request, int _far *result);
   int SICLAPI igpibppoll (INST id, unsigned int _far *result);
   int SICLAPI igpibppollconfig (INST id, int cval);
   int SICLAPI igpibppollresp (INST id, int sval);
   int SICLAPI igpibpassctl (INST id, int busaddr);
   int SICLAPI igpibrenctl (INST id, int ren);
   int SICLAPI igpibatnctl (INST id, int atnval);
   int SICLAPI igpibsendcmd (INST id, char _far *buf, int length);
   int SICLAPI igpibllo (INST id);
   int SICLAPI igpibbusaddr (INST id, int busaddr);
   int SICLAPI igpibgett1delay (INST id, int _far *delay);
   int SICLAPI igpibsett1delay (INST id, int delay);
   int SICLAPI igpibpulseifc (INST id);

/* GPIO Specific functions */
int SICLAPI igpioctrl(INST id,int request,unsigned long setting);
int SICLAPI igpiostat(INST id,int request,unsigned long _far *result);
int SICLAPI igpiosetwidth(INST id,int width);
int SICLAPI igpiogetwidth(INST id,int _far *width);

/* MSIB Specific functions */
int SICLAPI imsibeventmask(INST id,unsigned char mask);
int SICLAPI imsibcmd(INST id,unsigned int cmd,int row,int column,
           char _far *resp,unsigned long bufsize,
           unsigned long _far *actualcnt);
int SICLAPI imsibseterror(INST id,int row,int column,
                char _far *errtext,int errtype,int _far *msiberr);
int SICLAPI imsibclearerror(INST id,int msiberr);
int SICLAPI imsibinfo(INST id,int row,int column,
            struct msibinfo _far *info);
int SICLAPI imsibmodule(INST id,int row,int column,int _far *result);
int SICLAPI imsibsetstb(INST id,unsigned char stb);

/* LAN Specific functions */
int SICLAPI ilantimeout(INST id,long tval);
int SICLAPI ilangettimeout(INST id,long _far *tval);

/* USB Specific functions */
int SICLAPI iusbcontrolout(INST id, short bmRequestType, short bRequest,
                           unsigned short wValue, unsigned short wIndex, unsigned short wLength,
                           char _far *buf);
int SICLAPI iusbcontrolin(INST id, short bmRequestType, short bRequest,
                           unsigned short wValue, unsigned short wIndex, unsigned short wLength,
                           char _far *buf, unsigned short *retCnt);
int SICLAPI iusbgetcapabilities(INST id, usbcapinfo *capinfo);
int SICLAPI iusbgetinfo(INST id, usbinfo *info); 
int SICLAPI iusbintrgetsize(INST id, char handle, char *overflow, unsigned short *size);
int SICLAPI iusbintrgetdata(INST id, char handle, unsigned short size, char *data);
int SICLAPI iusbintrclose(INST id, char handle);
int SICLAPI iusbctrl (INST id, int request, unsigned long setting);
int SICLAPI iusbstat (INST id, int request, unsigned long _far *result);

/* Map routines */
char _far * SICLAPI imap(INST id,int mapspace,unsigned int pagestart,unsigned int pagecnt,char _far *suggested);
int SICLAPI iunmap(INST id,char _far *addr,int mapspace,unsigned int pagestart,unsigned int pagecnt);
int SICLAPI imapinfo(INST id,int mapspace,int _far *numwindows,int _far *winsize);

/* block copy and fifo routines */
int SICLAPI ibblockcopy(INST id, unsigned char _far *src, unsigned char _far *dest,
                unsigned long cnt);
int SICLAPI iwblockcopy(INST id, unsigned short _far *src, unsigned short _far *dest,
                unsigned long cnt, int swap);
int SICLAPI ilblockcopy(INST id, unsigned long _far *src, unsigned long _far *dest,
                unsigned long cnt, int swap);
int SICLAPI ibpushfifo(INST id, unsigned char _far *src, unsigned char _far *fifo,
               unsigned long cnt);
int SICLAPI iwpushfifo(INST id, unsigned short _far *src,unsigned short _far *fifo,
               unsigned long cnt, int swap);
int SICLAPI ilpushfifo(INST id, unsigned long _far *src, unsigned long _far *fifo,
               unsigned long cnt, int swap);
int SICLAPI ibpopfifo(INST id, unsigned char _far *fifo, unsigned char _far *dest,
              unsigned long cnt);
int SICLAPI iwpopfifo(INST id, unsigned short _far *fifo, unsigned short _far *dest,
              unsigned long cnt, int swap);
int SICLAPI ilpopfifo(INST id, unsigned long _far *fifo, unsigned long _far *dest,
              unsigned long cnt, int swap);
int SICLAPI icmd(INST,long,int,int,void _far *); /* Send non-standard commands to driver */
/* These are not standard SICL routines */
#if !defined(STD_SICL)
   int SICLAPI itrace(int level); /* Turn on tracing */
   int SICLAPI isetcscpidata(INST id, void _far *data);
   int SICLAPI igetcscpidata(INST id, void _far * _far *data);
   int SICLAPI isetsig(int sig_val);
   int SICLAPI igetsig(int _far *sig_val);
   int SICLAPI _export _siclcleanup(void); /* process cleanup for Win 3.1*/
   int SICLAPI _export _setsiclyield(int); /* yield option for Win 3.1 */
   int SICLAPI igetblockmode( INST id, short *mode );
#endif

#else /* __STDC__ || __cplusplus || _MS_DOS_WIN || _SICL_WIN32 */
   /* Old C (ie. not ANSI C or C++) */
   /* Version */
   int iversion();
   int idrvrversion();

   /* Open/Close */
   INST iopen();
   int iclose();
   INST igetintfsess();
   
   /* Read/Write */
   int iwrite();
   int iread();
   int itermchr();
   int igettermchr();

/* Formatted I/O */
   int iprintf ();
   int ivprintf ();
   int isprintf ();
   int isvprintf ();

   int iscanf ();
   int ivscanf ();
   int isscanf ();
   int isvscanf ();

   int ipromptf ();
   int ivpromptf ();

   int ifwrite ();
   int ifread ();

   int iflush ();
   int isetbuf ();
   int isetubuf ();
   
   /* Device/Interface Control */
   int iclear();
   int iabort();
   int ilocal ();
   int iremote ();
   int ireadstb();
   int itrigger();
   int ixtrig();
   int ihint();
   
   /* Commander Sessions */
   int isetstb();

   /* Service Requests */
   int ionsrq();
   int igetonsrq();
   
   /* Interrupts */
   int ionintr();
   int igetonintr();
   int isetintr();
   
   /* Asynchronous Events Control */
   int iintroff();
   int iintron();
   int iwaithdlr();
   
   /* Locking */
   int ilock();
   int iunlock();
   int isetlockwait();
   int igetlockwait();
   
   /* Timeouts */
   int itimeout();
   int igettimeout();
   
   /* Misc. Functions */
   int igetaddr();
   int isetdata();
   int igetdata();
   int igetintftype();
   int igetsesstype();
   int igetdevaddr();
   int igetlu();
   int ibeswap();
   int ileswap();
   int iswap();
   int igetlulist();
   int igetluinfo();
   int igetgatewaytype();
   
   /* Error Handling */
   int ionerror();
   int igetonerror();
   void I_ERROR_EXIT();
   void I_ERROR_NO_EXIT();
   int igeterrno ();
   char _far *igeterrstr ();
   void icauseerr ();

/* RS-232 specific functions */
   int iserialmclctrl ();
   int iserialmclstat ();
   int iserialctrl ();
   int iserialstat ();
   int iserialbreak ();

/* VXI Specific functions */
   int ivxibusstatus();
   int ivxiwaitnormop();
   int ivxitrigon();
   int ivxitrigoff();
   int ivxitrigroute();
   int ivxigettrigroute();
   int ivxiws();
   int ivxiservants();
   int ivxirminfo();

#if defined(_MS_DOS_WIN) || defined(_SICL_WIN32)
   void ibpoke();
   void iwpoke();
   void ilpoke();
   unsigned char ibpeek();
   unsigned short iwpeek();
   unsigned long ilpeek();
#endif 

/* GP-IB Specific functions */
   int igpibbusstatus();
   int igpibppoll();
   int igpibppollconfig();
   int igpibppollresp();
   int igpibpassctl();
   int igpibrenctl();
   int igpibatnctl();
   int igpibsendcmd();
   int igpibbusaddr ();
   int igpibllo ();
   int igpibpulseifc ();
   
/* GPIO Specific functions */
   int igpioctrl();
   int igpiostat();
   int igpiosetwidth();
   int igpiogetwidth();

/* MSIB Specific functions */
   int imsibeventmask();
   int imsibcmd();
   int imsibseterror();
   int imsibclearerror();
   int imsibinfo();
   int imsibmodule();
   int imsibsetstb();

/* LAN Specific functions */
   int ilantimeout();
   int ilangettimeout();

/* USB Specific functions */
   int iusbcontrolout();
   int iusbcontrolin();
   int iusbgetcapabilities();
   int iusbgetinfo(); 
   int iusbintrgetsize();
   int iusbintrgetdata();
   int iusbintrclose();

   /* Map routines */
   char _far *imap();
   int iunmap();
   int imapinfo();
   int ibblockcopy();
   int iwblockcopy();
   int ilblockcopy();
   int ibpushfifo();
   int iwpushfifo();
   int ilpushfifo();
   int ibpopfifo();
   int iwpopfifo();
   int ilpopfifo();
   
   int icmd();

   /* These are not standard SICL routines */
#if !defined(STD_SICL)
   int itrace();
   int isetcscpidata();
   int igetcscpidata();
   int isetsig();
   int igetsig();
   int igetblockmode();
#endif
   
#endif /* __STDC__ || __cplusplus || _MS_DOS_WIN || _SICL_WIN32 */

#endif /* ! SICL_NOPROTO */

/* Peek/Poke Macros */

#if !defined(_MS_DOS_WIN) && !defined(_SICL_WIN32)
/* Lynx/Fantasia VXI interface needs a FIFO check before the dereference on
 * VXI writes -- BJS
 */
#if defined(_SICL_LYNX_FA)

/* This global (defined and initialized by SICL) is a pointer to the Universe
 * MISC_STAT register.
 */
extern volatile unsigned long *sicl_universe_misc_stat;

/* UNIVERSE_FIFO_WAIT waits until the Universe write FIFO is empty */
#define UNIVERSE_FIFO_WAIT \
   do { \
   } while ((*sicl_universe_misc_stat & 0x00040000L) == 0)

/* In the i*poke macros below, don't even consider removing the outer
 * "do { } while (0)" structure.  This "trick" makes these macros into a
 * single incomplete statement, so they behave like the old i*poke macros.
 */
#define ibpoke(addr,val) \
do { \
   UNIVERSE_FIFO_WAIT; \
   (*(unsigned volatile char *)(addr)) = ((unsigned char)(val)); \
} while (0)

#define iwpoke(addr,val) \
do { \
   UNIVERSE_FIFO_WAIT; \
   (*(unsigned volatile short *)(addr)) = ((unsigned short)(val)); \
} while (0)

#define ilpoke(addr,val) \
do { \
   UNIVERSE_FIFO_WAIT; \
   (*(unsigned volatile long *)(addr)) = ((unsigned long)(val)); \
} while (0)

#define ibpeek(addr) *((unsigned volatile char *)(addr))
#define iwpeek(addr) *((unsigned volatile short *)(addr))
#define ilpeek(addr) *((unsigned volatile long *)(addr))

#else /* ! Lynx/Fantasia */
#define ibpoke(addr,val) (*(unsigned volatile char _far *)(addr))=((unsigned char)(val))
#define iwpoke(addr,val) (*(unsigned volatile short _far *)(addr))=((unsigned short)(val))
#define ilpoke(addr,val) (*(unsigned volatile long _far *)(addr))=((unsigned long)(val))
#define ibpeek(addr)     *((unsigned volatile char _far *)(addr))
#define iwpeek(addr)     *((unsigned volatile short _far *)(addr))
#define ilpeek(addr)     *((unsigned volatile long _far *)(addr))
#endif /* ! Lynx/Fantasia */
#endif /* ! _MS_DOS_WIN */

/* define VXI word serial commands for ivxiws() */
#if defined(I_SICL_VXI) && !defined(STD_SICL)
/* Misc. Word Serial Defines */
#define  WS_BNO_TOP_LVL    0x0100

/* Word Serial Commands */
#define  WS_CMD_ANO     0xc8ff
#define     WS_MASK_ANO    0xffff
#define  WS_CMD_AHL     0xa900
#define     WS_MASK_AHL    0xff00
#define  WS_CMD_AIL     0xaa00
#define     WS_MASK_AIL    0xff00
#define  WS_CMD_AMC     0xa800
#define     WS_MASK_AMC    0xff00
#define  WS_CMD_BNO     0xfcff
#define     WS_MASK_BNO    0xfeff
#define  WS_CMD_BA      0xbc00
#define  WS_CMD_BA_END     0xbd00
#define     WS_MASK_BA     0xfe00
#define  WS_CMD_BR      0xdeff
#define     WS_MASK_BR     0xffff
#define  WS_CMD_CLR     0xffff
#define     WS_MASK_CLR    0xffff
#define  WS_CMD_CL      0xefff
#define     WS_MASK_CL     0xffff
#define  WS_CMD_CE      0xaf00
#define     WS_MASK_CE     0xff00
#define  WS_CMD_ENO     0xc9ff
#define     WS_MASK_ENO    0xffff
#define  WS_CMD_RPE     0xcdff
#define     WS_MASK_RPE    0xffff
#define  WS_CMD_GD      0xbf00
#define     WS_MASK_GD     0xff00
#define  WS_CMD_IC      0xbe00
#define     WS_MASK_IC     0xff00
#define  WS_CMD_RHL     0x8c00
#define     WS_MASK_RHL    0xff00
#define  WS_CMD_RH      0xc7ff   
#define     WS_MASK_RH     0xffff
#define  WS_CMD_RIL     0x8d00
#define     WS_MASK_RIL    0xff00
#define  WS_CMD_RI      0xcaff
#define     WS_MASK_RI     0xffff
#define  WS_CMD_RMOD    0xccff
#define     WS_MASK_RMOD   0xffff
#define  WS_CMD_RP      0xdfff
#define     WS_MASK_RP     0xffff
#define  WS_CMD_RSTB    0xcfff
#define     WS_MASK_RSTB   0xffff
#define  WS_CMD_RSA     0xceff
#define     WS_MASK_RSA    0xffff
#define  WS_CMD_RD      0x8e00
#define     WS_MASK_RD     0xff00
#define  WS_CMD_CR      0x8f00
#define     WS_MASK_CR     0xff00
#define  WS_CMD_SL      0xeeff
#define     WS_MASK_SL     0xffff
#define  WS_CMD_SLMOD   0xae00
#define     WS_MASK_SLMOD  0xff00
#define  WS_CMD_SUMOD   0xad00
#define     WS_MASK_SUMOD  0xff00
#define  WS_CMD_TRIG    0xedff
#define     WS_MASK_TRIG   0xffff
#define  WS_CMD_USER    0x0000
#define     WS_MASK_USER   0x8000

#endif  /* VXI WS support */

/*
 * This is a collection of macros and entry points needed for
 * backwards compatability for SICL.  They are now a collection
 * of non-standard HPIB/GPIB macros.
 */
#if ! defined(STD_SICL)
#define I_SICL_HPIB              /* GP-IB ==> HP-IB */
#define I_INTF_HPIB  I_INTF_GPIB /* GP-IB ==> HP-IB */


#define I_INTR_HPIB_IFC         16
#define I_INTR_HPIB_PPOLLCONFIG 17
#define I_INTR_HPIB_REMLOC      18

#define I_HPIB_BUS_REM      I_GPIB_BUS_REM
#define I_HPIB_BUS_SRQ      I_GPIB_BUS_SRQ
#define I_HPIB_BUS_NDAC     I_GPIB_BUS_NDAC
#define I_HPIB_BUS_SYSCTLR  I_GPIB_BUS_SYSCTLR
#define I_HPIB_BUS_ACTCTLR  I_GPIB_BUS_ACTCTLR
#define I_HPIB_BUS_TALKER   I_GPIB_BUS_TALKER
#define I_HPIB_BUS_LISTENER I_GPIB_BUS_LISTENER
#define I_HPIB_BUS_ADDR     I_GPIB_BUS_ADDR

#define ihpibbusstatus    igpibbusstatus
#define ihpibppoll        igpibppoll
#define ihpibppollconfig  igpibppollconfig
#define ihpibpassctl      igpibpassctl
#define ihpibrenctl       igpibrenctl
#define ihpibatnctl       igpibatnctl
#define ihpibsendcmd      igpibsendcmd
#endif

#if defined(__cplusplus)
   };
#endif

#endif /* SICL_H */
