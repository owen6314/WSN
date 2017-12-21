#include <Timer.h>
#include "sensor.h"

configuration SensorAppC {
}
implementation 
{
  components SensorC as App;
  components MainC;
  components LedsC;
  components ActiveMessageC as Radio;
  components new TimerMilliC() as SampleTimer;
  // debug
  components PrintfC;
  components SerialStartC;
  // sensor
  components new HamamatsuS1087ParC();
  components new SensirionSht11C();

  App.Boot -> MainC;
  App.Leds -> LedsC;
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