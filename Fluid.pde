class Fluid implements DwFluid2D.FluidData {
  
  // fluid simulation setup
  private DwPixelFlow context; // library context
  private DwFilter filter; // image processing filters
  private DwFluid2D fluid; // fluid solver
  private DwOpticalFlow opticalflow; // optical flow

  // fluid parameters
  private float posX, posY;
  private float densRad;
  private float widthPct = 0.35;
  private float velX, velY;
  private float velRad;
  private float dissipVel = 0.95f;
  private float dissipDens = 1.0f;
  private float vorticity = 0.0f;
  
  // animation
  private int frameStart;
  private float initBurst = 120.0f;
  private float velFade = 0.01;
  private float velMin = 50.0f;
  private float velMax = 120.0f;
  private float velRadFade = 0.05;
  private float velRadMin = 10.0f;
  private float velRadMax = 100.0f;
  
  public Fluid(PApplet papp) {

    context = new DwPixelFlow(papp);
    filter = new DwFilter(context);
    newFluid();
  
    // set fluid parameters
    posX = canvasWidth * 0.5;
    posY = canvasHeight * 0.5;
    densRad = canvasWidth * widthPct;
    fluid.param.dissipation_velocity = dissipVel;
    fluid.param.dissipation_density = dissipDens;
    fluid.param.vorticity = vorticity;

    if (isUsingCam) {
      opticalflow = new DwOpticalFlow(context, cam_w, cam_h);
      opticalflow.param.display_mode = 1;
    }
  
  }
  
  private void newFluid() {
    fluid = new DwFluid2D(context, canvasWidth, canvasHeight, 1);
    fluid.addCallback_FluiData(this);
    frameStart = frameCount;
  }

  @Override
  public void update(DwFluid2D fluid) {
    
    // update velocity according to frames
    float vel = constrain(initBurst / ((frameCount - frameStart) * velFade), velMin, velMax);
    velX = (round(random(1)) * 2 - 1) * vel; // random pos/neg x
    velY = (round(random(1)) * 2 - 1) * vel; // random pos/neg y
    velRad = constrain(initBurst / ((frameCount - frameStart) * velRadFade), velRadMin, velRadMax);
    
    // add velocity
    addVelocityBlob(fluid, posX, posY, velRad, velX, velY);
    if (isUsingCam) {
      addVelocityTexture(fluid, opticalflow);
    }
    
    // density
    addDensityBlob(fluid, posX, posY, densRad,
      (fluidColor >> 16) & 0xFF,
      (fluidColor >> 8) & 0xFF,
      (fluidColor) & 0xFF,
      0.01f);
    
  }
  
  public void display() {
    pg_fluid.beginDraw();
    pg_fluid.clear();
    pg_fluid.endDraw();
    fluid.update();
    fluid.renderFluidTextures(pg_fluid, 0);
  }
  
  private void addDensityBlob(DwFluid2D fluid,
      float posX, float posY, float fluidRad,
      float r, float g, float b, float intensity) {
    context.begin();
    context.beginDraw(fluid.tex_density.dst);
    DwGLSLProgram shader = context.createShader("data/addDensityBlob.frag");
    shader.begin();
    shader.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);
    shader.uniform2f("data_pos", posX, posY);
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
      float posX, float posY, float fluidVel,
      float velX, float velY) {
    context.begin();
    context.beginDraw(fluid.tex_velocity.dst);
    DwGLSLProgram shader = context.createShader("data/addVelocityBlob.frag");
    shader.begin();
    shader.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);       
    shader.uniform2f("data_pos", posX, posY);
    shader.uniform1f("data_rad", fluidVel);
    shader.uniform2f("data_velocity", velX, velY);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.uniform1i("blend_mode", 2);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addVelocityBlob");
    fluid.tex_velocity.swap();
  }

  // add velocity from texture (PGraphics2D) to fluid
  private void addVelocityTexture(DwFluid2D fluid, DwOpticalFlow opticalflow) {
    context.begin();
    context.beginDraw(fluid.tex_velocity.dst);
    DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
    shader.begin();
    shader.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i("blend_mode", 2);    
    shader.uniform1f("multiplier", 1.0f);   
    shader.uniform1f("mix_value", 0.1f);
    shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addVelocity");
    fluid.tex_velocity.swap();
  }
  
  public void updateCam() {
    // render to offscreenbuffer
    pg_cam_b.beginDraw();
    pg_cam_b.clear();
    pg_cam_b.scale(-1, 1);
    pg_cam_b.image(cam, -cam_w, 0);
    pg_cam_b.endDraw();
    swapCamBuffer(); // pg_cam_a has the image now

    // update optical flow
    opticalflow.update(pg_cam_a);

    // apply grayscale for better contrast
    filter.luminance.apply(pg_cam_a, pg_cam_b); 
    swapCamBuffer();
  }

  private void swapCamBuffer() {
    PGraphics2D tmp = pg_cam_a;
    pg_cam_a = pg_cam_b;
    pg_cam_b = tmp;
  }
  
  public void reset() { 
    newFluid();
  }
  
}
