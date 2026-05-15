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

// --- HUD de debug ---
boolean mostrarHUD = true;

void setup() {
  size(1920, 1080, P2D);
  surface.setLocation(10, 10);
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
  background(#0A0A1E);  // fundo profundo (cor 0 da paleta)

  updateAudio();

  if (layerOn[0]) desenharAntonio1(aL1);
  if (layerOn[1]) desenharAntonio2(aL2);
  if (layerOn[2]) desenharAntonio3(aL3);
  if (layerOn[3]) desenharGabriel1(gL1);
  if (layerOn[4]) desenharGabriel2(gL2);
  if (layerOn[5]) desenharGabriel3(gL3);

  if (layerOn[0]) image(aL1, 0, 0);
  if (layerOn[1]) image(aL2, 0, 0);
  if (layerOn[2]) image(aL3, 0, 0);
  if (layerOn[3]) image(gL1, 0, 0);
  if (layerOn[4]) image(gL2, 0, 0);
  if (layerOn[5]) image(gL3, 0, 0);

  if (mostrarHUD) desenharHUD();

  // saveFrame("frames/frame-####.png");  // descomentar para gravar
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
  String s = "";
  for (int i = 0; i < 6; i++) s += layerOn[i] ? (i+1) : "-";
  return s;
}

void keyPressed() {
  // 1..6 → ligar/desligar cada layer
  if (key >= '1' && key <= '6') layerOn[key - '1'] = !layerOn[key - '1'];
  // m → música ⇄ microfone
  if (key == 'm' || key == 'M') alternarFonteAudio();
  // h → mostrar/esconder HUD
  if (key == 'h' || key == 'H') mostrarHUD = !mostrarHUD;
  // r → reiniciar layer Antonio1
  if (key == 'r' || key == 'R') resetAntonio1();
}
