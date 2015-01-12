//-----------------------------------------------------------------------------
// Constants for SILAB_USB_REQUEST dispatch
//-----------------------------------------------------------------------------
#ifndef SURConstantsH
#define SURConstantsH 1

//#pragma message SURConstants.h wird gelesen

#define FW_VERSION "20"

#define SUR_CONTROL_PIPE     0
#define SUR_DATA_OUT_PIPE    1
#define SUR_DATA_IN_PIPE     3

#define SUR_CONTROL_PIPE_FX     0
#define SUR_DATA_OUT_PIPE_FX    0
#define SUR_DATA_IN_PIPE_FX     1
#define SUR_DATA_FASTOUT_PIPE   2
#define SUR_DATA_FASTIN_PIPE    3
#define SUR_DIRECT_OUT_PIPE     4
#define SUR_DIRECT_IN_PIPE      5

#define SUR_DIR_OUT      0x00
#define SUR_DIR_IN       0x01

#define SUR_TYPE_LOOP     0
#define SUR_TYPE_8051     1
#define SUR_TYPE_XILINX   2
#define SUR_TYPE_EXTERNAL 3
#define SUR_TYPE_FIFO     4  
#define SUR_TYPE_I2C      5
#define SUR_TYPE_I2C_NV   6
#define SUR_TYPE_LATCH    7
#define SUR_TYPE_ADC      8
#define SUR_TYPE_CMD      9
#define SUR_TYPE_EEPROM  10
#define SUR_TYPE_RF      11
#define SUR_TYPE_SPI     12  // SmartCard
#define SUR_TYPE_ADCSPI  13  // SmartCard
#define SUR_TYPE_SERIAL   0  //obsolete
#define SUR_TYPE_XCONF   14
#define SUR_TYPE_FWVER   15
#define SUR_TYPE_GPIFBYTE 16
#define SUR_TYPE_GPIFBLOCK 17
#define SUR_TYPE_DEBUG   99  
#define SUR_TYPE_DATA   255  // for BT interface only

#define NO_CS_DESELECT   0x80

typedef struct _SILAB_USB_REQUEST_B
{
  unsigned char type;   // defines data source
  unsigned char dir;    // transfer direction
  unsigned char addr[4];
  unsigned char length[4]; // data block size
} SILAB_USB_REQUEST_B, *PSILAB_USB_REQUEST_B;

typedef struct _SILAB_USB_REQUEST
{
  unsigned char type;   // defines data source
  unsigned char dir;    // transfer direction
  int addr;
  int length; // data block size
} SILAB_USB_REQUEST, *PSILAB_USB_REQUEST;


#define EEPROM_USER_DATA_OFFSET     0x1f80 //!< address offset for user data (calibration and ID) in EEPROM
#define EEPROM_USER_DATA_OFFSET_FX  0x3000 //!< address offset for user data (calibration and ID) in EEPROM
#define EEPROM_USER_DATA_OFFSET_FX3  0     //!< address offset for user data (calibration and ID) in EEPROM

#ifdef FX3 // for uC firmware only !!!
  #define EEPROM_OFFSET_ADDR  EEPROM_USER_DATA_OFFSET_FX3
#elif FX // for uC firmware only !!!
  #define EEPROM_OFFSET_ADDR  EEPROM_USER_DATA_OFFSET_FX
#else
  #define EEPROM_OFFSET_ADDR  EEPROM_USER_DATA_OFFSET
#endif

#define EEPROM_MFG_ADDR     (EEPROM_OFFSET_ADDR)
#define EEPROM_MFG_SIZE     21
#define EEPROM_NAME_ADDR    (EEPROM_MFG_ADDR + EEPROM_MFG_SIZE)
#define EEPROM_NAME_SIZE    21
#define EEPROM_ID_ADDR      (EEPROM_NAME_ADDR + EEPROM_NAME_SIZE)
#define EEPROM_ID_SIZE      5
#define EEPROM_LIAC_ADDR    (EEPROM_ID_ADDR + EEPROM_ID_SIZE)
#define EEPROM_LIAC_SIZE    1
#define EEPROM_CAL_ADDR     (EEPROM_LIAC_ADDR + EEPROM_LIAC_SIZE)
#define EEPROM_CAL_SIZE     72 // (#sensors=9) * (gain + offset =2) * (sizeof(float)=4)

#define EEPROM_MFG_ADDR_FX  (EEPROM_USER_DATA_OFFSET_FX)
#define EEPROM_MFG_SIZE     21
#define EEPROM_NAME_ADDR_FX (EEPROM_MFG_ADDR_FX + EEPROM_MFG_SIZE)
#define EEPROM_NAME_SIZE    21
#define EEPROM_ID_ADDR_FX   (EEPROM_NAME_ADDR_FX + EEPROM_NAME_SIZE)
#define EEPROM_ID_SIZE      5
#define EEPROM_LIAC_ADDR_FX (EEPROM_ID_ADDR_FX + EEPROM_ID_SIZE)
#define EEPROM_LIAC_SIZE    1
#define EEPROM_CAL_ADDR_FX  (EEPROM_LIAC_ADDR + EEPROM_LIAC_SIZE)
#define EEPROM_CAL_SIZE     72 // (#sensors=9) * (gain + offset =2) * (sizeof(float)=4)

#define EEPROM_XBIT_ADDR   0x4000
#define EEPROM_XBIT_SIZE   16061

typedef struct EEPROM_MFG_STRUCT_T
{
  unsigned char length;
  char content[EEPROM_MFG_SIZE];
} EEPROM_MFG_STRUCT;

typedef struct EEPROM_NAME_STRUCT_T
{
  unsigned char length;
  char content[EEPROM_NAME_SIZE];
} EEPROM_NAME_STRUCT;

typedef struct EEPROM_ID_STRUCT_T
{
  unsigned char length;
  char content[EEPROM_ID_SIZE];
} EEPROM_ID_STRUCT;

#endif
