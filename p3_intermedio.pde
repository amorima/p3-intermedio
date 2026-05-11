import processing.sound.*;
import java.io.File;

final int TARGET_FPS = 30;
final int MIN_DURATION_SECONDS = 90;
final int MAX_DURATION_SECONDS = 180;

AudioIn microphone;
Amplitude micAmplitude;
SoundFile soundtrack;
Amplitude soundtrackAmplitude;

boolean micEnabled = true;
boolean soundtrackEnabled = false;
boolean showHud = true;
boolean recording = false;
int recordingStartFrame = 0;
float paletteShift = 0;
String statusMessage = "R inicia/parar gravação (90-180s) | M microfone | S soundtrack | H HUD";

void setup() {
  size(1280, 720, P2D);
  frameRate(TARGET_FPS);
  colorMode(HSB, 360, 100, 100, 100);
  smooth(8);

  microphone = new AudioIn(this, 0);
  microphone.start();
  micAmplitude = new Amplitude(this);
  micAmplitude.input(microphone);

  File soundtrackFile = new File(dataPath("soundtrack.mp3"));
  if (soundtrackFile.exists()) {
    soundtrack = new SoundFile(this, "soundtrack.mp3");
    soundtrack.loop();
    soundtrackAmplitude = new Amplitude(this);
    soundtrackAmplitude.input(soundtrack);
    soundtrackEnabled = true;
    statusMessage = "Soundtrack carregada. " + statusMessage;
  } else {
    statusMessage = "Sem data/soundtrack.mp3. A visualização usa apenas microfone + utilizador.";
  }

  background(0);
}

void draw() {
  float micLevel = micEnabled ? micAmplitude.analyze() : 0;
  float trackLevel = soundtrackEnabled && soundtrack != null ? soundtrackAmplitude.analyze() : 0;
  float userEnergy = constrain(map(mouseX, 0, width, 0, 1) * 0.6 + map(mouseY, 0, height, 1, 0) * 0.4, 0, 1);
  float combinedEnergy = constrain(micLevel * 1.8 + trackLevel * 1.4 + userEnergy * 0.8, 0, 1.5);

  paletteShift = (paletteShift + 0.6 + combinedEnergy * 5.5) % 360;

  noStroke();
  fill((paletteShift + 200) % 360, 40, 8, 12);
  rect(0, 0, width, height);

  translate(width / 2.0, height / 2.0);
  blendMode(ADD);

  int orbitCount = 190;
  float maxRadius = min(width, height) * 0.48;

  for (int i = 0; i < orbitCount; i++) {
    float orbitRatio = i / float(orbitCount - 1);
    float baseRadius = lerp(20, maxRadius, orbitRatio);
    float noiseValue = noise(i * 0.03, frameCount * 0.015);
    float beatWarp = 1.0 + combinedEnergy * 2.8 * noiseValue;
    float angle = frameCount * 0.012 + i * 0.085 + userEnergy * TWO_PI;

    float x = cos(angle) * baseRadius * beatWarp;
    float y = sin(angle * (1.0 + micLevel * 4.0)) * baseRadius * (0.9 + trackLevel * 2.0);
    float pointSize = 1.2 + combinedEnergy * 4.5 * (1.0 - orbitRatio);

    fill((paletteShift + i * 1.9 + mouseX * 0.08) % 360, 80, 100, 45);
    ellipse(x, y, pointSize, pointSize);
  }

  blendMode(BLEND);
  resetMatrix();

  if (recording) {
    saveFrame("renders/frame-######.png");
    float elapsedSeconds = (frameCount - recordingStartFrame) / float(TARGET_FPS);
    if (elapsedSeconds >= MAX_DURATION_SECONDS) {
      recording = false;
      statusMessage = "Gravação terminada automaticamente aos 180 segundos.";
    }
  }

  if (showHud) {
    drawHud(micLevel, trackLevel, userEnergy, combinedEnergy);
  }
}

void drawHud(float micLevel, float trackLevel, float userEnergy, float combinedEnergy) {
  fill(0, 0, 0, 55);
  rect(12, 12, 540, 140, 8);

  fill(0, 0, 100, 92);
  textSize(14);
  text("Mic: " + nf(micLevel, 1, 3), 26, 38);
  text("Soundtrack: " + nf(trackLevel, 1, 3), 26, 58);
  text("Utilizador (rato): " + nf(userEnergy, 1, 3), 26, 78);
  text("Energia combinada: " + nf(combinedEnergy, 1, 3), 26, 98);

  if (recording) {
    float elapsedSeconds = (frameCount - recordingStartFrame) / float(TARGET_FPS);
    fill(0, 95, 100, 100);
    text("REC a gravar frames: " + nf(elapsedSeconds, 1, 1) + "s", 270, 38);

    if (elapsedSeconds < MIN_DURATION_SECONDS) {
      fill(45, 90, 100, 100);
      text("Paragem manual disponível em " + nf(MIN_DURATION_SECONDS - elapsedSeconds, 1, 1) + "s", 270, 58);
    } else {
      fill(135, 85, 100, 100);
      text("Já pode parar (tecla R)", 270, 58);
    }
  } else {
    fill(140, 80, 100, 100);
    text("REC parado", 270, 38);
  }

  fill(0, 0, 100, 85);
  text(statusMessage, 26, 126);
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    toggleRecording();
  } else if (key == 'm' || key == 'M') {
    micEnabled = !micEnabled;
    statusMessage = micEnabled ? "Microfone ativo." : "Microfone em pausa.";
  } else if (key == 's' || key == 'S') {
    toggleSoundtrack();
  } else if (key == 'h' || key == 'H') {
    showHud = !showHud;
  } else if (key == 'c' || key == 'C') {
    background(0);
    statusMessage = "Canvas limpo.";
  }
}

void toggleRecording() {
  if (!recording) {
    recording = true;
    recordingStartFrame = frameCount;
    statusMessage = "Gravação iniciada. Os frames são guardados em /renders.";
    return;
  }

  float elapsedSeconds = (frameCount - recordingStartFrame) / float(TARGET_FPS);
  if (elapsedSeconds >= MIN_DURATION_SECONDS) {
    recording = false;
    statusMessage = "Gravação terminada manualmente aos " + nf(elapsedSeconds, 1, 1) + " segundos.";
  } else {
    statusMessage = "A gravação tem de durar pelo menos 90 segundos.";
  }
}

void toggleSoundtrack() {
  if (soundtrack == null) {
    statusMessage = "Sem soundtrack. Adicione data/soundtrack.mp3 para ativar.";
    return;
  }

  if (soundtrackEnabled) {
    soundtrack.pause();
    soundtrackEnabled = false;
    statusMessage = "Soundtrack em pausa.";
  } else {
    soundtrack.loop();
    soundtrackEnabled = true;
    statusMessage = "Soundtrack ativa.";
  }
}
