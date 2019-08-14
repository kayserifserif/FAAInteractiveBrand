class Fluid implements DwFluid2D.FluidData {
  
  // library context
  private DwPixelFlow context;
  
  // collection of imageprocessing filters
  private DwFilter filter;
  
  // fluid solver
  private DwFluid2D fluid;

  // optical flow
  private DwOpticalFlow opticalflow;

  // fluid parameters
  private float px, py;
  private float vx, vy;
  private float dissipVel = 0.99f;
  private float dissipDens = 0.99f;
  private float fluidVel;
  private float fluidRad;
  
  static final int BW = 0;
  static final int COLOR = 1;
  //static final color NAVY = color(0, 0, 255);
  static final color NAVY = -16776961;
  //static final color TEAL = color(0, 255, 255);
  static final color TEAL = -16711681;
  
  public Fluid(PApplet papp) {

    context = new DwPixelFlow(papp);
    filter = new DwFilter(context);
    newFluid();
  
    // fluid parameters
    fluidRad = canvasWidth * 0.35;
    fluid.param.dissipation_velocity = dissipVel;
    fluid.param.dissipation_density  = dissipDens;
    //fluid.param.dissipation_density     = 0.90f;
    //fluid.param.dissipation_velocity    = 0.80f;
    //fluid.param.dissipation_temperature = 0.70f;
    //fluid.param.vorticity               = 0.30f;

    if (isUsingCam) {
      opticalflow = new DwOpticalFlow(context, cam_w, cam_h);
      opticalflow.param.display_mode = 1;
    }
  
  }
  
  public void updateCam() {
    // render to offscreenbuffer
    pg_cam_b.beginDraw();
    pg_cam_b.background(0);
    pg_cam_b.scale(-1, 1);
    pg_cam_b.image(cam, -cam_w, 0);
    pg_cam_b.endDraw();
    swapCamBuffer(); // "pg_cam_a" has the image now

    // update Optical Flow
    opticalflow.update(pg_cam_a);

    // apply grayscale for better contrast
    filter.luminance.apply(pg_cam_a, pg_cam_b); 
    swapCamBuffer();
  }
  
  public void reset() { 
    newFluid();
  }
  
  private void newFluid() {
    fluid = new DwFluid2D(context, canvasWidth, canvasHeight, 1);
    fluid.addCallback_FluiData(this);
  }

  @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {
    
    px = canvasWidth * 0.5;
    py = canvasHeight * 0.5;
    
    vx = (round(random(1))*2-1) * random(50.0, 100.0);
    vy = (round(random(1))*2-1) * random(50.0, 100.0);

    fluidVel = constrain(60.0/(round(frameCount*0.01)), 10.0f, 30.0f);
    
    addVelocityBlob(fluid, px, py, fluidVel, vx, vy);
    if (isUsingCam) {
      addVelocityTexture(fluid, opticalflow);
    }
    
    if (fluidMode == BW) {
      addDensityBlob(fluid, px, py, fluidRad, 0.0f, 0.0f, 0.0f, 0.01f);
      addDensityBlob(fluid, px, py, fluidRad, 1.0f, 1.0f, 1.0f, 0.01f);
    } else if (fluidMode == COLOR) {
      addDensityBlob(fluid, px, py, fluidRad, 
        (fluidColor >> 16) & 0xFF,
        (fluidColor >> 8) & 0xFF,
        (fluidColor) & 0xFF,
        0.01f);
    }
  }
  
  public void display() {
    // render everything
    pg_fluid.beginDraw();
    pg_fluid.clear();
    pg_fluid.endDraw();
    fluid.update();
    // add fluid stuff to rendering
    fluid.renderFluidTextures(pg_fluid, 0);
  }
  
  private void addDensityBlob(DwFluid2D fluid,
      float px, float py, float fluidRad,
      float r, float g, float b, float intensity) {
    context.begin();
    context.beginDraw(fluid.tex_density.dst);
    DwGLSLProgram shader = context.createShader("data/addDensityBlob.frag");
    shader.begin();
    shader.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);
    shader.uniform2f("data_pos", px, py);
    shader.uniform1f("data_rad", fluidRad);
    shader.uniform4f("data_density", r, g, b, intensity);
    shader.uniformTexture("tex_density_old", fluid.tex_density.src);
    shader.uniform1i("blend_mode", 6);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addDensityBlob");
    fluid.tex_density.swap();
  }
  
  private void addVelocityBlob(DwFluid2D fluid,
      float px, float py, float fluidVel,
      float vx, float vy) {
    context.begin();
    context.beginDraw(fluid.tex_velocity.dst);
    DwGLSLProgram shader = context.createShader("data/addVelocityBlob.frag");
    shader.begin();
    shader.uniform2f     ("wh", fluid.fluid_w, fluid.fluid_h);       
    shader.uniform2f("data_pos", px, py);
    shader.uniform1f("data_rad", fluidVel);
    shader.uniform2f("data_velocity", vx, vy);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.uniform1i     ("blend_mode", 2);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addVelocityBlob");
    fluid.tex_velocity.swap();
  }

  // custom shader, to add density from a texture (PGraphics2D) to the fluid.
  private void addVelocityTexture(DwFluid2D fluid, DwOpticalFlow opticalflow) {
    context.begin();
    context.beginDraw(fluid.tex_velocity.dst);
    DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
    shader.begin();
    shader.uniform2f     ("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 2);    
    shader.uniform1f     ("multiplier", 1.0f);   
    shader.uniform1f     ("mix_value", 0.1f);
    shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addVelocity");
    fluid.tex_velocity.swap();
  }

  private void swapCamBuffer() {
    PGraphics2D tmp = pg_cam_a;
    pg_cam_a = pg_cam_b;
    pg_cam_b = tmp;
  }
  
}
