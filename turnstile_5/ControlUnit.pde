class ControlUnit {
  
  String name;
  ArrayList<Sample> samples;
  
  public ControlUnit(String cuName){
    
    name = cuName;
    samples = new ArrayList<Sample>();
    
  }
  
  String toString(){
    
    return "<ControlUnit:: name: "+name+" sample count: "+samples.size()+">";
    
  }
  
};
