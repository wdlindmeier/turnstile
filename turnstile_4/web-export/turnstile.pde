import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import Sample;
import ControlUnit;
import Station;

HashMap controlUnitData;
String dataFilename = "data/turnstile_130202.txt";

void setup()
{
  
  size(400, 200);
  
  println("Parsing turnstyle data in file: " + dataFilename);
  
  controlUnitData = new HashMap();
  String[] dataLines = loadStrings(dataFilename);
  for (String line:dataLines) {

    String stripLine = line.trim();
    if (!stripLine.equals("")) {

      String[] lineData = stripLine.split(",");
      String unitName = lineData[0];      
      HashMap unitData = (HashMap)controlUnitData.get(unitName);
      if (unitData == null) {
        unitData = new HashMap();
        unitData.put("control_area", unitName);
        controlUnitData.put(unitName, unitData);
      }
      ArrayList<HashMap> unitSamples = (ArrayList<HashMap>)unitData.get("samples");
      if (unitSamples == null) {
        unitSamples = new ArrayList<HashMap>();
        unitData.put("samples", unitSamples);
      } 
      HashMap lastSample = new HashMap();
      int samplesLength = lineData.length - 3;
      String[] sampleData = new String[samplesLength];
      System.arraycopy(lineData, 3, sampleData, 0, samplesLength); 
      for (int i=0;i<sampleData.length;i++) {
        String datum = sampleData[i];
        switch(i) {
        case 0:
          lastSample.put("date", datum); 
          break; 
        case 1:
          lastSample.put("time", datum);
          break; 
        case 2:
          lastSample.put("desc", datum);
          break; 
        case 3:
          lastSample.put("entries", datum);
          break; 
        case 4:
          lastSample.put("exits", datum);
          unitSamples.add(lastSample);
          lastSample = new HashMap();
          break;
        }
      }
    }
  }

  int cuSize = controlUnitData.size();
  println("controlUnitData.size: " + cuSize);

  // Sort the control names by alphabetical order
  Iterator iterator = controlUnitData.entrySet().iterator();
  String[] names = new String[cuSize];
  int i = 0;
  while (iterator.hasNext ()) {
    Map.Entry pairs = (Map.Entry)iterator.next();
    names[i] = (String)pairs.getKey();
    i += 1;
  }
  Arrays.sort(names);
  
  // Now that we have the sorted names, lets print out the name/samples count
  for(String cu:names){
    
    HashMap controlUnit = (HashMap)controlUnitData.get(cu);
    ArrayList<HashMap> cuSamples = (ArrayList<HashMap>)controlUnit.get("samples");
    long greatestNumEntries = 0;
    long leastNumEntries = 999999999;
    String earliestDate = "99-99-99 99:99:99";
    String latestDate = "00-00-00 00:00:00";
    for(HashMap sample:cuSamples){
      // Get the date range
      String date = (String)sample.get("date");
      String time = (String)sample.get("time");
      String dateTime = date + " " + time;
      if(dateTime.compareTo(earliestDate) < 0){
        earliestDate = dateTime; 
      }
      if(dateTime.compareTo(latestDate) > 0){
        latestDate = dateTime;
      }
      
      // Count the number of entries
      String entries = (String)sample.get("entries");
      long entriesCount = Integer.parseInt(entries); 
      if(entriesCount > greatestNumEntries){
        greatestNumEntries = entriesCount; 
      }
      if(entriesCount < leastNumEntries){
        leastNumEntries = entriesCount;
      }
    }
    
    println("---");
    
    int sampleSize = cuSamples.size();
    println(cu + " num samples: " + sampleSize);
    
    // NOTE: This isn't a valid total, because there are multiple 
    // sub-units in the samples.
    println("max entries: " + greatestNumEntries + " min entries: " + leastNumEntries);
    
    println("date range: " + earliestDate + " through " + latestDate);
    
  }
  
}

void draw()
{
  background(30);
  fill(255,255,0);
  text("Parsing Complete.\nNumber of Control Units Sampled: "+controlUnitData.size(), 20, 100);
}

class ControlUnit {
  
  String name;
  ArrayList<Sample> samples;
  
};
class Sample {
  
  DateTime datetime;
  long numEntries;
  long numExits;
  
};
class Station {
  
  String name;
  ArrayList<ControlUnit> controlUnits;
  
};

