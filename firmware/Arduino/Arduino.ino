void setup() {
  Serial.begin(9600);
  
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);

  for (int x = 2; x<=11; x++){
    digitalWrite(x, LOW);
  }
}

void send_state() {
  char str[] = "0000000000";
  int state;

  for (int x = 2; x<=11; x++){
    state = digitalRead(x);
    if (state == HIGH) {
      str[x-2] = '1';
    } else {
      str[x-2] = '0';
    }
  }
  Serial.println(str);
}

void loop() {
  char c;
  char l;
  int pin;
  int state;
  
  if (Serial.available()) {
    c = Serial.read();
    if (c == 'O') {
      pin = Serial.parseInt();
      l = Serial.read();
      state = Serial.parseInt();


      if (pin == 99) {
        for (int x = 2; x<=11; x++){
          digitalWrite(x, state);
        }
      } else {
        digitalWrite(pin, state);
      }
      send_state();
    } else if (c == '?') {
      send_state();
    }
  }
}
