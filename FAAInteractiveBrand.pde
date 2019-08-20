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


/*******
 OPTIONS
 This section contains most of the
 variables you may want to change.
 *******/
public boolean isFullScreen = true;
public int canvasWidth = 840;
public int canvasHeight = 1188;
public color fluidColor = BLACK; // BLACK (ON) WHITE, NAVY (ON) LAVENDER, TEAL (ON) LIGHTBLUE
public boolean isUsingCam = true;
public boolean isShowingCam = false;
public float camAlpha = 0.1;
public float maskThresh = 0.6;
/*******/


// layout
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
private float hmargin = 75.0;
private float vmargin;

// color
public color bgColor;
public color fillColor;

// shader
PShader shader;

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
    size(canvasWidth, canvasHeight, P2D);
  }
}

public void setup() {

  frameRate(60);
  
  if (isFullScreen) {
    if (width > height) {
      canvasHeight = height;
      canvasWidth = int(canvasHeight * aspectRatio);
    } else {
      canvasWidth = width;
      canvasHeight = int(canvasWidth / aspectRatio);
    }
  }
  
  canvasX = int((width - canvasWidth) * 0.5);
  canvasY = int((height - canvasHeight) * 0.5);

  // shapes
  pg_sans = createGraphics(canvasWidth, canvasHeight);
  pg_serif = createGraphics(canvasWidth, canvasHeight);
  pg_sans.noSmooth();
  pg_serif.noSmooth();
  sansShape = loadShape("logo_sans.svg");
  serifShape = loadShape("logo_serif.svg");
  float scaleFac = (canvasWidth - hmargin*2) / serifShape.width;
  sansShape.scale(scaleFac);
  serifShape.scale(scaleFac);
  vmargin = (canvasHeight - sansShape.height*scaleFac) * 0.5;
  
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
    shader = loadShader("blendCam.frag", "blend.vert");
  } else {
    shader = loadShader("blend.frag", "blend.vert");
  }
  shader.set( "canvasTranslate", new float[] {
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
  if (isShowingCam) {
    shader.set("tex_cam", pg_cam_a);
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
  if (isShowingCam) {
    shader.set("camAlpha", camAlpha);
  }
  shader.set("maskThresh", maskThresh);
  
}

public void draw() {

  background(bgColor);
  
  // update cam
  if (isUsingCam) {
    if ( cam.available() ) {
      cam.read();
      fluid_data.updateCam();
    }
  }
  
  // update visuals
  fluid_data.display();
  shader(shader);
  noStroke();
  rect(0, 0, width, height);

  // show title bar info
  if (!isFullScreen) {
    info();
  }
    
}

public void mousePressed() {
  fluid_data.reset();
}

private void info() {
  String s = String.format(getClass().getName() + " [fps %6.2f]", frameRate);
  surface.setTitle(s);
}
