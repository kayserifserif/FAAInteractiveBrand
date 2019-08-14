import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

import controlP5.*;

import processing.video.Capture;

// layout
public boolean isFullScreen = true;
public int canvasWidth = 840;
public int canvasHeight = 1188;
public int canvasX;
public int canvasY;

// fluid
public Fluid fluid_data;
public PGraphics2D pg_fluid;
public int fluidMode = Fluid.BW; // BW, COLOR
public color fluidColor = Fluid.NAVY; // NAVY, TEAL

// blob
public Blob blob;
public PGraphics2D pg_blob_mask;

// graphic
static final int INK = 0;
static final int BLOB = 1;
public int graphic = INK;
public PGraphics2D pg_graphic;

// camera
public boolean isUsingCam = true;
public boolean isShowingCam = false;
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
private float scaleFac;
private float hmargin = 75.0;
private float vmargin;

// color
public color bgColor;
public color fillColor;

// controls
public ControlP5 cp5;
public ButtonBar bb;
public int bbHeight;

public void settings() {
  if (isFullScreen) {
    fullScreen(P2D);
  } else {
    size(canvasWidth, canvasHeight, P2D);
  }
}

public void setup() {
  
  if (isFullScreen) {
    orientation(PORTRAIT);
    canvasHeight = height;
    canvasWidth = int(canvasHeight * 0.707);
  }
  
  canvasX = int((width - canvasWidth) * 0.5);
  canvasY = int((height - canvasHeight) * 0.5);

  // shapes
  pg_sans = createGraphics(canvasWidth, canvasHeight);
  pg_serif = createGraphics(canvasWidth, canvasHeight);
  sansShape = loadShape("logo_sans.svg");
  serifShape = loadShape("logo_serif.svg");
  scaleFac = (canvasWidth - hmargin*2) / serifShape.width;
  sansShape.scale(scaleFac);
  serifShape.scale(scaleFac);
  vmargin = (canvasHeight - sansShape.height*scaleFac) * 0.5;
    
  // FLUID
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
    pg_cam_a.background(0);
    pg_cam_a.endDraw();
    pg_cam_b = (PGraphics2D) createGraphics(cam_w, cam_h, P2D);
    pg_cam_b.noSmooth();
  }

  // BLOB
  blob = new Blob();
  pg_blob_mask = (PGraphics2D) createGraphics(canvasWidth, canvasHeight, P2D);
  
  // graphic
  pg_graphic = (PGraphics2D) createGraphics(canvasWidth, canvasHeight, P2D);
  
  // controls
  cp5 = new ControlP5(this);
  bbHeight = int(canvasHeight * 0.02);
  bb = cp5.addButtonBar("selectGraphic")
          .setPosition(canvasX, canvasY)
          .setSize(canvasWidth, bbHeight)
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

public void draw() {

  background(bgColor);
  
  // display cam
  if (isUsingCam) {
    if ( cam.available() ) {
      cam.read();
      fluid_data.updateCam();
    }
    if (isShowingCam) {
      pushStyle();
      tint(255, 50);
      image(pg_cam_a, canvasX, canvasY, canvasWidth, canvasHeight);
      popStyle();
    }
  }
  
  // prepare graphic
  if (graphic == INK) {
    fluid_data.display();
    pg_graphic = pg_fluid;
  } else if (graphic == BLOB) {
    blob.display();
    pg_graphic = pg_blob_mask;
  }

  // sans
  if (graphic == INK) {
    pg_sans.loadPixels();
    pg_graphic.loadPixels();
    for (int i = 0; i < pg_sans.pixels.length; i++) {
      if ((pg_sans.pixels[i] >> 24 & 0xFF) != 0) {
        // bit masking formula from oshoham
        // https://github.com/processing/processing/issues/1738
        int min = (255 << 24) | (0 << 16) | (0 << 8) | 0;
        int max = (255 << 24) | (255 << 16) | (255 << 8) | 255;
        int alpha = int(constrain(-(pg_graphic.pixels[i] >> 24 & 0xFF), min, max));
        pg_sans.pixels[i] = (alpha << 24) | (pg_sans.pixels[i] & 0xFFFFFF);
      }
    }
    pg_sans.updatePixels();
  }
  image(pg_sans, canvasX, canvasY);
  
  // serif
  pg_serif.mask(pg_graphic);
  image(pg_serif, canvasX, canvasY);

  // show title bar info
  if (!isFullScreen) {
    info();
  }
  
}

public void selectGraphic(int n) {
  graphic = n;
  updateGraphic();
}

public void updateGraphic() {
  
  if (graphic == INK) {
    if (fluidMode == Fluid.BW) {
      bgColor = (255 << 24) | (255 << 16) | (255 << 8) | 255;
      fillColor = (255 << 24) | (0 << 16) | (0 << 8) | 0;
    } else if (fluidMode == Fluid.COLOR) {
      if (fluidColor == Fluid.NAVY) {
        bgColor = (255 << 24) | (198 << 16) | (198 << 8) | 235;
        fillColor = (255 << 24) | (28 << 16) | (28 << 8) | 70;
      } else if (fluidColor == Fluid.TEAL) {
        bgColor = (255 << 24) | (177 << 16) | (213 << 8) | 213;
        fillColor = (255 << 24) | (15 << 16) | (77 << 8) | 77;
      }
    }
  } else if (graphic == BLOB) {
    bgColor = (255 << 24) | (199 << 16) | (209 << 8) | 181;
    fillColor = (255 << 24) | (35 << 16) | (62 << 8) | 33;
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

public void mousePressed() {
  if (mouseY > canvasY + bbHeight && mouseY < canvasY + canvasHeight) {
    if (graphic == 0) {
      fluid_data.reset();
    } else if (graphic == 1) {
      blob.reset();
    }
  }
}

private void info() {
  String s = String.format(getClass().getName() + " [fps %6.2f]", frameRate);
  surface.setTitle(s);
}
