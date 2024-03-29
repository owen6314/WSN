/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;

/* The "Oscilloscope" demo app. Displays graphs showing data received from
   the Oscilloscope mote application, and allows the user to:
   - zoom in or out on the X axis
   - set the scale on the Y axis
   - change the sampling period
   - change the color of each mote's graph
   - clear all data

   This application is in three parts:
   - the Node and Data objects store data received from the motes and support
     simple queries
   - the Window and Graph and miscellaneous support objects implement the
     GUI and graph drawing
   - the Oscilloscope object talks to the motes and coordinates the other
     objects

   Synchronization is handled through the Oscilloscope object. Any operation
   that reads or writes the mote data must be synchronized on Oscilloscope.
   Note that the messageReceived method below is synchronized, so no further
   synchronization is needed when updating state based on received messages.
*/
public class Oscilloscope implements MessageListener
{
    MoteIF mote;
    Data data;
    Window window;

    /* The current sampling period. If we receive a message from a mote
       with a newer version, we update our interval. If we receive a message
       with an older version, we broadcast a message with the current interval
       and version. If the user changes the interval, we increment the
       version and broadcast the new interval and version. */
    int interval = Constants.DEFAULT_INTERVAL;
    int version = -1;

    /* Main entry point */
    void run(int mode)
    {
        data = new Data(this);
        window = new Window(this, mode);
        window.setup();
        mote = new MoteIF(PrintStreamMessenger.err);
        mote.registerListener(new OscilloscopeMsg(), this);
    }

    /* The data object has informed us that nodeId is a previously unknown
       mote. Update the GUI. */
    void newNode(int nodeId) 
    {
        window.newNode(nodeId);
    }

    public synchronized void messageReceived(int dest_addr, Message msg) 
    {
        if (msg instanceof OscilloscopeMsg)
        {
            OscilloscopeMsg omsg = (OscilloscopeMsg)msg;
            /* Update interval and mote data */
            periodUpdate(omsg.get_version(), omsg.get_interval());
            SensorData sensorData = new SensorData(omsg.get_temperature(), omsg.get_humidity(), omsg.get_light_intensity());
            //fix the bug of showing what is sent by base station in a very LOW way
            if(omsg.get_node_id() != 0)
            {
                data.update(omsg.get_node_id(), omsg.get_sequence_number(), sensorData);
                /* Inform the GUI that new data showed up */
                window.newData();
                outputMsgToConsole(omsg);
            }
        }
        else
            System.out.println("GET");
    }

    /* A potentially new version and interval has been received from the
       mote */
    void periodUpdate(int moteVersion, int moteInterval) 
    {
        if (moteVersion > version) 
        {
            /* It's new. Update our vision of the interval. */
            version = moteVersion;
            interval = moteInterval;
            window.updateSamplePeriod();
        }
        else if (moteVersion < version)
        {
            /* It's old. Update the mote's vision of the interval. */
            sendInterval();
        }
    }

    /* The user wants to set the interval to newPeriod. Refuse bogus values
       and return false, or accept the change, broadcast it, and return
       true */
    synchronized boolean setInterval(int newPeriod) 
    {
        if (newPeriod < 1 || newPeriod > 65535) 
            return false;
        interval = newPeriod;
        version++;
        sendInterval();
        return true;
    }

    /* Broadcast a version+interval message. */
    void sendInterval() 
    {
        OscilloscopeMsg omsg = new OscilloscopeMsg();

        omsg.set_version(version);
        omsg.set_interval(interval);
        omsg.set_token(Constants.TOKEN);

        try 
        {
            mote.send(MoteIF.TOS_BCAST_ADDR, omsg);
        }
        catch (IOException e) 
        {
            window.error("Cannot send message to mote");
        }
    }

    /* User wants to clear all data. */
    void clear() 
    {
        data = new Data(this);
    }

    public static void main(String[] args)
    {
        Oscilloscope me = new Oscilloscope();
        int mode = Integer.parseInt(args[0]);
        me.run(mode);
    }

    void outputMsgToConsole(OscilloscopeMsg omsg) 
    {
        System.out.print("node id is " + omsg.get_node_id() + " ");
        System.out.print("seq num " + omsg.get_sequence_number() + " ");
        System.out.print("temperature = " + omsg.get_temperature() + " ");
        System.out.print("humidity = " + omsg.get_humidity() + " ");
        System.out.print("light = " + omsg.get_light_intensity() + " ");
        System.out.print("current_time = " + omsg.get_current_time() + " ");
        System.out.print("\n");
    }
}
