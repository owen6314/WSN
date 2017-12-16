#include <Timer.h>
#include "sensor.h"

module SensorC {
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend; 
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as BlinkLed0Timer;
	uses interface Timer<TMilli> as BlinkLed1Timer;
  uses interface Timer<TMilli> as SampleTimer;
}
implementation {

	uint16_t counter;
	message_t pkt;
	bool transit_busy;
  bool local_busy;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      counter = 0;
      transit_busy = FALSE;
      local_busy = FALSE;

      call SampleTimer.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

	void blinkLed0() {
		call Leds.led0On();
		call BlinkLed0Timer.startOneShot(BLINK_DURATION);
	}

  void blinkLed1() {
    call Leds.led1On();
    call BlinkLed1Timer.startOneShot(BLINK_DURATION);
  }

	event void BlinkLed0Timer.fired() {
		call Leds.led0Off();
	}

  event void BlinkLed1Timer.fired() {
    call Leds.led1Off();
  }

  void sendSample(uint16_t temperature, uint16_t humidity, uint16_t light_intensity) {
    if (!transit_busy) {
      SensorMsg* btrpkt = (SensorMsg*)(call Packet.getPayload(&pkt, sizeof(SensorMsg)));
      if (btrpkt == NULL) {
        return;
      }
      btrpkt->node_id = TOS_NODE_ID;
      btrpkt->sequence_number = counter;
      btrpkt->temperature = temperature;
      btrpkt->humidity = humidity;
      btrpkt->light_intensity = light_intensity;
      counter++;
      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SensorMsg)) == SUCCESS) {
        blinkLed1();
        transit_busy = TRUE;
      }
    }
  }

  event void SampleTimer.fired() {
    sendSample(0, 0, 0);
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    transit_busy = FALSE;
  }
}