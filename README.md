# p3-intermedio
Repositório do projeto intermédio de Programação 3 [Processing]

## Execução
1. Instalar o Processing (Java mode) e a biblioteca **Sound**.
2. Abrir `p3_intermedio.pde` no Processing.
3. (Opcional) colocar `soundtrack.mp3` na pasta `data/` do sketch.
4. Executar o sketch.

## Interação em tempo-real
- **Microfone**: entra automaticamente no arranque (tecla `M` para ligar/desligar).
- **Soundtrack**: se existir `data/soundtrack.mp3`, toca em loop (tecla `S` para ligar/desligar).
- **Utilizador**: posição do rato altera energia, cor e dinâmica visual.

## Exportação da sequência de imagens
- Tecla **`R`** inicia/para gravação dos frames (`renders/frame-######.png`).
- A gravação só pode ser parada manualmente após **90s**.
- A gravação é parada automaticamente aos **180s**.

Assim, é possível gerar uma sequência de imagens para montar um vídeo entre **1m30s e 3m** com inputs de soundtrack, microfone e utilizador.
