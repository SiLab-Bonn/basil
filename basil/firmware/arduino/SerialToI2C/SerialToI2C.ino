#include <Wire.h> //i2c

/*
 * Initialize global variables and arrays
 * -> 8 bit i2c address of bus device
 * number of arguments to read
 * lenght of these arguments
 * (argnum x arglen)-array to hold all data
 * some chars for serial communication (argument seperator and end-character)
 */


uint8_t i2cAddress; // Store I2C address
uint8_t i2cRetCode; // Store I2C return code

const char END = '\n';
const uint8_t END_PEEK = int(END); // Serial.peek returns byte as dtype int
const char DELIM = ':';
const char NULL_TERM = '\0';

size_t nProcessedBytes;
const size_t BUF_SIZE = 32;
char serialBuffer[BUF_SIZE]; // Max buffer 32 bytes in incoming serial data

// Commands
const char ADDR_CMD = 'A';
const char CHECK_CMD = 'T';
const char READ_CMD = 'R';
const char WRITE_CMD = 'W';
const char DELAY_CMD = 'D';

// Variables coming in over serial
uint8_t varReg;
uint8_t varData;
uint16_t serialDelayMillis = 1; // Delay between Serial.available() checks


uint8_t writeReg(uint8_t reg, uint8_t data){
  /*
   * transmit data via i2c to device on i2cAddress
   * write register _reg to be written on and write _data on it
   * end transmission and return the errorcode (0 is success) see documentation for further info
   */
  Wire.beginTransmission(i2cAddress);
  Wire.write(reg);
  Wire.write(data);
  return Wire.endTransmission();
}


uint8_t pointToReg(uint8_t reg){
  /*
   * point to register
   */
  Wire.beginTransmission(i2cAddress);
  Wire.write(reg);
  return Wire.endTransmission();
}


uint8_t readCurrentReg(){
  /*
   * read from currently pointed-to register
   */
  Wire.requestFrom(i2cAddress, 0x1U); //request 1 byte (Unsigned) from Adress i2cAddress
  return Wire.read();
}


uint8_t readReg(uint8_t reg){
  /*
   * read data via i2c from device in i2cAddress
   * write register to be read from
   * request data from device
   * read the received data from device i2cAddress register _reg and return it
   */
  pointToReg(reg);
  return readCurrentReg();
}


uint8_t checkWire(){
  /*
   * Checks the wire connection at i2cAddress
   * Return value of Wire.endTransmission:
   * 0:success
   * 1:data too long to fit in transmit buffer
   * 2:received NACK on transmit of address
   * 3:received NACK on transmit of data
   * 4:other error  
   */
   Wire.beginTransmission(i2cAddress);
   return Wire.endTransmission();
}


void processIncoming(){

  // We have reached the end of the transmission; clear serial by calling read
  if (Serial.peek() == END_PEEK){
    Serial.read();
    serialBuffer[0] = NULL_TERM;
  }
  else {
    // Read to buffer until delimiter
    nProcessedBytes = Serial.readBytesUntil(DELIM, serialBuffer, BUF_SIZE);

    // Null-terminate string
    serialBuffer[nProcessedBytes] = NULL_TERM;
  }
}


void resetIncoming(){
  // Wait 500 ms and clear the incoming data
  delay(500);
  while(Serial.available()){
    Serial.read();
  }
}


void setup() {
  /*
   * initiliaze i2c commication as master
   * initialize Serial communication with baudrate Serial.begin(<baudrate>)
   * delay 500ms to let connections and possible setups to be established
   */
  Wire.begin();
  Serial.begin(115200);
  delay(500);
}


void loop(){

  if (Serial.available()){

    processIncoming();

    // First processing should yield a single char because it the cmd
    if (strlen(serialBuffer) == 1){

      // Lowercase means we want to set some value and print back that value on the serial bus
      if (isLowerCase(serialBuffer[0])){
        
        // Set I2C address
        if (toupper(serialBuffer[0]) == ADDR_CMD){
          processIncoming();
          i2cAddress = atoi(serialBuffer);
          Serial.println(i2cAddress);
        }

        // Set serial dealy in millis
        if (toupper(serialBuffer[0]) == DELAY_CMD){
          processIncoming();
          serialDelayMillis = atoi(serialBuffer);
          Serial.println(serialDelayMillis);
        }
      
      }

      // Here we want to read something or interact with the I2C bus
      else {
        // Return I2C address
        if (serialBuffer[0] == ADDR_CMD){
          Serial.println(i2cAddress);
        }

        // Return serial delay millis
        if (serialBuffer[0] == DELAY_CMD){
          Serial.println(serialDelayMillis);
        }

        // Check I2C connection
        if (serialBuffer[0] == CHECK_CMD){
          i2cRetCode = checkWire();
          Serial.println(i2cRetCode);
        }

        // Read
        if (serialBuffer[0] == READ_CMD){
          processIncoming();
          varReg = atoi(serialBuffer);
          i2cRetCode = pointToReg(varReg);
          Serial.println(i2cRetCode);
          Serial.println(readCurrentReg());

        }
        
        // Write
        if (serialBuffer[0] == WRITE_CMD){
          processIncoming();
          varReg = atoi(serialBuffer);
          processIncoming();
          varData = atoi(serialBuffer);
          i2cRetCode = writeReg(varReg, varData);
          Serial.println(i2cRetCode);

        }
      }

      // At this point command should have been processed
      // This last call to processIncoming should just remove the END char from serial buffer
      processIncoming();

    }
    else {
      Serial.println("error");
      // resetIncoming(); //Does not do what I want
    }

  }
  delay(serialDelayMillis);
}
