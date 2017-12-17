#include <Timer.h>
#include "sensor.h"

configuration SensorAppC {
}
implementation {
  components MainC;
  components LedsC;
  components SensorC as App;
  components new TimerMilliC() as BlinkLed0Timer;
  components new TimerMilliC() as BlinkLed1Timer;
  components new TimerMilliC() as BlinkLed2Timer;
  components new TimerMilliC() as SampleTimer;
  components ActiveMessageC;
  components new AMSenderC(AM_SENSOR_TO_BASE) as TransitSend;
  components new AMSenderC(AM_SENSOR_TO_BASE) as LocalSend;
  components new AMReceiverC(AM_SENSOR_TO_SENSOR) as Receive;
  components new HamamatsuS1087ParC();
  components new SensirionSht11C();


  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> TransitSend;
  App.AMPacket -> TransitSend;
  App.TransitSend -> TransitSend;
  App.LocalSend -> LocalSend;
  App.Receive -> Receive;
  App.AMControl -> ActiveMessageC;
  App.BlinkLed0Timer -> BlinkLed0Timer;
  App.BlinkLed1Timer -> BlinkLed1Timer;
  App.BlinkLed2Timer -> BlinkLed2Timer;
  App.SampleTimer -> SampleTimer;
  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;
}