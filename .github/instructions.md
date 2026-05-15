# Instruções para assistência ao projeto — Programação III (Processing)

## Contexto do projeto

Este é um projeto académico da ESMAD (P.Porto), da unidade curricular **Programação III**, desenvolvido em **Processing (Java mode)**. O grupo é composto por dois elementos: António Amorim e Gabriel Paiva. (O enunciado oficial prevê grupos de até 3 alunos — a configuração reduzida deve ser confirmada com o docente.)

O objetivo é criar um **sketch generativo e reativo ao som**, capaz de gerar um vídeo de 1m30s a 3 minutos em tempo real, sem pós-produção. A estética centra-se na **desintegração geométrica e no caos controlado**, com sinestesia entre som e imagem.

---

## Stack técnica

- **Linguagem:** Processing 4 (Java mode)
- **Bibliotecas obrigatórias:**
  - `processing.sound.*` — SoundFile, **AudioIn (microfone)**, Amplitude, FFT, BeatDetector, WaveForm
  - `processing.video.*` — se necessário para conteúdo vídeo
- **Resolução:** 1920x1080 (FullHD), 25 fps
- **Música:** "Limit" de Nightmanoeuvres (SoundCloud) — ficheiro `limit.mp3` em `data/`

---

## Estrutura obrigatória do sketch

Segundo o enunciado oficial (Secção IV): **cada aluno desenvolve 3 separadores**, cada um com a sua própria layer (`PGraphics`) independente. Com 2 alunos: **6 layers + 1 principal + 1 áudio = 8 tabs**.

Cada layer deve conter:

- Uma `PGraphics` independente (sem partilhar acumulação/sobreposição entre layers)
- Elementos gráficos 2D e/ou 3D próprios
- Reatividade ao som (amplitude, FFT, BeatDetector) — fonte pode ser música **ou** microfone
- Controlo via teclado e/ou rato (ativar/desativar, animar)

### Estrutura de tabs:

```
p3-intermedio.pde   → setup, draw, paleta global, gestão de inputs, composição de layers
Audio.pde           → SoundFile + AudioIn, Amplitude/FFT/BeatDetector, comutação música⇄mic
AntonioLayer1.pde   → 1ª layer do António (PGraphics + classes próprias)
AntonioLayer2.pde   → 2ª layer do António
AntonioLayer3.pde   → 3ª layer do António
GabrielLayer1.pde   → 1ª layer do Gabriel
GabrielLayer2.pde   → 2ª layer do Gabriel
GabrielLayer3.pde   → 3ª layer do Gabriel
```

> Nota: o nome do ficheiro principal tem de coincidir com o nome da pasta do sketch (`p3-intermedio`).

### Estrutura de pastas:

```
p3-intermedio/
├── p3-intermedio.pde + restantes tabs .pde
├── data/      → limit.mp3, fontes, imagens (Processing procura aqui automaticamente)
└── frames/    → output de saveFrame() (ignorado pelo .gitignore)
```

---

## Requisitos obrigatórios (não negociáveis)

- `size(1920, 1080)` ou `fullScreen()` + `frameRate(25)`
- Carregar e reproduzir uma `SoundFile` (`limit.mp3` em `data/`)
- **Entrada por microfone** com `AudioIn` (exigido pelo enunciado: "inputs de som (soundtrack **e** microfone)")
- Paleta de 3 a 8 cores definida explicitamente (`color[]`)
- Uso de `random()` em cores, posições, dimensões e velocidades
- Gráficos estáticos, animados e condicionados
- Input do utilizador via teclado e rato
- Reatividade ao som: amplitude (`Amplitude`), FFT (`FFT`) e batidas (`BeatDetector`) — sobre `SoundFile` **e** `AudioIn`
- Geração e captura do vídeo em tempo real (`saveFrame`)
- 3 layers (`PGraphics`) por aluno, geridas independentemente

---

## Padrões de código a seguir

### Estrutura base do `p3-intermedio.pde`

```java
import processing.sound.*;

// Estado global de áudio (instanciado em Audio.pde)
SoundFile musica;
AudioIn mic;
Amplitude amp;
FFT fft;
BeatDetector beat;
boolean usarMic = false; // alterna entre música e microfone

// Layers — 3 por aluno
PGraphics aL1, aL2, aL3;   // António
PGraphics gL1, gL2, gL3;   // Gabriel

// Visibilidade de cada layer (controlada pelo teclado 1..6)
boolean[] layerOn = { true, true, true, true, true, true };

color[] paleta;

void setup() {
  size(1920, 1080);
  frameRate(25);

  paleta = new color[]{
    color(10, 10, 30),
    color(0, 200, 255),
    color(255, 50, 100),
    color(180, 0, 255),
    color(255, 220, 0)
  };

  setupAudio(); // definido em Audio.pde

  aL1 = createGraphics(width, height);
  aL2 = createGraphics(width, height);
  aL3 = createGraphics(width, height);
  gL1 = createGraphics(width, height);
  gL2 = createGraphics(width, height);
  gL3 = createGraphics(width, height);
}

void draw() {
  background(paleta[0]);

  float amplitude = amp.analyze();
  fft.analyze();
  boolean batida = beat.isOnset();

  if (layerOn[0]) desenharAntonio1(aL1, amplitude, batida);
  if (layerOn[1]) desenharAntonio2(aL2, amplitude, batida);
  if (layerOn[2]) desenharAntonio3(aL3, amplitude, batida);
  if (layerOn[3]) desenharGabriel1(gL1, amplitude, batida);
  if (layerOn[4]) desenharGabriel2(gL2, amplitude, batida);
  if (layerOn[5]) desenharGabriel3(gL3, amplitude, batida);

  if (layerOn[0]) image(aL1, 0, 0);
  if (layerOn[1]) image(aL2, 0, 0);
  if (layerOn[2]) image(aL3, 0, 0);
  if (layerOn[3]) image(gL1, 0, 0);
  if (layerOn[4]) image(gL2, 0, 0);
  if (layerOn[5]) image(gL3, 0, 0);

  // saveFrame("frames/frame-####.png"); // descomentar para gravar
}

void keyPressed() {
  // 1..6 → ligar/desligar cada layer
  if (key >= '1' && key <= '6') layerOn[key - '1'] = !layerOn[key - '1'];
  // m → alternar entre música e microfone (lógica em Audio.pde)
  if (key == 'm' || key == 'M') alternarFonteAudio();
}
```

### Padrão de uma layer (PGraphics)

Cada uma das 6 tabs de layer (`AntonioLayer1..3`, `GabrielLayer1..3`) expõe uma função de desenho:

```java
// em AntonioLayer1.pde
void desenharAntonio1(PGraphics pg, float amp, boolean beat) {
  pg.beginDraw();
  pg.clear(); // ou pg.background() se queres acumulação

  // lógica de desenho desta layer

  pg.endDraw();
}
```

### Padrão de `Audio.pde`

```java
void setupAudio() {
  musica = new SoundFile(this, "limit.mp3");
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  fft = new FFT(this, 512);
  beat = new BeatDetector(this);

  musica.loop();
  ligarAnalisadoresA(musica);
}

void ligarAnalisadoresA(SoundFile src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void ligarAnalisadoresA(AudioIn src) {
  amp.input(src);
  fft.input(src);
  beat.input(src);
}

void alternarFonteAudio() {
  usarMic = !usarMic;
  if (usarMic) {
    musica.pause();
    mic.start();
    ligarAnalisadoresA(mic);
  } else {
    mic.stop();
    musica.play();
    ligarAnalisadoresA(musica);
  }
}
```

### Padrão de uma classe de objeto

```java
class Particula {
  PVector pos, vel;
  float tamanho;
  color cor;

  Particula(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    vel.mult(random(1, 4));
    tamanho = random(5, 20);
    cor = paleta[int(random(paleta.length))];
  }

  void atualizar(float amplitude) {
    vel.mult(1 + amplitude);
    pos.add(vel);
  }

  void desenhar(PGraphics pg) {
    pg.noStroke();
    pg.fill(cor, 180);
    pg.ellipse(pos.x, pos.y, tamanho, tamanho);
  }
}
```

---

## Referências estéticas do projeto

| Obra                      | Autor           | Influência                                   |
| ------------------------- | --------------- | -------------------------------------------- |
| 189D0                     | Raven Kwok      | Formas reativas a batidas e frequências      |
| INFINITE.DISINTEGRATION   | Jared S Tarbell | Comportamento caótico, desintegração         |
| DATAGATE                  | Ouchhh Studio   | Visuais futuristas, simbiose som/imagem      |
| H-O-M-E-O-M-O-R-P-H-I-S-M | Ouchhh Studio   | Topologia e transformação contínua de formas |
| Limit                     | Nightmanoeuvres | Faixa sonora principal                       |

---

## Requisitos opcionais (a implementar se possível)

- `noise()` para movimento orgânico
- Transformações 2D/3D: `pushMatrix`, `translate`, `rotateX/Y/Z`, `scale`
- Iluminação 3D: `lights`, `ambientLight`, `directionalLight`, `pointLight`
- Filtros em layers: `pg.filter(BLUR, 2)`
- `PShape` para formas vetoriais
- `PFont` para tipografia generativa
- `tint` e `blendMode` para composição de layers
- `WaveForm` para visualização da onda sonora
- `PImage`/`Video` como fonte de cores ou texturas

---

## O que NÃO fazer

- Não usar `delay()` nem loops bloqueantes no `draw()`
- Não criar objetos dentro do `draw()` sem necessidade (usar ArrayLists pré-alocados)
- Não aceder a `pixels[]` em cada frame sem necessidade (é lento)
- Não esquecer `beginDraw()` / `endDraw()` nos PGraphics
- Não usar bibliotecas externas além das mencionadas sem validar compatibilidade

---

## Entrega e prazos

| O quê                           | Quando                  | Como      |
| ------------------------------- | ----------------------- | --------- |
| Proposta de trabalho            | 6 de maio (já entregue) | Email     |
| Trabalho + Apresentação + Vídeo | 26 de maio              | OneDrive  |
| Apresentação/Defesa             | 27 de maio, 09h-13h     | Sala B206 |

### Formato do vídeo

- MP4, 1920x1080 (pixel ratio 1.0), 25fps, x264, áudio estéreo 48kHz AAC
- Incluir separador da ESMAD, título, ano letivo e nomes dos autores

---

## Pesos de avaliação

| Componente                        | Peso |
| --------------------------------- | ---- |
| Trabalho prático (código + vídeo) | 40%  |
| Relatório                         | 30%  |
| Participação ativa                | 15%  |
| Apresentação / Defesa             | 15%  |

---

## Como pedir ajuda à IA de forma eficiente

Para obter o melhor resultado possível ao pedir assistência, sê específico:

**Mau exemplo:** "Faz-me a primeira layer do António"

**Bom exemplo:** "Cria uma classe `Fragmento` em `AntonioLayer1.pde` que desenha num PGraphics. Cada fragmento é um triângulo que se parte em direções aleatórias quando `beat == true`. Usa a paleta global `paleta[]`. A amplitude deve controlar o tamanho. A layer deve acumular (`pg.background(0, 20)` em vez de `clear()`)."

Sempre que pedires código:

- Indica em que tab vai o código (ex: `AntonioLayer2.pde`)
- Diz se é classe nova, função, ou modificação de existente
- Menciona variáveis globais que o código precisa de aceder (`paleta`, `amp`, `fft`, `beat`)
- Refere se o comportamento deve acumular no ecrã ou limpar por frame
