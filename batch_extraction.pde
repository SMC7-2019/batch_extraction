import com.runwayml.*;

float SCORE_THRESHOLD = 0.6;

String BASEFOLDER = "output";
String BASENAME = "plum";
String EXTENSION = "png";

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

RunwayHTTP runway;

PImage frame;
int fileCounter = 400;


void setup() {

  size(600, 800);
  background(0);
  frameRate(60);

  runway = new RunwayHTTP(this);
  runway.setAutoUpdate(false);
  
}

void draw() {

  String filename = getFilename(fileCounter);
  frame = loadImage(filename);
  
  if (frame == null) {
    noLoop();
    return;
  }
  
  image(frame, 0, 0);
  sendFrameToRunway();

  fileCounter++;

  //  

  //image(frame, 0, 0);

  //fill(0, 100);
  //noStroke();
  //rect(0, 0, frame.width, 45);
  //rect(0, frame.height, frame.width, 45);
}

void sendFrameToRunway() {

  JSONObject input = new JSONObject();

  input.setString("image", ModelUtils.toBase64(frame));
  input.setString("estimationType", "Single Pose");
  input.setInt("maxPoseDetections", 1);
  input.setFloat("scoreThreshold", SCORE_THRESHOLD);

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

  fill(0, 80);
  noStroke();
  rect(0, frame.height, frame.width, frame.height);

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

 d8888b. db    db d8b   db db   d8b   db  .d8b.  db    db
 88  `8D 88    88 888o  88 88   I8I   88 d8' `8b `8b  d8'
 88oobY' 88    88 88V8o 88 88   I8I   88 88ooo88  `8bd8'
 88`8b   88    88 88 V8o88 Y8   I8I   88 88~~~88    88
 88 `88. 88b  d88 88  V888 `8b d8'8b d8' 88   88    88
 88   YD ~Y8888P' VP   V8P  `8b8' `8d8'  YP   YP    YP
 
 */

void runwayDataEvent(JSONObject runwayData) {
  if (runwayData.getJSONArray("scores").size() > 0) {
    drawPoseNetParts(runwayData);
  }
}

public void runwayInfoEvent(JSONObject info) {
  //println(info);
}

public void runwayErrorEvent(String message) {
  println(message);
}




public String getFilename(int index) {
  return BASEFOLDER + "/" + BASENAME + "_" + nf(fileCounter, 5) + "." + EXTENSION;
}
