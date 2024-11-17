import processing.sound.*;

ArrayList<Firework> fireworks = new ArrayList<Firework>();
ArrayList<Particle> particles = new ArrayList<Particle>();
PianoKey[] keys = new PianoKey[15];
SinOsc[] oscA = new SinOsc[15];
SinOsc[] oscB = new SinOsc[15];
Env[] envelopes = new Env[15];

float globalHue = 0;
int lastPlayedKey = -1;
int[] scale = {60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84};
color[] fireworkColors = {
  color(255, 50, 50),
  color(50, 255, 50),
  color(50, 50, 255),
  color(255, 255, 50),
  color(255, 50, 255),
  color(255, 150, 50),
  color(255, 200, 50),
  color(200, 255, 255),
  color(255, 255, 255)
};

void setup() {
  size(1280, 720, P2D);
  colorMode(RGB, 255, 255, 255, 100);
  background(0);
  
  float keyWidth = width / 15.0;
  for (int i = 0; i < 15; i++) {
    keys[i] = new PianoKey(i * keyWidth, height - 100, keyWidth, 100, i);
    oscA[i] = new SinOsc(this);
    oscB[i] = new SinOsc(this);
    envelopes[i] = new Env(this);
  }
}

void draw() {
  fill(0, 0, 0, 25);
  noStroke();
  rect(0, 0, width, height);
  
  blendMode(ADD);
  
  for (int i = fireworks.size() - 1; i >= 0; i--) {
    Firework f = fireworks.get(i);
    f.update();
    f.display();
    if (f.exploded) {
      createExplosion(f.pos.x, f.pos.y, f.col, f.type, f.size);
      fireworks.remove(i);
    }
  }
  
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) {
      particles.remove(i);
    }
  }
  
  blendMode(BLEND);
  drawPianoKeys();
}

void drawPianoKeys() {
  for (PianoKey key : keys) {
    key.display();
  }
}

void mousePressed() {
  int keyIndex = int(map(mouseX, 0, width, 0, 15));
  keyIndex = constrain(keyIndex, 0, 14);
  keys[keyIndex].press();
  playNote(keyIndex);
  launchFireworks(mouseX, keyIndex);
}

void mouseReleased() {
  if (lastPlayedKey >= 0) {
    keys[lastPlayedKey].release();
    lastPlayedKey = -1;
  }
}

void launchFireworks(float x, int keyIndex) {
  int numFireworks = int(random(1, 3));
  for (int i = 0; i < numFireworks; i++) {
    float offset = random(-30, 30);
    float size = random(0.9, 1.5);
    color col = fireworkColors[keyIndex % fireworkColors.length];
    fireworks.add(new Firework(x + offset, height, col, int(random(5)), size));
  }
}

void playNote(int index) {
  float freq = midiToFreq(scale[index]);
  oscA[index].freq(freq);
  oscA[index].amp(0.3);
  oscA[index].play();
  
  oscB[index].freq(freq * 2);
  oscB[index].amp(0.15);
  oscB[index].play();
  
  envelopes[index].play(oscA[index], 0.002, 0.002, 0.5, 0.3);
  envelopes[index].play(oscB[index], 0.002, 0.002, 0.3, 0.3);
}

float midiToFreq(int note) {
  return 440 * pow(2, (note - 69) / 12.0);
}

void createExplosion(float x, float y, color col, int type, float size) {
  int particleCount;
  
  switch(type) {
    case 0:
      particleCount = 300;
      float baseSize = size;  // 减小基础大小
      for (int i = 0; i < particleCount; i++) {
        particles.add(new Particle(x, y, col, 0, baseSize));
      }
      for (int i = 0; i < particleCount/2; i++) {
        color sparkColor = color(red(col) * 1.2, green(col) * 1.2, blue(col) * 1.2);
        particles.add(new Particle(x, y, sparkColor, 0, baseSize * 0.5));  // 减小火花大小
      }
      break;
      
    case 1:
      particleCount = 350;
      for (int layer = 0; layer < 3; layer++) {
        float layerSize = size * (1.0 - layer * 0.2);  // 减小层大小
        for (int i = 0; i < particleCount/(layer+1); i++) {
          particles.add(new Particle(x, y, col, 1, layerSize));
        }
      }
      break;
      
    case 2:
      particleCount = 400;
      for (int i = 0; i < 12; i++) {
        float angle = TWO_PI * i / 12;
        float dist = 40 * size;  // 减小分布距离
        float px = x + cos(angle) * dist;
        float py = y + sin(angle) * dist;
        for (int j = 0; j < 30; j++) {
          particles.add(new Particle(px, py, col, 2, size));  // 减小大小
        }
      }
      for (int i = 0; i < particleCount; i++) {
        particles.add(new Particle(x, y, col, 2, size * 1.2));  // 减小大小
      }
      break;
      
    case 3:
      particleCount = 250;
      for (int ring = 0; ring < 3; ring++) {
        float ringSize = size * (1.0 + ring * 0.3);  // 减小环大小
        for (int i = 0; i < particleCount; i++) {
          particles.add(new Particle(x, y, col, 3, ringSize));
        }
      }
      break;
      
    case 4:
      particleCount = 500;
      float burstSize = size * 1.3;  // 减小爆炸大小
      for (int i = 0; i < particleCount; i++) {
        color particleCol = color(
          red(col) + random(-20, 20),
          green(col) + random(-20, 20),
          blue(col) + random(-20, 20)
        );
        particles.add(new Particle(x, y, particleCol, 4, burstSize));
      }
      break;
  }
}

class Firework {
  PVector pos;
  PVector vel;
  color col;
  boolean exploded = false;
  int type;
  float size;
  ArrayList<PVector> trail;
  
  Firework(float x, float y, color c, int t, float s) {
    pos = new PVector(x, y);
    vel = new PVector(random(-1, 1), -random(17, 19));
    col = c;
    type = t;
    size = s;
    trail = new ArrayList<PVector>();
  }
  
  void update() {
    trail.add(new PVector(pos.x, pos.y));
    if (trail.size() > 20) trail.remove(0);
    
    vel.y += 0.3;
    pos.add(vel);
    
    if (pos.y < height * 0.25 || (vel.y >= 0 && !exploded)) {
      exploded = true;
    }
  }
  
  void display() {
    for (int i = 0; i < trail.size(); i++) {
      PVector p = trail.get(i);
      float alpha = map(i, 0, trail.size(), 0, 80);
      float w = map(i, 0, trail.size(), 2, 4);
      stroke(red(col), green(col), blue(col), alpha);
      strokeWeight(w * size);
      point(p.x, p.y);
    }
  }
}

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  color col;
  float alpha = 100;
  float size;
  int type;
  float sparkLife;
  ArrayList<PVector> trail;
  float rotationSpeed;
  float initialSpeed;
  
  Particle(float x, float y, color c, int t, float s) {
    pos = new PVector(x, y);
    col = c;
    type = t;
    size = s;
    sparkLife = random(0.7, 1.0);
    trail = new ArrayList<PVector>();
    rotationSpeed = random(-0.2, 0.2);
    
    float angle = random(TWO_PI);
    initialSpeed = random(5, 10) * s;  // 减小初始速度范围
    
    switch(type) {
      case 0:
        vel = PVector.fromAngle(angle).mult(initialSpeed);
        acc = new PVector(0, 0.15);
        break;
        
      case 1:
        vel = PVector.fromAngle(angle).mult(initialSpeed * 0.6);
        acc = PVector.fromAngle(angle).mult(0.2);
        break;
        
      case 2:
        vel = PVector.fromAngle(angle).mult(initialSpeed * 0.8);
        acc = new PVector(0, 0.2);
        break;
        
      case 3:
        vel = PVector.fromAngle(angle).mult(initialSpeed * 0.7);
        acc = new PVector(0, 0.1);
        rotationSpeed = random(-0.1, 0.1);
        break;
        
      case 4:
        vel = PVector.fromAngle(angle).mult(initialSpeed);
        acc = new PVector(0, 0.12);
        break;
    }
  }
  
  void update() {
    trail.add(new PVector(pos.x, pos.y));
    if (trail.size() > 8) trail.remove(0);
    
    if (type == 1 || type == 3) {
      vel.rotate(rotationSpeed);
    }
    
    vel.add(acc);
    vel.mult(0.97);
    pos.add(vel);
    
    float fadeSpeed = map(type, 0, 4, 0.8, 1.2);
    alpha -= random(0.5, 1.0) * fadeSpeed;
  }
  
  void display() {
    if (alpha <= 0) return;
    
    for (int i = 0; i < trail.size(); i++) {
      PVector p = trail.get(i);
      float trailAlpha = map(i, 0, trail.size(), 0, alpha);
      float w = map(i, 0, trail.size(), 1, 4);
      strokeWeight(w * size * sparkLife);
      stroke(red(col), green(col), blue(col), trailAlpha);
      point(p.x, p.y);
      
      float glowSize = w * size * sparkLife * 1.5;  // 减小发光大小
      strokeWeight(glowSize);
      stroke(red(col), green(col), blue(col), trailAlpha * 0.3);
      point(p.x, p.y);
    }
  }
  
  boolean isDead() {
    return alpha <= 0;
  }
}

class PianoKey {
  float x, y, w, h;
  int index;
  boolean pressed;
  
  PianoKey(float x, float y, float w, float h, int index) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.index = index;
    this.pressed = false;
  }
  
  void display() {
    if (pressed) {
      fill(red(fireworkColors[index % fireworkColors.length]), 
           green(fireworkColors[index % fireworkColors.length]), 
           blue(fireworkColors[index % fireworkColors.length]), 80);
    } else {
      fill(40);
    }
    noStroke();
    rect(x + 1, y, w - 2, h, 6, 6, 0, 0);
    
    if (pressed) {
      blendMode(ADD);
      for (int i = 0; i < 3; i++) {
        fill(red(fireworkColors[index % fireworkColors.length]), 
             green(fireworkColors[index % fireworkColors.length]), 
             blue(fireworkColors[index % fireworkColors.length]), 20 - i * 5);
        rect(x + 1, y, w - 2, h * (1 - i * 0.2), 6, 6, 0, 0);
      }
      blendMode(BLEND);
    }
  }
  
  void press() {
    pressed = true;
  }
  
  void release() {
    pressed = false;
  }
}
