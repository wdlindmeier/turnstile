import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;

// Control
// String dataFilename = "data/turnstile_130202.txt";
// NYE
// String dataFilename = "data/turnstile_130105.txt";
// Sandy 0
// String dataFilename = "data/turnstile_121103.txt";
// Sandy 1
// String dataFilename = "data/turnstile_121110.txt";
// Sandy 2
// String dataFilename = "data/turnstile_121117.txt";
// All Sandy
String dataFilename = "data/sandy_composite_data.txt";

TurnstileParser parser; 

int numBuckets;
long startMS;
long endMS;
int hoursPerSample = 4;
long msPerSample = 3600000 * hoursPerSample;
long msAtSandy = 1351465200000l;

double centerLat = 40.74;
double centerLng = -73.9;
double spanLat = 0.354929;
double spanLng = 0.354929;
double minLat = centerLat - (spanLat * 0.5);
double minLng = centerLng - (spanLng * 0.5);
double maxLat = centerLat + (spanLat * 0.5);
double maxLng = centerLng + (spanLng * 0.5);

int drawMode = 1;
boolean didPrintRidershipRestoredData = false;
  
void setup()
{

  parser = new TurnstileParser();
  parser.parseDataFile(dataFilename);
  
  size(round((float)spanLng * 2000), round((float)spanLat * 2000));
  
  parseAllStations();
  
  /*
  // There are some unknowns, but I'm not sure how to
  // get their location, or the impact of the loss.
  // Ignoring for now.  
  println("unknownStationIDs:\n"+unknownStationIDs);
  println("unknownControlUnits:\n"+unknownControlUnits);
  */
  
}

void parseAllStations()
{
    
  startMS = parser.minSampleDate.getTime();
  endMS = parser.maxSampleDate.getTime();
  numBuckets = ceil((endMS - startMS) / msPerSample) + 1;    

  int streamIndex = 0;
  for (Object stationID : parser.stations.keySet()) {
    parseStationWithKey((String)stationID, streamIndex);    
    streamIndex++;
  }
  
}

void parseStationWithKey(String stationKey, int streamIndex)
{
  
  Station selectedStation = (Station)parser.stations.get(stationKey);
  
  int cuIdx = 0;
  
  int totalEntries[] = new int[numBuckets];
  
  for (Object cuName : selectedStation.controlUnits.keySet()) {
    
    ControlUnit cu = (ControlUnit)selectedStation.controlUnits.get(cuName);   
    
    long lastNumEntries = -1;

    int sampleIdx=0;
    
    for(Sample s : cu.samples){
      
      if(lastNumEntries != -1){
                        
        int numEntries = (int)(s.numEntries - lastNumEntries);
                
        int bucketNum = floor((s.datetime.getTime() - startMS) / msPerSample);
        bucketNum = constrain(bucketNum, 0, numBuckets-1);
        
        int bucketVal = totalEntries[bucketNum];
        int newBucketVal = bucketVal + numEntries;
        totalEntries[bucketNum] = newBucketVal;

        sampleIdx++;
        
      }
      
      lastNumEntries = s.numEntries;

    }
    
    cuIdx++;    
  }
  
  selectedStation.totalEntries = totalEntries;
  
  selectedStation.calculateRidershipDepth();

}

void keyPressed()
{
  drawMode = drawMode * -1;
  if(drawMode < 0){
    println("First Rider draw mode");
  }else{
    println("Station Restored draw mode");
  }
}

void draw()
{
  
  background(50);
  fill(255,255,0);
  
  boolean printRidershipData = drawMode > 0 && !didPrintRidershipRestoredData;
    
  if(printRidershipData){
    println("var stations = {");
  }    

  for (Object stationID : parser.stations.keySet()) {
    Station station = (Station)parser.stations.get(stationID);
    
    float x = (float)((station.longitude - minLng) / spanLng) * width; 
    float y = height - ((float)((station.latitude - minLat) / spanLat) * height);
    
    float scalarVal = 1.0f;
    if(drawMode < 0){
      scalarVal = 1.0 - station.scalarFirstRiderDepth;
    }else{
      scalarVal = 1.0 - station.scalarRestoreDepth;
    }
    
    if(printRidershipData){
      println("\t"+station.stationID+" : { x : "+x/(float)width+", y : "+y/(float)height+", z : "+scalarVal+"},");
    }
    
    // Multiply the brightness according to the mouse position
    scalarVal *= mouseY / (float)height;
    
    int plotBrightness = constrain(round(255 * scalarVal), 0, 255);
    
    noStroke();    
    fill(plotBrightness);
    ellipse(x, y, 10, 10);        

  }
  
  if(printRidershipData){
    println("};");
    didPrintRidershipRestoredData = true;
  }

  
}

