import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;

public class Oscilloscope implements MessageListener
{
    MoteIF mote;
    File file;
    void run() 
    {
       System.out.println("PC File application run");
       //ile = new File("result.txt");
       // need to specify MoteCom environment variaty
       mote = new MoteIF(BuildSource.makePhoenix("SensorMsg", PrintStreamMessenger.err));
       mote.registerListener(new SensorMsg(), this);
    }

    void outputMsgToFile(SensorMsg omsg) 
    {
      try {
          FileWriter fileWiter = new FileWriter(file, true);
          BufferedWriter bufferedWriter = new BufferedWriter(fileWiter);

          //bufferedWriter.write(omsg.get_id() + " ");
         /// bufferedWriter.write(omsg.get_count() + " ");
          bufferedWriter.write(omsg.get_temperature() + " ");
          bufferedWriter.write(omsg.get_humidity() + " ");
          //bufferedWriter.write(omsg.get_light() + " ");
         // bufferedWriter.write(omsg.get_current_time() + " ");
         // bufferedWriter.newLine();
         // bufferedWriter.close();
          fileWiter.close();
      } catch (IOException e) {
          System.out.println(e);
      }
    }

    void outputMsgToConsole(SensorMsg omsg) 
    {
        //System.out.print("version = " + omsg.get_version());
        //System.out.print("interval = " + omsg.get_interval());
       // System.out.print("id = " + omsg.get_id());
       // System.out.print("count = " + omsg.get_count());
        System.out.print("temperature = " + omsg.get_temperature());
        System.out.print("humidity = " + omsg.get_humidity());
      //  System.out.print("light = " + omsg.get_light());
       /// System.out.print("current_time = " + omsg.get_current_time());
       // System.out.print("token = " + omsg.get_token());
        System.out.print("\n");
    }

    public synchronized void messageReceived(int dest_addr,
            Message msg) 
    {
      System.out.println("receive message");
      if (msg instanceof SensorMsg) 
      {
          SensorMsg omsg = (SensorMsg)msg;
          outputMsgToConsole(omsg);
         //outputMsgToFile(omsg);
      }
    }

    public static void main(String[] args)
    {
       Oscilloscope me = new Oscilloscope();
       me.run();
    }

}
