class Station {
  
  String name;
  String controlArea;
  String stationID;
  String line;
  String division;
  double latitude;
  double longitude;
  int    totalEntries[];
  int    averageEntriesPreSandy[];
  double secondsUntilFirstRidership;
  double secondsUntilStationRestore;
  Date   dateFirstRider;
  Date   dateRidershipRestored;
  float  scalarRestoreDepth;
  float  scalarFirstRiderDepth;
  
  HashMap controlUnits;
  
  public Station(){
    
    dateFirstRider = new Date(1);
    dateRidershipRestored = new Date(2);
    controlUnits = new HashMap();
    
  }
  
  void calculateRidershipDepth()
  {
    calculateAverageRidershipPreSandy();
    calculateTimeOfFirstRidership();
    calculateTimeStationRestore();    
    // NOTE: If this is more than 1, remove "+ msPerSample" in calculateFirstRidershipForDate
    scalarFirstRiderDepth = (float)(dateFirstRider.getTime() - msAtSandy) / (float)(endMS - msAtSandy);
    scalarRestoreDepth = (float)(dateRidershipRestored.getTime() - msAtSandy) / (float)(endMS - msAtSandy); 
  }
  
  void calculateAverageRidershipPreSandy()
  {
      // Get the number of riders for each sample bucket (in a day) for the days before sandy
      // Average them by the number of days      
      long startSampleMS = parser.minSampleDate.getTime();
      long deltaMS = msAtSandy - startSampleMS;
      int numSamples = floor(deltaMS / msPerSample);  
      int samplesPerDay = 6;
      averageEntriesPreSandy = new int[samplesPerDay];
      for(int i=0;i<numSamples;i++){
        int idx = i%samplesPerDay;
        int idxMultiple = 1 + (i / samplesPerDay);
        int entries = averageEntriesPreSandy[idx];
        entries += totalEntries[i];
        averageEntriesPreSandy[idx] = round(entries / idxMultiple);
      }
      
  }
  
  void calculateTimeOfFirstRidership()
  {
    calculateFirstRidershipForDate(dateFirstRider);
  }
  
  void calculateTimeStationRestore()
  {
    calculateFirstRidershipForDate(dateRidershipRestored); 
  }

  void calculateFirstRidershipForDate(Date storeInDate)
  {
      // Find the first bucket that's 15% of the average pre-sandy
      long startSampleMS = parser.minSampleDate.getTime();
      long deltaMS = msAtSandy - startSampleMS;      
      int samplesPreSandy = (int)ceil((float)deltaMS / (float)msPerSample);
      long msAtFirstRidership = 0;     
      
      for(int i=samplesPreSandy+1;i<numBuckets;i++){
        int entryCount = totalEntries[i];
        int minimumManditoryRidership = minRidershipForValueInBucketForDate(i, storeInDate);
        if(entryCount > minimumManditoryRidership){
          // voila
          msAtFirstRidership = startSampleMS + (long)(i*msPerSample);
          break;
        }
      }
      
      if(msAtFirstRidership == 0){
        msAtFirstRidership = endMS + msPerSample;
      }
      
      Date thisDate = new Date(msAtFirstRidership);
      if(storeInDate == dateFirstRider){
        dateFirstRider = thisDate;
      }else if(storeInDate == dateRidershipRestored){
        dateRidershipRestored = thisDate;
      }else{
        println("ERROR: couldnt id date: "+storeInDate);
      }
      
  }
  
  // This is ghetto, but I don't want to learn how to make Java do functional programming at the moment.
  int minRidershipForValueInBucketForDate(int bucketNum, Date forDate)
  {
    if(forDate == dateFirstRider){
      return 0;
    }else if(forDate == dateRidershipRestored){
      return max(ceil(totalEntries[bucketNum] * 0.15f), 5); // 15% or 5, whichever is higher. Doesnt seem like too much to assume.
    }else{
      println("ERROR: Dont know date "+forDate);
    }
    return -1;
  }
  

  String toString(){
    
    return "<Station:: stationID: "+stationID+" name: "+name+" line: "+line+" controlArea: "+controlArea+" latitude: "+latitude+" longitude: "+longitude+" division: "+division+" controlUnit count: "+controlUnits.size()+">";

  }
  
};
