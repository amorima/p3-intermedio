// Antonio Layer 2 — Sistema K-D Tree (Estilo Raven Kwok Avançado)
//
// Uma estrutura de subdivisão espacial que alterna entre eixos X e Y.
// Contém formas geométricas variadas (círculos, chanfros, módulos técnicos)
// que se encaixam perfeitamente na matriz de retângulos.

final int   A2_MAX_DEPTH    = 10;       
final float A2_MERGE_RATE   = 0.03;    

NodeA2 a2Root;
ArrayList<NodeA2> a2Leaves = new ArrayList<NodeA2>();

void resetAntonio2() {
  a2Root = new NodeA2(0, 0, 1920, 1080, 0, 0); 
}

void desenharAntonio2(PGraphics pg) {
  if (a2Root == null) resetAntonio2();

  pg.beginDraw();
  pg.clear();

  a2Leaves.clear();
  a2Root.collectLeaves(a2Leaves);

  // Beat → Subdivisão dinâmica
  if (audioBeat && a2Leaves.size() > 0) {
    int budget = 3 + int(audioBass * 5);
    for (int i = 0; i < budget; i++) {
      NodeA2 c = a2Leaves.get(int(random(a2Leaves.size())));
      if (c.depth < A2_MAX_DEPTH) c.subdivide();
    }
  }

  // Stress → Densidade
  if (audioStress > 0.6 && random(1) < 0.15) {
    NodeA2 c = a2Leaves.get(int(random(a2Leaves.size())));
    if (c.depth < A2_MAX_DEPTH) c.subdivide();
  }

  a2Root.update();
  a2Root.tryMerge(audioCalm);
  a2Root.draw(pg);

  pg.endDraw();
}

class NodeA2 {
  float x, y, w, h;
  int depth;
  int axis; 
  NodeA2 left, right;
  boolean split = false;

  int cellStyle; // 0..4
  color cor;
  float life = 1.0;

  NodeA2(float x, float y, float w, float h, int depth, int axis) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.depth = depth;
    this.axis = axis;
    this.cellStyle = int(random(5)); // Mais estilos
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

  void draw(NodeA2 n) { /* unused helper */ }

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
      case 3: drawStyleChamfer(pg); break;
      case 4: drawStyleGrid(pg); break;
    }
    
    if (life > 0.1) {
      pg.fill(255, life * 150);
      pg.noStroke();
      pg.rect(0, 0, w, h);
    }
    pg.popMatrix();
  }

  // ESTILO 0: Círculo ou Elipse perfeita encaixada
  void drawStyleCircle(PGraphics pg) {
    pg.noStroke();
    pg.fill(cor, 200 + audioBass * 55);
    float d = min(w, h) * (0.8 + audioBass * 0.15);
    pg.ellipse(w*0.5, h*0.5, d, d);
    
    pg.noFill();
    pg.stroke(cor, 100);
    pg.strokeWeight(1);
    pg.rect(2, 2, w-4, h-4);
  }

  // ESTILO 1: Rectângulo arredondado (Stadium)
  void drawStyleStadium(PGraphics pg) {
    pg.noFill();
    pg.stroke(cor, 255);
    pg.strokeWeight(1.5 + audioTreble * 3);
    float r = min(w, h) * 0.4;
    pg.rect(2, 2, w-4, h-4, r);
    
    if (audioStress > 0.5) {
      pg.fill(cor, 80);
      pg.rect(6, 6, w-12, h-12, r * 0.8);
    }
  }

  // ESTILO 2: Módulo "Speaker" (Círculo dentro de Rect)
  void drawStyleSpeaker(PGraphics pg) {
    pg.fill(cor, 40 + audioBass * 100);
    pg.noStroke();
    pg.rect(1, 1, w-2, h-2);
    
    pg.fill(paleta[0]); // Recorte negativo
    float d = min(w, h) * 0.6;
    pg.ellipse(w*0.5, h*0.5, d, d);
    
    pg.noFill();
    pg.stroke(cor, 255);
    pg.strokeWeight(1);
    pg.ellipse(w*0.5, h*0.5, d * (0.7 + audioBass * 0.3), d * (0.7 + audioBass * 0.3));
  }

  // ESTILO 3: Chanfro (Cantos cortados)
  void drawStyleChamfer(PGraphics pg) {
    pg.fill(cor, 180);
    pg.noStroke();
    float c = min(w, h) * 0.2; // tamanho do chanfro
    pg.beginShape();
    pg.vertex(c, 0);
    pg.vertex(w - c, 0);
    pg.vertex(w, c);
    pg.vertex(w, h - c);
    pg.vertex(w - c, h);
    pg.vertex(c, h);
    pg.vertex(0, h - c);
    pg.vertex(0, c);
    pg.endShape(CLOSE);
  }

  // ESTILO 4: Grelha Técnica / Data
  void drawStyleGrid(PGraphics pg) {
    pg.stroke(cor, 150);
    pg.strokeWeight(0.5);
    int cols = 3;
    int rows = 3;
    float stepW = w / cols;
    float stepH = h / rows;
    for (int i = 1; i < cols; i++) pg.line(i * stepW, 0, i * stepW, h);
    for (int j = 1; j < rows; j++) pg.line(0, j * stepH, w, j * stepH);
    
    // Pequenos indicadores nos cruzamentos
    pg.fill(cor);
    pg.noStroke();
    float s = 2 + audioTreble * 4;
    for (int i = 0; i <= cols; i++) {
      for (int j = 0; j <= rows; j++) {
        pg.rect(i * stepW - s*0.5, j * stepH - s*0.5, s, s);
      }
    }
  }
}
