class Blob {

  // shape
  private PShape blobShape;
  private int numPoints = 5;
  private float radius;
  private float randomness;
  private PVector[] initPoints;
  private PVector[] offset;
  private PVector[] blobPoints;

  // animation
  private float stepSize = 0.5;
  private float speed = 0.01;

  public Blob() {
    radius = canvasWidth * 0.4;
    randomness = radius * 0.3;
    
    initPoints = new PVector[numPoints];
    offset = new PVector[numPoints];
    blobPoints = new PVector[numPoints];
    generatePoints();
  }
  
  public void reset() {
    generatePoints();
  }

  private void generatePoints() {
    for (int i = 0; i < numPoints; i++) {
      float angle = float(i)/numPoints*TWO_PI;
      initPoints[i] = new PVector(
        radius * (cos(angle)) + random(-randomness, randomness), 
        radius * (sin(angle)) + random(-randomness, randomness));
      blobPoints[i] = new PVector(initPoints[i].x, initPoints[i].y);
      offset[i] = new PVector(random(1000), random(1000));
    }
  }

  private void generateBlob() {

    // move points
    for (int i = 0; i < numPoints; i++) {
      blobPoints[i].add(new PVector(
        map(noise(offset[i].x), 0, 1, -stepSize, stepSize), 
        map(noise(offset[i].y), 0, 1, -stepSize, stepSize)));
    }

    // create blob shape
    blobShape = createShape();
    blobShape.beginShape();
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

  public void display() {
    
    generateBlob();
    
    // mask graphics buffer
    pg_blob_mask.beginDraw();
    pg_blob_mask.clear();
    pg_blob_mask.translate(pg_blob_mask.width * 0.5, pg_blob_mask.height * 0.5);
    blobShape.setFill((255 << 24) | (255 << 16) | (255 << 8) | 255);
    pg_blob_mask.shape(blobShape);
    pg_blob_mask.endDraw();
    
  }
  
}
