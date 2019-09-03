/**
 * 
 * Fine Art Asia Interactive Ink Branding Experience, 2019
 * from Superunion - https://www.superunion.com
 * by Katherine Yang - https://whykatherine.github.io
 * 
 * An interactive branding experience that uses computer vision
 * and motion tracking to create a dynamic ink visual that alternately
 * reveals and obscures the traditional and modern aspects of the
 * Fine Art Asia brand.
 * 
 * Press 'p' to capture a TIF screenshot.
 * 
 * Requires a connected camera device.
 * 
 * PixelFlow library by Thomas Diewald, 2016 - https://diwi.github.io/PixelFlow/
 * Video library by Processing - https://processing.org/reference/libraries/video/index.html
 * 
 */


import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

import processing.video.Capture;

import processing.pdf.*;


/*******
 OPTIONS
 This section contains most of the
 variables you may want to change.
 *******/
public boolean isFullScreen = true;
private float hmargin = 100.0;
public color fluidColor = BLACK; // BLACK (ON) WHITE, NAVY (ON) LAVENDER, TEAL (ON) LIGHTBLUE
public boolean isUsingCam = true;
public boolean isShowingCam = false;
public float camAlpha = 0.1;
public float maskThresh = 0.6;
public float framerate = 60.0;
/*******/


// layout
private int screen_canvasWidth = 744;
private int screen_canvasHeight = 1052;
private int print_canvasWidth = 2480;
private int print_canvasHeight = 3508;
public int canvasWidth;
public int canvasHeight;
public int canvasX;
public int canvasY;
private float aspectRatio = 0.707;

// fluid
public Fluid fluid_data;
public PGraphics2D pg_fluid;

// camera
public Capture cam;
public int cam_w = 640;
public int cam_h = 480;
public PGraphics2D pg_cam_a;
public PGraphics2D pg_cam_b;

// shapes
public PShape sansShape;
public PShape serifShape;
public PGraphics pg_sans;
public PGraphics pg_serif;
public float vmargin;

// color
public color bgColor;
public color fillColor;

// shader
public PShader shader;

// export
private PGraphics canvas_print;
private int fileNum = 1;
private int fileDP = 4;

// static constants
static final int INK = 0;
static final int BLOB = 1;
static final color BLACK     = (255 << 24) | (0   << 16) | (0   << 8) | 0  ; // 0   0   0
static final color WHITE     = (255 << 24) | (255 << 16) | (255 << 8) | 255; // 255 255 255
static final color NAVY      = (255 << 24) | (0   << 16) | (35  << 8) | 98 ; // 0   35  98
static final color LAVENDER  = (255 << 24) | (198 << 16) | (198 << 8) | 235; // 198 198 235
static final color TEAL      = (255 << 24) | (0   << 16) | (153 << 8) | 117; // 0   153 117
static final color LIGHTBLUE = (255 << 24) | (177 << 16) | (213 << 8) | 213; // 177 213 213


public void settings() {
  if (isFullScreen) {
    fullScreen(P2D);
  } else {
    size(screen_canvasWidth, screen_canvasHeight, P2D);
  }
}

public void setup() {
  
  // frame rate
  frameRate(framerate);
  
  // set up shader
  if (isShowingCam) {
    shader = loadShader("blendCam.frag", "blend.vert");
  } else {
    shader = loadShader("blend.frag", "blend.vert");
  }
  
  // transformations
  setOrientation(0);

  // type
  pg_sans = createGraphics(canvasWidth, canvasHeight);
  pg_serif = createGraphics(canvasWidth, canvasHeight);
  sansShape = loadShape("logo_sans.svg");
  serifShape = loadShape("logo_serif.svg");
  float shapeScale = (canvasWidth - hmargin*2) / serifShape.width;
  sansShape.scale(shapeScale);
  serifShape.scale(shapeScale);
  vmargin = (canvasHeight - sansShape.height*shapeScale) * 0.5;
  
  // colors
  fillColor = fluidColor;
  if      (fluidColor == BLACK) { bgColor = WHITE; }
  else if (fluidColor == WHITE) { bgColor = BLACK; }
  else if (fluidColor == NAVY) { bgColor = LAVENDER; }
  else if (fluidColor == LAVENDER) { bgColor = NAVY; }
  else if (fluidColor == TEAL) { bgColor = LIGHTBLUE; }
  else if (fluidColor == LIGHTBLUE) { bgColor = TEAL; }
  
  // sans
  pg_sans.beginDraw();
  pg_sans.clear();
  pg_sans.noStroke();
  pg_sans.translate(hmargin, vmargin);
  sansShape.setFill(fillColor);
  sansShape.draw(pg_sans);
  pg_sans.endDraw();
  
  // serif
  pg_serif.beginDraw();
  pg_serif.clear();
  pg_serif.noStroke();
  pg_serif.translate(hmargin, vmargin);
  serifShape.setFill(bgColor);
  serifShape.draw(pg_serif);
  pg_serif.endDraw();
    
  // fluid
  fluid_data = new Fluid(this);
  pg_fluid = (PGraphics2D) createGraphics(canvasWidth, canvasHeight, P2D);
  
  // camera
  if (isUsingCam) {
    cam = new Capture(this, cam_w, cam_h, 30);
    cam.start();
    // render buffers
    pg_cam_a = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
    pg_cam_a.noSmooth();
    pg_cam_a.beginDraw();
    pg_cam_a.clear();
    pg_cam_a.endDraw();
    pg_cam_b = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
    pg_cam_b.noSmooth();
  }
  
  // shader
  if (isShowingCam) {
    shader.set("tex_cam", pg_cam_a);
    shader.set("camAlpha", camAlpha);
  }
  shader.set("tex_fluid", pg_fluid);
  shader.set("tex_sans", pg_sans);
  shader.set("tex_serif", pg_serif);
  shader.set("fluidColor", new float[] {
      ((fluidColor >> 16) & 0xFF) / 255.0,
      ((fluidColor >> 8) & 0xFF) / 255.0,
      ((fluidColor) & 0xFF) / 255.0,
      ((fluidColor >> 24) & 0xFF) / 255.0
    }, 4);
  shader.set("maskThresh", maskThresh);
    
}

public void draw() {

  // update cam
  if (isUsingCam) {
    if ( cam.available() ) {
      cam.read();
      fluid_data.updateCam();
    }
  }
  
  // update fluid
  fluid_data.display();
  
  // draw visuals
  background(bgColor);
  shader(shader);
  noStroke();
  rect(0, 0, width, height);

  // show title bar info
  if (!isFullScreen) {
    info();
  }
    
}

public void keyPressed() {
  if (keyCode == 'p' || keyCode == 'P') {
    // switch to print mode
    setOrientation(1);
    canvas_print = createGraphics(print_canvasWidth, print_canvasHeight, P2D);
    beginRecord(canvas_print);
    background(bgColor);
    shader(shader);
    noStroke();
    rect(0, 0, print_canvasWidth, print_canvasHeight);
    canvas_print.save("tif/" + nf(fileNum, fileDP) + ".tif");
    endRecord();
    fileNum++;
    // reset to screen mode
    setOrientation(0);
  }
}

// 0 = horizontal
// 1 = vertical
public void setOrientation(int orientation) {
  if (orientation == 0) {
    if (isFullScreen) {
      if (width > height) {
        canvasHeight = height;
        canvasWidth = int(canvasHeight * aspectRatio);
      } else {
        canvasWidth = width;
        canvasHeight = int(canvasWidth / aspectRatio);
      }
    } else {
      canvasWidth = width;
      canvasHeight = height;
    }
    canvasX = int((width - canvasWidth) * 0.5);
    canvasY = int((height - canvasHeight) * 0.5);
    shader.set("canvasTranslate", new float[] {
        canvasX / (float(canvasWidth) / width),
        canvasY / (float(canvasHeight) / height),
        0.0f, 0.0f
      }, 4);
    shader.set("canvasScale", new PMatrix3D(
        float(canvasWidth) / width, 0.0f, 0.0f, 0.0f,
        0.0f, float(canvasHeight) / height, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
      ));
  } else if (orientation == 1) {
    canvasX = 0;
    canvasY = 0;
    canvasWidth = print_canvasWidth;
    canvasWidth = print_canvasHeight;
    shader.set("canvasTranslate", new float[] {
        0.0f, 0.0f,
        0.0f, 0.0f
      }, 4);
    shader.set("canvasScale", new PMatrix3D(
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
      ));
  }
}

public void mousePressed() {
  fluid_data.reset();
}

private void info() {
  String s = String.format(getClass().getName() + " [fps %6.2f]", frameRate);
  surface.setTitle(s);
}
