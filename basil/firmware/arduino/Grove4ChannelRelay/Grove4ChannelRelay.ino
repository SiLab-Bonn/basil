#include <multi_channel_relay.h>

Multi_Channel_Relay relay;

const char END = '\n';
const uint8_t END_PEEK = int(END); // Serial.peek returns byte as dtype int
const char DELIM = ':';
const char NULL_TERM = '\0';

size_t nProcessedBytes;
const size_t BUF_SIZE = 32;
char serialBuffer[BUF_SIZE]; // Max buffer 32 bytes in incoming serial data

// Commands
const char READ_CMD = 'R';
const char WRITE_CMD = 'W';
const char DELAY_CMD = 'D';

// Variables coming in over serial
uint8_t varPin;
uint8_t varState;
uint16_t serialDelayMillis = 1; // Delay between Serial.available() checks


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


void send_state() {
  Serial.println(relay.getChannelState(), BIN);
}


void setup() {
    // Set I2C address and start relay
    relay.begin(0x11);

    // Initialize as outputs and off
    relay.channelCtrl(0);

    // Begin serial connection adn wait to establish
    Serial.begin(115200);
    delay(500);
}


void loop() {

    if (Serial.available()) {

        processIncoming();

        // First processing should yield a single char because it the cmd
        if (strlen(serialBuffer) == 1){

            // Lowercase means we want to set some value and print back that value on the serial bus
            if (isLowerCase(serialBuffer[0])){

                // Set serial dealy in millis
                if (toupper(serialBuffer[0]) == DELAY_CMD){
                    processIncoming();
                    serialDelayMillis = atoi(serialBuffer);
                    Serial.println(serialDelayMillis);
                }
            } else{

                // Return serial delay millis
                if (serialBuffer[0] == DELAY_CMD){
                    Serial.println(serialDelayMillis);
                }

                // Read the state
                if (serialBuffer[0] == READ_CMD){
                    send_state();
                }

                // Write the state
                if (serialBuffer[0] == WRITE_CMD){
                    processIncoming();
                    varPin = atoi(serialBuffer);
                    processIncoming();
                    varState = atoi(serialBuffer);
                    
                    if (varState == 0) {
                        if (varPin == 99) {
                            relay.channelCtrl(0);
                        }
                        else {
                            relay.turn_off_channel(varPin);
                        }  
                    }
                    if (varState == 1) {
                        if (varPin == 99) {
                            relay.channelCtrl(0xf);
                        }
                        else {
                            relay.turn_on_channel(varPin);
                        }
                    }
                    send_state();
                }
            }

            // At this point command should have been processed
            // This last call to processIncoming should just remove the END char from serial buffer
            processIncoming();

        } else {
            Serial.println("error");
        }

    }
    delay(serialDelayMillis);
}
