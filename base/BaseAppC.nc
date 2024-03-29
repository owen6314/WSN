#include <Timer.h>
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "base.h"

configuration BaseAppC {
}
implementation {
  components MainC;
  components LedsC;
  components BaseC as App;
  components CC2420ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;

  //debug
  components PrintfC;
  components SerialStartC;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  // Serial
  App.SerialControl -> Serial; 
  App.UartSend -> Serial;
  App.UartReceive -> Serial.Receive;
  App.UartPacket -> Serial;
  App.UartAMPacket -> Serial;
  
  App.RadioControl -> Radio;
  App.RadioSend -> Radio;
  App.RadioReceive -> Radio.Receive;
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

}
