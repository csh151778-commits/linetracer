#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

RF24 radio(9, 10);
const byte address[6] = "00001";
const int N_SAMPLES = 5;

int readAvg(uint8_t pin, int n = N_SAMPLES) {
  long acc = 0;
  for (int i = 0; i < n; i++) {
    acc += analogRead(pin);
    delayMicroseconds(300);
  }
  return (int)(acc / n);
}

void setup() {
  Serial.begin(9600);
  radio.begin();
  radio.setChannel(76);
  radio.setDataRate(RF24_250KBPS);
  radio.setPALevel(RF24_PA_MIN);
  radio.setRetries(5, 15);
  radio.openWritingPipe(address);
  radio.stopListening();
}

void loop() {
  int x = readAvg(A0);
  int y = readAvg(A1);
  char code = 'C';

  // 위(U): X가 0~1023 사이 && Y가 900 이상
  if (x >= 0 && x <= 1023 && y >= 900) {
    code = 'U';
  }
  // 아래(D): X가 0~1023 사이 && Y가 200 이하
  else if (x >= 0 && x <= 1023 && y <= 200) {
    code = 'D';
  }
  // 왼쪽(L): Y가 0~1023 사이 && X가 200 이하
  else if (y >= 0 && y <= 1023 && x <= 200) {
    code = 'L';
  }
  // 오른쪽(R): Y가 0~1023 사이 && X가 900 이상
  else if (y >= 0 && y <= 1023 && x >= 900) {
    code = 'R';
  }
  // 중앙(C): 그 외
  else {
    code = 'C';
  }

  bool ok = radio.write(&code, 1);
  Serial.print("x="); Serial.print(x);
  Serial.print(" y="); Serial.print(y);
  Serial.print(" dir="); Serial.print(code);
  Serial.println(ok ? "  [TX OK]" : "  [TX FAIL]");
  delay(150);
}
