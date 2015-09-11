/* NOTES 
 * Tracking multiple objects based on colour - built around an 'OpenCV for Processing' example - "MultipleColorTracking"
 *  FEATURES:
 *  - Select maximum number of colours to track
 *  - Track up to 16 colours if set up correctly, more can be added if additional keys are used and the maxColours variable is increased
 *  - Display location of centrepoints for each colour
 *  - Uses the OpenCV for Processing library by Greg Borenstein
 * 
 *  TO DO:
 *  - Need variables for size (w&h) of objects min and max - detection in contours
 *  - Need to improve accuracy of colour recognition (orange is detecting skin better than orange paper)
 *  - Investigate erode() and see if line above is better / worse.
 *  - Improve detection of 'blobs' search for to do further down
 *  - Look for *** to find areas noted.
 */
import gab.opencv.*;//import OpenCV library for computer vision functionality
import processing.video.*;//import video handling capabilities   
import surf.*;//import SURF feature identification
import java.awt.Rectangle;//import additional rectangle capabilities
//end of import1s and notes
//********************************************************
 
Capture video;//video capture object
OpenCV opencv;//OpenCV object

PImage src;//source image to provide detection - each frame is put into this
//ArrayList<Integer> colours;//***would be used for a larger # of colours
int maxColours = 8;//**SET MAX COLOURS to detect
ArrayList<Contour>[] contours = new ArrayList[maxColours];//detection contours arraylist
ArrayList<Contour>[] sampleContours = new ArrayList[maxColours];//detection contours arraylist

boolean contoursNotEmpty[] = new boolean[maxColours];
PVector points[] = new PVector[maxColours];

int[] hues;//array of hue values
int[] colours;//array of detection colours
int rangeWidth = 7;//***SET SENSITIVITY of hue detection

PImage[] outputs;//output images for cancelled out previews

int colourToChange = -1;//default (null) colour value
//end of global variables
//********************************************************

void setup() {
  video = new Capture(this, 640, 480);//initialise video capture object
  opencv = new OpenCV(this, video.width, video.height);//initialise OpenCV object based around size of video capture
  
  size(opencv.width + opencv.width/maxColours + 30, opencv.height, P2D);//set size of sketch window based on max. # of colours
  
  colours = new int[maxColours];//selected detection colours
  hues = new int[maxColours];//hue values of selected colours
  
  outputs = new PImage[maxColours];//output images (cancelled out apart from selected colour)
  
  textFont(createFont("BebasNeue Regular.ttf", 26));//import the BebasNeue font to Processing and set the text to use this font
  
  video.start();//start capturing video
}//end of setup
//********************************************************

void draw() {
  
  background(150);//set the background grey
  
  if (video.available()){//if there is a video stream incoming
    video.read();//read incoming video frames
  }
  opencv.loadImage(video);//load the read video frame to OpenCV
  
  opencv.useColor();//make OpenCV use colour information

  src = opencv.getSnapshot();//use a snapshot of what OpenCV's capture sees
  
  opencv.useColor(HSB);//make OpenCV use the HSV colourTo space.
  detectColours();//
  
  image(src, 0, 0);//Show camera view
  
  for (int i=0; i<outputs.length; i++) {
    if (outputs[i] != null){//if there is a colour selected at i
      image(outputs[i], width - (src.width/maxColours), i*src.height/maxColours, src.width/maxColours, src.height/maxColours);//display images with other colour removed
      noStroke();//draw shape with no line
      fill(colours[i]);//set the fill for the rectangle to match the colour detected
      rect(width-(src.width/maxColours + 30), i*src.height/maxColours, 30, src.height/maxColours);//display the selected colour on screen
    }
  }
  
  // Print text if new colourTo expected
  stroke(255);//make lines drawn from this point white
  fill(255);//fill shapes from this point white
  
  if (colourToChange > -1){//if there is a colour to change now
    text("click to change colour " + (colourToChange+1), 10, 25);//display secondary instruction
  } else {
    text("press key [1-0 or q-t] to select colour", 10, 25);//display initial instruction
  }
  
  displayContourBoxes();//display boxes round tracked items
}//end of draw
//********************************************************

void detectColours() {//detect chosen colours
    
  for (int i=0; i< hues.length; i++) {//for each chosen hue value
    if (hues[i] <= 0)//if no colour
    continue;//skip detection
    
    opencv.loadImage(src);//take the source camera capture frame as an input to OpenCV
    opencv.useColor(HSB);//use HSB colours
    
    opencv.setGray(opencv.getH().clone());//copy hue channel into gray channel, which we process further
    
    int hueToDetect = hues[i];
    //println("i: " + i + " - hue: " + hueToDetect);//debugging - show hue to detect in console
    
    opencv.inRange(hueToDetect-rangeWidth/2, hueToDetect+rangeWidth/2);//filter by the hue values that match the object we want to track.

    //opencv.dilate();//untested - unknown function***
    //opencv.erode();//erode image.***DEFAULT WAS NOT REMOVED - FURTHER TESTING TO DO
    
    //***TO DO: Add here some image filtering to detect blobs better***
    
    outputs[i] = opencv.getSnapshot();//save the output to the corresponding array item
    contoursNotEmpty[i] = false;//tell the program that this is an empty contour list (default value)

    if (outputs[i] != null) {//if there is a colour selected to detect at position i 
    //***THIS IS WHERE FURTHER RECOGNITION NEEDS TO TAKE PLACE   
      opencv.loadImage(outputs[i]);//load the output image from the array
      
      contours[i] = opencv.findContours(true,true);//find the contours of the objects.. passing 'true' sorts them by descending area.
      contoursNotEmpty[i] = true;//tell the program that contours have been found - the list won't be empty
   //***NEW STUFF HERE   
      //opencv.loadImage("sample.png");
      //sampleContours[i]=opencv.findContours(true,true);
      //float compare = opencv.matchShapes(contours[i], sampleContours[i],1,0.0);//not compatible with OpenCV for (processing)
 //***END OF NEW STUFF
    }
  }
}//end of detectColours
//********************************************************

void displayContourBoxes() {//display the contour surrounding boxes for each colour chosen.
  for (int i=0; i < maxColours; i++){//for each colour 
    if (contoursNotEmpty[i] && !contours[i].isEmpty()){//if there are detected contours
      for (int j=0; j < contours[i].size(); j++) {//find contours ** DEPRECATED if only largest contour is needed.
        Contour contour = contours[i].get(j);//** DEPRECATED if only largest contour is needed.
        //Contour contour = contours[i].get(0);//get the largest detected contour only
        Rectangle r = contour.getBoundingBox();//find the rectangle tightly fitting the contour
        
        if (r.width < 20 || r.height < 20 || r.width > 220 || r.height > 220){continue;}//IGNORE THE CONTOUR IF TOO BIG OR TOO SMALL
        
        fill(255);//set the fill colour to white for following drawing
        //println("point " + i+1 + " centre x: " + (r.x + r.width/2) + ", y: " + (r.y + r.height/2));//CONSOLE DISPLAY OF POSITIONS *debugging only
        text("x:" + (r.x + r.width/2) + ", y: " + (r.y + r.height/2), src.width + 15, (i * src.height/maxColours) + 20);//OSD OF POSITIONS
       
        stroke(colours[i]);//set stroke to the colour i
        fill(colours[i], 180);//set fill to transparent version of colour i
        strokeWeight(3);//stroke (line) weight to 3px
        rect(r.x, r.y, r.width, r.height);//draw the surrounding rectangle of i contour
      }//FOR LOOP j brace 
    }
  }//FOR LOOP i brace
}//end of displayContourBoxes
//********************************************************

void mousePressed() {//called when mouse is clicked 
    
  if (colourToChange != -1) {//if there is a colour key pressed
    
    color c = get(mouseX, mouseY);//GET THE PIXEL VALUE AT THE CURRENT MOUSE POINTER POSITION
    //println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));//print rgb value of current colour - debugging
   
    int hue = int(map(hue(c), 0, 255, 0, 180));//determine hue based on mapping the rgb value
    
    colours[colourToChange] = c;//change the colour required
    hues[colourToChange] = hue;//change the hue value required
    
    //println("color index " + (colourToChange) + ", value: " + hue);//display hue change - debugging
  }
}//end of mousePressed
//********************************************************

void keyPressed() {//called when a key is pressed
  switch(key){//base a decision on which key value is detected
    default: colourToChange = -1; break;//default - if key does not match any of the following cases
    
    case '1': colourToChange = 0; break;//1-9 values on number keys
    case '2': colourToChange = 1; break;
    case '3': colourToChange = 2; break;
    case '4': colourToChange = 3; break;
    case '5': colourToChange = 4; break;
    case '6': colourToChange = 5; break;
    case '7': colourToChange = 6; break;
    case '8': colourToChange = 7; break;
    case '9': colourToChange = 8; break;
    case '0': colourToChange = 9; break;
    
    case 'q': colourToChange = 10; break;//10-15 (q-y letter keys)
    case 'w': colourToChange = 11; break;
    case 'e': colourToChange = 12; break;
    case 'r': colourToChange = 13; break;
    case 't': colourToChange = 14; break;
    case 'y': colourToChange = 15; break;
  }
}//end of keyPressed
//********************************************************

void keyReleased() {//called on release of a pressed key
  colourToChange = -1;//reset the variable so that no unwanted changes are made
}//end of keyReleased
