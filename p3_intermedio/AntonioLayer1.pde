// fazer algo semlehante ao https://ravenkwok.com/189d0/
//
// Quad-tree audio-reativo. O ecrã é subdividido recursivamente em quadrantes.
// Cada beat parte N células (N escala com bass). Em momentos de calma as
// células voltam a fundir-se. Em cada folha desenha-se uma forma geométrica
// que reage a bass / mids / treble.

// Paleta — declarada aqui (não no principal) porque o cross-tab anda a falhar.
// Quando renomearmos a pasta para `p3_intermedio`, isto pode voltar ao main.
color[] paleta = {
  #0A0A1E,   // fundo profundo
  #00DCFF,   // ciano
  #FF3C6E,   // magenta quente
  #B400FF,   // violeta
  #FFDC00,   // amarelo
  #FFFFFF    // branco
};

final int   A1_MAX_DEPTH    = 6;        // 4^6 = 4096 folhas no pior caso
final float A1_MERGE_RATE   = 0.018;    // prob/frame de fusão quando a calma é máxima
final float A1_ROT_BASE     = 0.012;
final float A1_TRAIL_ALPHA  = 35;       // alpha do fade do fundo

QuadA1 a1Root;
ArrayList<QuadA1> a1Leaves = new ArrayList<QuadA1>();

void resetAntonio1() {
  a1Root = new QuadA1(0, 0, 1920, 1080, 0);
}

void desenharAntonio1(PGraphics pg) {
  if (a1Root == null) resetAntonio1();

  pg.beginDraw();

  // Trail: pinta fundo translúcido por cima — preserva rasto em momentos densos
  pg.noStroke();
  pg.fill(red(paleta[0]), green(paleta[0]), blue(paleta[0]),
          A1_TRAIL_ALPHA + audioCalm * 60);
  pg.rect(0, 0, pg.width, pg.height);

  // Recolher folhas para acções globais
  a1Leaves.clear();
  a1Root.collectLeaves(a1Leaves);

  // Beat → subdividir N folhas aleatórias (orçamento escala com bass + stress)
  if (audioBeat && a1Leaves.size() > 0) {
    int budget = 1 + int(audioBass * 5 + audioStress * 3);
    for (int i = 0; i < budget; i++) {
      QuadA1 c = a1Leaves.get(int(random(a1Leaves.size())));
      if (c.depth < A1_MAX_DEPTH) c.subdivide();
    }
  }

  // Stress sustentado → empurrar subdivisões mesmo sem beat
  if (audioStress > 0.6 && random(1) < audioStress * 0.15 && a1Leaves.size() > 0) {
    QuadA1 c = a1Leaves.get(int(random(a1Leaves.size())));
    if (c.depth < A1_MAX_DEPTH) c.subdivide();
  }

  a1Root.update();
  a1Root.tryMerge(audioCalm);
  a1Root.draw(pg);

  pg.endDraw();
}

class QuadA1 {
  float x, y, w, h;
  int depth;
  QuadA1[] kids;
  boolean split = false;

  color cor;
  float rot, rotSpeed;
  int kind;       // 0..3 → família de forma
  float life;     // 0..1 → recém-subdividida (flash branco)

  QuadA1(float x, float y, float w, float h, int depth) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.depth = depth;
    // Cor: ignora o índice 0 (fundo), usa pitch para enviesar escolha
    int idx = 1 + int(random(paleta.length - 1));
    this.cor = paleta[idx];
    this.rot = random(TWO_PI);
    this.rotSpeed = random(-A1_ROT_BASE, A1_ROT_BASE);
    this.kind = int(random(4));
    this.life = 1;
  }

  void collectLeaves(ArrayList<QuadA1> acc) {
    if (split) {
      for (QuadA1 k : kids) k.collectLeaves(acc);
    } else {
      acc.add(this);
    }
  }

  void subdivide() {
    if (split || depth >= A1_MAX_DEPTH) return;
    float hw = w * 0.5, hh = h * 0.5;
    kids = new QuadA1[] {
      new QuadA1(x,      y,      hw, hh, depth + 1),
      new QuadA1(x + hw, y,      hw, hh, depth + 1),
      new QuadA1(x,      y + hh, hw, hh, depth + 1),
      new QuadA1(x + hw, y + hh, hw, hh, depth + 1)
    };
    split = true;
  }

  void update() {
    if (split) {
      for (QuadA1 k : kids) k.update();
    } else {
      // Mids → velocidade de rotação
      rot += rotSpeed * (1 + audioMids * 5);
      life *= 0.94;
    }
  }

  void tryMerge(float calm) {
    if (!split) return;
    for (QuadA1 k : kids) k.tryMerge(calm);
    // Só fundo se todos os filhos são folhas
    boolean allLeaves = true;
    for (QuadA1 k : kids) if (k.split) { allLeaves = false; break; }
    if (allLeaves && random(1) < calm * A1_MERGE_RATE) {
      kids = null;
      split = false;
      life = 1;  // marca o sítio que voltou
    }
  }

  void draw(PGraphics pg) {
    if (split) {
      for (QuadA1 k : kids) k.draw(pg);
    } else {
      drawLeaf(pg);
    }
  }

  void drawLeaf(PGraphics pg) {
    pg.pushMatrix();
    pg.translate(x + w * 0.5, y + h * 0.5);
    pg.rotate(rot);

    float s = min(w, h) * 0.45;
    float sw = 1 + audioTreble * 4 + audioBass * 2;

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
      case 0:  // rectângulo com aspas em cruz
        pg.rect(-s, -s, s * 2, s * 2);
        pg.line(-s, -s,  s,  s);
        pg.line( s, -s, -s,  s);
        break;

      case 1:  // círculo concêntrico — interno pulsa com bass
        pg.ellipse(0, 0, s * 2, s * 2);
        float inner = s * (0.25 + audioBass * 0.55);
        pg.ellipse(0, 0, inner * 2, inner * 2);
        break;

      case 2:  // grelha de linhas paralelas — densidade com treble
        int lines = 3 + int(audioTreble * 6);
        for (int i = 0; i < lines; i++) {
          float t = map(i, 0, max(lines - 1, 1), -s, s);
          pg.line(-s, t, s, t);
        }
        break;

      case 3:  // polígono regular — n-lados varia com mids
        pg.beginShape();
        int n = 5 + int(audioMids * 4);
        for (int i = 0; i < n; i++) {
          float a = TWO_PI * i / n - HALF_PI;
          pg.vertex(cos(a) * s, sin(a) * s);
        }
        pg.endShape(CLOSE);
        break;
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
