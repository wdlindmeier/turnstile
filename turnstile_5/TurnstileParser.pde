import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;
import java.util.Set;

String stationIDsFile = "data/control_station_ids.csv";
String stationLocationsFile = "data/station_locations.csv";

ArrayList<String> unknownStationIDs = new ArrayList<String>();
ArrayList<String> unknownControlUnits = new ArrayList<String>();

class TurnstileParser
{
  
  HashMap stations;

  long subunitCount = 0;
  long sampleCount = 0;
  int numStations;

  Date minSampleDate;
  Date maxSampleDate;

  public TurnstileParser()
  {
    maxSampleDate = new Date(1000);
    minSampleDate = new Date();
    stations = new HashMap();
    parseControlUnitStationIDs();
    parseStationLocations();
    storeStationsByControlArea();
    numStations = stations.size();
    
  }

  void parseControlUnitStationIDs()
  {    
    println("Parsing station IDs in file: " + stationIDsFile);    
    String[] stationLines = loadStrings(stationIDsFile);
    for (int i=0;i<stationLines.length;i++) {
      if (i>0) { // NOTE: 0 is the column names
        String line = stationLines[i];
        String[] stationData = line.split(",");

        if(stationData.length > 3){
          // Just create a shell for the station
          Station station = new Station();
          String stationID = stationData[3].trim();
          String controlAreaID = stationData[1].trim();          
          station.stationID = stationID;
          station.controlArea = controlAreaID;
          stations.put(stationID, station);
        }

      }
    }
  }
  
  void parseStationLocations()
  {
    println("Parsing station locations in file: " + stationLocationsFile);    
    String[] stationLines = loadStrings(stationLocationsFile);
    for (int i=0;i<stationLines.length;i++) {
      if (i>0) { // NOTE: 0 is the column names
        String line = stationLines[i];
        String[] stationData = line.split(",");
        if (stationData.length > 5) {          
          String stationID = stationData[0].trim();
          Station station = (Station)stations.get(stationID);
          if(station != null){
            
            String stationName = stationData[1].trim();
            String lineName = stationData[2].trim();
            String division = stationData[3].trim();
            String lat = stationData[4].trim();
            String lng = stationData[5].trim();
            
            station.name = stationName;
            station.line = lineName; 
            station.division = division;
            station.latitude = float(lat);
            station.longitude = float(lng);
            
          }else{
            if(unknownStationIDs.indexOf(stationID) == -1){
              unknownStationIDs.add(stationID);
            }
          }
        }
      }
    }
  }
  
  void storeStationsByControlArea()
  {
    HashMap stationsByControlArea = new HashMap();
    for (Object stationID : stations.keySet()) {    
      Station station = (Station)stations.get(stationID);      
      stationsByControlArea.put(station.controlArea, station);
    }   
    // Replace
    stations = stationsByControlArea;
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
        String controlArea = lineData[0];      
        Station station = (Station)stations.get(controlArea);
        if (station == null) {
          if(unknownControlUnits.indexOf(controlArea) == -1){
            unknownControlUnits.add(controlArea);
          }
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
    
  }
  
};

