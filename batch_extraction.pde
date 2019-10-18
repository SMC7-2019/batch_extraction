import com.runwayml.*;
import processing.video.*;

RunwayHTTP runway;
float scoreThreshold = 0.8;

Movie movie;
int FULL_COUNTER = 0;
int PARTIAL_COUNTER = 1;
int[] frameCounters = {0, 0};


PImage frame;
float scale;
int scaledW, scaledH;

String status = "";

int[][] connections = {
  {ModelUtils.POSE_NOSE_INDEX, ModelUtils.POSE_LEFT_EYE_INDEX}, 
  {ModelUtils.POSE_LEFT_EYE_INDEX, ModelUtils.POSE_LEFT_EAR_INDEX}, 
  {ModelUtils.POSE_NOSE_INDEX, ModelUtils.POSE_RIGHT_EYE_INDEX}, 
  {ModelUtils.POSE_RIGHT_EYE_INDEX, ModelUtils.POSE_RIGHT_EAR_INDEX}, 
  {ModelUtils.POSE_RIGHT_SHOULDER_INDEX, ModelUtils.POSE_RIGHT_ELBOW_INDEX}, 
  {ModelUtils.POSE_RIGHT_ELBOW_INDEX, ModelUtils.POSE_RIGHT_WRIST_INDEX}, 
  {ModelUtils.POSE_LEFT_SHOULDER_INDEX, ModelUtils.POSE_LEFT_ELBOW_INDEX}, 
  {ModelUtils.POSE_LEFT_ELBOW_INDEX, ModelUtils.POSE_LEFT_WRIST_INDEX}, 
  {ModelUtils.POSE_RIGHT_HIP_INDEX, ModelUtils.POSE_RIGHT_KNEE_INDEX}, 
  {ModelUtils.POSE_RIGHT_KNEE_INDEX, ModelUtils.POSE_RIGHT_ANKLE_INDEX}, 
  {ModelUtils.POSE_LEFT_HIP_INDEX, ModelUtils.POSE_LEFT_KNEE_INDEX}, 
  {ModelUtils.POSE_LEFT_KNEE_INDEX, ModelUtils.POSE_LEFT_ANKLE_INDEX}, 

  {ModelUtils.POSE_RIGHT_SHOULDER_INDEX, ModelUtils.POSE_LEFT_SHOULDER_INDEX}, 
  {ModelUtils.POSE_LEFT_SHOULDER_INDEX, ModelUtils.POSE_LEFT_HIP_INDEX}, 
  {ModelUtils.POSE_LEFT_HIP_INDEX, ModelUtils.POSE_RIGHT_HIP_INDEX}, 
  {ModelUtils.POSE_RIGHT_HIP_INDEX, ModelUtils.POSE_RIGHT_SHOULDER_INDEX}, 
};


void setup() {

  size(600, 800);
  background(0);

  frame = createImage(600, 400, RGB);

  runway = new RunwayHTTP(this);
  runway.setAutoUpdate(false);

  //selectInput("Select a file to process:", "fileSelected");

  movie = new Movie(this, "dance_of_the_sugar_plum_fairy_from_the_nutcracker_the_royal_ballet.mp4");
  movie.play();
  movie.jump(0);
  movie.pause();

  scale = min(float(frame.width) / movie.width, float(frame.height) / movie.height);
  scaledW = int(movie.width*scale);
  scaledH = int(movie.height*scale);
}

void draw() {

  int f=ceil (map(mouseX, 0, width, 1, getLastFrame()));
  gotoFrame(f);

  frame.copy(movie, 0, 0, movie.width, movie.height, (frame.width-scaledW)/2, (frame.height-scaledH)/2, scaledW, scaledH);
  image(frame, 0, 0);

  fill(0, 100);
  noStroke();
  rect(0, 0, width, 20);
  rect(0, frame.height, width, 20);

  fill(255);
  text(getCurrFrame() + "/" + getLastFrame(), 8, 15);
  text(frameCounters[PARTIAL_COUNTER] + "/" + frameCounters[FULL_COUNTER], 8, frame.height + 15);
}

void sendFrameToRunway() {

  JSONObject input = new JSONObject();

  input.setString("image", ModelUtils.toBase64(frame));
  input.setString("estimationType", "Single Pose");
  input.setInt("maxPoseDetections", 1);
  input.setFloat("scoreThreshold", scoreThreshold);

  runway.query(input.toString());
}



//void fileSelected(File selection) {
//  if (selection == null) {
//    println("Window was closed or the user hit cancel.");
//  } else {
//    println("User selected " + selection.getAbsolutePath());
//    // load image
//    image = loadImage(selection.getAbsolutePath());
//    // resize sketch
//    surface.setSize(image.width,image.height);
//    // send image to Runway
//    runway.query(image);
//  }
//}



/*

 d8888b.  .d88b.  .d8888. d88888b d8b   db d88888b d888888b
 88  `8D .8P  Y8. 88'  YP 88'     888o  88 88'     `~~88~~'
 88oodD' 88    88 `8bo.   88ooooo 88V8o 88 88ooooo    88
 88~~~   88    88   `Y8b. 88~~~~~ 88 V8o88 88~~~~~    88
 88      `8b  d8' db   8D 88.     88  V888 88.        88
 88       `Y88P'  `8888Y' Y88888P VP   V8P Y88888P    YP
 
 */

void drawPoseNetParts(JSONObject data) {

  stroke(255);
  strokeWeight(2);

  JSONArray humans = data.getJSONArray("poses");
  JSONArray keypoints = humans.getJSONArray(0);

  for (int i = 0; i < connections.length; i++) {

    JSONArray startPart = keypoints.getJSONArray(connections[i][0]);
    JSONArray endPart   = keypoints.getJSONArray(connections[i][1]);
    // extract floats fron JSON array and scale normalized value to sketch size
    float startX = startPart.getFloat(0) * frame.width;
    float startY = startPart.getFloat(1) * frame.height + frame.height;
    float endX   = endPart.getFloat(0) * frame.width;
    float endY   = endPart.getFloat(1) * frame.height + frame.height;

    line(startX, startY, endX, endY);
  }
}


/*

 .88b  d88.  .d88b.  db    db .d8888. d88888b
 88'YbdP`88 .8P  Y8. 88    88 88'  YP 88'
 88  88  88 88    88 88    88 `8bo.   88ooooo
 88  88  88 88    88 88    88   `Y8b. 88~~~~~
 88  88  88 `8b  d8' 88b  d88 db   8D 88.
 YP  YP  YP  `Y88P'  ~Y8888P' `8888Y' Y88888P
 
 */

void mousePressed() {
  image(frame, 0, height/2);
  sendFrameToRunway();
}



/*

 .88b  d88.  .d88b.  db    db d888888b d88888b
 88'YbdP`88 .8P  Y8. 88    88   `88'   88'
 88  88  88 88    88 Y8    8P    88    88ooooo
 88  88  88 88    88 `8b  d8'    88    88~~~~~
 88  88  88 `8b  d8'  `8bd8'    .88.   88.
 YP  YP  YP  `Y88P'     YP    Y888888P Y88888P
 
 */

void movieEvent(Movie m) {
  m.read();
}



/*

 d88888b d8888b.  .d8b.  .88b  d88. d88888b
 88'     88  `8D d8' `8b 88'YbdP`88 88'
 88ooo   88oobY' 88ooo88 88  88  88 88ooooo
 88~~~   88`8b   88~~~88 88  88  88 88~~~~~
 88      88 `88. 88   88 88  88  88 88.
 YP      88   YD YP   YP YP  YP  YP Y88888P
 
 */

void gotoFrame(int n) {

  movie.play();

  float frameDuration = 1.0 / movie.frameRate;
  float where = (n + 0.5) * frameDuration; 
  float diff = movie.duration() - where;
  if (diff < 0) {
    where += diff - 0.25 * frameDuration;
  }

  movie.jump(where);
  movie.pause();
}  

int getCurrFrame() {
  return ceil(movie.time() * movie.frameRate) - 1;
}

int getLastFrame() {
  return int(movie.duration() * movie.frameRate);
}



/*

 d8888b. db    db d8b   db db   d8b   db  .d8b.  db    db
 88  `8D 88    88 888o  88 88   I8I   88 d8' `8b `8b  d8'
 88oobY' 88    88 88V8o 88 88   I8I   88 88ooo88  `8bd8'
 88`8b   88    88 88 V8o88 Y8   I8I   88 88~~~88    88
 88 `88. 88b  d88 88  V888 `8b d8'8b d8' 88   88    88
 88   YD ~Y8888P' VP   V8P  `8b8' `8d8'  YP   YP    YP
 
 */

void runwayDataEvent(JSONObject runwayData) {

  frameCounters[FULL_COUNTER]++;

  if (runwayData.getJSONArray("scores").size() > 0) {
    frameCounters[PARTIAL_COUNTER]++;
    drawPoseNetParts(runwayData);
  }
  print();
  println(" " + runwayData.getJSONArray("scores"));
}

public void runwayInfoEvent(JSONObject info) {
  //println(info);
}

public void runwayErrorEvent(String message) {
  println(message);
}
