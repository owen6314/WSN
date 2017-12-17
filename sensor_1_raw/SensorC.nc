#include <Timer.h>
#include "sensor.h"

module SensorC {
	uses{
		interface Boot;
		interface Leds;
		interface Packet;
		interface AMPacket;
		interface AMSend as TransitSend; 
		interface AMSend as LocalSend; 
		interface Receive;
		interface SplitControl as AMControl;
		interface Timer<TMilli> as BlinkLed0Timer;
		interface Timer<TMilli> as BlinkLed1Timer;
		interface Timer<TMilli> as BlinkLed2Timer;
		interface Timer<TMilli> as SampleTimer;
		interface Read<uint16_t> as readTemp;
		interface Read<uint16_t> as readHumidity;
		interface Read<uint16_t> as readLight;
	}
}
implementation {

	uint16_t counter;
	message_t pkt;
	bool transit_busy;
	bool local_busy;

	uint16_t TempData;
	uint16_t HumidityData;
	uint16_t LightData;

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

  /*event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    blinkLed0();
    if (len == sizeof(SensorMsg)) {
      SensorMsg* btrpkt = (SensorMsg*)payload;
      
    }
    return msg;
    }*/

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    	blinkLed0();
    	if (len == sizeof(SensorMsg)) {

    		if (!transit_busy) {
    			if (msg == NULL) {
    				return;
    			}
    			if (call TransitSend.send(AM_BROADCAST_ADDR, msg, sizeof(SensorMsg)) == SUCCESS) {
    				blinkLed2();
    				transit_busy = TRUE;
    			}
    		}
    	}
    	return msg;
    }

    void sendSample(uint16_t temperature, uint16_t humidity, uint16_t light_intensity) {
    	if (!local_busy) {
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
    		if (call LocalSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SensorMsg)) == SUCCESS) {
    			blinkLed1();
    			local_busy = TRUE;
    		}
    	}
    }

    event void SampleTimer.fired() {
    	call readTemp.read();
    	call readHumidity.read();
    	call readLight.read();
    	sendSample(TempData, HumidityData, LightData);
    }

    event void TransitSend.sendDone(message_t* msg, error_t err) {
    	transit_busy = FALSE;
    }

    event void LocalSend.sendDone(message_t* msg, error_t err) {
    	local_busy = FALSE;
    }

    event void readTemp.readDone(error_t result, uint16_t val) {
    	if (result == SUCCESS){ 
    		//val = -40.1+ 0.01*val;
    		TempData = val;
    	}
    	else TempData = 0xffff;
    //call Leds.led0Toggle();
}

event void readHumidity.readDone(error_t result, uint16_t val) {
	if (result == SUCCESS){
		HumidityData = val;
		//HumidityData = -4 + 4*val/100 + (-28/1000/10000)*(val*val);
		//HumidityData = (TempData-25)*(1/100+8*val/100/1000)+HumidityData;
	}
	else HumidityData = 0xffff;
      //call Leds.led1Toggle();
  }

  event void readLight.readDone(error_t result, uint16_t val) {
  	if (result == SUCCESS){ 
  		LightData = val;
  	}
  	else LightData = 0xffff;
    //call Leds.led2Toggle();
}
}