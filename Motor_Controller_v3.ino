//Control variables
const unsigned int Ts = 10000; // sample time in us
const int UPDATE = 50; // number of samples between serial data updates
const bool SERIAL_OUTPUT = true; // set to true to send data out serial line
const bool SERIAL_DIAGNOSE = false; // set to true to send back what was recieved
const float EncoderScaling = 2 * 3.141 / 1440; // Encoder counts to radians
const int MAX_CHANGE = 10; // If the position of an encoder jumps by more than this number, flag an error

// Digial/output
//   Motor
const int ENABLE = 4;
const int PWMA = 9;
const int DIRA = 7;
const int MAFB = 0; // current sense
const int PWMB = 10;
const int DIRB = 8;
const int DIRC = 5;
const int PWMC = 6;


// Speed Controller gains
const float P = 1000;
const float Pd = 50;
const float PInt = 2000;
const float umax = 75;

// Switches
//#define DECREASE 16
//#define INCREASE 17
//#define TIGHTEN 20
/*
*Quadrature Decoder
*/
#include "Arduino.h"
#include <digitalWriteFast.h>  // library for high performance reads and writes by jrraines
// see http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1267553811/0
// and http://code.google.com/p/digitalwritefast/
// It turns out that the regular digitalRead() calls are too slow and bring the arduino down when
// I use them in the interrupt routines while the motor runs at full speed.

// Pin Change interrups http://gammon.com.au/interrupts
// Pin Change Interrupt Request 0 (pins D8 to D13) (PCINT0_vect)
// Pin Change Interrupt Request 1 (pins A0 to A5)  (PCINT1_vect)
// Pin Change Interrupt Request 2 (pins D0 to D7)  (PCINT2_vect)
//
#define Debounce_Time 200 // ms

// Quadrature encoders
#define c_FirstEncoderPinA 18 // yellow
#define c_FirstEncoderPinB 19 // non-yellow
#define c_SecondEncoderPinA 2 // yellow
#define c_SecondEncoderPinB 3 // non-yellow
#define c_ThirdEncoderPinA 20 // yellow
#define c_ThirdEncoderPinB 21 // white
#define FALSE 0
#define TRUE 1

volatile bool _FirstEncoderASet;
volatile bool _FirstEncoderBSet;
volatile bool _FirstEncoderAPrev;
volatile bool _FirstEncoderBPrev;
volatile long _FirstEncoderTicks = 0;

volatile bool _SecondEncoderASet;
volatile bool _SecondEncoderBSet;
volatile bool _SecondEncoderAPrev;
volatile bool _SecondEncoderBPrev;
volatile long _SecondEncoderTicks = 0;

volatile bool _ThirdEncoderASet;
volatile bool _ThirdEncoderBSet;
volatile bool _ThirdEncoderAPrev;
volatile bool _ThirdEncoderBPrev;
volatile long _ThirdEncoderTicks = 0;


// Controller variables
int Pos1 = 0;
int Pos1old = 0;
float Pos1rad = 0;
volatile float ref1 = 0;
float xvel1 = 0;
float err1 = 0;
float err1int = 0;
float u1;
int uint1;

int Pos2 = 0;
int Pos2old = 0;
float Pos2rad = 0;
volatile float ref2 = 0;
float xvel2 = 0;
float err2 = 0;
float err2int = 0;
float u2;
int uint2;

int Pos3 = 0;
int Pos3old = 0;
float Pos3rad = 0;
volatile float ref3 = 0;
float xvel3 = 0;
float err3 = 0;
float err3int = 0;
float u3;
int uint3;



int incomingByte = 0;
// Time variables
unsigned int last_time = 0;
unsigned int current_time = 0;
unsigned int k = 1;
volatile bool tighten = FALSE;
volatile long last_interrupt_time = 0;
bool problem = false;

// Serial Communication
String inputString = "";         // a string to hold incoming data
String tempstring= "";
bool stringComplete = false;  // whether the string is complete


void pciSetup(byte pin)
{
  *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
  PCIFR  |= bit (digitalPinToPCICRbit(pin)); // clear any outstanding interrupt
  PCICR  |= bit (digitalPinToPCICRbit(pin)); // enable interrupt for the group
}

void setup() {

  // Quadrature encoders
  // Left encoder
  pinMode(c_FirstEncoderPinA, INPUT_PULLUP);     // sets pin A as input
  //digitalWrite(c_FirstEncoderPinA, LOW);  // turn on pullup resistors
  pinMode(c_FirstEncoderPinB, INPUT_PULLUP);      // sets pin B as input
  //digitalWrite(c_FirstEncoderPinB, LOW);  // turn on pullup resistors
  
  pinMode(c_SecondEncoderPinA, INPUT_PULLUP);      // sets pin A as input
  //digitalWrite(c_SecondEncoderPinA, LOW);  // turn on pullup resistors
  pinMode(c_SecondEncoderPinB, INPUT_PULLUP);      // sets pin B as input
  //digitalWrite(c_SecondEncoderPinB, LOW);  // turn on pullup resistors
  
  pinMode(c_ThirdEncoderPinA, INPUT_PULLUP);      // sets pin A as input
  //digitalWrite(c_ThirdEncoderPinA, LOW);  // turn on pullup resistors
  pinMode(c_ThirdEncoderPinB, INPUT_PULLUP);      // sets pin B as input
  //digitalWrite(c_ThirdEncoderPinB, LOW);  // turn on pullup resistors
  
  attachInterrupt(digitalPinToInterrupt(c_FirstEncoderPinA), HandleLeftMotorInterruptA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(c_FirstEncoderPinB), HandleLeftMotorInterruptB, CHANGE);
  attachInterrupt(digitalPinToInterrupt(c_SecondEncoderPinA), HandleSecondInterruptA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(c_SecondEncoderPinB), HandleSecondInterruptB, CHANGE);
  attachInterrupt(digitalPinToInterrupt(c_ThirdEncoderPinA), HandleThirdInterruptA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(c_ThirdEncoderPinB), HandleThirdInterruptB, CHANGE);



  // Setup Motor and Gyro Pin Modes
  pinMode(DIRA, OUTPUT);
  pinMode(PWMA, OUTPUT);
  pinMode(DIRB,OUTPUT);
  pinMode(PWMB,OUTPUT);
  pinMode(PWMC, OUTPUT);  
  pinMode(DIRC, OUTPUT);
  pinMode(ENABLE, OUTPUT);


  // Setup Motor
  digitalWrite(ENABLE, HIGH);

  TCCR1B = (TCCR1B & 0b11111000) | 0x04; // change PWM frequency  http://playground.arduino.cc/Main/TimerPWMCheatsheet

  Serial.begin(115200);

  last_time = micros();
  ref1 = 0; // reference position in radians

  // Switches
  //    pinMode(DECREASE, INPUT);     //set the pin to input
  //    digitalWrite(DECREASE, HIGH); // use internal pullup resistor
  //    pinMode(INCREASE, INPUT);     //set the pin to input
  //    digitalWrite(INCREASE, HIGH); // use internal pullup resistor
  //     pinMode(TIGHTEN, INPUT);     //set the pin to input
  //   digitalWrite(TIGHTEN, HIGH); // use internal pullup resistor
  

  if (SERIAL_OUTPUT) {
    Serial.println();
    Serial.print("M1 StPt");
    Serial.print("\t");
    Serial.print("M1 Pos");
    Serial.print("\t");
    Serial.print("M1 Volt");
    Serial.print("\t");
    Serial.print("M1 Err");
    Serial.print("\t");
    Serial.print("\t");
    Serial.print("M2 StPt");
    Serial.print("\t");
    Serial.print("M2 Pos");
    Serial.print("\t");
    Serial.print("M2 Volt");
    Serial.print("\t");
    Serial.print("M2 Err");
    Serial.print("\t");
    Serial.print("\t");
    Serial.print("M3 StPt");
    Serial.print("\t");
    Serial.print("M3 Pos");
    Serial.print("\t");
    Serial.print("M3 Volt");
    Serial.print("\t");
    Serial.print("M3 Err");
    Serial.print("\t");
    Serial.print("Exe Time");  //Time to Execute
    Serial.print("\t");
    Serial.println("Error");
  }

}

void loop() {
  
  if (stringComplete) {
    //Serial.println(inputString);
    
    //  while (Serial.available() > 0) {
    //    // read the incoming byte:
    //    incomingByte = Serial.read();
    //
    //    // say what you got:
    if (SERIAL_DIAGNOSE) {
       Serial.print("got: ");
        Serial.println(incomingByte, DEC);
    }

    // Acknowledge an error if it happened
    if (problem && inputString.substring(0,2) == "OK"){
      Serial.println("Error acknowledged");
      problem = false;
    }
    
    switch (inputString.charAt(0)) {
      case 'P': // Go to position immediately
          tempstring=inputString.substring(2);
          tighten = FALSE;
//          Serial.println(tempstring);
        switch (inputString.charAt(1)) {
          case '1':
            ref1 = EncoderScaling * (float)tempstring.toInt();
            break;
          case '2':
            ref2 = EncoderScaling * (float)tempstring.toInt();
            break;
          case '3':
            ref3 = EncoderScaling * (float)tempstring.toInt();
            break;
          default:
            // nothing
            break;
        }
        break;
//        case 'R': // Ramp to position
//          tempstring=inputString.substring(2);
//          tighten = FALSE;
////          Serial.println(tempstring);
//        switch (inputString.charAt(1)) {
//          case '1':
//            ref1 = EncoderScaling * (float)tempstring.toInt();
//            break;
//          case '2':
//            ref2 = EncoderScaling * (float)tempstring.toInt();
//            break;
//          default:
//            // nothing
//            break;
//        }
//        break;
      case 84: // T
        tighten = TRUE;
        
        break;
      default:
        // nothing
        break;
    }
    // clear the string:
    inputString = "";
    stringComplete = false;
  }
  //  incomingByte = 0;

  if (!problem){    
    // Read First encoder
    Pos1 = _FirstEncoderTicks;

    // Check for an error
    if (difference(Pos1, Pos1old) >= MAX_CHANGE){
      problem = true;
      Serial.println("Error in Encoder 1. Type 'OK' to issue commands again");
    }

    Pos1rad = EncoderScaling * (float)Pos1;
    xvel1 = -EncoderScaling * (float)(Pos1 - Pos1old);
    xvel1 = xvel1 * 1000000.0 / (float)Ts;
    Pos1old = Pos1;
  
    // Position Control
    err1 = ref1 - Pos1rad;
    err1int = err1int + err1 * Ts / 1000000.0;
    u1 = (int)(P * err1 + Pd * xvel1 + PInt * err1int);
    // Anti-windup
    if (abs(u1) > umax) {
      u1 = umax * sgn(u1);
      if (P > 0) {
        err1 = max(u1 / P, err1);
      }
      if (PInt > 0) {
        err1int = ((float)u1 - P * err1 - Pd * xvel1) / PInt;
      }
    }
  
    // Read Second encoder
    Pos2 = _SecondEncoderTicks;

    // Check for an error
    if (difference(Pos2, Pos2old) >= MAX_CHANGE){
      problem = true;
      Serial.println("Error in Encoder 2. Type 'OK' to issue commands again");
    }
    Pos2rad = EncoderScaling * (float)Pos2;
    xvel2 = -EncoderScaling * (float)(Pos2 - Pos2old);
    xvel2 = xvel2 * 1000000.0 / (float)Ts;
    Pos2old = Pos2;
    
    // Position Control
    err2 = ref2 - Pos2rad;
    err2int = err2int + err2 * Ts / 1000000.0;
    u2 = (int)(P * err2 + Pd * xvel2 + PInt * err2int);
    // Anti-windup
    if (abs(u2) > umax) {
      u2 = umax * sgn(u2);
      if (P > 0) {
        err2 = max(u2 / P, err2);
      }
      if (PInt > 0) {
        err2int = ((float)u2 - P * err2 - Pd * xvel2) / PInt;
      }
    }
    
    // Read Third encoder
    Pos3 = _ThirdEncoderTicks;

    // Check for an error
    if (difference(Pos3, Pos3old) >= MAX_CHANGE){
      problem = true;
      Serial.println("Error in Encoder 3. Type 'OK' to issue commands again");
    }
    Pos3rad = EncoderScaling * (float)Pos3;
    xvel3 = -EncoderScaling * (float)(Pos3 - Pos3old);
    xvel3 = xvel3 * 1000000.0 / (float)Ts;
    Pos3old = Pos3;
    
    // Position Control
    err3 = ref3 - Pos3rad;
    err3int = err3int + err3 * Ts / 1000000.0;
    u3 = (int)(P * err3 + Pd * xvel3 + PInt * err3int);
    // Anti-windup
    if (abs(u3) > umax) {
      u3 = umax * sgn(u3);
      if (P > 0) {
        err3 = max(u3 / P, err3);
      }
      if (PInt > 0) {
        err3int = ((float)u3 - P * err3 - Pd * xvel3) / PInt;
      }
    }
  } else {
    u1 = 0;
    u2 = 0;
    u3 = 0;
  }

  // Data Outputs

  k = k + 1;
  if (k >= UPDATE) {
    if (tighten & (abs(err1int) < .02)) {
      ref1 = ref1 - EncoderScaling * 10;
    }
    if (SERIAL_OUTPUT) {
      Serial.print(ref1, 4);
      Serial.print("\t");
      Serial.print(Pos1rad, 4);
      Serial.print("\t");
      Serial.print(u1);
      Serial.print("\t");
      Serial.print(err1int);
      Serial.print("\t");
      Serial.print("\t");
      Serial.print(ref2, 4);
      Serial.print("\t");
      Serial.print(Pos2rad, 4);
      Serial.print("\t");
      Serial.print(u2);
      Serial.print("\t");
      Serial.print(err2int);
      Serial.print("\t");
      Serial.print("\t");
      Serial.print(ref3, 4);
      Serial.print("\t");
      Serial.print(Pos3rad, 4);
      Serial.print("\t");
      Serial.print(u3);
      Serial.print("\t");
      Serial.print(err3int);
      Serial.print("\t");
      current_time = micros();
      Serial.print(current_time - last_time);
      Serial.print("\t");
      Serial.println(problem);

      k = 1;
    }
  }
  current_time = micros();
  while ((current_time - last_time) < Ts) {
    current_time = micros();
  }
  last_time = current_time;


  // Send out command
  if (u1 < 0) {
    digitalWriteFast(DIRA, LOW);
    u1 = min(-u1, 255);
    analogWrite(PWMA, u1);
  } else {
    digitalWriteFast(DIRA, HIGH);
    u1 = min(u1, 255);
    analogWrite(PWMA, u1);
  }

  // Send out command
  if (u2 < 0) {
    digitalWriteFast(DIRB, LOW);
    u2 = min(-u2, 255);
    analogWrite(PWMB, u2);
  } else {
    digitalWriteFast(DIRB, HIGH);
    u2 = min(u2, 255);
    analogWrite(PWMB, u2);
  }
  
  // Send out command
  if (u3 < 0) {
    digitalWriteFast(DIRC, LOW);
    u3 = min(-u3, 255);
    analogWrite(PWMC, u3);
  } else {
    digitalWriteFast(DIRC, HIGH);
    u3 = min(u3, 255);
    analogWrite(PWMC, u3);
  }


}


// Interrupt service routines for the left motor's quadrature encoder
void HandleLeftMotorInterruptA() {
  
  _FirstEncoderBSet = digitalReadFast(c_FirstEncoderPinB);
  _FirstEncoderASet = digitalReadFast(c_FirstEncoderPinA);

  _FirstEncoderTicks += ParseEncoder(_FirstEncoderAPrev, _FirstEncoderBPrev, _FirstEncoderASet, _FirstEncoderBSet);

  _FirstEncoderAPrev = _FirstEncoderASet;
  _FirstEncoderBPrev = _FirstEncoderBSet;
}

// Interrupt service routines for the right motor's quadrature encoder
void HandleLeftMotorInterruptB() {

  // Test transition;
  _FirstEncoderBSet = digitalReadFast(c_FirstEncoderPinB);
  _FirstEncoderASet = digitalReadFast(c_FirstEncoderPinA);

  _FirstEncoderTicks += ParseEncoder(_FirstEncoderAPrev, _FirstEncoderBPrev, _FirstEncoderASet, _FirstEncoderBSet);

  _FirstEncoderAPrev = _FirstEncoderASet;
  _FirstEncoderBPrev = _FirstEncoderBSet;
}


// Interrupt service routines for the second encoder
void HandleSecondInterruptA() {
  _SecondEncoderBSet = digitalReadFast(c_SecondEncoderPinB);
  _SecondEncoderASet = digitalReadFast(c_SecondEncoderPinA);

  _SecondEncoderTicks += ParseEncoder(_SecondEncoderAPrev, _SecondEncoderBPrev, _SecondEncoderASet, _SecondEncoderBSet);

  _SecondEncoderAPrev = _SecondEncoderASet;
  _SecondEncoderBPrev = _SecondEncoderBSet;
}

// Interrupt service routines for the second encoder
void HandleSecondInterruptB() {
  // Test transition;
  _SecondEncoderBSet = digitalReadFast(c_SecondEncoderPinB);
  _SecondEncoderASet = digitalReadFast(c_SecondEncoderPinA);

  _SecondEncoderTicks += ParseEncoder(_SecondEncoderAPrev, _SecondEncoderBPrev, _SecondEncoderASet, _SecondEncoderBSet);

  _SecondEncoderAPrev = _SecondEncoderASet;
  _SecondEncoderBPrev = _SecondEncoderBSet;
}

// Interrupt service routines for the second encoder
void HandleThirdInterruptA() {
  _ThirdEncoderBSet = digitalReadFast(c_ThirdEncoderPinB);
  _ThirdEncoderASet = digitalReadFast(c_ThirdEncoderPinA);

  _ThirdEncoderTicks += ParseEncoder(_ThirdEncoderAPrev, _ThirdEncoderBPrev, _ThirdEncoderASet, _ThirdEncoderBSet);

  _ThirdEncoderAPrev = _ThirdEncoderASet;
  _ThirdEncoderBPrev = _ThirdEncoderBSet;
}

// Interrupt service routines for the Third encoder
void HandleThirdInterruptB() {
  // Test transition;
  _ThirdEncoderBSet = digitalReadFast(c_ThirdEncoderPinB);
  _ThirdEncoderASet = digitalReadFast(c_ThirdEncoderPinA);

  _ThirdEncoderTicks += ParseEncoder(_ThirdEncoderAPrev, _ThirdEncoderBPrev, _ThirdEncoderASet, _ThirdEncoderBSet);

  _ThirdEncoderAPrev = _ThirdEncoderASet;
  _ThirdEncoderBPrev = _ThirdEncoderBSet;
}

int ParseEncoder(bool APrev, bool BPrev, bool ASet, bool BSet) {
  if (APrev && BPrev) {
    if (!ASet && BSet) return 1;
    if (ASet && !BSet) return -1;
  } else if (!APrev && BPrev) {
    if (!ASet && !BSet) return 1;
    if (ASet && BSet) return -1;
  } else if (!APrev && !BPrev) {
    if (ASet && !BSet) return 1;
    if (!ASet && BSet) return -1;
  } else if (APrev && !BPrev) {
    if (ASet && BSet) return 1;
    if (!ASet && !BSet) return -1;
  }
  return 0;
}

int sgn(int val) {
  if (val < 0) return -1;
  if (val == 0) return 0;
  return 1;
}


void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a newline, set a flag
    // so the main loop can do something about it:
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}

int difference(int first, int second){
  int diff = first - second;
  diff = diff * sgn(diff);
  return diff;
}

