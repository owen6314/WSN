#include <Timer.h>
#include "BlinkToRadio.h"
#include "printf.h"

module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {

  uint16_t m_flag[ARRAY_SIZE / 8 + 2] = {};
  uint32_t m_data[ARRAY_SIZE] = {};
  uint16_t m_data_len = 0;
  uint16_t m_flag_len = 0;
  message_t pkt_resp;
  bool busy = FALSE;

  bool check(int offset) {
    int main_offset = offset / 8;
    int sub_offset = 7 - offset % 8;
    m_flag[main_offset] = (1 << sub_offset) & m_flag[main_offset]; 
    return m_flag[main_offset]!= 0;
  }
  void set(int offset) {
    int main_offset = offset / 8;
    int sub_offset = 7 - offset % 8;
    m_flag[main_offset] = (1 << sub_offset) | m_flag[main_offset];
  }

  void update_flag() {
    for (; m_flag_len != m_data_len; ++m_flag_len) {
      if (check(m_flag_len))
      break;
    }
  }

  void handle_message(source_msg src) {
    uint16_t seq = src.sequence_number;
    uint32_t data = src.random_integer;
    //printf("seq:%u data:%u\n",seq,data);
    if(!check(seq - 1)) {
      m_data[seq - 1] = data;
      set(seq - 1);
    }
  }

  void init() {
    uint16_t i = 0;
    for(;i<ARRAY_SIZE;i++){
      set(i);
      m_data[i] = i;
    }
  }

  event void Boot.booted() {
    call AMControl.start();
    init();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt_resp == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    
    am_addr_t id = call AMPacket.source(msg);
    if (id != SERVER_ID && id != MY_BASE)
      return msg;
    if (len == sizeof(source_msg)) {

      source_msg *pkt_source = (source_msg *)payload;
        call Leds.led0Toggle();

      handle_message(*pkt_source);
    } 
    else if (len == sizeof(request_msg)) {
      request_msg *pkt_request = (request_msg *)payload;

      uint16_t seq = pkt_request->index;
        call Leds.led2Toggle();
        printf("have:%u,%d\n",seq,check(seq - 1));
        printfflush();

      //printf("requset=%u\n",pkt_request->index);
      if (check(seq - 1)) {
        source_msg *da_resp = 
        (source_msg *)(call Packet.getPayload(&pkt_resp,
         sizeof(source_msg)));
        da_resp->random_integer = m_data[seq - 1];
        da_resp->sequence_number = seq;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt_resp,
         sizeof(source_msg)) == SUCCESS) {
          busy = TRUE;
        }
      } 
      else {
      }
    }
    return msg;
  }
}
