# O jardim que sonha

À noite, um coelho de feltro descansa numa clareira. Uma pequena mariposa de papel dança a seu lado enquanto névoas atravessam as colinas, vaga-lumes pairam e plantas se movem em primeiro plano. Uma casa acesa sugere um abrigo, e as flores-lanterna do cenário dão escala e calor ao mundo.

**Direção de arte:** infantil, onírica e acolhedora; azul noturno com âmbar, rosa e creme. A referência do usuário orienta o sentimento de maravilhamento, não o desenho de personagens existentes. Formato 4:5, 720 × 900, 24 fps, dez segundos, sem áudio.

**Construção e movimento:** o fundo é uma ilustração gerada, levemente deslocada; seus objetos pintados não têm movimento individual. As faixas de névoa e pontos luminosos são camadas animadas por código. O coelho é montado com peças `CraftSurface` de feltro e linho: as orelhas giram, o corpo respira, o rosto pisca e o cachecol balança. A mariposa usa superfícies de feltro e papel com asas articuladas e movimento de voo. As costuras do cachecol e das asas usam `paintCraftStitch`. As plantas desenhadas na frente dos personagens oscilam. O Fluvie fornece o relógio e exporta os quadros. Não há geração de vídeo por IA.

**Limites:** personagens são formas programáticas estilizadas, não animação de personagem quadro a quadro. A ilustração de fundo não foi segmentada; casa, nuvens e flores pintadas não se movem independentemente. Não há iluminação física compartilhada entre os elementos.

**Reproduzir:** `bash tool/render_example.sh jardim_sonho`. Código: `example/lib/jardim_sonho.dart`; cenário: `example/assets/jardim_sonho.png`.

## Revisão 2 — roupa e acabamento

O cachecol passa a ter gola curva, nó e ponta com franja; o material é algodão. Braços articulados e uma região mais escura na barriga dão leitura ao corpo. Flores em aquarela, pintadas pelo Handcrafted, oscilam em primeiro plano; sombras de contato aproximam os personagens do chão. O exportador carrega a imagem antes da captura do primeiro quadro, evitando o fundo preto enquanto o asset ainda é decodificado.

## Revisão 3 — caimento do cachecol

Gola reduzida de 102 para 82 unidades e reposicionada junto à base do rosto. Nó e ponta menores acompanham o novo caimento, com menos tecido cobrindo a bochecha e o peito.
