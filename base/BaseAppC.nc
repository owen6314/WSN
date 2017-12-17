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
  components new TimerMilliC() as BlinkLed0Timer;
  components new TimerMilliC() as BlinkLed1Timer;
  components new TimerMilliC() as BlinkLed2Timer;
  components ActiveMessageC;
  components new AMReceiverC(AM_SENSOR_TO_BASE) as Receive;
  components PrintfC;
  components SerialStartC;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Receive -> Receive;
  App.AMControl -> ActiveMessageC;
  App.BlinkLed0Timer -> BlinkLed0Timer;
  App.BlinkLed1Timer -> BlinkLed1Timer;
  App.BlinkLed2Timer -> BlinkLed2Timer;
}