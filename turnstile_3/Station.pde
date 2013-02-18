class Station {
  
  String name;
  String controlArea;
  String stationID;
  String line;
  String division;
  double latitude;
  double longitude;
  int totalEntries[];
  
  HashMap controlUnits;
  
  public Station(){
    
    controlUnits = new HashMap();
    
  }
  
  String toString(){
    
    return "<Station:: stationID: "+stationID+" name: "+name+" line: "+line+" controlArea: "+controlArea+" latitude: "+latitude+" longitude: "+longitude+" division: "+division+" controlUnit count: "+controlUnits.size()+">";

  }
  
};
