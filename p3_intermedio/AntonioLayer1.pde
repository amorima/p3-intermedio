// Antonio Layer 1 - Círculo de Transição Pura
//
// Um único círculo central que muda de cor de forma suave e contínua,
// percorrendo a paleta global sem qualquer outro elemento visual.

float a1ColorProgress = 0;
color a1LogoCurrentColor = color(255);

// --- Estado da Transição ---
int a1TransitionState = 0;    // 0: parado, 1: expandir, 2: encolher
float a1TransitionFactor = 0; // 0 a 1
int a1TargetLayer = -1;       // Alvo da transição
float a1TransitionSpeed = 0.12; // Mais rápido para ser dinâmico

void resetAntonio1() {
  a1ColorProgress = 0;
  a1TransitionState = 0;
  a1TransitionFactor = 0;
  a1LogoCurrentColor = color(255);
}

void iniciarTransicaoA1(int target) {
  if (a1TransitionState == 0) {
    target = constrain(target, -1, 5);
    a1TransitionState = 1; // Começa a expandir
    a1TransitionFactor = 0;
    a1TargetLayer = target;
  }
}

void desenharAntonio1(PGraphics pg) {
  pg.beginDraw();
  pg.clear();
  
  pg.pushMatrix();
  pg.translate(pg.width/2, pg.height/2);
  
  // --- Lógica de Transição de Cor ---
  float speed = 0.01 + (audioStress * 0.03);
  a1ColorProgress = (a1ColorProgress + speed) % (paleta.length - 1);
  
  int idx1 = 1 + floor(a1ColorProgress);
  int idx2 = 1 + floor((a1ColorProgress + 1) % (paleta.length - 1));
  float amt = a1ColorProgress - floor(a1ColorProgress);
  
  color currentColor = lerpColor(paleta[idx1], paleta[idx2], amt);
  
  // Tamanho base (pulsação normal)
  float baseSize = min(pg.width, pg.height) * 0.45;
  float dNormal = baseSize * (0.85 + audioBass * 0.4);
  float d = dNormal;

  // --- Máquina de Estados da Transição ---
  if (a1TransitionState == 1) {
    // FASE 1: Expandir
    a1TransitionFactor += a1TransitionSpeed;
    if (a1TransitionFactor >= 1.0) {
      a1TransitionFactor = 1.0;
    }
    float maxD = dist(0, 0, pg.width, pg.height) * 2.1; 
    d = lerp(dNormal, maxD, a1TransitionFactor);
    
  } else if (a1TransitionState == 2) {
    // FASE 2: Encolher
    a1TransitionFactor -= a1TransitionSpeed;
    if (a1TransitionFactor <= 0) {
      a1TransitionFactor = 0;
      a1TransitionState = 0; // Terminou
    }
    float maxD = dist(0, 0, pg.width, pg.height) * 2.1; 
    d = lerp(dNormal, maxD, a1TransitionFactor);
  }
  
  // --- Desenho do Círculo ---
  pg.noStroke();
  pg.fill(currentColor);
  pg.ellipse(0, 0, d, d);

  // --- Desenho do Logo TDW (Manual e Dinâmico) ---
  
  // 1. Lógica de Cor Oposta (Contraste Total)
  // Calculamos a cor complementar/oposta para garantir contraste máximo
  float r = red(currentColor);
  float g = green(currentColor);
  float b = blue(currentColor);
  color oppositeColor = color(255 - r, 255 - g, 255 - b);
  
  // Suavizamos a transição da cor do logo
  a1LogoCurrentColor = lerpColor(a1LogoCurrentColor, oppositeColor, 0.15);

  // 2. Cálculo de Tamanho (Mantendo a escala segura de 35%)
  float minCircleD = baseSize * 0.85; 
  float targetH = minCircleD * 0.35; 
  if (a1TransitionState != 0) targetH *= (1.0 + a1TransitionFactor * 0.2);

  pg.pushMatrix();
  float logoOriginalW = 236.0;
  float logoOriginalH = 92.1851;
  float sc = targetH / logoOriginalH;
  pg.scale(sc);
  pg.translate(-logoOriginalW/2, -logoOriginalH/2);
  
  pg.fill(a1LogoCurrentColor);
  pg.noStroke();
  
  desenharT(pg);
  desenharD(pg);
  desenharW(pg);
  
  pg.popMatrix();
  
  pg.popMatrix();
  pg.endDraw();
}

void desenharT(PGraphics pg) {
  pg.beginShape();
  pg.vertex(0, 37.1851); pg.vertex(10, 37.1851); pg.vertex(10, 10.5688); pg.vertex(27.2641, 10.5688);
  pg.vertex(27.2641, 81.4679); pg.vertex(5.0256, 81.4679); pg.vertex(5.0256, 92.1851); pg.vertex(58.31, 92.1851);
  pg.vertex(58.31, 81.0276); pg.vertex(37, 81.0276); pg.vertex(37, 10.5688); pg.vertex(53.6862, 10.5688);
  pg.vertex(53.6862, 37.1851); pg.vertex(64, 37.1851); pg.vertex(64, 0); pg.vertex(0, 0);
  pg.endShape(CLOSE);
}

void desenharD(PGraphics pg) {
  pg.beginShape();
  // Exterior
  pg.vertex(119.5573, 7.2549);
  pg.bezierVertex(119.5573 - 6.5575, 7.2549 - 4.8436, 119.5573 - 14.5978, 0, 119.5573 - 22.7501, 0);
  pg.vertex(77.6862, 0);
  pg.vertex(77.6862, 92.1851);
  pg.vertex(96.9847, 92.1851);
  pg.bezierVertex(96.9847 + 7.5922, 92.1851, 96.9847 + 15.1021, 90.1175, 96.9847 + 21.4064, 85.8869);
  pg.bezierVertex(118.3911 + 15.102, 85.8869 - 10.1344, 118.3911 + 17.6089, 58.4844, 118.3911 + 17.6089, 46.1851);
  pg.bezierVertex(136, 34.4742, 136 - 2.3767, 17.6445, 136 - 16.4427, 7.2549);
  
  // Interior
  pg.beginContour();
  pg.vertex(113.715, 77.2355);
  pg.bezierVertex(113.715 - 4.0613, 77.2355 + 3.3019, 113.715 - 8.8992, 82.1512, 113.715 - 13.7902, 82.1512);
  pg.vertex(87.4924, 82.1512);
  pg.vertex(87.4924, 10.2011);
  pg.vertex(99.8104, 10.2011);
  pg.bezierVertex(99.8104 + 5.2518, 10.2011, 99.8104 + 10.4315, 12.0832, 99.8104 + 14.6559, 15.8636);
  pg.bezierVertex(114.4663 + 9.0615, 15.8636 + 8.1089, 114.4663 + 10.5926, 37.1082, 114.4663 + 10.5926, 46.2484);
  pg.bezierVertex(125.0589, 55.8479, 125.0589 - 1.615, 69.3257, 125.0589 - 11.3439, 77.2355);
  pg.endContour();
  pg.endShape(CLOSE);
}

void desenharW(PGraphics pg) {
  pg.beginShape();
  pg.vertex(150, 0.1851); pg.vertex(161, 0.1851); pg.vertex(161, 66.4955); pg.vertex(200, 32.1851); 
  pg.vertex(200, 71.5597); pg.vertex(229, 50.1851); pg.vertex(236, 58.1851); pg.vertex(191.3008, 92.1851); 
  pg.vertex(191.3008, 54.1851); pg.vertex(150, 92.1851);
  pg.endShape(CLOSE);
}
