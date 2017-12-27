#include <Timer.h>
#include "sensor.h"
#include "printf.h"

module SensorC 
{
  uses
  {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as SampleTimer;
    interface Read<uint16_t> as readTemp;
    interface Read<uint16_t> as readHumidity;
    interface Read<uint16_t> as readPhoto;

    interface SplitControl as RadioControl;
    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
    interface PacketLink;
  }
}
implementation 
{
	message_t pkt;
  bool busy;

  // sensor data
  uint16_t counter;     //sequence number
  uint16_t temperature;
  uint16_t humidity;
  uint16_t light_intensity;

  uint16_t current_sample_period = DEFAULT_INTERVAL;
  uint16_t local_version = DEFAULT_VERSION;

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  task void radioSendTask();

  event void Boot.booted() 
  {
    uint8_t i;
    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    counter = 0;
    radioBusy = FALSE;
    radioFull = TRUE;
    busy = FALSE;
    if (call RadioControl.start() == EALREADY)
      radioFull = FALSE;
  }

  event void RadioControl.startDone(error_t error) 
  {
    if (error == SUCCESS) 
    {
      radioFull = FALSE;
      call SampleTimer.startPeriodic(current_sample_period);
    }
    else
      call RadioControl.start();
  }
  event void RadioControl.stopDone(error_t error) {}
  
  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);
  
  event message_t *RadioReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len)
  {
    return receive(msg, payload, len);
  }
  
  
  message_t* receive(message_t *msg, void *payload, uint8_t len) 
  {
    SensorMsg* btrpkt_receive;
    message_t *ret = msg;

    if (len == sizeof(SensorMsg)) 
    {
      btrpkt_receive = (SensorMsg*)payload;
      if (btrpkt_receive->version > local_version)
      {
        local_version = btrpkt_receive->version;
        current_sample_period = btrpkt_receive->interval;
        call SampleTimer.startPeriodic(current_sample_period);
      }
    }
    atomic if (!radioFull)
    {
      ret = radioQueue[radioIn];
      radioQueue[radioIn] = msg;
      radioIn = (radioIn + 1) % RADIO_QUEUE_LEN;

      if (radioIn == radioOut)
        radioFull = TRUE;

      if (!radioBusy)
      {
        post radioSendTask();
        radioBusy = TRUE;
      }
    }
    return ret;
  }

  event void SampleTimer.fired() 
  {
    SensorMsg* btrpkt = (SensorMsg*)(call RadioPacket.getPayload(&pkt, sizeof(SensorMsg)));
    btrpkt->version = local_version;
    btrpkt->interval = current_sample_period;
    btrpkt->node_id = TOS_NODE_ID;
    btrpkt->sequence_number = counter;
    btrpkt->temperature = temperature;
    btrpkt->humidity = humidity;
    btrpkt->light_intensity = light_intensity;
    btrpkt->current_time = call SampleTimer.getNow();  // time after booting
    counter++;

    radioQueue[radioIn] = &pkt;
    if (++radioIn >= RADIO_QUEUE_LEN)
      radioIn = 0;
    if (radioIn == radioOut)
        radioFull = TRUE;
    if (!radioBusy)
    {
      post radioSendTask();
      radioBusy = TRUE;
    }

    // read new data from sensor
    call readTemp.read();
    call readHumidity.read();
    call readPhoto.read();
  }
  task void radioSendTask() 
  {
    uint8_t len;
    message_t* msg;
    atomic 
      if (radioIn == radioOut && !radioFull)
      {
       radioBusy = FALSE;
       return;
      }

    msg = radioQueue[radioOut];
    len = call RadioPacket.payloadLength(msg);

    call PacketLink.setRetries(msg, 100); //set retries
    call PacketLink.setRetryDelay(msg, 5); //set delay

    if (call RadioSend.send[AM_SENSOR2_TO_SENSOR1](1, msg, sizeof(SensorMsg)) == SUCCESS)
    {
      call Leds.led2Toggle();
    }
    else
    {
      post radioSendTask();
      call Leds.led0Toggle();
    }

    
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) 
  {
    printf("send done is called!\n");
    if (error != SUCCESS) 
      call Leds.led0Toggle();
    else
    {
      atomic if (msg == radioQueue[radioOut])
      {
        if (++radioOut >= RADIO_QUEUE_LEN)
          radioOut = 0;
        if (radioFull)
          radioFull = FALSE;
      }
    }
    // can't delete this line
    post radioSendTask();
  }

  event void readTemp.readDone(error_t result, uint16_t val) {
    if (result == SUCCESS)
    { 
      val = -40.1+ 0.01*val;
      temperature = val;
    }
    else temperature = 0xffff;
  }

  event void readHumidity.readDone(error_t result, uint16_t val)
   {
    if (result == SUCCESS)
    {
      humidity = val;
      humidity = -4 + 4*val/100 + (-28/1000/10000)*(val*val);
      humidity = (temperature-25)*(1/100+8*val/100/1000)+humidity;
      printf("humidity is %d", humidity);
    }
    else humidity = 0xffff;
  }

  event void readPhoto.readDone(error_t result, uint16_t val) 
  {
    if (result == SUCCESS)
      light_intensity = val;
    else light_intensity = 0xffff;
  }
}