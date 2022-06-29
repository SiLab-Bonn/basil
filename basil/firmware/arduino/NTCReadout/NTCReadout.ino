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
const float NTC_NOMINAL_RES = 10000.0; // Resistance of NTC at 25 degrees C
const float RESISTOR_RES = 10000.0; // Resistance of the resistors in series to the NTC, forming voltage divider
const float TEMP_NOMINAL = 25.0; // Nominal temperature for above resistance (almost always 25 C)
const float BETA_COEFF = 3950.0; // The beta coefficient of the NTC (usually 3000-4000); EPC B57891-M103 NTC Thermistor
const float KELVIN = 273.15; // Kelvin
const int SAMPLE_DELAY_US = 50; // Microseconds delay between two measurement samples
const int NTC_PINS [] = {A0, A1, A2, A3, A4, A5, A6, A7}; // Array of analog input pins on Arduino


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
const char DELAY_CMD = 'D';
const char SAMPLE_CMD = 'S';


// Define variables to be used for calculation
float temperature;
float resistance;
int ntcPin;
bool oneLastProcess;


// Define vars potentially coming in from serial
int nSamples = 5; // Average each temperature value over N_SAMPLES analog reads
uint16_t serialDelayMillis = 1; // Delay between Serial.available() checks


float steinhartHartNTC(float res){
  /*
  Steinhart-Hart equation for NTC: 1/T = 1/T_0 + 1/B * ln(R/R_0)  
  */

  // Do calculation
  temperature = 1.0 / (1.0 / (TEMP_NOMINAL + KELVIN) + 1.0 / BETA_COEFF * log(res / NTC_NOMINAL_RES));

  // To Kelvin
  temperature -= KELVIN;
  
  return temperature;
}


float getTemp(int ntc){
  /*
  Reads the voltage from analog pin *ntc_pin* in ADC units and converts them to resistance.
  Returns the temperature calculated from Steinhart-Hart-Equation
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
  resistance = RESISTOR_RES / resistance;

  return steinhartHartNTC(resistance);
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


void printNTCTemps(){
  /*
  Read the input buffer, read pins to read and print the respective temp to serial
  */
  
  while (processIncoming()){
  
    ntcPin = atoi(serialBuffer);

    // We only have 8 analog pins
    if (0 <= ntcPin && ntcPin < 8) {
      // Send out, two decimal places, wait
      Serial.println(getTemp(NTC_PINS[ntcPin]), 2);
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
  Serial.begin(115200); // Initialize serial connection
  analogReference(EXTERNAL); // Set 3.3V as external reference voltage instead of internal 5V reference
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

        // Set numper of samples
        if (toupper(serialBuffer[0]) == SAMPLE_CMD){
          processIncoming();
          nSamples = atoi(serialBuffer);
          processIncoming();
          Serial.println(nSamples);
        }

        // Set serial dealy in millis
        if (toupper(serialBuffer[0]) == DELAY_CMD){
          processIncoming();
          serialDelayMillis = atoi(serialBuffer);
          Serial.println(serialDelayMillis);
        }
      }

      else {

        if (serialBuffer[0] == TEMP_CMD){
          printNTCTemps();
          oneLastProcess = false;
        }

        // Return serial delay millis
        if (serialBuffer[0] == DELAY_CMD){
          Serial.println(serialDelayMillis);
        }

        if (serialBuffer[0] == SAMPLE_CMD){
          Serial.println(nSamples);
        }

      }

      if (oneLastProcess){
        processIncoming();
      }

    } else{
      Serial.println("error");
      resetIncoming();
    }
  }
  delay(serialDelayMillis);
}
