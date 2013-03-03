import processing.dxf.*;

import org.processing.wiki.triangulate.*;
import processing.opengl.*;
import processing.opengl.*;

HashMap pointDepths = new HashMap();
ArrayList points = new ArrayList();
ArrayList triangles = new ArrayList();
boolean record = true;

void setup()
{
  size(800,800,P3D);
  parseLocs();
}

void draw()
{
  
  background(50);

  float camZ = (height/2.0) / tan(PI*60.0 / 360.0);
  camera(width-mouseX, 
         height-mouseY, 
         camZ,
         width/2.0, height/2.0, 0,
         0, 1, 0);

  pushMatrix();
  translate(0,0,-800);
  scale(width,height,width);
  
  /*
  for (int i = 0; i < points.size(); i++) {
    PVector p = (PVector)points.get(i);    
    stroke(255,0,0);
    strokeWeight(3);
    point(p.x, p.y, p.z);
  }*/
  
  if (record) {
    beginRaw(DXF, "output.dxf");
  }
  
  stroke(0, 40);
  fill(255, 100);
  beginShape(TRIANGLES);
 
  for (int i = 0; i < triangles.size(); i++) {
    PVector[] tri = (PVector[])triangles.get(i);
    vertex(tri[0].x, tri[0].y, tri[0].z);
    vertex(tri[1].x, tri[1].y, tri[1].z);
    vertex(tri[2].x, tri[2].y, tri[2].z);
  }
  
  endShape();

  if (record) {
    endRaw();
    record = false;
  }
  
  popMatrix();
}

float depthForPoint(PVector p)
{
    String z = (String)pointDepths.get(p.x+","+p.y); 
    return float(z); 
}

void parseLocs()
{
  
  String[] dataLines = loadStrings("basin3.obj");
  
  for (int i=0;i<dataLines.length;i++) {

    String line = dataLines[i];
    String[] rowData = line.split(" ");
    String type = rowData[0];
 
    if(type.equals("v")){
 
      float x = float(rowData[1]);
      float y = float(rowData[2]);
      float z = float(rowData[3]);
      points.add(new PVector(x,y,z));
      
    }else if(type.equals("f")){
      
      // This is a triangle.
      // Indexes start at 1
      int a = int(rowData[1]) - 1;
      int b = int(rowData[2]) - 1;
      int c = int(rowData[3]) - 1;
      PVector p1 = (PVector)points.get(a);
      PVector p2 = (PVector)points.get(b);
      PVector p3 = (PVector)points.get(c);
      PVector[] triangle = {p1,p2,p3};
      triangles.add(triangle);
      
    } 
    
  }
  
  println(points.size()+" points");
  
}
