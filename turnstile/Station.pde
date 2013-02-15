class Station {
  
  String name;
  String remote;
  String booth;
  String line;
  String division;
  
  HashMap controlUnits;
  
  public Station(String stationName){
    
    name = stationName;
    controlUnits = new HashMap();
    
  }
  
  String toString(){
    
    return "<Station:: name: "+name+" remote: "+remote+" booth: "+booth+" line: "+line+" division: "+division+" controlUnit count: "+controlUnits.size()+">";
    
  }
  
};
