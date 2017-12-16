#include <Timer.h>
#include "base.h"

module BaseC {
	uses interface Boot;
	uses interface Leds;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as BlinkLed0Timer;
  uses interface Timer<TMilli> as BlinkLed1Timer;
  uses interface Timer<TMilli> as BlinkLed2Timer;
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

  void blinkLed2() {
    call Leds.led2On();
    call BlinkLed2Timer.startOneShot(BLINK_DURATION);
  }

	event void BlinkLed0Timer.fired() {
		call Leds.led0Off();
	}

  event void BlinkLed1Timer.fired() {
    call Leds.led1Off();
  }

  event void BlinkLed2Timer.fired() {
    call Leds.led2Off();
  }


  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    blinkLed0();
		if (len == sizeof(SensorMsg)) {
      
			if (!transit_busy) {
				if (msg == NULL) {
					return;
				}
			}
		}
		return msg;
	}
}