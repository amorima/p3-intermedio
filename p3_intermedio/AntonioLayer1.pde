// Antonio Layer 1 - Círculo de Transição Pura
//
// Um único círculo central que muda de cor de forma suave e contínua,
// percorrendo a paleta global sem qualquer outro elemento visual.

float a1ColorProgress = 0;

// --- Estado da Transição ---
int a1TransitionState = 0;    // 0: parado, 1: expandir, 2: encolher
float a1TransitionFactor = 0; // 0 a 1
int a1TargetLayer = -1;       // Alvo da transição
float a1TransitionSpeed = 0.12; // Mais rápido para ser dinâmico

void resetAntonio1() {
  a1ColorProgress = 0;
  a1TransitionState = 0;
  a1TransitionFactor = 0;
}

void iniciarTransicaoA1(int target) {
  if (a1TransitionState == 0) {
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
      // O p3_intermedio vai mudar o layer e passar para o estado 2
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
  
  // --- Desenho ---
  pg.noStroke();
  pg.fill(currentColor);
  pg.ellipse(0, 0, d, d);
  
  pg.popMatrix();
  pg.endDraw();
}
