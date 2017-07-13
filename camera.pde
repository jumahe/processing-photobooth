import com.dhchoi.*;
import gifAnimation.*;
import controlP5.*;
import gohai.glvideo.*;

// -- accessing camera
GLCapture cam;
String[] configs;
int px,py;

// -- creating a gif
GifMaker gifExport;
PImage img1,img2,img3;
boolean req1,req2,req3 = false;

// -- playing GIF
boolean playing_gif = false;
String last_filename = "";
String last_path = "";
Gif lastGif;
CountdownTimer gif_timer;

// -- UI & steps
PImage title,overlay,warning,traitement,cd04,cd03,cd02,cd01,cd00;
String step = "stand"; // "stand","warn","4","3","2","1","click","process"

// -- timers for sequencing
CountdownTimer warn_t,t1,t2,t3,t4;
boolean ongoing = false;
int cpt = 0;

// -- control UI
ControlP5 cp5;
Textlabel debug,counter,info;
ControlFont font;
PFont font1,font2;
Button shoot;

// -- SETUP
// -------------------------------------------------------------------
void setup()
{
  fullScreen(P2D);
  
  // -- init UI
  cp5 = new ControlP5(this);
  font1 = createFont("arial",20);
  font2 = createFont("arial",100);
  
  info = cp5.addTextlabel("info")
    .setText("information : les images seront disponibles apres la soiree.")
    .setPosition(0,-10)
    .setColor( color(255,255,255) );
  
  debug = cp5.addTextlabel("debug")
    .setText("debug")
    .setPosition(10,height - 20)
    .setSize(400,100)
    .setColor( color(255,255,255) );
  
  shoot = cp5.addButton("shoot")
    .setLabel("COMMENCER")
    .setSize(400,50)
    .setPosition( (width - 400) / 2, height - 50 - 50);

  String[] devices = GLCapture.list();
  println("--> Devices:");
  printArray(devices);
  
  if (0 < devices.length)
  {
    configs = GLCapture.configs(devices[0]);
    println("--> Configs:");
    printArray(configs);
  }

  //cam = new GLCapture(this);
  //cam = new GLCapture(this, devices[5]);
  //cam = new GLCapture(this, devices[0], 640, 480, 25);
  cam = new GLCapture(this, devices[0], configs[3]); // LOGITECH
  //cam = new GLCapture(this, devices[0], configs[0]); // PS-EYE
  cam.start();
  
  // -- init the UI images
  title = loadImage("assets/title.png");
  overlay = loadImage("assets/overlay.png");
  warning = loadImage("assets/warning.png");
  traitement = loadImage("assets/traitement.png");
  cd04 = loadImage("assets/cd04.png");
  cd03 = loadImage("assets/cd03.png");
  cd02 = loadImage("assets/cd02.png");
  cd01 = loadImage("assets/cd01.png");
  cd00 = loadImage("assets/cd00.png");
  
  // -- init the storage images
  img1 = new PImage(cam.width, cam.height);
  img2 = new PImage(cam.width, cam.height);
  img3 = new PImage(cam.width, cam.height);
  
  // -- position of the central area
  px = int((width - cam.width) / 2);
  py = int((height - cam.height) / 2);
  
  // -- init the gif player timer
  gif_timer = CountdownTimerService.getNewCountdownTimer(this).configure(5000, 10000);
}

// -- DRAW (LOOP)
// -------------------------------------------------------------------
void draw()
{
  background(0);
  
  // -- the top left title
  image(title,0,0);
  
  // -- check if GIF is playing
  if(playing_gif == true && lastGif != null)
  {
    image(lastGif,px,py); // only display the animated GIF
  }
  else
  {
    // -- get the cam view
    if(cam.available() == true)
    {
      cam.read();
    }
    
    // -- flip and display the cam monitor
    pushMatrix();
    scale(-1,1);
    image(cam, 0 - cam.width - px, py); // flip for mirror effect
    popMatrix();
    
    //image(overlay, px, py);
    
    // -- display overlay 
    switch(step)
    {
      case "stand":
        // -- nothing
        break;
      case "warn":
        image(warning,px,py);
        break;
      case "4":
        image(cd04,px,py);
        break;
      case "3":
        image(cd03,px,py);
        break;
      case "2":
        image(cd02,px,py);
        break;
      case "1":
        image(cd01,px,py);
        break;
      case "click":
        image(cd00,px,py);
        break;
      case "process":
        image(traitement,px,py);
        break;
    }
    
    // -- request the 1st caption
    if(req1 == true)
    {
      cam.loadPixels();
      arrayCopy(cam.pixels, img1.pixels);
      req1 = false;
      donePic1();
    }
    
    // -- request the second one
    if(req2 == true)
    {
      cam.loadPixels();
      arrayCopy(cam.pixels, img2.pixels);
      req2 = false;
      donePic2();
    }
    
    // -- request the third one
    if(req3 == true)
    {
      cam.loadPixels();
      arrayCopy(cam.pixels, img3.pixels);
      req3 = false;
      donePic3();
    }
  }
  
  // -- update the center area position
  px = int((width - cam.width) / 2);
  py = int((height - cam.height) / 2);
  
  // -- set the info label position
  info.setPosition(px,py + cam.height + 10);
}

// -- SHOOT: launch the shooting sequence
// -------------------------------------------------------------------
public void shoot(int val)
{
  if(ongoing == true || playing_gif == true)
  {
    println("process déjà en cours");
  }
  else
  {
    ongoing = true;
    
    shoot.setVisible(false);
    
    int y = year();
    int m = month();
    int d = day();
    int h = hour();
    int mn = minute();
    int s = second();
    
    img1 = new PImage(cam.width, cam.height);
    img2 = new PImage(cam.width, cam.height);
    img3 = new PImage(cam.width, cam.height);
    
    //String filename = y + "0" + m + "" + d + "-" + h + mn + s + ".jpg";
    String filename = y + "0" + m + "" + d + "-" + h + mn + s + ".gif";
    last_filename = filename;
    filename = "/home/pi/processing/camera/exports/" + filename;
    last_path = filename;
    
    //cam.save("/home/pi/processing/camera/exports/" + filename);
    
    gifExport = new GifMaker(this, filename);
    gifExport.setRepeat(0);
    gifExport.setSize(cam.width, cam.height);
    gifExport.setDelay(500);
    
    req1 = false;
    req2 = false;
    req3 = false;
    
    warn_t = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t1 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t2 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t3 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t4 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 2000);
    
    debug.setText("get ready...");
    
    step = "warn";
    warn_t.start();
  }
}

// -- GLOBAL TICK EVENT
// -------------------------------------------------------------------
public void onTickEvent(CountdownTimer t, long timeLeftUntilFinish)
{
  println("tick " + t.getId() + " : " + timeLeftUntilFinish);
  
  if(step != "stand" && step != "warn" && step != "process" && t.getId() != t4.getId() && t.getId() != gif_timer.getId())
  {
    println("cpt: " + cpt);
    
    switch(cpt)
    {
      case 4:
        step = "4";
        break;
      case 3:
        step = "3";
        break;
      case 2:
        step = "2";
        break;
      case 1:
        step = "1";
        break;
    }
    
    cpt--;
  }
}

// -- GLOBAL FINISH EVENT
// -------------------------------------------------------------------
public void onFinishEvent(CountdownTimer t)
{
  // -- reinit the cpt var
  cpt = 4;
  
  // -- end of the warn message
  if(t.getId() == warn_t.getId())
  {
    step = "4";
    debug.setText("picture 1");
    t1.start();
  }
  
  // -- end of the first countdown: take the first picture
  if(t.getId() == t1.getId())
  {
    takePic1();
  }
  
  // -- end of the second countdown: take the second picture
  if(t.getId() == t2.getId())
  {
    takePic2();
  }
  
  // -- end of the third countdown: take the third picture
  if(t.getId() == t3.getId())
  {
    takePic3();
  }
  
  // -- end of the pre-processing pause: finalize the GIF
  if(t.getId() == t4.getId())
  {
    debug.setText("creating GIF file");
    step = "process";
    finalizeGif();
  }
  
  // -- end of the GIF preview
  if(t.getId() == gif_timer.getId())
  {
    playing_gif = false;
    lastGif.stop();
    debug.setText("ready");
    shoot.setVisible(true);
  }
}

public void takePic1()
{
  step = "click";
  req1 = true;
}

public void donePic1()
{
  delay(1000);
  debug.setText("picture 2");
  t2.start();
}

public void takePic2()
{
  step = "click";
  req2 = true;
}

public void donePic2()
{
  delay(1000);
  debug.setText("picture 3");
  t3.start();
}

public void takePic3()
{
  step = "click";
  req3 = true;
}

public void donePic3()
{
  t4.start();
}

// -- FINALIZING GIF
// -------------------------------------------------------------------
public void finalizeGif()
{
  println("finalize GIF...");
  println("+pic 1");
  img1.blend(overlay,0,0,overlay.width,overlay.height,0,0,img1.width,img1.height,BLEND);
  gifExport.addFrame(img1.pixels, cam.width, cam.height);
  println("+pic 2");
  img2.blend(overlay,0,0,overlay.width,overlay.height,0,0,img2.width,img2.height,BLEND);
  gifExport.addFrame(img2.pixels, cam.width, cam.height);
  println("+pic 3");
  img3.blend(overlay,0,0,overlay.width,overlay.height,0,0,img3.width,img3.height,BLEND);
  gifExport.addFrame(img3.pixels, cam.width, cam.height);
  println("saving...");
  gifExport.finish();
  println("done");
  
  step = "stand";
  ongoing = false;
  debug.setText("completed");
  
  delay(1000);
  debug.setText("now playing GIF preview");
  launchLastGif();
}

// -- PLAYING THE LAST GIF
// -------------------------------------------------------------------
public void launchLastGif()
{
  shoot.setVisible(false);
  
  lastGif = new Gif(this, last_path);
  lastGif.play();
  
  playing_gif = true;
  
  gif_timer.start();
}