import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Date;
import org.processing.wiki.triangulate.*;

ArrayList triangles = new ArrayList();
ArrayList points = new ArrayList();

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
  
  size(round((float)spanLng * 2000), round((float)spanLat * 2000), P3D);
  
  parseAllStations();
  
  /*
  // There are some unknowns, but I'm not sure how to
  // get their location, or the impact of the loss.
  // Ignoring for now.  
  println("unknownStationIDs:\n"+unknownStationIDs);
  println("unknownControlUnits:\n"+unknownControlUnits);
  */
    renderTriangles();

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

void renderTriangles()
{
  
//  background(50);
//  fill(255,255,0);

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
    
    points.add(new PVector(x, y, plotBrightness));
    
//    noStroke();    
//    fill(plotBrightness);
//    ellipse(x, y, 10, 10);        

  }
  
  /*
  points.add(new PVector(100, 100, 150));
  points.add(new PVector(500, 100, 50));
  points.add(new PVector(100, 500, 150));
  points.add(new PVector(500, 500, 50));
  */
  
  println("Starting triangulate");
  
  triangles = Triangulate.triangulate(points);
  
  println("End triangulate");
  
  /*
  if(printRidershipData){
    println("};");
    didPrintRidershipRestoredData = true;
  }
  */
  
}


void draw() {
 
  background(200);
  
  // Change height of the camera with mouseY
  /*
  camera(mouseX, mouseY, 220.0, // eyeX, eyeY, eyeZ
         0.0, 0.0, 0.0, // centerX, centerY, centerZ
         0.0, 1.0, 0.0); // upX, upY, upZ  
 */
 
  // draw points as red dots     
  noStroke();
  fill(255, 0, 0);
 
  for (int i = 0; i < points.size(); i++) {
    PVector p = (PVector)points.get(i);
    ellipse(p.x, p.y, 2.5, 2.5);
  }
 
  // draw the mesh of triangles
  stroke(0, 40);
  fill(255, 100);
  beginShape(TRIANGLES);
 
  for (int i = 0; i < triangles.size(); i++) {
    Triangle t = (Triangle)triangles.get(i);
    vertex(t.p1.x, t.p1.y);
    vertex(t.p2.x, t.p2.y);
    vertex(t.p3.x, t.p3.y);
  }
  endShape();
 
}
