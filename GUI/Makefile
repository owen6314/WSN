GEN=OscilloscopeMsg.java Constants.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: Oscilloscope.h
	mig -target=telosb -java-classname=OscilloscopeMsg java Oscilloscope.h SensorMsg -o $@

Constants.java: Oscilloscope.h
	ncg -target=telosb -java-classname=Constants java Oscilloscope.h NREADINGS DEFAULT_INTERVAL -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm oscilloscope.jar
