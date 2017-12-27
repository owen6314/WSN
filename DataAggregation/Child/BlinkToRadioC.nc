// $Id: BlinkToRadioC.nc,v 1.5 2007/09/13 23:10:23 scipio Exp $

/*
 * "Copyright (c) 2000-2006 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
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

  uint16_t m_flag[ARRAY_SIZE / 16 + 2] = {};
  uint32_t m_data[ARRAY_SIZE] = {};
  uint16_t m_data_len = 0;
  uint16_t m_flag_len = 0;
  message_t pkt_resp;
  bool busy = FALSE;

  bool have(int offset) {
    int main_offset = offset / 16;
    int sub_offset = 15 - offset % 16;
    return ((1 << sub_offset) & m_flag[main_offset]) != 0;
  }
  void set(int offset) {
    int main_offset = offset / 16;
    int sub_offset = 15 - offset % 16;
    m_flag[main_offset] = (1 << sub_offset) | m_flag[main_offset];
  }

  void update_flag() {
    for (; m_flag_len != m_data_len; ++m_flag_len) {
      if (have(m_flag_len))
      break;
    }
  }

  void handle_message(m_source src) {
    uint16_t seq = src.sequence_number;
    uint32_t data = src.random_integer;
    if(!have(seq - 1)) {
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
    //init();
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
    if (len == sizeof(m_source)) {
      m_source *pkt_source = (m_source *)payload;
      call Leds.led0Toggle();
      handle_message(*pkt_source);
    } 
    else if (len == sizeof(m_request)) {
      m_request *pkt_request = (m_request *)payload;

      uint16_t seq = pkt_request->index;
      call Leds.led2Toggle();
      //printf("have:%u,%d\n",seq,have(seq - 1));
      //printfflush();
      if (have(seq - 1)) {
        m_source *da_resp = 
        (m_source *)(call Packet.getPayload(&pkt_resp,
         sizeof(m_source)));
        da_resp->random_integer = m_data[seq - 1];
        da_resp->sequence_number = seq;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt_resp,
         sizeof(m_source)) == SUCCESS) {
          busy = TRUE;
        }
      } 
      else {
        call Leds.led1Toggle();
      }
    }
    return msg;
  }
}
