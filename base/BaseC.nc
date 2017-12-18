#include <Timer.h>
#include "base.h"
#include "printf.h"

module BaseC {
	uses {
    interface Boot;
	  interface Leds;
    interface SplitControl as RadioControl;
    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    //interface Receive as RadioSnoop[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;

    interface Timer<TMilli> as ChangeFreqTimer;
  }
}
implementation {

	uint16_t counter;
	message_t pkt;
	bool transit_busy;
  bool local_busy;

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  event void Boot.booted() {
    uint8_t i;
    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    if (call RadioControl.start() == EALREADY)
      radioFull = FALSE;
      call ChangeFreqTimer.startPeriodic(TIMER_PERIOD_MILLI);
  }

  event void RadioControl.startDone(error_t error) {
    if (error == SUCCESS) {
      radioFull = FALSE;
      call Leds.led1On();
    }
  }

  event void RadioControl.stopDone(error_t error) {}

  uint8_t count = 0;

  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);
  
  //event message_t *RadioSnoop.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
  //  call Leds.led2Toggle();
  //  return receive(msg, payload, len);
  //}

  event message_t *RadioReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
    call Leds.led0Toggle();
    return receive(msg, payload, len);
  }

  message_t* receive(message_t *msg, void *payload, uint8_t len) {
    SensorMsg* btrpkt = (SensorMsg*)payload;
    message_t *ret = msg;
    call Leds.led2Toggle();
    printf("from : %d, number: %d, temp: %d, humi: %d, lght: %d\n", 
      btrpkt->node_id, btrpkt->sequence_number, btrpkt->temperature, btrpkt->humidity, btrpkt->light_intensity);
    printfflush();
    return ret;
  }

  task void radioSendTask() {
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
    call RadioPacket.clear(msg);
    call RadioAMPacket.setGroup(msg, 20);

    if (call RadioSend.send[AM_BASE_TO_SENSORS](AM_BROADCAST_ADDR, msg, sizeof(FreqMsg)) == SUCCESS)
      call Leds.led1Toggle();
    else
    {
      post radioSendTask();
      call Leds.led0Toggle();
    }
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS) {
      call Leds.led0Toggle();
    }
    else{
      call Leds.led2Toggle();
          atomic if (msg == radioQueue[radioOut])
      {
        if (++radioOut >= RADIO_QUEUE_LEN)
          radioOut = 0;
        if (radioFull)
          radioFull = FALSE;
      }
    }
    post radioSendTask();
  }

  uint16_t counter_2 = 0;
  uint16_t freq = 500;

  event void ChangeFreqTimer.fired() {
    FreqMsg* btrpkt = (FreqMsg*)(call RadioPacket.getPayload(&pkt, sizeof(FreqMsg)));
    if (++counter_2 % 40 == 0) {
      if(++counter % 2 == 0) {
        freq = 500;
      }
      else {
        freq = 50;
      }
    }
    btrpkt->freq = freq;
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
    else {

    }
  }
}