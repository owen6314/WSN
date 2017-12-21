#include <Timer.h>
#include "sensor.h"

configuration SensorAppC {
}
implementation {
  components MainC;
  components LedsC;
  components SensorC as App;
  components new TimerMilliC() as SampleTimer;
  components ActiveMessageC as Radio;
  //components ActiveMessageC;
  //components new AMSenderC(AM_SENSOR_TO_BASE) as TransitSend;
  //components new AMSenderC(AM_SENSOR_TO_BASE) as LocalSend;
  //components new AMReceiverC(AM_SENSOR_TO_SENSOR) as Receive;
  components new HamamatsuS1087ParC();
  components new SensirionSht11C();
  components PrintfC;
  components SerialStartC;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.RadioControl -> Radio;

  App.RadioSend -> Radio;
  App.RadioReceive -> Radio.Receive;
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;
  App.SampleTimer -> SampleTimer;
  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;
}