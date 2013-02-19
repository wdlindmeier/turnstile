import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;

//String dataFilename = "data/turnstile_130202.txt";
String dataFilename = "data/turnstile_121103.txt";

TurnstileParser parser; 

int numBuckets;
int numBucketStreams;
int allEntries[][];
int maxSample = 0;
long startMS;
long endMS;
int hoursPerSample = 4;
long msPerSample = 3600000 * hoursPerSample;
  
void setup()
{
    
  parser = new TurnstileParser();
  parser.parseDataFile(dataFilename);
  
  size(800, parser.numStations);
  
  parseAllStations();
  
  println("maxSample: "+maxSample);
  
}

void parseAllStations()
{
    
  // A stream for each station
  numBucketStreams = parser.numStations;
  startMS = parser.minSampleDate.getTime();
  endMS = parser.maxSampleDate.getTime();
  numBuckets = ceil((endMS - startMS) / msPerSample) + 1;    
  allEntries = new int[numBucketStreams][numBuckets];

  int streamIndex = 0;
  for(String name : parser.stationNames){
    parseStationWithName(name, streamIndex);
    streamIndex++;
  }
  
}

void parseStationWithName(String stationName, int streamIndex)
{
  
  Station selectedStation = (Station)parser.stations.get(stationName);
  
  int cuIdx = 0;
  
  for (Object cuName : selectedStation.controlUnits.keySet()) {
    
    ControlUnit cu = (ControlUnit)selectedStation.controlUnits.get(cuName);   
    
    long lastNumEntries = -1;

    int sampleIdx=0;
    
    for(Sample s : cu.samples){
      
      if(lastNumEntries != -1){
                        
        int numEntries = (int)(s.numEntries - lastNumEntries);
                
        int bucketNum = floor((s.datetime.getTime() - startMS) / msPerSample);
        bucketNum = constrain(bucketNum, 0, numBuckets-1);
        
        int bucketVal = allEntries[streamIndex][bucketNum];
        int newBucketVal = bucketVal + numEntries;
        if(newBucketVal > maxSample){
          maxSample = newBucketVal;
        }
        allEntries[streamIndex][bucketNum] = newBucketVal;

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
    
    // Play with this.
    // Mouse adjusts the contrast of the data.
    float maxSample = mouseY * 20;
    
    for(int s=0;s<numBucketStreams;s++){    
      for(int b=0;b<numBuckets;b++){

        float x = b*bucketWidth;
        float y = s*streamHeight;
        int entryCount = allEntries[s][b];
        float scalarVal = (float)entryCount / (float)maxSample;
        int plotBrightness = constrain(round(255 * scalarVal), 0, 255);
        noStroke();        
        fill(plotBrightness);
        rect(x, y, bucketWidth, streamHeight);        
      }
    }
    
  }
  
  textAlign(LEFT);
  fill(255);
  
  pushMatrix();
  rotate(HALF_PI);
  text(parser.minSampleDate + " - " + parser.maxSampleDate, 5, -5);
  popMatrix();  
  
}

