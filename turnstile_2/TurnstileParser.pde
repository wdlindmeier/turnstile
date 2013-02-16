import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;

String stationFilename = "data/station_names.csv";

class TurnstileParser
{

  HashMap stations;
  String[] stationNames;

  long subunitCount = 0;
  long sampleCount = 0;
  int numStations;

  Date minSampleDate;
  Date maxSampleDate;

  public TurnstileParser()
  {
       parseStationNames();
  }

  void parseStationNames()
  {
        
    maxSampleDate = new Date(1000);
    minSampleDate = new Date();

    stations = new HashMap();

    println("Parsing turnstyle data in file: " + stationFilename);
    
    String[] stationLines = loadStrings(stationFilename);
    for (int i=0;i<stationLines.length;i++) {
      if (i>0) {
        String line = stationLines[i];
        String[] stationData = line.split(",");
        if (stationData.length > 4) {      
          String stationName = stationData[2];
          Station station = new Station(stationName);
          station.remote = stationData[0];
          station.booth = stationData[1];
          station.line = stationData[3];
          station.division = stationData[4];       
          stations.put(station.remote, station);
        }
        else {
          println("Couldnt parse line: "+line);
        }
      }
    }
    
    numStations = stations.size();
    println("Parsed "+numStations+" stations");

  }

  void parseDataFile(String dataFilename)
  {
    if(stations == null){
      println("ERROR: Station names have not been parsed");
      return;
    }
    
    println("Parsing turnstyle data in file: " + dataFilename);

    Date today = new Date();

    String[] dataLines = loadStrings(dataFilename);
    for (String line:dataLines) {

      String stripLine = line.trim();
      if (!stripLine.equals("")) {

        String[] lineData = stripLine.split(",");

        // Get the station 
        String remoteName = lineData[1];      
        Station station = (Station)stations.get(remoteName);
        if (station == null) {
          println("ERROR: Could not find station with remote name: "+remoteName);
          continue;
        }

        // Get the sub-unit
        String subunitName = lineData[2];
        ControlUnit subunit = (ControlUnit)station.controlUnits.get(subunitName);
        if (subunit == null) {
          subunit = new ControlUnit(subunitName);
          station.controlUnits.put(subunitName, subunit); 
          subunitCount++;
        }

        // Add the samples
        int samplesLength = lineData.length - 3;
        if (samplesLength % 5 != 0) {

          println("ERROR: irregular sample length:");
          println(lineData);
        }
        else {
          for (int i=0;i<samplesLength;i+=5) {

            String date = lineData[3+i+0];
            String time = lineData[3+i+1];
            String desc = lineData[3+i+2];
            String entries = lineData[3+i+3];
            String exits = lineData[3+i+4];

            if (desc.equals("REGULAR")) { // Ignore irregular samples

                Sample sample = new Sample(date, time);

              if (sample.datetime.compareTo(today) > 0) {
                println("ERROR: sample date is greater than today");
                println(lineData);
              }

              sample.desc = desc;
              sample.numEntries = (long)int(entries);
              sample.numExits = (long)int(exits);
              subunit.samples.add(sample);

              if (sample.datetime.compareTo(maxSampleDate) > 0) {
                maxSampleDate = sample.datetime;
              }

              if (sample.datetime.compareTo(minSampleDate) < 0) {
                minSampleDate = sample.datetime;
              }

              sampleCount++;
            }
          }
        }
      }
    }

    println("Date Range: "+minSampleDate+" - "+maxSampleDate);

    // Sort the control names by alphabetical order
    Iterator iterator = stations.entrySet().iterator();
    stationNames = new String[numStations];
    int i = 0;
    while (iterator.hasNext ()) {
      Map.Entry pairs = (Map.Entry)iterator.next();
      stationNames[i] = (String)pairs.getKey();
      i += 1;
    }
    Arrays.sort(stationNames);

  }
  
};

