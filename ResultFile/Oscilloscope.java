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
       file = new File("result.txt");
       try{
         FileWriter fileWriter = new FileWriter(file, true);
         BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);
         bufferedWriter.write("ID SeqNum Temperature Humidity Light Time" + "\n");
         bufferedWriter.close();
         fileWriter.close();
       }catch (IOException e)
       {
         System.out.println(e);
       }
       // need to specify MoteCom environment variaty
       mote = new MoteIF(PrintStreamMessenger.err);
       mote.registerListener(new SensorMsg(), this);
    }

    void outputMsgToFile(SensorMsg omsg) 
    {
      try {
          FileWriter fileWiter = new FileWriter(file, true);
          BufferedWriter bufferedWriter = new BufferedWriter(fileWiter);

          bufferedWriter.write(omsg.get_node_id() + " ");
          bufferedWriter.write(omsg.get_sequence_number() + " ");
          bufferedWriter.write(omsg.get_temperature() + " ");
          bufferedWriter.write(omsg.get_humidity() + " ");
          bufferedWriter.write(omsg.get_light_intensity() + " ");
          bufferedWriter.write(omsg.get_current_time() + " ");
          bufferedWriter.newLine();
          bufferedWriter.close();
          fileWiter.close();
      } catch (IOException e) {
          System.out.println(e);
      }
    }

    void outputMsgToConsole(SensorMsg omsg) 
    {
        System.out.print(omsg.get_node_id() + " ");
        System.out.print(omsg.get_sequence_number() + " ");
        System.out.print("temperature = " + omsg.get_temperature());
        System.out.print("humidity = " + omsg.get_humidity());
        System.out.print("light = " + omsg.get_light_intensity());
        System.out.print("current_time = " + omsg.get_current_time() + " ");
        System.out.print("\n");
    }

    public synchronized void messageReceived(int dest_addr,
            Message msg) 
    {
      
      if (msg instanceof SensorMsg) 
      {
          SensorMsg omsg = (SensorMsg)msg;
          outputMsgToConsole(omsg);
          outputMsgToFile(omsg);
      }
    }

    public static void main(String[] args)
    {
       Oscilloscope me = new Oscilloscope();
       me.run();
    }

}
