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
  uses interface Timer<TMilli> as Timer;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {

  uint8_t m_flag[ARRAY_SIZE] = {};
  uint32_t m_data[ARRAY_SIZE / 2 + 5] = {};
  uint16_t m_len = ARRAY_SIZE / 2 + 4;
  uint16_t m_data_len = 0;
  uint16_t m_flag_len = 0;
  m_answer m_ans;
  message_t pkt_ans;
  message_t pkt_req;
  bool answer_acked = FALSE;
  bool busy = FALSE;

  void init() {
    uint16_t i = 0;
    for(;i < ARRAY_SIZE; i++) {
      m_flag[i] = 0;
    }
    m_ans.max = 0;
    m_ans.min = 10000;
    m_ans.sum = 0;
    m_ans.average = 0;
    m_ans.median = 0;
    m_ans.group_id = GROUP_ID;
  }

  bool received_all_data() {
    return m_data_len == ARRAY_SIZE;
  }

  void update_flag() {
    for (; m_flag_len != m_data_len; m_flag_len++) {
      if (m_flag[m_flag_len] != 1)
      break;
    }
  }

  void handle_message(m_source src) {
    uint16_t seq = src.sequence_number;
    uint32_t data = src.random_integer;
    uint16_t i = 0, j;
    if(m_flag[seq - 1] != 1) {
      m_flag[seq - 1] = 1;
      if(m_ans.max < data) {
        m_ans.max = data;
      }
      if(m_ans.min > data) {
        m_ans.min = data;
      }
      m_ans.sum += data;
      m_data_len += 1;
      if(m_data_len <= m_len) {
        while(i < m_data_len) {
          i++;
          if (m_data[i] > data) {
            break;
          }
        }
        for (j = m_data_len - 1; j > i; j--) {
          m_data[j] = m_data[j - 1];
        }   
        m_data[i] = data;
      }
      else {
        while(i < m_len) {
          i++;
          if (m_data[i] > data) {
            break;
          }
        }
        for (j = m_len - 1; j > i; j--) {
          m_data[j] = m_data[j - 1];
        }
        m_data[i] = data;
      }
    }
  }

  void cal_result() {
    if (m_data_len != ARRAY_SIZE)
    return;
    m_ans.average = m_ans.sum / ARRAY_SIZE;
    m_ans.median = (m_data[ARRAY_SIZE / 2] + m_data[ARRAY_SIZE / 2 + 1]) / 2;
  }

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      init();
      call Timer.startPeriodic(PERIOD);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer.fired() {
    if (received_all_data()) {
      call Timer.stop();
      return;
    }
    update_flag();
    if (m_flag_len != m_data_len && !busy) {

      m_request *da_req = 
      (m_request *)(call Packet.getPayload(&pkt_req, sizeof(m_request)));
      if (da_req == NULL) {
        return;
      }
      da_req->index = m_flag_len + 1;
      if (call AMSend.send(AM_BROADCAST_ADDR, 
        &pkt_req, sizeof(m_request)) == SUCCESS) {
        busy = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt_ans == msg || &pkt_req == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    am_addr_t id = call AMPacket.source(msg);
    if (id != SERVER_ID && !(id <= MY_SUB2 && id >= MY_SUB1) && id != 0)
    return msg;
    if (id == SERVER_ID){ 
      call Leds.led0Toggle();
    }
    if(id <= MY_SUB2 && id >= MY_SUB1) {
      call Leds.led2Toggle();
    }
    if (len == sizeof(m_source)) {
      m_source *pkt_source = (m_source *)payload;
      handle_message(*pkt_source);
      update_flag();
      if (answer_acked == FALSE && received_all_data()) {
        if (!busy) {
          m_answer* da_ans;
          da_ans = (m_answer *)(call Packet.getPayload(&pkt_ans, sizeof(m_answer)));
          if (da_ans == NULL) {
            return msg;
          }
          cal_result();
          da_ans->max = m_ans.max;
          da_ans->min = m_ans.min;
          da_ans->sum = m_ans.sum;
          da_ans->average = m_ans.average;
          da_ans->median = m_ans.median;
          printf(
            "max=%ld, min=%ld, sum=%ld, average=%ld, median=%ld\n",
            m_ans.max, m_ans.min, m_ans.sum, m_ans.average,
            m_ans.median);
          if (call AMSend.send(AM_BROADCAST_ADDR, 
            &pkt_ans, sizeof(m_answer)) == SUCCESS) {
            busy = TRUE;
          }
        }
      } 
      else if (len == sizeof(m_ack)) {
        m_ack *pkt_ack = (m_ack *)payload;
        if (pkt_ack->group_id == GROUP_ID) {
          answer_acked = TRUE;
        }
      }
    }
    return msg;
  }
}
