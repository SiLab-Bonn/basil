/*
------------------------------------------------------------
Copyright (c) All rights reserved
SiLab, Institute of Physics, University of Bonn
-----------------------------------------------------------
Using the Arduino Nano as temperature sensor via voltage divider and NTC thermistor.
Every analog pin is connected to read the voltage over a thermistor, therefore up to 8
temperature values can be recorded.
*/

// Define constants
const float KELVIN = 273.15; // Kelvin
const int SAMPLE_DELAY_US = 50; // Microseconds delay between two measurement samples
const int NTC_PINS [] = {A0, A1, A2, A3, A4, A5, A6, A7}; // Array of analog input pins on Arduino

// Default values
const int N_SAMPLES = 5; // Average each temperature value over N_SAMPLES analog reads
const uint16_t SERIAL_DELAY_MILLIS = 1; // Delay between Serial.available() checks
const float NTC_NOMINAL_RES = 10000.0; // Resistance of NTC at 25 degrees C
const float RESISTOR_RES = 10000.0; // Resistance of the resistors in series to the NTC, forming voltage divider
const float TEMP_NOMINAL_DEGREE_C = 25.0; // Nominal temperature for above resistance (almost always 25 C)
const float BETA_COEFFICIENT = 3950.0; // The beta coefficient of the NTC (usually 3000-4000); EPC B57891-M103 NTC Thermistor
const uint16_t MEAS_OVER_NTC = 0; // Whether the voltage drop in the divider configuration is measured over the NTC. If 0, then it is measured over the fixed resistor

// Serial related
const char END = '\n';
const uint8_t END_PEEK = int(END); // Serial.peek returns byte as dtype int
const char DELIM = ':';
const char NULL_TERM = '\0';
size_t nProcessedBytes;
const size_t BUF_SIZE = 32;
char serialBuffer[BUF_SIZE]; // Max buffer 32 bytes in incoming serial data


// Commands
const char TEMP_CMD = 'T';
const char RES_CMD = 'Q';
const char DELAY_CMD = 'D';
const char SAMPLE_CMD = 'S';
const char BETA_CMD = 'B';
const char NOMINAL_RES_CMD = 'O';
const char NOMINAL_TEMP_CMD = 'C';
const char RESISTANCE_CMD = 'R';
const char RESET_CMD = 'X';
const char MEAS_OVER_NTC_CMD = 'Y';


// Define variables to be used for calculation
float temperature;
float resistance;
int ntcPin;
bool oneLastProcess;


// Define vars potentially coming in from serial
int nSamples;
uint16_t serialDelayMillis; 
float ntcNominalRes;
float resistorRes;
float tempNominalDegreeC;
float betaCoefficient;
uint16_t measureOverNTC;


void restoreDefaults(){
  /*
  Resores default values of all variables that potentially come in over serial
  */
  nSamples = N_SAMPLES;
  serialDelayMillis = SERIAL_DELAY_MILLIS;
  ntcNominalRes = NTC_NOMINAL_RES;
  resistorRes = RESISTOR_RES;
  tempNominalDegreeC = TEMP_NOMINAL_DEGREE_C;
  betaCoefficient = BETA_COEFFICIENT;
  measureOverNTC = MEAS_OVER_NTC;
}


float steinhartHartNTC(float res){
  /*
  Steinhart-Hart equation for NTC: 1/T = 1/T_0 + 1/B * ln(R/R_0)  
  */

  // Do calculation
  temperature = 1.0 / (1.0 / (tempNominalDegreeC + KELVIN) + 1.0 / betaCoefficient * log(res / ntcNominalRes));

  // To Kelvin
  temperature -= KELVIN;
  
  return temperature;
}


float getRes(int ntc){
  /*
  Reads the voltage from analog pin *ntc_pin* in ADC units and converts them to resistance.
  */

  // Reset resitance
  resistance = 0;

  // take N samples in a row, with a slight delay
  for (int i=0; i< nSamples; i++){
    resistance += analogRead(ntc);
    delayMicroseconds(SAMPLE_DELAY_US);
  }

  // Do the average
  resistance /= nSamples;

  // Convert  ADC resistance value to resistance in Ohm
  resistance = 1023 / resistance - 1 ;

  // Voltage divider is measured over the NTC with NTC_NOMINAL_RES
  if (measureOverNTC > 0) {
    resistance = resistorRes / resistance;
  }

  // Voltage divider is measured over the fixed RESISTOR_RES
  else {
    resistance = resistorRes * resistance;  
  }

  return resistance;
}


float getTemp(int ntc){
  /*
  Reads the voltage from analog pin *ntc_pin* in ADC units and converts them to resistance.
  Returns the temperature calculated from Steinhart-Hart-Equation
  */
  return steinhartHartNTC(getRes(ntc));
}


uint8_t processIncoming(){

  // We have reached the end of the transmission; clear serial by calling read
  if (Serial.peek() == END_PEEK){
    Serial.read();
    serialBuffer[0] = NULL_TERM;
    return 0;
  }
  else {
    // Read to buffer until delimiter
    nProcessedBytes = Serial.readBytesUntil(DELIM, serialBuffer, BUF_SIZE);

    // Null-terminate string
    serialBuffer[nProcessedBytes] = NULL_TERM;
    return 1;
  }
}


void printNTCMeasurements(int kind){
  /*
  Read the input buffer, read pins to read and print the respective temp or resistance to serial
  */
  
  while (processIncoming()){
  
    ntcPin = atoi(serialBuffer);

    // We only have 8 analog pins
    if (0 <= ntcPin && ntcPin < 8) {
      if (kind == 0) {
        // Send out tempertaure in C, two decimal places, wait
        Serial.println(getTemp(NTC_PINS[ntcPin]), 2);
      } else {
        // Send out resitance in Ohm, two decimal places, wait
        Serial.println(getRes(NTC_PINS[ntcPin]));
      }
      delay(50);
    }
    else {
      // Pin out of range
      Serial.println(999);
    }
  }
}


void resetIncoming(){
  // Wait 500 ms and clear the incoming data
  delay(500);
  while(Serial.available()){
    Serial.read();
  }
}


void setup(void){
  /*
   * initiliaze with external ref voltage
   * initialize Serial communication with baudrate Serial.begin(<baudrate>)
   * delay 500ms to let connections and possible setups to be established
   */
  restoreDefaults(); // Restore default values
  Serial.begin(115200); // Initialize serial connection
  analogReference(EXTERNAL); // Set 3.3V as external reference voltage instead of internal 5V reference
  delay(500);
}


void loop(void){

  // Get input from serial connection
  if (Serial.available()){

    processIncoming();
    oneLastProcess = true;

    // First processing should yield a single char because it the cmd
    if (strlen(serialBuffer) == 1){

      // Lowercase means we want to set some value and print back that value on the serial bus
      if (isLowerCase(serialBuffer[0])){

        // Set number of samples
        if (toupper(serialBuffer[0]) == SAMPLE_CMD){
          processIncoming();
          nSamples = atoi(serialBuffer);
          Serial.println(nSamples);
        }

        // Set serial dealy in millis
        if (toupper(serialBuffer[0]) == DELAY_CMD){
          processIncoming();
          serialDelayMillis = atoi(serialBuffer);
          Serial.println(serialDelayMillis);
        }

        // Set beta coefficient in Kelvin
        if (toupper(serialBuffer[0]) == BETA_CMD){
          processIncoming();
          betaCoefficient = atof(serialBuffer);
          Serial.println(betaCoefficient);
        }

        // Set nominal resistance in Ohm
        if (toupper(serialBuffer[0]) == NOMINAL_RES_CMD){
          processIncoming();
          ntcNominalRes = atof(serialBuffer);
          Serial.println(ntcNominalRes);
        }

        // Set nominal temp in Celsius
        if (toupper(serialBuffer[0]) == NOMINAL_TEMP_CMD){
          processIncoming();
          tempNominalDegreeC = atof(serialBuffer);
          Serial.println(tempNominalDegreeC);
        }

        // Set resistance of resistor in voltage divider config in Ohm
        if (toupper(serialBuffer[0]) == RESISTANCE_CMD){
          processIncoming();
          resistorRes = atof(serialBuffer);
          Serial.println(resistorRes);
        }

        // Set whether we measure the voltage over the NTC or the fixed resistor in voltage divider config
        if (toupper(serialBuffer[0]) == MEAS_OVER_NTC_CMD){
          processIncoming();
          measureOverNTC = atoi(serialBuffer);
          Serial.println(measureOverNTC);
        }

        // Restore all variables to their default value
        if (toupper(serialBuffer[0]) == RESET_CMD){
          restoreDefaults();
          processIncoming();
          Serial.println(atoi(serialBuffer)); // Test response
        }

      }

      else {

        if (serialBuffer[0] == TEMP_CMD){
          printNTCMeasurements(0); // Temperature
          oneLastProcess = false;
        }

        if (serialBuffer[0] == RES_CMD){
          printNTCMeasurements(1); // Resistance
          oneLastProcess = false;
        }

        // Return serial delay millis
        if (serialBuffer[0] == DELAY_CMD){
          Serial.println(serialDelayMillis);
        }

        // Return number of samples
        if (serialBuffer[0] == SAMPLE_CMD){
          Serial.println(nSamples);
        }

        // Return beta coefficient in Kelvin
        if (serialBuffer[0] == BETA_CMD){
          Serial.println(betaCoefficient);
        }

        // Return nominal ntc resistance at nominal temp in Ohm
        if (serialBuffer[0] == NOMINAL_RES_CMD){
          Serial.println(ntcNominalRes);
        }

        // Return nominal ntc temp in Celsius
        if (serialBuffer[0] == NOMINAL_TEMP_CMD){
          Serial.println(tempNominalDegreeC);
        }

        // Return resistor value in voltage divider config in Ohm
        if (serialBuffer[0] == RESISTANCE_CMD){
          Serial.println(resistorRes);
        }

        // Return whether we measure over the NTC or fixed resistor
        if (serialBuffer[0] == MEAS_OVER_NTC_CMD){
          Serial.println(measureOverNTC);
        }

      }

      if (oneLastProcess){
        processIncoming();
      }

    } else{
      Serial.println("error");
      // resetIncoming(); //Does not do what I want
    }
  }
  delay(serialDelayMillis);
}
