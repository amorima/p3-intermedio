import processing.sound.*;

// --- Áudio (inicializado em Audio.pde) ---
SoundFile musica;
AudioIn mic;
Amplitude amp;
FFT fft;
BeatDetector beat;
boolean usarMic = false;

// --- Layers (1 por separador, 3 por aluno) ---
PGraphics aL1, aL2, aL3;
PGraphics gL1, gL2, gL3;

// Visibilidade — só Antonio1 ligada à partida; 1..6 alterna no teclado
boolean[] layerOn = { true, false, false, false, false, false };

// --- Paleta global (3 a 8 cores, requisito do enunciado) ---
color[] paleta = {
  #0A0A1E,   // fundo profundo
  #00DCFF,   // ciano
  #FF3C6E,   // magenta quente
  #B400FF,   // violeta
  #FFDC00,   // amarelo
  #FFFFFF    // branco
};

// --- HUD de debug ---
boolean mostrarHUD = false;

void setup() {
  size(1920, 1080);
  smooth(8);
  surface.setLocation((displayWidth - width) / 2, (displayHeight - height) / 2);
  frameRate(25);

  setupAudio();

  aL1 = createGraphics(width, height);
  aL2 = createGraphics(width, height);
  aL3 = createGraphics(width, height);
  gL1 = createGraphics(width, height);
  gL2 = createGraphics(width, height);
  gL3 = createGraphics(width, height);
}

void draw() {
  background(paleta[0]);

  updateAudio();

  // --- Lógica de Troca de Layer no Pico da Transição ---
  if (a1TransitionState == 1 && a1TransitionFactor >= 1.0) {
    // Chegámos ao ponto em que o círculo tapa tudo. Trocamos os layers por baixo.
    
    // 1. Desligar todos os layers de conteúdo (2 a 6)
    for (int i = 1; i < 6; i++) {
      layerOn[i] = false;
    }
    
    // 2. Ligar o alvo
    if (a1TargetLayer >= 1 && a1TargetLayer <= 5) {
      layerOn[a1TargetLayer] = true;
    }
    
    // 3. Passar para a fase de encolher
    a1TransitionState = 2; 
  }

  // Layer 1 está SEMPRE ativo como overlay
  desenharAntonio1(aL1);
  if (layerOn[1]) desenharAntonio2(aL2);
  if (layerOn[2]) desenharAntonio3(aL3);
  if (layerOn[3]) desenharGabriel1(gL1);
  if (layerOn[4]) desenharGabriel2(gL2);
  if (layerOn[5]) desenharGabriel3(gL3);

  // Ordem de desenho: Conteúdo primeiro, Overlay (L1) por último
  if (layerOn[1]) image(aL2, 0, 0);
  if (layerOn[2]) image(aL3, 0, 0);
  if (layerOn[3]) image(gL1, 0, 0);
  if (layerOn[4]) image(gL2, 0, 0);
  if (layerOn[5]) image(gL3, 0, 0);
  
  // Layer 1 sempre visível e no topo
  image(aL1, 0, 0);

  if (mostrarHUD) desenharHUD();
}

void desenharHUD() {
  noStroke();
  fill(0, 160);
  rect(10, 10, 280, 170);
  fill(255);
  textSize(14);
  text("amp:    " + nf(audioAmp, 0, 2),       20, 32);
  text("bass:   " + nf(audioBass, 0, 2),      20, 52);
  text("mids:   " + nf(audioMids, 0, 2),      20, 72);
  text("treble: " + nf(audioTreble, 0, 2),    20, 92);
  text("energ:  " + nf(audioEnergy, 0, 2),    20, 112);
  text("calma:  " + nf(audioCalm, 0, 2),      20, 132);
  text("fonte:  " + (usarMic ? "MIC" : "limit.mp3"), 20, 152);
  text("layers: " + estadoLayers(),           20, 172);
}

String estadoLayers() {
  String s = "1"; // Layer 1 sempre ON
  for (int i = 1; i < 6; i++) s += layerOn[i] ? (i+1) : "-";
  return s;
}

void keyPressed() {
  // 2..6 → ligar/desligar cada layer manualmente (1 é permanente)
  if (key >= '2' && key <= '6') {
    int idx = key - '1';
    // Desliga os outros de conteúdo para manter coerência
    for (int i = 1; i < 6; i++) if (i != idx) layerOn[i] = false;
    layerOn[idx] = !layerOn[idx];
  }
  
  // Setas para transição sequencial
  if (key == CODED) {
    // Descobrir qual é o layer de conteúdo atualmente ativo (2 a 6)
    int currentActive = -1;
    for (int i = 1; i < 6; i++) {
      if (layerOn[i]) {
        currentActive = i;
        break;
      }
    }

    if (keyCode == RIGHT) {
      // Próximo layer
      int target;
      if (currentActive == -1) {
        target = 1; // De "só Layer 1" para Layer 2 (index 1)
      } else {
        target = currentActive + 1;
        if (target > 5) target = -1; // De Layer 6 volta para "só Layer 1"
      }
      iniciarTransicaoA1(target);
    } else if (keyCode == LEFT) {
      // Layer anterior
      int target;
      if (currentActive == -1) {
        target = 5; // De "só Layer 1" para Layer 6 (index 5)
      } else {
        target = currentActive - 1;
        if (target < 0) target = -1; // De Layer 2 para "só Layer 1"
      }
      iniciarTransicaoA1(target);
    }
  }

  // m → música ⇄ microfone
  if (key == 'm' || key == 'M') alternarFonteAudio();
  // h → mostrar/esconder HUD
  if (key == 'h' || key == 'H') mostrarHUD = !mostrarHUD;
  // r → reiniciar layer Antonio1
  if (key == 'r' || key == 'R') resetAntonio1();
}
