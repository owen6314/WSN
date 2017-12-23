#include <Timer.h>
#include "base.h"
#include "printf.h"

module BaseC 
{
	uses 
  {
    interface Boot;
    interface Leds;
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;

    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;

    interface AMSend as UartSend[am_id_t id];
    interface Receive as UartReceive[am_id_t id];
    interface Packet as UartPacket;
    interface AMPacket as UartAMPacket; 

  }
}

implementation 
{
  uint8_t count = 0;
  uint16_t counter;
  message_t pkt;
  
  // radio
  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;
  
  // serial
  message_t  uartQueueBufs[UART_QUEUE_LEN];
  message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;

   
  task void uartSendTask();
  task void radioSendTask();
  
  // 丢包、错误统一亮红灯
  void dropBlink()
  {
    call Leds.led0Toggle();
  }

  void failBlink()
  {
    call Leds.led0Toggle();
  }

  event void Boot.booted() 
  {
    uint8_t i;

    for(i = 0; i < UART_QUEUE_LEN; i++)
      uartQueue[i] = &uartQueueBufs[i];
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = TRUE;

    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    if (call RadioControl.start() == EALREADY)
      radioFull = FALSE;

    if (call SerialControl.start() == EALREADY)
      uartFull = FALSE;

    //call ChangeFreqTimer.startPeriodic(TIMER_PERIOD_MILLI);
  }

  event void RadioControl.startDone(error_t error) 
  {
    if (error == SUCCESS) 
      radioFull = FALSE;
  }
  event void RadioControl.stopDone(error_t error) {}

  event void SerialControl.startDone(error_t error) 
  {
    if (error == SUCCESS) 
      uartFull = FALSE;
  }
  event void SerialControl.stopDone(error_t error) {}
//****************************************************************************************************
// receive from radio, send to Uart

  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);
  
  //指示接收来自sensor的包
  event message_t *RadioReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) 
  {
    return receive(msg, payload, len);
  }
  
  //接收包后转发
  message_t* receive(message_t *msg, void *payload, uint8_t len) 
  {
    message_t *ret = msg;
    //use printf library to deliver message
    //SensorMsg* btrpkt = (SensorMsg*)payload;
    //printf("from : %d, number: %d, temp: %d, humi: %d, lght: %d\n", 
    //btrpkt->node_id, btrpkt->sequence_number, btrpkt->temperature, btrpkt->humidity, btrpkt->light_intensity);
    call Leds.led2Toggle();
    atomic
    {
      //队列已满：丢包
      //串口busy：重新发送
      if(!uartFull)
      {
        ret = uartQueue[uartIn];
        uartQueue[uartIn] = msg;
        uartIn = (uartIn + 1) % UART_QUEUE_LEN;
        if(uartIn == uartOut)
          uartFull = TRUE;

        if(!uartBusy)
        {
          post uartSendTask();
          uartBusy = TRUE;
        }
      }
      else
          dropBlink();
    }
    return ret;
  }

  // 串口发送给PC
  // 发送成功亮绿灯，失败亮红灯
  task void uartSendTask()
  {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    am_group_t grp;
    atomic
      if(uartIn == uartOut && !uartFull)
      {
        uartBusy = FALSE;
        return;
      }
    
    msg = uartQueue[uartOut];
    len = call RadioPacket.payloadLength(msg);
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    grp = call RadioAMPacket.group(msg);
    call UartPacket.clear(msg);
    call UartAMPacket.setSource(msg, src);
    call UartAMPacket.setGroup(msg, grp);
    
    if(call UartSend.send[AM_SENSORMSG](addr, msg, len) == SUCCESS)
    {
      call Leds.led1Toggle();
    }
    else
    {
      failBlink();
      post uartSendTask();
    }
  }

  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error)
  {
    if(error != SUCCESS)
      failBlink();
    else
      atomic
        if(msg == uartQueue[uartOut])
        {
          if(++uartOut >= UART_QUEUE_LEN)
            uartOut = 0;
          if(uartFull)
            uartFull = FALSE;
        }
        post uartSendTask();
  }

//******************************************************************************************************
// receive from uart, send to radio

  event message_t *UartReceive.receive[am_id_t id](message_t*msg, void* payload, uint8_t len)
  {
    message_t *ret = msg;
    atomic
      if(!radioFull)
      {
        ret = radioQueue[radioIn];
        radioQueue[radioIn] = msg;
        if(++radioIn >= RADIO_QUEUE_LEN)
          radioIn = 0;
        if(radioIn == radioOut)
          radioFull = TRUE;
        if(!radioBusy)
        {
          post radioSendTask();
          radioBusy = TRUE;
        }
      }
      else
        dropBlink();
    return ret;
  }

  // send to other nodes
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
    len = call UartPacket.payloadLength(msg);
    addr = call UartAMPacket.destination(msg);
    source = call UartAMPacket.source(msg);
    id = call UartAMPacket.type(msg);

    call RadioPacket.clear(msg);
    call RadioAMPacket.setSource(msg, source);
    if (call RadioSend.send[id](addr, msg, len) == SUCCESS)
    {
      call Leds.led1Toggle();
    }
    else
    {
      post radioSendTask();
      call Leds.led0Toggle();
    }
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error)
  {
    if (error != SUCCESS) 
    {
      call Leds.led0Toggle();
    }
    else{
      call Leds.led1Toggle();
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
}
