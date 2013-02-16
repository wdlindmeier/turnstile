import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;

String dataFilename = "data/turnstile_130202.txt";

TurnstileParser parser; 

Station selectedStation;

int numBuckets;
int numBucketStreams;
int allEntries[][];
int stationIdx = 0;

void setup()
{
  
  size(800, 600);
  
  parser = new TurnstileParser();
  parser.parseDataFile(dataFilename);
  
  parseStationWithName(parser.stationNames[stationIdx]);
  
}

void keyPressed()
{
  println("KEY PRESS");
  if(key == CODED){
    if(keyCode == LEFT){
      stationIdx = stationIdx-1;
      if(stationIdx < 0){
        stationIdx = parser.numStations + stationIdx;
      }
    }else if(keyCode == RIGHT){
      stationIdx = (stationIdx+1) % parser.numStations;
    }
    String nextStationName = parser.stationNames[stationIdx];
    println("Selected station: "+nextStationName);
    parseStationWithName(nextStationName);
  }
}

void parseStationWithName(String stationName)
{
  
  selectedStation = (Station)parser.stations.get(stationName);
  println("selectedStation: "+selectedStation);
  
  numBucketStreams = selectedStation.controlUnits.size();
  long startMS = parser.minSampleDate.getTime();
  long endMS = parser.maxSampleDate.getTime();
  int hoursPerSample = 4;
  long msPerSample = 3600000 * hoursPerSample;
  numBuckets = ceil((endMS - startMS) / msPerSample);
    
  allEntries = new int[numBucketStreams][numBuckets];
  
  int cuIdx = 0;
  
  for (Object cuName : selectedStation.controlUnits.keySet()) {
    
    ControlUnit cu = (ControlUnit)selectedStation.controlUnits.get(cuName);   
    
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
  background(50);
  fill(255,255,0);  
  
  if(numBucketStreams > 0 && numBuckets > 0){
  
    float streamHeight = height / numBucketStreams;
    float bucketWidth = width / numBuckets;
  
    float maxSample = constrain(10, mouseY, height);
    for(int s=0;s<numBucketStreams;s++){    
      for(int b=0;b<numBuckets;b++){
        float x = b*bucketWidth;
        float y = streamHeight+(s*streamHeight);
        int entryCount = allEntries[s][b];
        float scalarVal = (float)entryCount / (float)maxSample;
        float dataHeight = streamHeight * scalarVal;  
        fill(255,255,255,150);
        rect(x, y-dataHeight, bucketWidth, dataHeight);
      }
    }
    
  }
  
  textAlign(LEFT);
  fill(255);
  text(selectedStation.name + " / " + selectedStation.remote + " / " + selectedStation.booth, 10, 20);    
  
}

