import processing.sound.*;

ArrayList<Firework> fireworks = new ArrayList<Firework>();
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Star3D> stars = new ArrayList<Star3D>();
SoundFile backgroundMusic;
float lastAutoFirework = 0;
float autoFireworkInterval = 2000;
float cameraRotation = 0;

// Color
color[] fireworkColors = {
  color(255, 50, 255),   // 
  color(50, 150, 255),   // 
  color(255, 50, 50),    // 
  color(255, 255, 50),   // 
  color(255, 150, 255),  // 
  color(50, 255, 255),   // 
  color(255, 150, 50),   // 
  color(200, 50, 255)    // 
};

void setup() {
  size(1280, 720, P3D);
  colorMode(RGB, 255, 255, 255, 100);
  background(0);
  
  // 
  for (int i = 0; i < 2000; i++) {
    stars.add(new Star3D());
  }
  
  // 
  backgroundMusic = new SoundFile(this, "/Users/rita/Desktop/Sacred Play Secret Place.mp3");
  backgroundMusic.loop();
}

void draw() {
  // 
  background(0);
  
  // 
  pushMatrix();
  translate(width/2, height/2, 0);
  rotateY(cameraRotation);
  cameraRotation += 0.0005;
  
  for (Star3D star : stars) {
    star.update();
    star.display();
  }
  popMatrix();
  
  // 
  hint(DISABLE_DEPTH_TEST);
  
  // 
  if (millis() - lastAutoFirework > autoFireworkInterval) {
    float x = random(width * 0.1, width * 0.9);
    launchFireworks(x, height);
    lastAutoFirework = millis();
    autoFireworkInterval = random(1000, 3000);
  }
  
  // 
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
  
  // 
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) {
      particles.remove(i);
    }
  }
  blendMode(BLEND);
  hint(ENABLE_DEPTH_TEST);
}

void mousePressed() {
  launchFireworks(mouseX, height);
}

void launchFireworks(float x, float y) {
  int numFireworks = int(random(1, 4));
  for (int i = 0; i < numFireworks; i++) {
    float offset = random(-30, 30);
    float size = random(0.9, 1.5);
    color col = fireworkColors[int(random(fireworkColors.length))];
    fireworks.add(new Firework(x + offset, y, col, int(random(5)), size));
  }
}

class Star3D {
  PVector pos;
  float brightness;
  float twinkleSpeed;
  float size;
  
  Star3D() {
    float radius = random(300, 2000);
    float theta = random(TWO_PI);
    float phi = random(TWO_PI);
    
    pos = new PVector(
      radius * sin(theta) * cos(phi),
      radius * sin(theta) * sin(phi),
      radius * cos(theta)
    );
    
    brightness = random(100, 255);
    twinkleSpeed = random(0.02, 0.05);
    size = random(1, 2);
  }
  
  void update() {
    brightness += sin(frameCount * twinkleSpeed) * 2;
    brightness = constrain(brightness, 100, 255);
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    float dist = pos.mag();
    float alpha = map(dist, 300, 2000, 255, 50);
    
    stroke(255, brightness * alpha / 255);
    strokeWeight(size * (2000 - dist) / 2000);
    point(0, 0, 0);
    
    popMatrix();
  }
}

class Firework {
  PVector pos;
  PVector vel;
  color col;
  boolean exploded;
  int type;
  float size;
  ArrayList<PVector> trail;
  
  Firework(float x, float y, color c, int t, float s) {
    pos = new PVector(x, y);
    vel = new PVector(random(-1, 1), -random(15, 20));
    col = c;
    exploded = false;
    type = t;
    size = s;
    trail = new ArrayList<PVector>();
  }
  
  void update() {
    if (!exploded) {
      vel.y += 0.3;
      pos.add(vel);
      
      trail.add(new PVector(pos.x, pos.y));
      if (trail.size() > 20) trail.remove(0);
      
      if (vel.y >= 0) {
        exploded = true;
      }
    }
  }
  
  void display() {
    for (int i = 0; i < trail.size(); i++) {
      PVector p = trail.get(i);
      float alpha = map(i, 0, trail.size(), 0, 100);
      
      for (int j = 0; j < 3; j++) {
        float w = map(i, 0, trail.size(), 1, 3);
        strokeWeight(w * (j + 1) * size);
        stroke(red(col), green(col), blue(col), alpha / (j + 1));
        point(p.x, p.y);
      }
    }
  }
}
void createExplosion(float x, float y, color baseCol, int type, float size) {
  int particleCount;
  color[] colors = new color[3];
  colors[0] = baseCol;
  colors[1] = color(red(baseCol) * 0.8, green(baseCol) * 0.8, blue(baseCol) * 1.2);
  colors[2] = color(red(baseCol) * 1.2, green(baseCol) * 0.8, blue(baseCol) * 0.8);
  
  switch(type) {
    case 0: // 球形爆炸
      particleCount = 300;
      for (int i = 0; i < particleCount; i++) {
        color col = colors[int(random(3))];
        particles.add(new Particle(x, y, col, 0, size));
      }
      for (int i = 0; i < particleCount/2; i++) {
        color sparkColor = colors[int(random(3))];
        particles.add(new Particle(x, y, sparkColor, 0, size * 0.5));
      }
      break;
      
    case 1: // 环形爆炸
      particleCount = 350;
      for (int ring = 0; ring < 3; ring++) {
        float ringSize = size * (1.0 - ring * 0.2);
        for (int i = 0; i < particleCount/3; i++) {
          color col = colors[int(random(3))];
          particles.add(new Particle(x, y, col, 1, ringSize));
        }
      }
      break;
      
    case 2: // 多点爆炸
      particleCount = 400;
      for (int i = 0; i < 12; i++) {
        float angle = TWO_PI * i / 12;
        float dist = 40 * size;
        float px = x + cos(angle) * dist;
        float py = y + sin(angle) * dist;
        for (int j = 0; j < 30; j++) {
          color col = colors[int(random(3))];
          particles.add(new Particle(px, py, col, 2, size));
        }
      }
      break;
      
    case 3: // 螺旋爆炸
      particleCount = 500;
      for (int i = 0; i < particleCount; i++) {
        color col = colors[int(random(3))];
        particles.add(new Particle(x, y, col, 3, size));
      }
      break;
      
    case 4: // 闪烁爆炸
      particleCount = 600;
      float burstSize = size * 1.3;
      for (int i = 0; i < particleCount; i++) {
        color col = colors[int(random(3))];
        particles.add(new Particle(x, y, col, 4, burstSize));
      }
      break;
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
    initialSpeed = random(5, 10) * s;
    
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
      
      for (int j = 0; j < 3; j++) {
        float w = map(i, 0, trail.size(), 0.5, 2);
        float glowSize = w * size * sparkLife * (j + 1);
        stroke(red(col), green(col), blue(col), trailAlpha / (j + 1));
        strokeWeight(glowSize);
        point(p.x, p.y);
      }
    }
  }
  
  boolean isDead() {
    return alpha <= 0;
  }
}
