class Fluid implements DwFluid2D.FluidData {
  
  // fluid simulation setup
  private DwPixelFlow context; // library context
  private DwFilter filter; // image processing filters
  private DwFluid2D fluid; // fluid solver
  private DwOpticalFlow opticalflow; // optical flow

  // fluid parameters
  private float px, py;
  private float vx, vy;
  private float dissipVel = 0.95f;
  private float dissipDens = 1.0f;
  private float vorticity = 0.0f;
  private float fluidVel;
  private float fluidRad;
  
  public Fluid(PApplet papp) {

    context = new DwPixelFlow(papp);
    filter = new DwFilter(context);
    newFluid();
  
    // set fluid parameters
    fluidRad = canvasWidth * 0.35;
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
  }

  @Override
  public void update(DwFluid2D fluid) {
    
    px = canvasWidth * 0.5;
    py = canvasHeight * 0.5;
    
    vx = (round(random(1))*2-1) * random(50.0, 100.0);
    vy = (round(random(1))*2-1) * random(50.0, 100.0);

    fluidVel = constrain(60.0/(round(frameCount*0.01)), 10.0f, 30.0f);
    
    // velocity
    addVelocityBlob(fluid, px, py, fluidVel, vx, vy);
    if (isUsingCam) {
      addVelocityTexture(fluid, opticalflow);
    }
    
    // density
    addDensityBlob(fluid, px, py, fluidRad,
      (fluidColor >> 16) & 0xFF,
      (fluidColor >> 8) & 0xFF,
      (fluidColor) & 0xFF,
      0.01f);
    
    //addDensityBlob(fluid, px, py, fluidRad, 0.0f, 1.0f, 1.0f, 0.01f);
  }
  
  public void display() {
    // render everything
    pg_fluid.beginDraw();
    pg_fluid.clear();
    pg_fluid.endDraw();
    fluid.update();
    // add fluid to rendering
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
    shader.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);       
    shader.uniform2f("data_pos", px, py);
    shader.uniform1f("data_rad", fluidVel);
    shader.uniform2f("data_velocity", vx, vy);
    shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
    shader.uniform1i("blend_mode", 2);
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
