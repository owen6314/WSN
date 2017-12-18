#include <Timer.h>
#include "sensor.h"

configuration SensorAppC {
}
implementation {
  components MainC;
  components LedsC;
  components SensorC as App;
  //components new TimerMilliC() as BlinkLed0Timer;
  //components new TimerMilliC() as BlinkLed1Timer;
  components new TimerMilliC() as SampleTimer;
  //components ActiveMessageC;
  //components new AMSenderC(AM_SENSOR_TO_SENSOR);

  components ActiveMessageC as Radio;
  components new HamamatsuS1087ParC();
  components new SensirionSht11C();

  App.Boot -> MainC;
  App.Leds -> LedsC;
  //App.Packet -> AMSenderC;
  //App.AMPacket -> AMSenderC;
  //App.AMSend -> AMSenderC;
  //App.AMControl -> ActiveMessageC;
  //App.BlinkLed0Timer -> BlinkLed0Timer;
  //App.BlinkLed1Timer -> BlinkLed1Timer;
  App.SampleTimer -> SampleTimer;
  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;

  App.RadioControl -> Radio;
  App.RadioSend -> Radio;
  App.RadioReceive -> Radio.Receive;
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

}