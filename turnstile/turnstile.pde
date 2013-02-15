import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;

HashMap stations;
String[] stationNames;

String stationFilename = "data/station_names.csv";
String dataFilename = "data/turnstile_130202.txt";

long subunitCount = 0;
long sampleCount = 0;
int numBuckets;
int numBucketStreams;
int allEntries[][];
Station selectedStation;

Date minSampleDate;
Date maxSampleDate;

void setup()
{
  
  size(800, 600);
  
  maxSampleDate = new Date(1000);
  minSampleDate = new Date();

  stations = new HashMap();
  
  // First parse the station names
  
  println("Parsing turnstyle data in file: " + stationFilename);
  String[] stationLines = loadStrings(stationFilename);
  for (int i=0;i<stationLines.length;i++) {
    if(i>0){
      String line = stationLines[i];
      String[] stationData = line.split(",");
      if(stationData.length > 4){      
        String stationName = stationData[2];
        Station station = new Station(stationName);
        station.remote = stationData[0];
        station.booth = stationData[1];
        station.line = stationData[3];
        station.division = stationData[4];       
        stations.put(station.remote, station);
      }else{
        println("Couldnt parse line: "+line);
      }      
    }
  }
  println("Parsed "+stations.size()+" stations");

  // Then parse the data  
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
      if(subunit == null){
        subunit = new ControlUnit(subunitName);
        station.controlUnits.put(subunitName, subunit); 
        subunitCount++;
      }
      
      // Add the samples
      int samplesLength = lineData.length - 3;
      if(samplesLength % 5 != 0){
        
        println("ERROR: irregular sample length:");
        println(lineData);
        
      }else{
        for (int i=0;i<samplesLength;i+=5) {
          
          String date = lineData[3+i+0];
          String time = lineData[3+i+1];
          String desc = lineData[3+i+2];
          String entries = lineData[3+i+3];
          String exits = lineData[3+i+4];
          
          if(desc.equals("REGULAR")){ // Ignore irregular samples
            
            Sample sample = new Sample(date, time);
            
            if(sample.datetime.compareTo(today) > 0){
              println("ERROR: sample date is greater than today");
              println(lineData);
            }
            
            sample.desc = desc;
            sample.numEntries = (long)int(entries);
            sample.numExits = (long)int(exits);
            subunit.samples.add(sample);
            
            if(sample.datetime.compareTo(maxSampleDate) > 0){
              maxSampleDate = sample.datetime;
            }
            
            if(sample.datetime.compareTo(minSampleDate) < 0){
              minSampleDate = sample.datetime;
            }
            
            sampleCount++;
            
          }        
        }
      }
    }
  }
  
  // Sort the control names by alphabetical order
  Iterator iterator = stations.entrySet().iterator();
  stationNames = new String[stations.size()];
  int i = 0;
  while (iterator.hasNext ()) {
    Map.Entry pairs = (Map.Entry)iterator.next();
    stationNames[i] = (String)pairs.getKey();
    i += 1;
  }
  Arrays.sort(stationNames);
  
  // Lets take a look at a sampple station. The Roosevelt Island Tram
  
  selectedStation = (Station)stations.get("R469");
  println("tramStation: "+selectedStation);
  
  numBucketStreams = selectedStation.controlUnits.size();
  long startMS = minSampleDate.getTime();
  long endMS = maxSampleDate.getTime();
  int hoursPerSample = 4;
  long msPerSample = 3600000 * hoursPerSample;
  numBuckets = ceil((endMS - startMS) / msPerSample);
    
  allEntries = new int[numBucketStreams][numBuckets];
  
  println("numBucketStreams "+numBucketStreams+" numBuckets "+numBuckets);
  
  int cuIdx = 0;
  
  for (Object cuName : selectedStation.controlUnits.keySet()) {
    
    ControlUnit cu = (ControlUnit)selectedStation.controlUnits.get(cuName);
    println(cu);
    
    long lastNumEntries = -1;

    int sampleIdx=0;
    
    for(Sample s : cu.samples){
      
      if(lastNumEntries != -1){
                        
        int numEntries = (int)(s.numEntries - lastNumEntries);
        
        // Why minus 1?        
        int bucketNum = floor((s.datetime.getTime() - startMS) / msPerSample) - 1;
        
        int bucketVal = allEntries[cuIdx][bucketNum];
        allEntries[cuIdx][bucketNum] = bucketVal + numEntries;

        sampleIdx++;  
      }
      
      lastNumEntries = s.numEntries;

    }
    
    cuIdx++;
    
  }

  
}

void draw()
{
  background(80);
  fill(255,255,0);  

  float streamHeight = height / numBucketStreams;
  float bucketWidth = width / numBuckets;

  textAlign(LEFT);
  fill(255);
  text(selectedStation.name + " / " + selectedStation.remote + " / " + selectedStation.booth, 10, 20);    
  
  float maxSample = mouseY;
  for(int s=0;s<numBucketStreams;s++){    
    for(int b=0;b<numBuckets;b++){
      float x = b*bucketWidth;
      float y = streamHeight+(s*streamHeight);
      int entryCount = allEntries[s][b];
      float scalarVal = (float)entryCount / (float)maxSample;
      float dataHeight = streamHeight * scalarVal;  
      fill(255,255,255,200);
      rect(x, y-dataHeight, bucketWidth, dataHeight);
    }
  }
  
}

