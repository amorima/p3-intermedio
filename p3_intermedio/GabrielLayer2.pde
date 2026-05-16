// Gabriel Layer 2 - LayerCristalIso
//
// Renders a living, breathing isometric crystal that grows and collapses in
// real time, driven entirely by audio input.

// --- Configuração da Grelha Isométrica ---
final int G2_GRID_SIZE = 25; // Tamanho da grelha (25x25)
final float G2_CELL_SCALE = 40; // Tamanho de cada célula isométrica

// --- Cores (consistente com a paleta do projeto) ---
final color G2_COLOR_TOP = #00DCFF;   // Ciano para o topo
final color G2_COLOR_LEFT = #B400FF;  // Violeta para a esquerda
final color G2_COLOR_RIGHT = #FF3C6E; // Magenta para a direita

// --- Estado do Cristal ---
IsoCube[][] g2Grid = new IsoCube[G2_GRID_SIZE][G2_GRID_SIZE];
int g2TargetSize = 1;
float g2CurrentSize = 1;
float g2PrismaFactor = 0; // 0: flat, 1: prisma
boolean g2PrismaMode = false;

// --- Efeitos ---
float g2BeatFlash = 0;

void resetGabriel2() {
  for (int q = 0; q < G2_GRID_SIZE; q++) {
    for (int r = 0; r < G2_GRID_SIZE; r++) {
      g2Grid[q][r] = new IsoCube(q, r);
    }
  }
  g2Grid[G2_GRID_SIZE/2][G2_GRID_SIZE/2].active = true;
  g2Grid[G2_GRID_SIZE/2][G2_GRID_SIZE/2].life = 1.0;
}

void desenharGabriel2(PGraphics pg) {
  if (g2Grid[0][0] == null) {
    resetGabriel2();
  }

  // --- Lógica de Crescimento e Contração ---
  g2TargetSize = 1 + floor(audioAmp * (G2_GRID_SIZE / 2 - 2));
  if (audioBeat) {
    g2TargetSize += 3;
    g2BeatFlash = 1.0;
  }
  g2TargetSize = constrain(g2TargetSize, 1, G2_GRID_SIZE / 2 - 2);

  float growthSpeed = (audioMids * 0.1) + (audioCalm * 0.02);
  g2CurrentSize = lerp(g2CurrentSize, g2TargetSize, growthSpeed);

  // --- Atualizar Estado dos Cubos ---
  int center = G2_GRID_SIZE / 2;
  for (int q = 0; q < G2_GRID_SIZE; q++) {
    for (int r = 0; r < G2_GRID_SIZE; r++) {
      int dist = max(abs(q - center), abs(r - center));
      g2Grid[q][r].update(dist < g2CurrentSize, audioMids, audioStress);
    }
  }
  
  // --- Lógica do Modo Prisma ---
  g2PrismaFactor = lerp(g2PrismaFactor, g2PrismaMode ? 1.0 : 0.0, 0.05);

  // --- Desenho ---
  pg.beginDraw();
  pg.clear(); // Fundo transparente para motion trail
  pg.blendMode(ADD);
  
  pg.translate(pg.width / 2, pg.height / 2);

  // Desenhar todos os cubos
  for (int q = 0; q < G2_GRID_SIZE; q++) {
    for (int r = 0; r < G2_GRID_SIZE; r++) {
      g2Grid[q][r].draw(pg);
    }
  }
  
  // Flash do Beat
  if (g2BeatFlash > 0) {
    pg.fill(255, 255 * g2BeatFlash);
    pg.noStroke();
    pg.ellipse(0, 0, 300 * (1.0 - g2BeatFlash), 300 * (1.0 - g2BeatFlash));
    g2BeatFlash -= 0.08;
  }

  pg.endDraw();
}

// Alternar modo prisma (pode ser chamado via keyPressed no .pde principal)
void g2TogglePrisma() {
  g2PrismaMode = !g2PrismaMode;
}

// Classe para um único cubo isométrico na grelha
class IsoCube {
  int q, r; // Coordenadas axiais
  boolean active = false;
  float life = 0; // 0: morto, 1: vivo

  boolean topOn, leftOn, rightOn;
  float topFlip, leftFlip, rightFlip;

  IsoCube(int q, int r) {
    this.q = q;
    this.r = r;
    // Estado inicial aleatório para as faces
    topOn = random(1) > 0.5;
    leftOn = random(1) > 0.5;
    rightOn = random(1) > 0.5;
    topFlip = random(100);
    leftFlip = random(100);
    rightFlip = random(100);
  }

  void update(boolean shouldBeActive, float mids, float stress) {
    // Suavizar ativação/desativação
    life = lerp(life, shouldBeActive ? 1.0 : 0.0, 0.1);
    if (life < 0.01) {
      active = false;
      return;
    }
    active = true;

    // Lógica de piscar das faces
    float flipRate = mids * 0.2 + stress * 0.1;
    if (random(1) < flipRate) topOn = !topOn;
    if (random(1) < flipRate) leftOn = !leftOn;
    if (random(1) < flipRate) rightOn = !rightOn;
  }

  void draw(PGraphics pg) {
    if (!active) return;

    // Converter coordenadas axiais para cartesianas
    float x = G2_CELL_SCALE * 3.0/2.0 * (q - G2_GRID_SIZE/2);
    float y = G2_CELL_SCALE * sqrt(3) * ((r - G2_GRID_SIZE/2) + (q - G2_GRID_SIZE/2) / 2.0);

    pg.pushMatrix();
    pg.translate(x, y);
    pg.scale(life); // Efeito de aparecer/desaparecer

    float prismaDepth = audioBass * G2_CELL_SCALE * 0.5 * g2PrismaFactor;

    // Face do Topo (Ciano)
    if (topOn) {
      drawFace(pg, G2_COLOR_TOP, 0, prismaDepth);
    }
    // Face da Esquerda (Violeta)
    if (leftOn) {
      drawFace(pg, G2_COLOR_LEFT, -TWO_PI / 3, prismaDepth);
    }
    // Face da Direita (Magenta)
    if (rightOn) {
      drawFace(pg, G2_COLOR_RIGHT, TWO_PI / 3, prismaDepth);
    }

    pg.popMatrix();
  }

  void drawFace(PGraphics pg, color c, float angle, float prisma) {
    pg.pushMatrix();
    pg.rotate(angle);
    
    float s = G2_CELL_SCALE;
    PVector p1 = new PVector(0, -s);
    PVector p2 = new PVector(s * sqrt(3)/2, -s/2);
    PVector p3 = new PVector(0, 0);
    PVector p4 = new PVector(-s * sqrt(3)/2, -s/2);
    PVector center = new PVector(0, -s/2 + prisma);

    pg.noStroke();
    pg.fill(c, 200 * life * (0.5 + audioStress * 0.5));

    if (g2PrismaFactor > 0.01) {
      // Modo Prisma
      pg.beginShape(TRIANGLES);
      pg.vertex(p1.x, p1.y); pg.vertex(p2.x, p2.y); pg.vertex(center.x, center.y);
      pg.vertex(p2.x, p2.y); pg.vertex(p3.x, p3.y); pg.vertex(center.x, center.y);
      pg.vertex(p3.x, p3.y); pg.vertex(p4.x, p4.y); pg.vertex(center.x, center.y);
      pg.vertex(p4.x, p4.y); pg.vertex(p1.x, p1.y); pg.vertex(center.x, center.y);
      pg.endShape();
    } else {
      // Modo Flat
      pg.beginShape();
      pg.vertex(p1.x, p1.y);
      pg.vertex(p2.x, p2.y);
      pg.vertex(p3.x, p3.y);
      pg.vertex(p4.x, p4.y);
      pg.endShape(CLOSE);
    }
    
    pg.popMatrix();
  }
}

