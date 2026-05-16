// Gabriel Layer 1 - Particle System "Infinite Disintegration"
//
// Inspirado em "INFINITE.DISINTEGRATION" de Jared S. Tarbell.
// As partículas reagem à música e ao rato, criando uma formação coesa
// com o anel do AntonioLayer1 em momentos de calma e desintegrando-se
// em momentos de stress.

// --- Configuração do Sistema de Partículas ---
final int G1_MAX_PARTICLES            = 8000;   // Número máximo de partículas.
final int G1_MAX_NEW_PARTICLES        = 50;     // Máximo de partículas novas por frame.
final float G1_LIFESPAN_DECAY         = 1.0;    // Decaimento da vida da partícula por frame.

// --- Interação e Forças ---
final float G1_MOUSE_REPEL_RADIUS       = 200;    // Raio de repulsão do rato.
final float G1_MOUSE_REPEL_FORCE        = 1.5;    // Força de repulsão do rato.
final float G1_MOUSE_ATTRACT_RADIUS_MULT = 1.5;   // Multiplicador do raio de atração do rato (quando clicado).
final float G1_MOUSE_ATTRACT_FORCE_MULT  = 2.0;   // Multiplicador da força de atração do rato (quando clicado).
final float G1_RING_ATTRACT_RADIUS      = 300;    // Raio de influência para a atração do anel.
final float G1_RING_ATTRACT_FORCE       = 0.5;    // Força de atração para o anel em momentos de calma.
final float G1_STRESS_REPEL_FORCE       = 0.2;    // Força de repulsão do centro em momentos de stress.
final float G1_VIBRATION_ENERGY_MULT    = 0.5;    // Multiplicador da vibração com a energia da música.
final float G1_VIBRATION_BASS_MULT      = 1.5;    // Multiplicador da vibração com o baixo da música.
final float G1_DAMPING                  = 0.97;   // Fator de amortecimento para a velocidade.

// --- Aparência ---
final float G1_PARTICLE_BASE_SIZE       = 2.5;    // Tamanho base da partícula.
final float G1_PARTICLE_BASS_SIZE_MULT  = 5.0;    // Multiplicador do tamanho da partícula com o baixo.

// --- Estado ---
ArrayList<ParticleG1> g1Particles;

void resetGabriel1() {
  g1Particles = new ArrayList<ParticleG1>();
}

void desenharGabriel1(PGraphics pg) {
  if (g1Particles == null) {
    resetGabriel1();
  }

  pg.beginDraw();
  pg.clear();
  pg.blendMode(ADD); // Usar ADD para um efeito de brilho sobre outras layers

  // --- Adicionar novas partículas com base na amplitude ---
  int numNewParticles = int(map(audioAmp, 0, 0.5, 0, G1_MAX_NEW_PARTICLES));
  for (int i = 0; i < numNewParticles; i++) {
    if (g1Particles.size() < G1_MAX_PARTICLES) {
      g1Particles.add(new ParticleG1());
    }
  }

  // --- Calcular raio do anel de AntonioLayer1 ---
  float baseSize = min(pg.width, pg.height) * 0.45;
  float ringRadius = (baseSize * (0.85 + audioBass * 0.4)) / 2.0;

  // --- Atualizar e desenhar partículas ---
  for (int i = g1Particles.size() - 1; i >= 0; i--) {
    ParticleG1 p = g1Particles.get(i);
    p.update(ringRadius);
    p.draw(pg);
    if (p.isDead()) {
      g1Particles.remove(i);
    }
  }
  pg.endDraw();
}

class ParticleG1 {
  PVector pos;
  PVector vel;
  PVector acc;
  float lifespan;
  color c;

  ParticleG1() {
    // Nasce numa posição aleatória no ecrã
    pos = new PVector(random(width), random(height));
    vel = new PVector();
    acc = new PVector();
    lifespan = 255;
    c = paleta[1 + int(random(paleta.length - 1))];
  }

  void update(float ringRadius) {
    // --- Forças ---
    PVector center = new PVector(width / 2, height / 2);

    // Força de atração/repulsão em relação ao anel
    float distToCenter = dist(pos.x, pos.y, center.x, center.y);
    PVector dirToCenter = PVector.sub(center, pos);
    dirToCenter.normalize();

    // Em calma, atrai para o anel. Em stress, repele do centro.
    if (audioCalm > 0.5) {
      float distToRing = abs(distToCenter - ringRadius);
      float attractForce = map(distToRing, 0, G1_RING_ATTRACT_RADIUS, G1_RING_ATTRACT_FORCE, 0);
      acc.add(PVector.mult(dirToCenter, (distToCenter > ringRadius ? -attractForce : attractForce)));
    } else { // Stress
      float repelForce = map(audioStress, 0.5, 1.0, 0, G1_STRESS_REPEL_FORCE);
      acc.add(PVector.mult(dirToCenter, -repelForce));
    }

    // Interação com o rato
    float distToMouse = dist(pos.x, pos.y, mouseX, mouseY);
    if (mousePressed) {
      // Atrai para o rato se o botão estiver pressionado
      if (distToMouse < G1_MOUSE_REPEL_RADIUS * G1_MOUSE_ATTRACT_RADIUS_MULT) {
        PVector dirToMouse = PVector.sub(new PVector(mouseX, mouseY), pos);
        dirToMouse.normalize();
        float attractForce = map(distToMouse, 0, G1_MOUSE_REPEL_RADIUS * G1_MOUSE_ATTRACT_RADIUS_MULT, G1_MOUSE_REPEL_FORCE * G1_MOUSE_ATTRACT_FORCE_MULT, 0);
        acc.add(PVector.mult(dirToMouse, attractForce));
      }
    } else {
      // Repele do rato caso contrário
      if (distToMouse < G1_MOUSE_REPEL_RADIUS) {
        PVector dirFromMouse = PVector.sub(pos, new PVector(mouseX, mouseY));
        dirFromMouse.normalize();
        float repel = map(distToMouse, 0, G1_MOUSE_REPEL_RADIUS, G1_MOUSE_REPEL_FORCE, 0);
        acc.add(PVector.mult(dirFromMouse, repel));
      }
    }
    
    // Vibração com a música
    float vibration = audioEnergy * G1_VIBRATION_ENERGY_MULT + audioBass * G1_VIBRATION_BASS_MULT;
    acc.add(PVector.random2D().mult(vibration));

    // --- Física ---
    vel.add(acc);
    vel.mult(G1_DAMPING);
    pos.add(vel);
    acc.mult(0); // Resetar aceleração

    lifespan -= G1_LIFESPAN_DECAY;
  }

  void draw(PGraphics pg) {
    // A cor e o tamanho reagem ao stress
    float r = red(c);
    float g = green(c);
    float b = blue(c);
    float alpha = lifespan * (0.5 + audioStress * 0.5);
    float particleSize = G1_PARTICLE_BASE_SIZE + audioBass * G1_PARTICLE_BASS_SIZE_MULT;

    pg.noStroke();
    pg.fill(r, g, b, alpha);
    pg.ellipse(pos.x, pos.y, particleSize, particleSize);
  }

  boolean isDead() {
    return lifespan <= 0;
  }
}

