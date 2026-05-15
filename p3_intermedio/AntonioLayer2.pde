// Layer 2 — grid de formas numa "fita" horizontal que scrolla.
// Em vez de spawnar formas aleatórias sobrepostas, há uma grelha fixa de
// células determinísticas (mesma posição -> mesma forma quando passa).
// Bass + stress aceleram a fita; beats dão um "chuto"; calma deixa a fita
// ondular suavemente em vertical.

// --- Parâmetros da fita ---
final int   A2_COLS         = 12;     // colunas visíveis na fita
final int   A2_ROWS         = 5;      // linhas
final float A2_VEL_BASE     = 1.2;    // px/frame em calma absoluta
final float A2_VEL_MAX      = 32;     // px/frame em stress máximo
final float A2_BEAT_KICK    = 14;     // empurrão instantâneo no beat
final float A2_KICK_DECAY   = 0.84;   // decay do empurrão por frame
final float A2_VEL_SMOOTH   = 0.08;   // EMA do alvo de velocidade
final float A2_RIBBON_FRAC  = 0.62;   // fracção da altura ocupada pela fita
final float A2_WAVE_AMP     = 70;     // amplitude vertical da ondulação (px)
final float A2_PARALLAX     = 0.18;   // diferença de velocidade entre linhas

// --- Estado ---
float a2Scroll = 0;     // offset acumulado
float a2Vel = 0;        // velocidade smoothed
float a2Kick = 0;       // boost decaying do último beat

void resetAntonio2() {
  a2Scroll = 0;
  a2Vel = 0;
  a2Kick = 0;
}

void desenharAntonio2(PGraphics pg) {
  pg.beginDraw();
  pg.clear();

  // --- Velocidade alvo a partir do áudio ---
  float energy = constrain(audioBass * 0.55 + audioStress * 0.45, 0, 1);
  float velTarget = lerp(A2_VEL_BASE, A2_VEL_MAX, energy);

  if (audioBeat) a2Kick = A2_BEAT_KICK + audioBass * 22;
  a2Kick *= A2_KICK_DECAY;

  a2Vel += ((velTarget + a2Kick) - a2Vel) * A2_VEL_SMOOTH;
  a2Scroll += a2Vel;

  // --- Geometria da fita ---
  float cellW = pg.width / (float) A2_COLS;
  float ribbonH = pg.height * A2_RIBBON_FRAC;
  float ribbonY = (pg.height - ribbonH) * 0.5;
  float cellH = ribbonH / A2_ROWS;

  // --- Iteração das células ---
  for (int row = 0; row < A2_ROWS; row++) {
    // parallax: cada linha scrolla um pouco diferente
    float rowFactor = 1.0 + (row - A2_ROWS * 0.5) * A2_PARALLAX;
    float rowScroll = a2Scroll * rowFactor;

    int scrollCells = (int) floor(rowScroll / cellW);
    float scrollPx = rowScroll - scrollCells * cellW;

    for (int col = -1; col <= A2_COLS; col++) {
      int absCol = scrollCells + col;
      int idx = hashCellA2(absCol, row);

      float cx = col * cellW - scrollPx + cellW * 0.5;
      float cy = ribbonY + row * cellH + cellH * 0.5;

      // Ondulação vertical da fita — mais forte em calma
      float wave = sin(absCol * 0.35 + frameCount * 0.018 + row * 0.6)
                 * A2_WAVE_AMP * (0.25 + audioCalm * 0.9);
      cy += wave;

      desenharCelulaA2(pg, cx, cy, cellW, cellH, idx);
    }
  }

  pg.endDraw();
}

// Hash determinístico para uma célula (col, row) — 32-bit mix
int hashCellA2(int col, int row) {
  int h = col * 73856093 ^ row * 19349663;
  h ^= (h >>> 16);
  return h;
}

void desenharCelulaA2(PGraphics pg, float cx, float cy, float cellW, float cellH, int idx) {
  float s = min(cellW, cellH) * 0.36;
  int kind = (idx & 0x7FFFFFFF) % 4;
  int colorIdx = 1 + ((idx >>> 4) & 0x7FFFFFFF) % (paleta.length - 1);

  // Fase per-cell estável — usada nas animações sub-forma
  float phase = ((idx >>> 8) & 0xFF) / 255.0 * TWO_PI;

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

  pg.noFill();
  pg.stroke(c, 230);
  pg.strokeWeight(1 + audioTreble * 3 + audioBass * 1.5);

  // Rotação lenta partilhada (cada célula com fase distinta via idx)
  float rotBase = idx * 0.0001 + frameCount * 0.004 * (0.6 + audioMids * 0.8);

  switch (kind) {
    case 0: {  // quadrado pulsante + X
      pg.rotate(rotBase);
      float scale0 = 1.0 + audioBass * 0.35 + sin(phase + frameCount * 0.04) * 0.05;
      float ss = s * scale0;
      pg.rect(-ss, -ss, ss * 2, ss * 2);
      pg.line(-ss, -ss,  ss,  ss);
      pg.line( ss, -ss, -ss,  ss);
      break;
    }

    case 1: {  // círculos concêntricos — núcleo pulsa com bass (intocado)
      pg.rotate(rotBase * 0.3);
      pg.ellipse(0, 0, s * 2, s * 2);
      float inner = s * (0.25 + audioBass * 0.55);
      pg.ellipse(0, 0, inner * 2, inner * 2);
      break;
    }

    case 2: {  // linhas-scanline dentro de quadrado — linhas deslizam
      pg.rect(-s, -s, s * 2, s * 2);
      int lines = 4 + int(audioTreble * 5);
      float stride = (s * 2) / lines;
      float scroll = (frameCount * (0.5 + audioMids * 2.0) + phase * 50.0) % stride;
      if (scroll < 0) scroll += stride;
      for (int i = -1; i <= lines + 1; i++) {
        float t = -s + i * stride - scroll;
        if (t < -s || t > s) continue;
        pg.line(-s, t, s, t);
      }
      break;
    }

    case 3: {  // polígono que respira — vértices oscilam independentemente
      pg.rotate(rotBase * 0.5);
      int n = 6;
      pg.beginShape();
      for (int i = 0; i < n; i++) {
        float a = TWO_PI * i / n - HALF_PI;
        float breath = 1.0 + sin(phase + frameCount * 0.05 + i * TWO_PI / n)
                           * (0.15 + audioBass * 0.30);
        pg.vertex(cos(a) * s * breath, sin(a) * s * breath);
      }
      pg.endShape(CLOSE);
      break;
    }
  }

  pg.popMatrix();
}
