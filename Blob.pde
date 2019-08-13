class Blob {

  // shape
  PShape blobShape;
  int numPoints = 5;
  float radius = 350.0;
  float randomness = 100.0;
  PVector[] initPoints;
  PVector[] offset;
  PVector[] blobPoints;

  // animation
  float stepSize = 0.5;
  float speed = 0.01;

  Blob() {
    initPoints = new PVector[numPoints];
    offset = new PVector[numPoints];
    blobPoints = new PVector[numPoints];
    generatePoints();
  }
  
  void reset() {
    generatePoints();
  }

  void generatePoints() {
    for (int i = 0; i < numPoints; i++) {
      float angle = float(i)/numPoints*TWO_PI;
      initPoints[i] = new PVector(
        radius*(cos(angle)) + random(-randomness, randomness), 
        radius*(sin(angle)) + random(-randomness, randomness));
      blobPoints[i] = new PVector(initPoints[i].x, initPoints[i].y);
      offset[i] = new PVector(random(1000), random(1000));
    }
  }

  void generateBlob() {

    // move points
    for (int i = 0; i < numPoints; i++) {
      blobPoints[i].add(new PVector(
        map(noise(offset[i].x), 0, 1, -stepSize, stepSize), 
        map(noise(offset[i].y), 0, 1, -stepSize, stepSize)));
    }

    // create blob shape
    blobShape = createShape();
    blobShape.beginShape();
    //blobShape.fill(fillColor);
    blobShape.noStroke();
    blobShape.curveVertex(blobPoints[numPoints-1].x, blobPoints[numPoints-1].y);
    for (int i = 0; i < numPoints; i++) {
      blobShape.curveVertex(blobPoints[i].x, blobPoints[i].y);
    }
    blobShape.curveVertex(blobPoints[0].x, blobPoints[0].y);
    blobShape.curveVertex(blobPoints[1].x, blobPoints[1].y);
    blobShape.endShape();

    // increment
    for (int i = 0; i < numPoints; i++) {
      offset[i].x += speed;
      offset[i].y += speed;
    }
    
  }

  void display() {
    
    generateBlob();
    
    // graphics buffer
    pg_blob.beginDraw();
    pg_blob.clear();
    //pg_blob.translate(width/2, height/2);
    pg_blob.translate(pg_blob.width * 0.5, pg_blob.height * 0.5);
    blobShape.setFill(fillColor);
    pg_blob.shape(blobShape);
    pg_blob.endDraw();
    
    // mask buffer
    pg_blob_mask.beginDraw();
    pg_blob_mask.clear();
    //pg_blob_mask.translate(width/2, height/2);
    pg_blob_mask.translate(pg_blob_mask.width * 0.5, pg_blob_mask.height * 0.5);
    blobShape.setFill((255 << 24) | (255 << 16) | (255 << 8) | 255);
    pg_blob_mask.shape(blobShape);
    pg_blob_mask.endDraw();
    
  }
  
}
