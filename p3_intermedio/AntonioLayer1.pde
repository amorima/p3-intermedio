// Antonio Layer 1 - Círculo de Transição Pura
//
// Um único círculo central que muda de cor de forma suave e contínua,
// percorrendo a paleta global sem qualquer outro elemento visual.

float a1ColorProgress = 0;

void resetAntonio1() {
  a1ColorProgress = 0;
}

void desenharAntonio1(PGraphics pg) {
  pg.beginDraw();
  pg.clear();
  
  pg.pushMatrix();
  pg.translate(pg.width/2, pg.height/2);
  
  // --- Lógica de Transição de Cor ---
  // A velocidade da transição é levemente influenciada pelo stress do áudio
  float speed = 0.01 + (audioStress * 0.03);
  a1ColorProgress = (a1ColorProgress + speed) % (paleta.length - 1);
  
  int idx1 = 1 + floor(a1ColorProgress);
  int idx2 = 1 + floor((a1ColorProgress + 1) % (paleta.length - 1));
  float amt = a1ColorProgress - floor(a1ColorProgress);
  
  color currentColor = lerpColor(paleta[idx1], paleta[idx2], amt);
  
  // Tamanho que pulsa suavemente com o bass
  float baseSize = min(pg.width, pg.height) * 0.45;
  float d = baseSize * (0.85 + audioBass * 0.4);
  
  // --- Desenho ---
  pg.noStroke();
  pg.fill(currentColor);
  
  // Apenas um círculo, sem mais nada.
  pg.ellipse(0, 0, d, d);
  
  pg.popMatrix();
  pg.endDraw();
}
