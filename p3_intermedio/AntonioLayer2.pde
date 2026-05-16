// Antonio Layer 2 — Sistema K-D Tree (Estilo Raven Kwok Avançado)
//
// Uma estrutura de subdivisão espacial que alterna entre eixos X e Y.
// Contém formas geométricas variadas (círculos, chanfros, módulos técnicos)
// que se encaixam perfeitamente na matriz de retângulos.

final int   A2_MAX_DEPTH    = 10;       
final float A2_MERGE_RATE   = 0.03;    

NodeA2 a2Root;
ArrayList<NodeA2> a2Leaves = new ArrayList<NodeA2>();
PGraphics a2FaceBuffer; 

// Variáveis para rotação smooth
float a2RotX = 0;
float a2RotY = 0;

void resetAntonio2() {
  // Criamos o buffer com a resolução nativa para o 2D ficar perfeito
  a2Root = new NodeA2(0, 0, 1920, 1080, 0, 0); 
  a2FaceBuffer = createGraphics(1920, 1080, P2D);
}

void desenharAntonio2(PGraphics pg) {
  if (a2Root == null) resetAntonio2();

  // 1. Atualizar a lógica do sistema K-D Tree
  a2Leaves.clear();
  a2Root.collectLeaves(a2Leaves);

  if (audioBeat && a2Leaves.size() > 0) {
    int budget = 3 + int(audioBass * 5);
    for (int i = 0; i < budget; i++) {
      NodeA2 c = a2Leaves.get(int(random(a2Leaves.size())));
      if (c.depth < A2_MAX_DEPTH) c.subdivide();
    }
  }

  if (audioStress > 0.6 && random(1) < 0.15) {
    NodeA2 c = a2Leaves.get(int(random(a2Leaves.size())));
    if (c.depth < A2_MAX_DEPTH) c.subdivide();
  }

  a2Root.update();
  a2Root.tryMerge(audioCalm);

  // 2. Renderizar no buffer (sempre na resolução nativa)
  a2FaceBuffer.beginDraw();
  a2FaceBuffer.clear();
  a2Root.draw(a2FaceBuffer);
  a2FaceBuffer.endDraw();

  // 3. Desenho Final
  pg.beginDraw();
  pg.clear();

  if (!a2Mode3D) {
    // MODO 2D: Desenha o buffer 1:1, sem distorção
    pg.image(a2FaceBuffer, 0, 0);
  } else {
    // MODO 3D: Desenha o cubo maior e mais fluido
    pg.pushMatrix();
    pg.translate(pg.width/2, pg.height/2, -400);
    
    // Rotação Smooth (Interpolação)
    float targetRotX = sin(frameCount * 0.005) * 0.4 + audioBass * 0.3;
    float targetRotY = frameCount * 0.01;
    a2RotX = lerp(a2RotX, targetRotX, 0.05);
    a2RotY = lerp(a2RotY, targetRotY, 0.05);
    
    pg.rotateX(a2RotX);
    pg.rotateY(a2RotY);
    
    // Desenha um cubo maior (1000 pixels de lado)
    desenharCubo(pg, 1000);
    
    pg.popMatrix();
  }

  pg.endDraw();
}

void desenharCubo(PGraphics pg, float dim) {
  float half = dim / 2;
  pg.textureMode(NORMAL);
  pg.noStroke();
  
  // Usamos apenas a parte central (quadrada) do buffer para as faces do cubo
  // UVs: (0.23, 0) a (0.76, 1) para manter o aspecto quadrado num buffer 1920x1080
  float uStart = 0.2395; 
  float uEnd = 0.7604;
  
  // Frente
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex(-half, -half,  half, uStart, 0);
  pg.vertex( half, -half,  half, uEnd, 0);
  pg.vertex( half,  half,  half, uEnd, 1);
  pg.vertex(-half,  half,  half, uStart, 1);
  pg.endShape();
  
  // Trás
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex( half, -half, -half, uStart, 0);
  pg.vertex(-half, -half, -half, uEnd, 0);
  pg.vertex(-half,  half, -half, uEnd, 1);
  pg.vertex( half,  half, -half, uStart, 1);
  pg.endShape();
  
  // Cima
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex(-half, -half, -half, uStart, 0);
  pg.vertex( half, -half, -half, uEnd, 0);
  pg.vertex( half, -half,  half, uEnd, 1);
  pg.vertex(-half, -half,  half, uStart, 1);
  pg.endShape();
  
  // Baixo
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex(-half,  half,  half, uStart, 0);
  pg.vertex( half,  half,  half, uEnd, 0);
  pg.vertex( half,  half, -half, uEnd, 1);
  pg.vertex(-half,  half, -half, uStart, 1);
  pg.endShape();
  
  // Direita
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex( half, -half,  half, uStart, 0);
  pg.vertex( half, -half, -half, uEnd, 0);
  pg.vertex( half,  half, -half, uEnd, 1);
  pg.vertex( half,  half,  half, uStart, 1);
  pg.endShape();
  
  // Esquerda
  pg.beginShape(QUADS);
  pg.texture(a2FaceBuffer);
  pg.vertex(-half, -half, -half, uStart, 0);
  pg.vertex(-half, -half,  half, uEnd, 0);
  pg.vertex(-half,  half,  half, uEnd, 1);
  pg.vertex(-half,  half, -half, uStart, 1);
  pg.endShape();
}

class NodeA2 {
  float x, y, w, h;
  int depth;
  int axis; 
  NodeA2 left, right;
  boolean split = false;

  int cellStyle; 
  color cor;
  float life = 1.0;

  NodeA2(float x, float y, float w, float h, int depth, int axis) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.depth = depth;
    this.axis = axis;
    this.cellStyle = int(random(5));
    this.cor = paleta[1 + (int(random(100)) % (paleta.length - 1))];
  }

  void collectLeaves(ArrayList<NodeA2> acc) {
    if (split) {
      left.collectLeaves(acc);
      right.collectLeaves(acc);
    } else {
      acc.add(this);
    }
  }

  void subdivide() {
    if (split || depth >= A2_MAX_DEPTH) return;
    float splitRatio = 0.5 + (noise(depth, frameCount * 0.01) - 0.5) * 0.2;
    
    if (axis == 0) {
      float sw = w * splitRatio;
      left  = new NodeA2(x,      y, sw,     h, depth + 1, 1);
      right = new NodeA2(x + sw, y, w - sw, h, depth + 1, 1);
    } else {
      float sh = h * splitRatio;
      left  = new NodeA2(x, y,      w, sh,     depth + 1, 0);
      right = new NodeA2(x, y + sh, w, h - sh, depth + 1, 0);
    }
    split = true;
  }

  void update() {
    if (split) {
      left.update();
      right.update();
    } else {
      life *= 0.94;
    }
  }

  void tryMerge(float calm) {
    if (!split) return;
    left.tryMerge(calm);
    right.tryMerge(calm);
    if (!left.split && !right.split && random(1) < calm * A2_MERGE_RATE) {
      left = null; right = null; split = false; life = 1.0;
    }
  }

  void draw(PGraphics pg) {
    if (split) {
      left.draw(pg);
      right.draw(pg);
    } else {
      drawLeaf(pg);
    }
  }

  void drawLeaf(PGraphics pg) {
    if (w < 4 || h < 4) return;
    pg.pushMatrix();
    pg.translate(x, y);
    
    switch(cellStyle) {
      case 0: drawStyleCircle(pg); break;
      case 1: drawStyleStadium(pg); break;
      case 2: drawStyleSpeaker(pg); break;
      case 3: drawStyleOrganic(pg); break;
      case 4: drawStyleGrid(pg); break;
    }
    
    pg.popMatrix();
  }

  void drawStyleCircle(PGraphics pg) {
    pg.noStroke();
    pg.fill(cor, 200 + audioBass * 55);
    float d = min(w, h) * (0.8 + audioBass * 0.15);
    pg.ellipse(w*0.5, h*0.5, d, d);
  }

  void drawStyleStadium(PGraphics pg) {
    pg.noFill();
    pg.stroke(cor, 255);
    pg.strokeWeight(1.5 + audioTreble * 3);
    float r = min(w, h) * 0.4;
    pg.rect(2, 2, w-4, h-4, r);
  }

  void drawStyleSpeaker(PGraphics pg) {
    pg.fill(cor, 40 + audioBass * 100);
    pg.noStroke();
    pg.rect(1, 1, w-2, h-2);
    pg.fill(paleta[0]);
    float d = min(w, h) * 0.6;
    pg.ellipse(w*0.5, h*0.5, d, d);
  }

  void drawStyleOrganic(PGraphics pg) {
    pg.fill(cor, 180 + audioBass * 40);
    pg.noStroke();
    float r = min(w, h);
    pg.rect(1, 1, w-2, h-2, r * 0.5);
  }

  void drawStyleGrid(PGraphics pg) {
    pg.stroke(cor, 150);
    pg.strokeWeight(0.5);
    int cols = 3;
    int rows = 3;
    float stepW = w / cols;
    float stepH = h / rows;
    for (int i = 1; i < cols; i++) pg.line(i * stepW, 0, i * stepW, h);
    for (int j = 1; j < rows; j++) pg.line(0, j * stepH, w, j * stepH);
  }
}
