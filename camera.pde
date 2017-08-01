import processing.io.*;
import com.dhchoi.*;
import gifAnimation.*;
import controlP5.*;
import gohai.glvideo.*;
import http.requests.*;

// -- config
// --> ALL THE MAIN CONFIGS ARE STORED IN data/config.json
boolean btn_mode = true; // true = using a physical button
boolean debug_mode = false;

// -- accessing camera
GLCapture cam;
String[] configs;
int px,py;

// -- export
String EXPORT_PATH = "";
String base_filename = "";

// -- upload to server
boolean upload_to_server = true;
String UPLOAD_URL = "";
String upload_tokken = "";

// -- create a collage
boolean create_a_collage = true;
boolean do_collage = false;
PImage col1,col2,col3,col4;

// -- saving individual images
boolean save_pictures = true;

// -- creating a gif
GifMaker gifExport;
int gif_width = 400;
int gif_height = 0; // to be calculated from the cam ratio
PImage img1,img2,img3,img4;
boolean req1,req2,req3,req4 = false;

// -- playing GIF
boolean playing_gif = false;
String last_filename = "";
String last_path = "";
Gif lastGif;
CountdownTimer gif_timer;

// -- UI & steps
PImage title,overlay,warning,traitement,cd04,cd03,cd02,cd01,cd00,base_collage;
String step = "stand"; // "stand","warn","4","3","2","1","click","process"

// -- timers for sequencing
CountdownTimer warn_t,t1,t2,t3,t4,t5;
boolean ongoing = false;
int cpt = 0;

// -- control UI
ControlP5 cp5;
Textlabel debug,info;
String info_text = "";
PFont font1;
Button shoot;
String shoot_label = "START";

// -- GPIO
int button_pin = 17;
int button_state = 1;

// -- SETUP
// -------------------------------------------------------------------
void setup()
{
  size(1024,900,P2D);
  //fullScreen(P2D);
  frameRate(60);
  
  // -- JSON CONFIG FILE
  JSONObject config = loadJSONObject("config.json");
  EXPORT_PATH = config.getString("local_export_path");
  UPLOAD_URL = config.getString("upload_service_url");
  upload_tokken = config.getString("upload_service_tokken");
  btn_mode = (config.getInt("use_physical_button") == 1) ? true : false;
  upload_to_server = (config.getInt("upload_option") == 1) ? true : false;
  create_a_collage = (config.getInt("collage_option") == 1) ? true : false;
  save_pictures = (config.getInt("save_individual") == 1) ? true : false;
  debug_mode = (config.getInt("debug_mode") == 1) ? true : false;
  info_text = config.getString("info_text");
  shoot_label = config.getString("button_label");
  gif_width = config.getInt("gif_width");
  
  // -- if we use a physical button, we don't need to display the cursor
  if(btn_mode == true) noCursor();
  
  // -- init UI
  cp5 = new ControlP5(this);
  font1 = createFont("arial",20);
  
  info = cp5.addTextlabel("info")
    .setText(info_text)
    .setPosition(0,-10)
    .setColor( color(255,255,255) );
  
  debug = cp5.addTextlabel("debug")
    .setText("debug")
    .setPosition(10,height - 20)
    .setSize(400,100)
    .setColor( color(255,255,255) );
  
  if(btn_mode == false)
  {
    shoot = cp5.addButton("shoot")
      .setLabel(shoot_label)
      .setSize(400,50)
      .setPosition( (width - 400) / 2, height - 50 - 50);
  }
  
  // -- looking for capture devices
  String[] devices = GLCapture.list();
  println("__________ Devices:");
  printArray(devices);
  
  if (0 < devices.length)
  {
    // -- getting the config modes of the first device
    configs = GLCapture.configs(devices[0]);
    println("__________ Configs:");
    printArray(configs);
  }

  //cam = new GLCapture(this);
  //cam = new GLCapture(this, devices[5]);
  //cam = new GLCapture(this, devices[0], 640, 480, 25);
  cam = new GLCapture(this, devices[0], configs[3]); // LOGITECH CAM on my RPi 
  //cam = new GLCapture(this, devices[0], configs[0]); // PS-EYE CAM on my RPi
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
  base_collage = loadImage("assets/base_collage.png");
  
  // -- init the storage images
  img1 = new PImage(cam.width, cam.height);
  img2 = new PImage(cam.width, cam.height);
  img3 = new PImage(cam.width, cam.height);
  img4 = new PImage(cam.width, cam.height);
  
  // -- calculating gif height
  if(gif_width == 0) gif_width = cam.width;
  gif_height = int((cam.height/cam.width)*gif_width);
  
  // -- init GPIO (for the physical button)
  if(btn_mode == true) GPIO.pinMode(button_pin, GPIO.INPUT);
  
  // -- init the gif player timer (10secs)
  gif_timer = CountdownTimerService.getNewCountdownTimer(this).configure(5000, 10000);
}

// -- DRAW (LOOP)
// -------------------------------------------------------------------
void draw()
{
  background(0);
  
  // -- the top left title
  image(title,0,0);
  
  // -- check the button state
  if(btn_mode == true) readButton();
  
  // -- update the center area position
  px = int((width - cam.width) / 2);
  py = int((height - cam.height) / 2);
  
  // -- check if GIF is playing
  if(playing_gif == true && lastGif != null)
  {
    int pgx = int((width - gif_width) / 2);
    int pgy = int((height - gif_height) / 2);
    image(lastGif,pgx,pgy); // only display the animated GIF
  }
  else
  {
    // -- get the cam view
    if(cam.available() == true) cam.read();
    
    // -- flip and display the cam monitor
    pushMatrix();
    scale(-1,1);
    image(cam, 0 - cam.width - px, py); // flip for mirror effect
    popMatrix();
    
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
    
    // -- request the fourth one
    if(req4 == true)
    {
      cam.loadPixels();
      arrayCopy(cam.pixels, img4.pixels);
      req4 = false;
      donePic4();
    }
  }
  
  // -- set the info label position
  info.setPosition(px,py + cam.height + 10);
}

// -- READ the BUTTON state
// -------------------------------------------------------------------
public void readButton()
{
  int current_state = 1;
  if(GPIO.digitalRead(button_pin) == GPIO.LOW) current_state = 0;
  
  if(current_state != button_state)
  {
    println("button state changed");
    button_state = current_state;
    if(button_state == 1)
    {
      println("button state back to 1: triggering a photo shoot sequence");
      shoot(1);
    }
  }
}

// -- SHOOT: launch the shooting sequence
// -------------------------------------------------------------------
public void shoot(int val)
{
  println("shoot requested: " + val);
  
  if(ongoing == true || playing_gif == true)
  {
    println("***** process en cours *****");
  }
  else
  {
    ongoing = true;
    
    if(btn_mode == false) shoot.setVisible(false);
    
    // -- the base name for exports: YYMMDD-hhmmss
    base_filename = getBaseName();
    
    img1 = new PImage(cam.width, cam.height);
    img2 = new PImage(cam.width, cam.height);
    img3 = new PImage(cam.width, cam.height);
    img4 = new PImage(cam.width, cam.height);
    
    String filename = EXPORT_PATH + "gifs/" + base_filename + ".gif";
    last_path = filename;
    
    gifExport = new GifMaker(this, filename);
    gifExport.setRepeat(0);
    gifExport.setSize(gif_width, gif_height);
    gifExport.setDelay(500);
    
    req1 = false;
    req2 = false;
    req3 = false;
    req4 = false;
    
    warn_t = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t1 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t2 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t3 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t4 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 5000);
    t5 = CountdownTimerService.getNewCountdownTimer(this).configure(1000, 1000);
    
    debug.setText("get ready...");
    
    step = "warn";
    warn_t.start();
  }
}

// -- Format a base name (based on the datetime)
// -------------------------------------------------------------------
public String getBaseName()
{
  int y = year();
  int m = month();
  int d = day();
  int h = hour();
  int mn = minute();
  int s = second();
  
  String month_str = (m < 10) ? ("0" + m) : ("" + m);
  String day_str = (d < 10) ? ("0" + d) : ("" + d);
  String hour_str = (h < 10) ? ("0" + h) : ("" + h);
  String minute_str = (mn < 10) ? ("0" + mn) : ("" + mn);
  String second_str = (s < 10) ? ("0" + s) : ("" + s);
  
  return (y + month_str + day_str + "-" + hour_str + minute_str + second_str);
}

// -- GLOBAL TICK EVENT
// -------------------------------------------------------------------
public void onTickEvent(CountdownTimer t, long timeLeftUntilFinish)
{
  println("tick " + t.getId() + " : " + timeLeftUntilFinish);
  
  if(step != "stand" 
  && step != "warn" 
  && step != "process" 
  && t.getId() != t5.getId() 
  && t.getId() != gif_timer.getId())
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
  
  // -- end of the fourth countdown: take the fourth picture
  if(t.getId() == t4.getId())
  {
    takePic4();
  }
  
  // -- end of the pre-processing pause: finalize the GIF
  if(t.getId() == t5.getId())
  {
    debug.setText("Processing and exporting...");
    step = "process";
    process_and_export();
  }
  
  // -- end of the GIF preview
  if(t.getId() == gif_timer.getId())
  {
    playing_gif = false;
    lastGif.stop();
    debug.setText("ready");
    if(btn_mode == false) shoot.setVisible(true);
    
    cleanLastGif();
  }
}

// -- Request the first picture
// -------------------------------------------------------------------
public void takePic1()
{
  step = "click";
  req1 = true;
}

// -- First picture ok
// -------------------------------------------------------------------
public void donePic1()
{
  delay(1000);
  debug.setText("picture 2");
  t2.start();
}

// -- Request the second picture
// -------------------------------------------------------------------
public void takePic2()
{
  step = "click";
  req2 = true;
}

// -- Second picture ok
// -------------------------------------------------------------------
public void donePic2()
{
  delay(1000);
  debug.setText("picture 3");
  t3.start();
}

// -- Request the third picture
// -------------------------------------------------------------------
public void takePic3()
{
  step = "click";
  req3 = true;
}

// -- Third picture ok
// -------------------------------------------------------------------
public void donePic3()
{
  delay(1000);
  debug.setText("picture 4");
  t4.start();
}

// -- Request the fourth picture
// -------------------------------------------------------------------
public void takePic4()
{
  step = "click";
  req4 = true;
}

// -- Fourth picture ok
// -------------------------------------------------------------------
public void donePic4()
{
  t5.start();
}

// -- PROCESS AND EXPORT
// -------------------------------------------------------------------
public void process_and_export()
{
  // -- save individual pictures
  if(save_pictures == true)
  {
    thread("export_pictures");
  }
  
  // -- make a collage
  if(create_a_collage == true)
  {
    thread("createCollage");
  }
  
  // -- and, of course...
  finalizeGif();
}

// -- FINALIZING GIF
// -------------------------------------------------------------------
public void finalizeGif()
{
  // -- exporting the GIF
  println("finalize GIF...");
  debug.setText("finalizing GIF file...");
  ///
  println("+pic1");
  img1.blend(overlay,0,0,overlay.width,overlay.height,0,0,img1.width,img1.height,BLEND);
  img1.resize(gif_width,gif_height);
  gifExport.addFrame(img1.pixels, gif_width, gif_height);
  ///
  println("+pic2");
  img2.blend(overlay,0,0,overlay.width,overlay.height,0,0,img2.width,img2.height,BLEND);
  img2.resize(gif_width,gif_height);
  gifExport.addFrame(img2.pixels, gif_width, gif_height);
  ///
  println("+pic3");
  img3.blend(overlay,0,0,overlay.width,overlay.height,0,0,img3.width,img3.height,BLEND);
  img3.resize(gif_width,gif_height);
  gifExport.addFrame(img3.pixels, gif_width, gif_height);
  ///
  println("+pic4");
  img4.blend(overlay,0,0,overlay.width,overlay.height,0,0,img4.width,img4.height,BLEND);
  img4.resize(gif_width,gif_height);
  gifExport.addFrame(img4.pixels, gif_width, gif_height);
  ///
  println("now saving gif...");
  gifExport.finish();
  println("done saving gif");
  
  step = "stand";
  ongoing = false;
  debug.setText("GIF completed");
  
  // -- trying to send to server
  if(upload_to_server == true)
  {
    thread("sendToServer");
  }
  
  // -- displaying the last generated GIF
  debug.setText("now playing GIF preview");
  launchLastGif();
}

// -- PLAYING THE LAST GIF
// -------------------------------------------------------------------
public void launchLastGif()
{
  if(btn_mode == false) shoot.setVisible(false);
  
  lastGif = new Gif(this, last_path);
  lastGif.play();
  
  playing_gif = true;
  
  gif_timer.start();
}

// -- CLEAN THE LAST GIF
// -------------------------------------------------------------------
public void cleanLastGif()
{
  println("***cleanLastGif");
  
  img1 = null;
  img2 = null;
  img3 = null;
  img4 = null;
  
  if(lastGif != null)
  {
    lastGif.dispose();
    lastGif = null;
  }
  
  delay(500);
  System.gc();
}

// -- SEND TO SERVER
// -------------------------------------------------------------------
public void sendToServer()
{
  println("sending to server...");
  debug.setText("sending to server.");
  
  PostRequest post = new PostRequest(UPLOAD_URL);
  post.addData("t", upload_tokken);
  post.addFile("uploadFile", EXPORT_PATH + "gifs/" + base_filename + ".gif");
  //post.addFile("uploadFile", EXPORT_PATH + "collages/" + base_filename + ".png");
  post.send();
  
  String response = post.getContent();
  println("POST RESPONSE: " + response);
  
  post = null;
}

// -- CREATE A COLLAGE
// -------------------------------------------------------------------
public void createCollage()
{
  println("creating the collage...");
  
  // -- 1772x1181px for a 15x10cm 300dpi export
  PImage base = new PImage(base_collage.width, base_collage.height);
  PImage col1 = new PImage(img1.width, img1.height);
  PImage col2 = new PImage(img2.width, img2.height);
  PImage col3 = new PImage(img3.width, img3.height);
  PImage col4 = new PImage(img4.width, img4.height);
  
  // -- duplicate sources
  arrayCopy(base_collage.pixels, base.pixels);
  arrayCopy(img1.pixels, col1.pixels);
  arrayCopy(img2.pixels, col2.pixels);
  arrayCopy(img3.pixels, col3.pixels);
  arrayCopy(img4.pixels, col4.pixels);
  
  // -- set the destination size for the pictures
  int dest_h = 590;
  int dest_w = int((col1.width * dest_h) / col1.height);
  
  // -- resize the pictures
  col1.resize(dest_w, dest_h);
  col2.resize(dest_w, dest_h);
  col3.resize(dest_w, dest_h);
  col4.resize(dest_w, dest_h);
  
  // -- create the collage
  base.set(0, 0, col1);
  base.set(dest_w + 1, 0, col2);
  base.set(0, dest_h + 1, col3);
  base.set(dest_w + 1, dest_h + 1, col4);
  
  // -- save the collage
  base.save(EXPORT_PATH + "collages/" + base_filename + ".jpg");
  
  println("collage done");
  
  // -- reset the clones
  base = null;
  col1 = null;
  col2 = null;
  col3 = null;
  col4 = null;
}

// -- SAVE INDIVIDUAL PICTURES
// -------------------------------------------------------------------
public void export_pictures()
{
  println("saving pictures...");
  debug.setText("saving pictures...");
  img1.save( EXPORT_PATH + "pictures/" + base_filename + "__001.png");
  img2.save( EXPORT_PATH + "pictures/" + base_filename + "__002.png");
  img3.save( EXPORT_PATH + "pictures/" + base_filename + "__003.png");
  img4.save( EXPORT_PATH + "pictures/" + base_filename + "__004.png");
  println("saving pictures DONE");
}