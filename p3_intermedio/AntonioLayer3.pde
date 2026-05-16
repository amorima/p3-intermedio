// Layer 3 — grid de formas numa "fita" horizontal que scrolla.
// Em vez de spawnar formas aleatórias sobrepostas, há uma grelha fixa de
// células determinísticas (mesma posição -> mesma forma quando passa).
// Bass + stress aceleram a fita; beats dão um "chuto"; calma deixa a fita
// ondular suavemente em vertical.

// --- Parâmetros da fita ---
final int   A3_COLS         = 12;     // colunas visíveis na fita
final int   A3_ROWS         = 5;      // linhas
final float A3_VEL_BASE     = 1.2;    // px/frame em calma absoluta
final float A3_VEL_MAX      = 32;     // px/frame em stress máximo
final float A3_BEAT_KICK    = 14;     // empurrão instantâneo no beat
final float A3_KICK_DECAY   = 0.84;   // decay do empurrão por frame
final float A3_VEL_SMOOTH   = 0.08;   // EMA do alvo de velocidade
final float A3_RIBBON_FRAC  = 0.62;   // fracção da altura ocupada pela fita
final float A3_WAVE_AMP     = 70;     // amplitude vertical da ondulação (px)
final float A3_PARALLAX     = 0.18;   // diferença de velocidade entre linhas

// --- Estado ---
float a3Scroll = 0;     // offset acumulado
float a3Vel = 0;        // velocidade smoothed
float a3Kick = 0;       // boost decaying do último beat

void resetAntonio3() {
  a3Scroll = 0;
  a3Vel = 0;
  a3Kick = 0;
}

void desenharAntonio3(PGraphics pg) {
  pg.beginDraw();
  pg.clear();

  // --- Velocidade alvo a partir do áudio ---
  float energy = constrain(audioBass * 0.55 + audioStress * 0.45, 0, 1);
  float velTarget = lerp(A3_VEL_BASE, A3_VEL_MAX, energy);

  if (audioBeat) a3Kick = A3_BEAT_KICK + audioBass * 22;
  a3Kick *= A3_KICK_DECAY;

  a3Vel += ((velTarget + a3Kick) - a3Vel) * A3_VEL_SMOOTH;
  a3Scroll += a3Vel;

  // --- Geometria da fita ---
  float cellW = pg.width / (float) A3_COLS;
  float ribbonH = pg.height * A3_RIBBON_FRAC;
  float ribbonY = (pg.height - ribbonH) * 0.5;
  float cellH = ribbonH / A3_ROWS;

  // --- Iteração das células ---
  for (int row = 0; row < A3_ROWS; row++) {
    // parallax: cada linha scrolla um pouco diferente
    float rowFactor = 1.0 + (row - A3_ROWS * 0.5) * A3_PARALLAX;
    float rowScroll = a3Scroll * rowFactor;

    int scrollCells = (int) floor(rowScroll / cellW);
    float scrollPx = rowScroll - scrollCells * cellW;

    for (int col = -1; col <= A3_COLS; col++) {
      int absCol = scrollCells + col;
      int idx = hashCellA3(absCol, row);

      float cx = col * cellW - scrollPx + cellW * 0.5;
      float cy = ribbonY + row * cellH + cellH * 0.5;

      // Ondulação vertical da fita — mais forte em calma
      float wave = sin(absCol * 0.35 + frameCount * 0.018 + row * 0.6)
                 * A3_WAVE_AMP * (0.25 + audioCalm * 0.9);
      cy += wave;

      // --- Convergência para o centro horizontal ---
      // Faz com que as linhas se aproximem do centro vertical à medida que chegam ao centro do ecrã
      float centerX = pg.width * 0.5;
      float centerY = ribbonY + ribbonH * 0.5;
      float distToCenterX = abs(cx - centerX);
      
      // Fator de convergência: 1.0 no centro (totalmente convergido), 0.0 longe
      float convergeFactor = map(distToCenterX, 0, pg.width * 0.45, 1.0, 0.0);
      convergeFactor = constrain(convergeFactor, 0, 1.0);
      // Aplicar easing para ser mais suave (opcional, mas fica melhor)
      convergeFactor = pow(convergeFactor, 1.5);

      // Interpolar a posição Y atual para o centro do ribbon
      cy = lerp(cy, centerY, convergeFactor * 0.85); // 0.85 para não colapsar totalmente se preferires

      desenharCelulaA3(pg, cx, cy, cellW, cellH, idx);
    }
  }

  pg.endDraw();
}

// Hash determinístico para uma célula (col, row) — 32-bit mix
int hashCellA3(int col, int row) {
  int h = col * 73856093 ^ row * 19349663;
  h ^= (h >>> 16);
  return h;
}

void desenharCelulaA3(PGraphics pg, float cx, float cy, float cellW, float cellH, int idx) {
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

  // --- Efeito de escala por proximidade ao centro ---
  // Quanto mais perto do (width/2, height/2), mais pequeno.
  float d = dist(cx, cy, pg.width * 0.5, pg.height * 0.5);
  // Definimos que a "distância de normalização" é 40% da largura.
  // Perto de 0px de distância -> escala 0.15; a partir de ~40% da largura -> escala 1.0
  float sFactor = map(d, 0, pg.width * 0.4, 0.15, 1.0);
  sFactor = constrain(sFactor, 0.15, 1.0);
  pg.scale(sFactor);

  pg.noFill();
  pg.stroke(c, 230);
  pg.strokeWeight(1 + audioTreble * 3 + audioBass * 1.5);

  // Rotação lenta partilhada (cada célula com fase distinta via idx)
  float rotBase = idx * 0.0001 + frameCount * 0.004 * (0.6 + audioMids * 0.8);

  switch (kind) {
    case 0: {  // quadrados concêntricos — moldura estática + 2 rodam em sentidos opostos
      // Exterior — estático, ancora a célula
      pg.rect(-s, -s, s * 2, s * 2);

      // Médio — roda no sentido do rotBase da célula
      pg.pushMatrix();
      pg.rotate(rotBase * 0.7);
      float mid = s * 0.65;
      pg.rect(-mid, -mid, mid * 2, mid * 2);
      pg.popMatrix();

      // Interior — roda em sentido contrário, pulsa com bass
      pg.pushMatrix();
      pg.rotate(-rotBase * 1.2);
      float inner0 = s * (0.32 + audioBass * 0.18);
      pg.rect(-inner0, -inner0, inner0 * 2, inner0 * 2);
      pg.popMatrix();
      break;
    }

    case 1: {  // círculos concêntricos — núcleo pulsa com bass (intocado)
      pg.rotate(rotBase * 0.3);
      pg.ellipse(0, 0, s * 2, s * 2);
      float inner = s * (0.25 + audioBass * 0.55);
      pg.ellipse(0, 0, inner * 2, inner * 2);
      break;
    }

    case 2: {  // crosshair — sem rotação, braços vertical/horizontal independentes
      float armV = s * (0.55 + audioBass * 0.45);    // bass estica o braço vertical
      float armH = s * (0.55 + audioTreble * 0.45);  // treble estica o horizontal
      pg.line(0, -armV, 0, armV);
      pg.line(-armH, 0, armH, 0);
      // pequena âncora central
      float anchor = s * 0.08;
      pg.rect(-anchor, -anchor, anchor * 2, anchor * 2);
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
