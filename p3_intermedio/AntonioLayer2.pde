// fazer algo semlehante ao https://ravenkwok.com/189d0/
//
// Grid de formas numa "fita" horizontal que scrolla. Em vez de spawnar formas
// aleatórias sobrepostas, há uma grelha fixa de células. Cada célula tem uma
// forma determinística (mesma posição -> mesma forma quando passa).
// Bass + stress aceleram a fita; beats dão um "chuto"; calma deixa a fita
// ondular suavemente em vertical.

// Paleta — temporariamente declarada aqui até o cross-tab ficar 100% no novo
// caminho do sketch. Depois move-se de volta para o p3_intermedio.pde.
color[] paleta = {
  #0A0A1E,   // fundo profundo
  #00DCFF,   // ciano
  #FF3C6E,   // magenta quente
  #B400FF,   // violeta
  #FFDC00,   // amarelo
  #FFFFFF    // branco
};

// --- Parâmetros da fita ---
final int   A1_COLS         = 12;     // colunas visíveis na fita
final int   A1_ROWS         = 5;      // linhas
final float A1_VEL_BASE     = 1.2;    // px/frame em calma absoluta
final float A1_VEL_MAX      = 32;     // px/frame em stress máximo
final float A1_BEAT_KICK    = 14;     // empurrão instantâneo no beat
final float A1_KICK_DECAY   = 0.84;   // decay do empurrão por frame
final float A1_VEL_SMOOTH   = 0.08;   // EMA do alvo de velocidade
final float A1_RIBBON_FRAC  = 0.62;   // fracção da altura ocupada pela fita
final float A1_WAVE_AMP     = 70;     // amplitude vertical da ondulação (px)
final float A1_PARALLAX     = 0.18;   // diferença de velocidade entre linhas

// --- Estado ---
float a1Scroll = 0;     // offset acumulado
float a1Vel = 0;        // velocidade smoothed
float a1Kick = 0;       // boost decaying do último beat

void resetAntonio2() {
  a1Scroll = 0;
  a1Vel = 0;
  a1Kick = 0;
}

void desenharAntonio2(PGraphics pg) {
  pg.beginDraw();
  pg.clear();

  // --- Velocidade alvo a partir do áudio ---
  float energy = constrain(audioBass * 0.55 + audioStress * 0.45, 0, 1);
  float velTarget = lerp(A1_VEL_BASE, A1_VEL_MAX, energy);

  if (audioBeat) a1Kick = A1_BEAT_KICK + audioBass * 22;
  a1Kick *= A1_KICK_DECAY;

  a1Vel += ((velTarget + a1Kick) - a1Vel) * A1_VEL_SMOOTH;
  a1Scroll += a1Vel;

  // --- Geometria da fita ---
  float cellW = pg.width / (float) A1_COLS;
  float ribbonH = pg.height * A1_RIBBON_FRAC;
  float ribbonY = (pg.height - ribbonH) * 0.5;
  float cellH = ribbonH / A1_ROWS;

  // --- Bordas subtis da fita (ajuda a "ler" a metáfora) ---
  pg.noFill();
  pg.stroke(255, 30);
  pg.strokeWeight(1);
  // pg.line(0, ribbonY, pg.width, ribbonY);
  // pg.line(0, ribbonY + ribbonH, pg.width, ribbonY + ribbonH);

  // --- Iteração das células ---
  for (int row = 0; row < A1_ROWS; row++) {
    // parallax: cada linha scrolla um pouco diferente
    float rowFactor = 1.0 + (row - A1_ROWS * 0.5) * A1_PARALLAX;
    float rowScroll = a1Scroll * rowFactor;

    int scrollCells = (int) floor(rowScroll / cellW);
    float scrollPx = rowScroll - scrollCells * cellW;

    for (int col = -1; col <= A1_COLS; col++) {
      int absCol = scrollCells + col;
      int idx = hashCell(absCol, row);

      float cx = col * cellW - scrollPx + cellW * 0.5;
      float cy = ribbonY + row * cellH + cellH * 0.5;

      // Ondulação vertical da fita — mais forte em calma
      float wave = sin(absCol * 0.35 + frameCount * 0.018 + row * 0.6)
                 * A1_WAVE_AMP * (0.25 + audioCalm * 0.9);
      cy += wave;

      desenharCelula(pg, cx, cy, cellW, cellH, idx);
    }
  }

  pg.endDraw();
}

// Hash determinístico para uma célula (col, row) — 32-bit mix
int hashCell(int col, int row) {
  int h = col * 73856093 ^ row * 19349663;
  h ^= (h >>> 16);
  return h;
}

void desenharCelula(PGraphics pg, float cx, float cy, float cellW, float cellH, int idx) {
  float s = min(cellW, cellH) * 0.36;
  int kind = (idx & 0x7FFFFFFF) % 4;
  int colorIdx = 1 + ((idx >>> 4) & 0x7FFFFFFF) % (paleta.length - 1);

  // Cor base + desvio por pitch
  color base = paleta[colorIdx];
  float pitchShift = map(audioDominantBin, 0, FFT_BANDS, -40, 40);
  color c = color(
    constrain(red(base)   + pitchShift,       0, 255),
    constrain(green(base) - pitchShift * 0.5, 0, 255),
    constrain(blue(base)  + pitchShift * 0.3, 0, 255)
  );

  pg.pushMatrix();
  pg.translate(cx, cy);
  // Rotação animada pelo mids + offset por célula (cada uma com fase distinta)
  pg.rotate(idx * 0.0001 + audioMids * 0.8 + frameCount * 0.006 * (1 + audioMids * 2));

  pg.noFill();
  pg.stroke(c, 230);
  pg.strokeWeight(1 + audioTreble * 4 + audioBass * 1.8);

  switch (kind) {
    case 0:  // quadrado com aspas em X
      pg.rect(-s, -s, s * 2, s * 2);
      pg.line(-s, -s,  s,  s);
      pg.line( s, -s, -s,  s);
      break;

    case 1:  // círculos concêntricos — o interior pulsa com bass
      pg.ellipse(0, 0, s * 2, s * 2);
      float inner = s * (0.25 + audioBass * 0.55);
      pg.ellipse(0, 0, inner * 2, inner * 2);
      break;

    case 2:  // grelha de linhas paralelas — densidade com treble
      int lines = 3 + int(audioTreble * 5);
      for (int i = 0; i < lines; i++) {
        float t = map(i, 0, max(lines - 1, 1), -s, s);
        pg.line(-s, t, s, t);
      }
      break;

    case 3:  // polígono regular — n-lados varia com mids
      pg.beginShape();
      int n = 5 + int(audioMids * 3);
      for (int i = 0; i < n; i++) {
        float a = TWO_PI * i / n - HALF_PI;
        pg.vertex(cos(a) * s, sin(a) * s);
      }
      pg.endShape(CLOSE);
      break;
  }

  pg.popMatrix();
}
