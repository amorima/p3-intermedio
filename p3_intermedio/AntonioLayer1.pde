// Antonio Layer 1 - Círculo Central Opaco
//
// Um único círculo grande no centro que pulsa com o bass,
// inspirado no núcleo do efeito Quad-tree.

float a1Rotation = 0;

void resetAntonio1() {
  a1Rotation = 0;
}

void desenharAntonio1(PGraphics pg) {
  pg.beginDraw();
  pg.clear();

  pg.pushMatrix();
  pg.translate(pg.width/2, pg.height/2);

  // Rotação lenta influenciada pelos médios
  a1Rotation += 0.01 * (1.0 + audioMids);
  pg.rotate(a1Rotation);

  // Tamanho base (40% da menor dimensão) + pulsação via bass
  float baseSize = min(pg.width, pg.height) * 0.4;
  float pulse = baseSize * (0.8 + audioBass * 0.6);

  // Cor: Usamos uma cor da paleta (ex: ciano ou magenta)
  // Deslocamos ligeiramente com o pitch para dar vida
  int colIdx = 1 + (frameCount / 100) % (paleta.length - 1);
  color baseCol = paleta[colIdx];
  float pitchShift = map(audioDominantBin, 0, FFT_BANDS, -30, 30);

  pg.fill(
    constrain(red(baseCol)   + pitchShift, 0, 255),
    constrain(green(baseCol) - pitchShift, 0, 255),
    constrain(blue(baseCol)  + pitchShift, 0, 255)
    );

  pg.noStroke();

  // Desenha o círculo principal opaco
  pg.ellipse(0, 0, pulse, pulse);

  // // Opcional: Um pequeno detalhe interno (stroke) para dar profundidade
  // pg.noFill();
  // pg.stroke(255, 150);
  // pg.strokeWeight(2 + audioTreble * 4);
  // pg.ellipse(0, 0, pulse * 0.9, pulse * 0.9);

  pg.popMatrix();

  pg.endDraw();
}

