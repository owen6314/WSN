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

  uint16_t current_sample_period = TIMER_PERIOD_MILLI;
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
      call SampleTimer.startPeriodic(TIMER_PERIOD_MILLI);
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
    SensorMsg* btrpkt_sensor;
    FreqMsg* btrpkt_freq;
    message_t *ret = msg;
    if (len == sizeof(FreqMsg)) 
    {
      btrpkt_freq = (FreqMsg*)payload;
      if (btrpkt_freq->period != current_sample_period) 
      {
        current_sample_period = btrpkt_freq->period;
        call SampleTimer.startPeriodic(current_sample_period);
        call Leds.led0Toggle();
      }
    }
    else 
    {
      btrpkt_sensor = (SensorMsg*)payload;
      atomic {
      if (!radioFull)
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
      else {
      }
    }
  }
    return ret;
  }

  event void SampleTimer.fired() 
  {
    //if(!busy)

    SensorMsg* btrpkt = (SensorMsg*)(call RadioPacket.getPayload(&pkt, sizeof(SensorMsg)));
    btrpkt->node_id = TOS_NODE_ID;
    btrpkt->sequence_number = counter;
    btrpkt->temperature = temperature;
    btrpkt->humidity = humidity;
    btrpkt->light_intensity = light_intensity;
    counter++;
    //printf("Not busy.\n");
    radioQueue[radioIn] = &pkt;
    if (++radioIn >= RADIO_QUEUE_LEN)
      radioIn = 0;
    if (radioIn == radioOut)
        radioFull = TRUE;
    if (!radioBusy)
    {
      post radioSendTask();
      printf("Packet send task is post.\n");
      radioBusy = TRUE;
    }
    //busy = TRUE;
   // }
    // read new data from sensor
    call readTemp.read();
    call readHumidity.read();
    call readPhoto.read();
  }
  task void radioSendTask() 
  {
    uint8_t len;
    am_id_t id;
    am_addr_t addr,source;
    message_t* msg;
    atomic 
      if (radioIn == radioOut && !radioFull)
      {
       radioBusy = FALSE;
       return;
      }

    msg = radioQueue[radioOut];
    len = call RadioPacket.payloadLength(msg);

    if (call RadioSend.send[AM_SENSOR2_TO_SENSOR1](1, msg, sizeof(SensorMsg)) == SUCCESS)
    {
      call Leds.led1Toggle();
    }
    else
    {
      post radioSendTask();
      call Leds.led0Toggle();
    }

    // can't delete this line
    post radioSendTask();
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
    // defensive style to verify the sent message is the same one that is being signaled is required
    if(&pkt == msg)
    {
      printf("pkt is verified with msg\n");
      busy = FALSE;
    }
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