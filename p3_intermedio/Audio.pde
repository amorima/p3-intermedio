// inputs via microfone
//
// Inicializa SoundFile + AudioIn e os analisadores (Amplitude, FFT, BeatDetector).
// Expõe variáveis globais que as layers consomem:
//   audioAmp / audioAmpSmooth
//   audioBass / audioMids / audioTreble (cada um 0..1, já normalizado)
//   audioBeat (true uma frame por batida)
//   audioDominantBin (bin FFT com mais energia — proxy de pitch)
//   audioEnergy (EMA longa de amp — referência de "normal")
//   audioStress (amp >> energia) / audioCalm (1 - stress)

final int FFT_BANDS = 512;

// Limites de banda (índices dos bins, FFT a 44.1kHz/2/512 ≈ 43 Hz/bin)
final int BIN_BASS_END   = 8;    // ~0–344 Hz   (kick, bass)
final int BIN_MIDS_END   = 64;   // ~344–2752 Hz (vozes, snare)
final int BIN_TREBLE_END = 256;  // ~2.7–11 kHz  (pratos, ar)

// Factores empíricos para normalizar a média da banda em [0..1]
final float GAIN_BASS   = 6.0;
final float GAIN_MIDS   = 12.0;
final float GAIN_TREBLE = 20.0;

final float SMOOTH       = 0.25;   // EMA rápida (smooth)
final float ENERGY_DECAY = 0.005;  // EMA lenta (energia)

float audioAmp, audioAmpSmooth;
float audioBass, audioBassSmooth;
float audioMids, audioMidsSmooth;
float audioTreble, audioTrebleSmooth;
boolean audioBeat;
int audioDominantBin;
float audioEnergy;
float audioStress;
float audioCalm = 1.0;

void setupAudio() {
  musica = new SoundFile(this, "limit.mp3");
  mic    = new AudioIn(this, 0);
  amp    = new Amplitude(this);
  fft    = new FFT(this, FFT_BANDS);
  beat   = new BeatDetector(this);

  musica.loop();
  ligarAnalisadores(musica);
}

void ligarAnalisadores(SoundFile src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void ligarAnalisadores(AudioIn src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void alternarFonteAudio() {
  usarMic = !usarMic;
  if (usarMic) {
    musica.pause();
    mic.start();
    ligarAnalisadores(mic);
  } else {
    mic.stop();
    musica.play();
    ligarAnalisadores(musica);
  }
}

void updateAudio() {
  audioAmp = amp.analyze();
  fft.analyze();
  audioBeat = beat.isBeat();

  float sumBass = 0, sumMids = 0, sumTreble = 0;
  float maxVal = 0;
  int maxBin = 0;

  for (int i = 0; i < FFT_BANDS; i++) {
    float v = fft.spectrum[i];
    if (i < BIN_BASS_END)        sumBass   += v;
    else if (i < BIN_MIDS_END)   sumMids   += v;
    else if (i < BIN_TREBLE_END) sumTreble += v;
    if (v > maxVal) { maxVal = v; maxBin = i; }
  }

  audioBass   = constrain((sumBass   / BIN_BASS_END)                       * GAIN_BASS,   0, 1);
  audioMids   = constrain((sumMids   / (BIN_MIDS_END   - BIN_BASS_END))    * GAIN_MIDS,   0, 1);
  audioTreble = constrain((sumTreble / (BIN_TREBLE_END - BIN_MIDS_END))    * GAIN_TREBLE, 0, 1);
  audioDominantBin = maxBin;

  audioAmpSmooth    += (audioAmp    - audioAmpSmooth)    * SMOOTH;
  audioBassSmooth   += (audioBass   - audioBassSmooth)   * SMOOTH;
  audioMidsSmooth   += (audioMids   - audioMidsSmooth)   * SMOOTH;
  audioTrebleSmooth += (audioTreble - audioTrebleSmooth) * SMOOTH;

  // Energia: EMA lenta da amplitude — representa o "normal" da música
  audioEnergy += (audioAmp - audioEnergy) * ENERGY_DECAY;

  // Stress: quanto a amplitude actual ultrapassa o "normal"
  float ratio = audioAmpSmooth / max(audioEnergy, 0.001);
  audioStress = constrain((ratio - 1.0) * 0.5, 0, 1);
  audioCalm = 1.0 - audioStress;
}
