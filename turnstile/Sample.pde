import java.text.SimpleDateFormat;
import java.text.ParseException;

class Sample {
  
  Date datetime;
  long numEntries;
  long numExits;
  String desc;
  
  public Sample(String dateString, String timeString){
    
    numEntries = 0;
    numExits = 0;
    SimpleDateFormat df = new SimpleDateFormat("MM-dd-yy HH:mm:ss");
    String dateTimeString = dateString + " " + timeString;
    try{
      datetime = df.parse(dateTimeString);
    }catch(ParseException e){
      println("ERROR parsing date "+dateTimeString);
      println(e);
    }
    
  }
  
  String toString(){
    
    return "<Sample:: datetime: "+datetime+" numEntries: "+numEntries+" numExits: "+numExits+" desc: "+desc+">";
    
  }
  
};
