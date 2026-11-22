# Chá de estrelas

Uma história silenciosa para quem ainda olha para o céu com curiosidade. Um coelhinho de cachecol e uma pequena mariposa encontram, no alto de uma colina, uma chaleira de vidro que derrama estrelas sobre o vale. Uma casa iluminada, morros cobertos de névoa e flores em primeiro plano sugerem um mundo maior que continua fora do quadro.

**Direção de arte:** livro infantil onírico, materiais de feltro, papel pintado e aquarela; azul profundo e índigo em contraste com dourado quente e rosa suave. Personagens originais; sem texto na cena. O post de referência indicado pelo usuário inspirou a atmosfera noturna e o encantamento, não a reprodução dos personagens.

**Movimento:** duração de 10 segundos, 24 fps, 720 × 900 (4:5), sem áudio. A câmera respira num movimento lento de aproximação e retorno; pontos de luz se deslocam e brilham em trajetórias cíclicas, e um detalhe costurado insinua uma constelação. A ilustração de base é uma imagem gerada e os personagens permanecem estáticos: esta versão é uma composição animada, não uma animação articulada dos personagens nem um cenário em camadas independentes. O Fluvie controla quadros e exportação; o `handcrafted_flutter` desenha a costura.

**Evolução desejada:** separar personagens, primeiro plano e fundo em elementos independentes para criar parallax verdadeiro; animar o piscar, a respiração e as orelhas do coelho, o bater de asas da mariposa e o fluxo de estrelas saindo da chaleira. A imagem atual não permite esses movimentos independentemente sem novos assets.

**Reproduzir:** `bash tool/render_example.sh cha_de_estrelas`. Ilustração gerada por imagem para este projeto; composição em `example/lib/cha_de_estrelas.dart`.
