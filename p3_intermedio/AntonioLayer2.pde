// fazer algo semlehante ao https://ravenkwok.com/189d0/
//
// Quad-tree audio-reativo. O ecrã é subdividido recursivamente em quadrantes.
// Cada beat parte N células (N escala com bass). Em momentos de calma as
// células voltam a fundir-se. Em cada folha desenha-se uma forma geométrica
// que reage a bass / mids / treble.

final int   A2_MAX_DEPTH    = 6;        // 4^6 = 4096 folhas no pior caso
final float A2_MERGE_RATE   = 0.018;    // prob/frame de fusão quando a calma é máxima
final float A2_ROT_BASE     = 0.005;    // rotação base (5× mais lenta que antes)
final float A2_TRAIL_ALPHA  = 35;       // alpha do fade do fundo

QuadA2 a2Root;
ArrayList<QuadA2> a2Leaves = new ArrayList<QuadA2>();

void resetAntonio2() {
  a2Root = new QuadA2(0, 0, 1920, 1080, 0);
}

void desenharAntonio2(PGraphics pg) {
  if (a2Root == null) resetAntonio2();

  pg.beginDraw();

  // Trail: pinta fundo translúcido por cima — preserva rasto em momentos densos
  pg.noStroke();
  pg.fill(red(paleta[0]), green(paleta[0]), blue(paleta[0]),
          A2_TRAIL_ALPHA + audioCalm * 60);
  pg.rect(0, 0, pg.width, pg.height);

  // Recolher folhas para acções globais
  a2Leaves.clear();
  a2Root.collectLeaves(a2Leaves);

  // Beat → subdividir N folhas aleatórias (orçamento escala com bass + stress)
  if (audioBeat && a2Leaves.size() > 0) {
    int budget = 1 + int(audioBass * 5 + audioStress * 3);
    for (int i = 0; i < budget; i++) {
      QuadA2 c = a2Leaves.get(int(random(a2Leaves.size())));
      if (c.depth < A2_MAX_DEPTH) c.subdivide();
    }
  }

  // Stress sustentado → empurrar subdivisões mesmo sem beat
  if (audioStress > 0.6 && random(1) < audioStress * 0.15 && a2Leaves.size() > 0) {
    QuadA2 c = a2Leaves.get(int(random(a2Leaves.size())));
    if (c.depth < A2_MAX_DEPTH) c.subdivide();
  }

  a2Root.update();
  a2Root.tryMerge(audioCalm);
  a2Root.draw(pg);

  pg.endDraw();
}

class QuadA2 {
  float x, y, w, h;
  int depth;
  QuadA2[] kids;
  boolean split = false;

  color cor;
  float rot, rotSpeed;
  int kind;       // 0..3 → família de forma
  float life;     // 0..1 → recém-subdividida (flash branco)
  float phase;    // 0..TWO_PI → fase determinística por célula (anima sub-forma)

  QuadA2(float x, float y, float w, float h, int depth) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.depth = depth;
    // Cor: ignora o índice 0 (fundo), usa pitch para enviesar escolha
    int idx = 1 + int(random(paleta.length - 1));
    this.cor = paleta[idx];
    this.rot = random(TWO_PI);
    this.rotSpeed = random(-A2_ROT_BASE, A2_ROT_BASE);
    this.kind = int(random(4));
    this.life = 1;
    this.phase = random(TWO_PI);   // fase única para animações sub-forma
  }

  void collectLeaves(ArrayList<QuadA2> acc) {
    if (split) {
      for (QuadA2 k : kids) k.collectLeaves(acc);
    } else {
      acc.add(this);
    }
  }

  void subdivide() {
    if (split || depth >= A2_MAX_DEPTH) return;
    float hw = w * 0.5, hh = h * 0.5;
    kids = new QuadA2[] {
      new QuadA2(x,      y,      hw, hh, depth + 1),
      new QuadA2(x + hw, y,      hw, hh, depth + 1),
      new QuadA2(x,      y + hh, hw, hh, depth + 1),
      new QuadA2(x + hw, y + hh, hw, hh, depth + 1)
    };
    split = true;
  }

  void update() {
    if (split) {
      for (QuadA2 k : kids) k.update();
    } else {
      // Rotação lenta — só os mids dão um leve boost
      rot += rotSpeed * (0.6 + audioMids * 0.8);
      life *= 0.94;
    }
  }

  void tryMerge(float calm) {
    if (!split) return;
    for (QuadA2 k : kids) k.tryMerge(calm);
    // Só fundo se todos os filhos são folhas
    boolean allLeaves = true;
    for (QuadA2 k : kids) if (k.split) { allLeaves = false; break; }
    if (allLeaves && random(1) < calm * A2_MERGE_RATE) {
      kids = null;
      split = false;
      life = 1;  // marca o sítio que voltou
    }
  }

  void draw(PGraphics pg) {
    if (split) {
      for (QuadA2 k : kids) k.draw(pg);
    } else {
      drawLeaf(pg);
    }
  }

  void drawLeaf(PGraphics pg) {
    pg.pushMatrix();
    pg.translate(x + w * 0.5, y + h * 0.5);

    float s = min(w, h) * 0.45;
    float sw = 1 + audioTreble * 3 + audioBass * 1.5;

    // Cor com pitch — desloca o tom em função do bin dominante
    float pitchShift = map(audioDominantBin, 0, FFT_BANDS, -60, 60);
    color c2 = color(
      constrain(red(cor)   + pitchShift, 0, 255),
      constrain(green(cor) - pitchShift * 0.5, 0, 255),
      constrain(blue(cor)  + pitchShift * 0.3, 0, 255)
    );

    pg.noFill();
    pg.stroke(c2, 230);
    pg.strokeWeight(sw);

    switch (kind) {
      case 0: {  // quadrados concêntricos — moldura estática + 2 rodam em sentidos opostos
        // Exterior — estático, dá uma "moldura" que ancora a célula
        pg.rect(-s, -s, s * 2, s * 2);

        // Médio — roda lento no sentido do rot da célula
        pg.pushMatrix();
        pg.rotate(rot * 0.7);
        float mid = s * 0.65;
        pg.rect(-mid, -mid, mid * 2, mid * 2);
        pg.popMatrix();

        // Interior — roda em sentido contrário, pulsa com bass
        pg.pushMatrix();
        pg.rotate(-rot * 1.2);
        float inner0 = s * (0.32 + audioBass * 0.18);
        pg.rect(-inner0, -inner0, inner0 * 2, inner0 * 2);
        pg.popMatrix();
        break;
      }

      case 1: {  // círculos concêntricos — núcleo pulsa com bass (intocado)
        pg.pushMatrix();
        pg.rotate(rot * 0.3);
        pg.ellipse(0, 0, s * 2, s * 2);
        float inner = s * (0.25 + audioBass * 0.55);
        pg.ellipse(0, 0, inner * 2, inner * 2);
        pg.popMatrix();
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
        pg.pushMatrix();
        pg.rotate(rot * 0.5);
        int n = 6;
        pg.beginShape();
        for (int i = 0; i < n; i++) {
          float a = TWO_PI * i / n - HALF_PI;
          // cada vértice respira em fase própria — uma onda viaja à volta
          float breath = 1.0 + sin(phase + frameCount * 0.05 + i * TWO_PI / n)
                             * (0.15 + audioBass * 0.30);
          pg.vertex(cos(a) * s * breath, sin(a) * s * breath);
        }
        pg.endShape(CLOSE);
        pg.popMatrix();
        break;
      }
    }

    // Flash branco no contorno da célula quando acabou de mudar de estado
    if (life > 0.08) {
      pg.stroke(255, life * 220);
      pg.strokeWeight(2);
      pg.noFill();
      pg.rect(-w * 0.5, -h * 0.5, w, h);
    }

    pg.popMatrix();
  }
}
