// Gabriel Layer 2 - LayerCristalIso
//
// Renders a living, breathing isometric crystal that grows and collapses in
// real time, driven entirely by audio input.

// =========================================================================
// --- CONFIGURAÇÃO DE FINE-TUNING ---
// =========================================================================

// --- Grelha e Tamanho ---
final int   G2_GRID_SIZE        = 30;    // Resolução da grelha (células). Mais alto = mais detalhe, mais pesado.
final float G2_CELL_SCALE       = 40;    // Tamanho base de cada cubo isométrico em pixels.
final int   G2_MIN_SIZE         = 1;     // Tamanho mínimo do cristal (núcleo central).
final int   G2_MAX_SIZE_FACTOR  = 2;     // O tamanho máx é GRID_SIZE / MAX_SIZE_FACTOR. 2 = metade, 3 = um terço.

// --- Cores e Intensidade ---
final color G2_COLOR_TOP          = #00DCFF; // Cor para a face de topo dos cubos.
final color G2_COLOR_LEFT         = #B400FF; // Cor para a face esquerda.
final color G2_COLOR_RIGHT        = #FF3C6E; // Cor para a face direita.
final float G2_BASE_ALPHA         = 200;   // Transparência base das faces (0-255).
final float G2_STRESS_ALPHA_BOOST = 0.5;   // Boost de alpha com 'audioStress' (0.0 a 1.0). 0.5 = 50% do stress é adicionado.

// --- Reatividade ao Áudio ---
final float G2_GROWTH_SPEED_MIDS  = 0.1;   // Velocidade de crescimento com 'audioMids'.
final float G2_SHRINK_SPEED_CALM  = 0.02;  // Velocidade de contração com 'audioCalm'.
final float G2_FACE_FLIP_RATE_MIDS  = 0.2;   // Taxa de piscar das faces com 'audioMids'.
final float G2_FACE_FLIP_RATE_STRESS= 0.1;   // Taxa de piscar adicional com 'audioStress'.

// --- Efeito de Beat ---
final int   G2_BEAT_SIZE_BOOST    = 3;     // Impulso de tamanho instantâneo no beat.
final float G2_BEAT_FLASH_DECAY   = 0.08;  // Velocidade com que o flash do beat desaparece.
final float G2_BEAT_FLASH_SCALE   = 300;   // Tamanho máximo do flash do beat.

// --- Modo Prisma ---
final float G2_PRISMA_DEPTH_BASS  = 0.5;   // Profundidade do relevo no modo prisma, multiplicada pelo 'audioBass'.
final float G2_PRISMA_TRANSITION  = 0.05;  // Velocidade da transição para o modo prisma.

// =========================================================================
// --- ESTADO INTERNO DO LAYER (não mexer) ---
// =========================================================================
IsoCube[][] g2Grid = new IsoCube[G2_GRID_SIZE][G2_GRID_SIZE];
int g2TargetSize = G2_MIN_SIZE;
float g2CurrentSize = G2_MIN_SIZE;
float g2PrismaFactor = 0; // 0: flat, 1: prisma
boolean g2PrismaMode = false;
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
  int maxSize = G2_GRID_SIZE / G2_MAX_SIZE_FACTOR - 2;
  g2TargetSize = G2_MIN_SIZE + floor(audioAmp * maxSize);
  if (audioBeat) {
    g2TargetSize += G2_BEAT_SIZE_BOOST;
    g2BeatFlash = 1.0;
  }
  g2TargetSize = constrain(g2TargetSize, G2_MIN_SIZE, maxSize);

  float growthSpeed = (audioMids * G2_GROWTH_SPEED_MIDS) + (audioCalm * G2_SHRINK_SPEED_CALM);
  g2CurrentSize = lerp(g2CurrentSize, g2TargetSize, growthSpeed);

  // --- Atualizar Estado dos Cubos ---
  int center = G2_GRID_SIZE / 2;
  for (int q = 0; q < G2_GRID_SIZE; q++) {
    for (int r = 0; r < G2_GRID_SIZE; r++) {
      int dist = hexDistance(q, r, center, center);
      g2Grid[q][r].update(dist < g2CurrentSize, audioMids, audioStress);
    }
  }
  
  // --- Lógica do Modo Prisma ---
  g2PrismaFactor = lerp(g2PrismaFactor, g2PrismaMode ? 1.0 : 0.0, G2_PRISMA_TRANSITION);

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
    pg.ellipse(0, 0, G2_BEAT_FLASH_SCALE * (1.0 - g2BeatFlash), G2_BEAT_FLASH_SCALE * (1.0 - g2BeatFlash));
    g2BeatFlash -= G2_BEAT_FLASH_DECAY;
  }

  pg.endDraw();
}

// Calcula a distância hexagonal (distância de Manhattan em coordenadas cúbicas)
int hexDistance(int q1, int r1, int q2, int r2) {
  int dq = abs(q1 - q2);
  int dr = abs(r1 - r2);
  int ds = abs((-q1 - r1) - (-q2 - r2));
  return (dq + dr + ds) / 2;
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
    float flipRate = mids * G2_FACE_FLIP_RATE_MIDS + stress * G2_FACE_FLIP_RATE_STRESS;
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

    float prismaDepth = audioBass * G2_CELL_SCALE * G2_PRISMA_DEPTH_BASS * g2PrismaFactor;

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
    float alpha = G2_BASE_ALPHA * life * (1.0 - G2_STRESS_ALPHA_BOOST + audioStress * G2_STRESS_ALPHA_BOOST);
    pg.fill(c, alpha);

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

