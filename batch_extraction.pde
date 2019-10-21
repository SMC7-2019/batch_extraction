import com.runwayml.*;

float SCORE_THRESHOLD = 0.6;

String BASEFOLDER = "output";
String BASENAME = "plum";
String EXTENSION = "png";
int    FRAMERATE = 30;

int[][] connections = {
  {ModelUtils.POSE_RIGHT_EYE_INDEX, ModelUtils.POSE_LEFT_EYE_INDEX}, 

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

int[] head = {
  ModelUtils.POSE_RIGHT_EYE_INDEX, 
  ModelUtils.POSE_LEFT_EYE_INDEX, 
  ModelUtils.POSE_LEFT_EAR_INDEX, 
  ModelUtils.POSE_RIGHT_EAR_INDEX, 
  ModelUtils.POSE_NOSE_INDEX, 
};

int[] torso = {
  ModelUtils.POSE_RIGHT_HIP_INDEX, 
  ModelUtils.POSE_LEFT_HIP_INDEX, 
  ModelUtils.POSE_RIGHT_SHOULDER_INDEX, 
  ModelUtils.POSE_LEFT_SHOULDER_INDEX, 
};

RunwayHTTP runway;

PImage frame;
int firstFile = 1;
int fileCounter = 0;
int skippedCounter = 0;

JSONObject fullData;
JSONArray framesData;
float maxSpan = -1;

void setup() {

  size(600, 800);
  background(0);
  textSize(15);
  frameRate(60);
  //pixelDensity(2);

  fullData = new JSONObject();
  framesData = new JSONArray();

  runway = new RunwayHTTP(this);
  runway.setAutoUpdate(false);
}

void draw() {

  String filename = getFilename(fileCounter + firstFile);
  frame = loadImage(filename);

  if (frame == null) {
    noLoop();
    fullData.setInt("videoStart", firstFile);
    fullData.setInt("videoEnd", firstFile+fileCounter-1);
    fullData.setInt("totalFrames", fileCounter);
    fullData.setInt("frameRate", FRAMERATE);
    fullData.setJSONArray("frames", framesData);
    fullData.setInt("skipped", skippedCounter);
    fullData.setFloat("maxSpan", maxSpan);
    saveJSONObject(fullData, "data/"+BASENAME+".json");
    return;
  }

  image(frame, 0, 0);
  sendFrameToRunway();

  fill(0, 100);
  noStroke();
  rect(0, 0, frame.width, 45);

  fill(255);
  text("Frame " + (fileCounter + firstFile) + "  (" + nf(frameRate, 0, 1)  + "fps)", 8, 18);
  text("Skipped: " + skippedCounter + " ("+ (nf((100.0*skippedCounter/(fileCounter+1)), 0, 2)) + "%)", 8+frame.width/2, 18);
  text("Max. span: " + maxSpan, 8, 35);

  fileCounter++;
}

void sendFrameToRunway() {

  JSONObject input = new JSONObject();

  input.setString("image", ModelUtils.toBase64(frame));
  input.setString("estimationType", "Single Pose");
  input.setInt("maxPoseDetections", 1);
  input.setFloat("scoreThreshold", SCORE_THRESHOLD);

  runway.query(input.toString());
}

void drawParts(JSONObject data) {

  fill(0, 110);
  noStroke();
  rect(0, frame.height, frame.width, frame.height);

  stroke(255);


  JSONArray head = data.getJSONArray("head");
  JSONArray torso = data.getJSONArray("torso");

  JSONArray keypoints = data.getJSONArray("data");

  pushMatrix();
  scale(frame.width, frame.height);  
  translate(torso.getFloat(0), torso.getFloat(1)*3);

  //WTF, Processing
  strokeWeight(0.003);

  for (int i = 0; i < connections.length; i++) {

    JSONArray startPart = keypoints.getJSONArray(connections[i][0]);
    JSONArray endPart   = keypoints.getJSONArray(connections[i][1]);
    float startX = startPart.getFloat(0);
    float startY = startPart.getFloat(1);
    float endX   = endPart.getFloat(0);
    float endY   = endPart.getFloat(1);

    line(startX, startY, endX, endY);
  }

  ellipse(head.getFloat(0), head.getFloat(1), 15.0/frame.width, 20.0/frame.height);

  JSONArray startPart = keypoints.getJSONArray(ModelUtils.POSE_RIGHT_WRIST_INDEX);
  float startX = startPart.getFloat(0);
  float startY = startPart.getFloat(1);

  stroke(#3262b5);
  line(startX, startY, 0, 0);

  startPart = keypoints.getJSONArray(ModelUtils.POSE_LEFT_WRIST_INDEX);
  startX = startPart.getFloat(0);
  startY = startPart.getFloat(1);

  line(startX, startY, 0, 0);

  noStroke();
  fill(#e03854);
  ellipse(0, 0, 12.0/frame.width, 12.0/frame.height);
  
  popMatrix();
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

 d8888b. db    db d8b   db db   d8b   db  .d8b.  db    db
 88  `8D 88    88 888o  88 88   I8I   88 d8' `8b `8b  d8'
 88oobY' 88    88 88V8o 88 88   I8I   88 88ooo88  `8bd8'
 88`8b   88    88 88 V8o88 Y8   I8I   88 88~~~88    88
 88 `88. 88b  d88 88  V888 `8b d8'8b d8' 88   88    88
 88   YD ~Y8888P' VP   V8P  `8b8' `8d8'  YP   YP    YP
 
 */

void runwayDataEvent(JSONObject runwayData) {

  JSONObject frameData = new JSONObject();

  if (runwayData.getJSONArray("scores").size() > 0) {

    JSONArray mainPose = runwayData.getJSONArray("poses").getJSONArray(0);

    JSONArray torsoCenter = getCenter(torso, mainPose);
    PVector torsoVector = new PVector(torsoCenter.getFloat(0), torsoCenter.getFloat(1));

    //We use these to calculate the span, so we don't need to center them 
    JSONArray leftWrist = mainPose.getJSONArray(ModelUtils.POSE_LEFT_WRIST_INDEX);
    JSONArray rightWrist = mainPose.getJSONArray(ModelUtils.POSE_RIGHT_WRIST_INDEX);

    float currSpan = torsoVector.dist(new PVector(leftWrist.getFloat(0), leftWrist.getFloat(1)));
    if (currSpan > maxSpan) {
      maxSpan = currSpan;
    }

    currSpan = torsoVector.dist(new PVector(rightWrist.getFloat(0), rightWrist.getFloat(1)));
    if (currSpan > maxSpan) {
      maxSpan = currSpan;
    }  

    //Translate the head
    JSONArray headCenter = getCenter(head, mainPose);
    JSONArray headCentered = new JSONArray();
    headCentered.setFloat(0, headCenter.getFloat(0) - torsoVector.x);
    headCentered.setFloat(1, headCenter.getFloat(1) - torsoVector.y);

    //Translate the joints
    JSONArray centeredPose = new JSONArray();
    for (int f=0; f<mainPose.size(); f++) {
      JSONArray joint = mainPose.getJSONArray(f);
      JSONArray jointCentered = new JSONArray();
      jointCentered.setFloat(0, joint.getFloat(0) - torsoVector.x);
      jointCentered.setFloat(1, joint.getFloat(1) - torsoVector.y);
      centeredPose.setJSONArray(f, jointCentered);
    }

    frameData.setBoolean("interpolation", false);
    frameData.setFloat("score", runwayData.getJSONArray("scores").getFloat(0));
    frameData.setJSONArray("torso", torsoCenter);    
    frameData.setJSONArray("head", headCentered);
    frameData.setJSONArray("data", centeredPose);

    drawParts(frameData);
  } else {
    //TODO: Interpolate features, torso and head
    frameData.setBoolean("interpolation", true);
    frameData.setFloat("score", 0);
    skippedCounter++;
  }

  frameData.setFloat("timeRel", fileCounter/float(FRAMERATE));
  frameData.setFloat("timeAbs", (fileCounter + firstFile)/float(FRAMERATE));
  frameData.setInt("frameRel", fileCounter);
  frameData.setInt("frameAbs", fileCounter + firstFile);
  framesData.setJSONObject(fileCounter, frameData);
}

public void runwayInfoEvent(JSONObject info) {
  //println(info);
}

public void runwayErrorEvent(String message) {
  println(message);
}



/*

 db   db d88888b db      d8888b. d88888b d8888b. .d8888.
 88   88 88'     88      88  `8D 88'     88  `8D 88'  YP
 88ooo88 88ooooo 88      88oodD' 88ooooo 88oobY' `8bo.
 88~~~88 88~~~~~ 88      88~~~   88~~~~~ 88`8b     `Y8b.
 88   88 88.     88booo. 88      88.     88 `88. db   8D
 YP   YP Y88888P Y88888P 88      Y88888P 88   YD `8888Y'
 
 */

JSONArray getCenter(int[] markers, JSONArray data) {

  JSONArray center = new JSONArray();

  PVector vCenter = new PVector(0, 0);
  for (int i = 0; i < markers.length; i++) {
    JSONArray part = data.getJSONArray(markers[i]);
    vCenter.add(part.getFloat(0), part.getFloat(1));
  }  
  vCenter.div(markers.length);   

  center.setFloat(0, vCenter.x);
  center.setFloat(1, vCenter.y);

  return center;
}

public String getFilename(int index) {
  return BASEFOLDER + "/" + BASENAME + "_" + nf(index, 5) + "." + EXTENSION;
}
