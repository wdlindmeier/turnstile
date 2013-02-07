import org.json.*;

void setup()
{
  println("Loading data...");
  String dataStrings[] = loadStrings("data/parsed_data.json");
  try {
    // Load the JSON data
    JSONObject jsonData = new JSONObject(join(dataStrings, ""));
    println("There are "+jsonData.length()+" entries in the data");
    
    // Get all of the station names so we can access them from the JSONObject
    String[] stationNames = JSONObject.getNames(jsonData);
    // println(stationNames);
    
    // Sample getting a station
    String stationName = stationNames[0];
    println("The first station is named: "+stationName);
    JSONObject firstStation = (JSONObject)jsonData.get(stationName);
    // println(firstStation);  
    long stationEntries = firstStation.getLong("total_entries");
    long stationExits = firstStation.getLong("total_exits");
    println("stationEntries: "+stationEntries+" stationExits: "+stationExits);
    JSONArray samples = firstStation.getJSONArray("samples");
    println("samples count: "+samples.length());
    
  }catch(JSONException e){
    println(e);
  }
}

void draw()
{
  background(100,255,100);
}

