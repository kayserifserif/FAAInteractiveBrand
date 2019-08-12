import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

import controlP5.*;

import processing.video.Capture;

// GRAPHIC
// 0 = INK
// 1 = BLOB
int graphic = 0;
PGraphics2D pg_graphic;

// fluid
Fluid fluid_data;
PGraphics2D pg_fluid;

// blob
Blob blob;
PGraphics2D pg_blob;
PGraphics2D pg_blob_mask;

// camera
boolean showCam = true;
Capture cam;
int cam_w = 640;
int cam_h = 480;
PGraphics2D pg_cam_a, pg_cam_b;

// shapes
PShape sansShape;
PShape serifShape;
PGraphics pg_sans;
PGraphics pg_serif;
float scaleFac;
float hmargin = 75.0;
float vmargin;

// color
color bgColor;
color fillColor;

// controls
ControlP5 cp5;
ButtonBar bb;
int bbHeight = 20;

void setup() {
  
  //fullScreen();
  size(840, 1188, P2D);

  // shapes
  pg_sans = createGraphics(width, height);
  pg_serif = createGraphics(width, height);
  sansShape = loadShape("logo_sans.svg");
  serifShape = loadShape("logo_serif.svg");
  scaleFac = (width - hmargin*2)/serifShape.width;
  sansShape.scale(scaleFac);
  serifShape.scale(scaleFac);
  vmargin = (height - sansShape.height*scaleFac)*0.5;
    
  // FLUID
  fluid_data = new Fluid(this);
  pg_fluid = (PGraphics2D) createGraphics(width, height, P2D);
  // camera
  cam = new Capture(this, cam_w, cam_h, 30);
  cam.start();
  // render buffers
  pg_cam_a = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
  pg_cam_a.noSmooth();
  pg_cam_a.beginDraw();
  pg_cam_a.background(0);
  pg_cam_a.endDraw();
  pg_cam_b = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
  pg_cam_b.noSmooth();

  // BLOB
  blob = new Blob();
  pg_blob = (PGraphics2D) createGraphics(width, height, P2D);
  pg_blob_mask = (PGraphics2D) createGraphics(width, height, P2D);
  
  // graphic
  pg_graphic = (PGraphics2D) createGraphics(width, height, P2D);
  
  // controls
  cp5 = new ControlP5(this);
  bb = cp5.addButtonBar("selectGraphic")
          .setPosition(0, 0)
          .setSize(width, bbHeight)
          .addItems(new String[] {"ink", "jade"})
          ;
  bb.changeItem("ink", "text", "");
  bb.changeItem("jade", "text", "");
  if (graphic == 0) {
    bb.changeItem("ink", "selected", true);
  } else if (graphic == 1) {
    bb.changeItem("jade", "selected", true);
  }
  
  updateGraphic();
  
}

void draw() {

  background(bgColor);
  
  // display cam
  if ( cam.available() ) {
    cam.read();
    fluid_data.updateCam();
  }
  if (showCam) {
    pushStyle();
    tint(255, 50);
    image(pg_cam_a, 0, 0, width, height);
    popStyle();
  }
  
  // prepare graphic
  if (graphic == 0) {
    fluid_data.display();
    pg_graphic = pg_fluid;
  } else if (graphic == 1) {
    blob.display();
    pg_graphic = pg_blob_mask;
  }

  // display
  pg_sans.loadPixels();
  pg_graphic.loadPixels();
  // sans
  for (int i = 0; i < pg_sans.pixels.length; i++) {
    if ((pg_sans.pixels[i] >> 24 & 0xFF) != 0) {
      // bit masking formula from oshoham
      // https://github.com/processing/processing/issues/1738
      int alpha = int(constrain(-(pg_graphic.pixels[i] >> 24 & 0xFF), color(0), color(255)));
      pg_sans.pixels[i] = (alpha << 24) | (pg_sans.pixels[i] & 0xFFFFFF);
    }
  }
  pg_sans.updatePixels();
  // graphic
  image(pg_sans, 0, 0);
  if (graphic == 0) {
    image(pg_graphic, 0, 0);
  } else if (graphic == 1) {
    image(pg_blob, 0, 0);
  }
  // serif
  pg_serif.mask(pg_graphic);
  image(pg_serif, 0, 0);

  // show title bar info
  info();
  
}

void selectGraphic(int n) {
  graphic = n;
  updateGraphic();
}

void updateGraphic() {
  
  if (graphic == 0) {
    bgColor = color(255);
    fillColor = color(0);
    //fillColor = color(0, 0, 50);
    //fillColor = color(0, 50, 50);
    //fillColor = color(0, 50, 75);
  } else if (graphic == 1) {
    bgColor = color(199, 209, 181);
    fillColor = color(35, 62, 33);
  }

  pg_sans.beginDraw();
  pg_sans.noStroke();
  pg_sans.translate(hmargin, vmargin);
  sansShape.setFill(fillColor);
  sansShape.draw(pg_sans);
  pg_sans.endDraw();

  pg_serif.beginDraw();
  pg_serif.noStroke();
  pg_serif.background(fillColor);
  pg_serif.translate(hmargin, vmargin);
  serifShape.setFill(bgColor);
  serifShape.draw(pg_serif);
  pg_serif.endDraw();
  
  bb.setColorForeground(lerpColor(bgColor, fillColor, 0.5))
    .setColorActive(bgColor)
    .setColorBackground(fillColor)
    ;
    
}

void mousePressed() {
  if (mouseY > bbHeight) {
    if (graphic == 0) {
      fluid_data.reset();
    } else if (graphic == 1) {
      blob.reset();
    }
  }
}

void info() {
  String s = String.format(getClass().getName() + " [fps %6.2f]", frameRate);
  surface.setTitle(s);
}
