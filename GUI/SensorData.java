/*
Sensor data class used to draw lines.
cast int temp, humidity, light data from sensor to double

*/
public class SensorData 
{
	public int temperature;
	public int humidity;
	public int light_intensity;

	public SensorData(int temperature, int humidity, int light_intensity)
	 {
		this.temperature = temperature;
		this.humidity = humidity;
		this.light_intensity = light_intensity;
	}

	public double getPhysicalTemp() 
	{
	  return (double)this.temperature;
	}

	public double getPhysicalHumid() 
	{
		return (double)this.humidity;
	}

	public double getPhysicalLight() 
	{
		return (double)this.light_intensity;
	}
}
