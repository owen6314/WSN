GEN=SensorMsg.java


all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

SensorMsg.java: Oscilloscope.h
	mig java -target=telosb -java-classname=SensorMsg Oscilloscope.h SensorMsg -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm oscilloscope.jar
