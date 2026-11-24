# Mapa de ilustrações possíveis para o X

Escolha o formato pela leitura que a pauta precisa facilitar. As composições abaixo entram pelo fluxo editorial do Dots, passam pela revisão do `visual.json` e voltam como imagem para aprovação. [Fluxo do Dots](dots-editorial.md)

O [mini roadmap](roadmap.md#8-dots-illustration-pipeline) registra as próximas integrações e como verificá-las. Cada mudança passa por revisão independente do Astra antes do merge.

| O que o post precisa mostrar | Composição | Ponto de partida |
| --- | --- | --- |
| Caminho de compra, distribuição, API ou processamento | `editorial_illustration` | [AWS Marketplace com dois destinos](../example/fixtures/editorial_illustration.json) |
| Evolução ou comparação de medidas em um eixo | `data_story` | [Linha](../example/fixtures/data_story_axis.json) · [Pontos pareados](../example/fixtures/data_story_paired_dot.json) |
| Partes de um total | `data_story` | [Barra com subtotal](../example/fixtures/data_story_stacked_bar.json) · [Rosca agrupada](../example/fixtures/data_story_grouped_donut.json) |
| Mudanças ao longo do tempo e papéis de organizações | `editorial_matrix` | [Cronologia com indicador](../example/fixtures/editorial_matrix_hero.json) |
| Explicação que se lê em módulos | `editorial_catalog` | [Grade ilustrada](../example/fixtures/editorial_catalog.json) |

## Reaproveitar a ilustração em camadas

1. Abra a [fixture do Marketplace](../example/fixtures/editorial_illustration.json) e salve uma cópia como `visual.json`. O exemplo representa uma empresa, um canal de compra e dois produtos. A versão 1 também aceita um único destino.
2. Edite só os elementos que a pauta muda. `origin`, `channel` e cada item de `destinations` têm título, detalhe e símbolo independentes. Os símbolos disponíveis são `organization`, `marketplace`, `application`, `compute`, `storage`, `shield` e `queue`. O campo opcional `asset`, como `chip.png`, usa um PNG da pasta `assets/` ao lado do JSON como arte do cartão. As setas seguem os cartões, e `annotation` pode receber uma condição, escopo ou detalhe com os IDs de fonte correspondentes.
3. Use as fontes verificadas da nova pauta em `sources`. Cada entrada é `{id, label}`. A anotação usa `source_ids` do mesmo rodapé. No Dots, escolha `template: editorial_illustration` e `media: image` ou `media: both` conforme o briefing. A origem, o canal e os destinos devem descrever uma relação demonstrada pelas fontes.
4. Para testar localmente, execute da raiz do repo com Flutter e FFmpeg no `PATH`. O exemplo inclui `alt_text` para render manual. No Dots, a descrição vem do rascunho revisado.

   ```bash
   dart example/bin/validate_editorial.dart editorial_illustration < visual.json
   bash tool/render_example.sh editorial_illustration visual.json example/build/minha-pauta
   bash tool/render_example.sh editorial_illustration_video visual.json example/build/minha-pauta-video
   ```

O PNG sai em 1080 × 1350. O vídeo silencioso tem cinco segundos a 24 fps e usa a composição completa como capa. Confira o PNG a 360 px de largura. Ao trocar só um produto, o outro cartão, as setas e a chave de fontes devem conservar o enquadramento. Uma sessão que recebe um pacote do Dots pode repetir a exportação com o `visual.json` e recuperar o texto alternativo em `alt-text.txt`.

No piloto, o worker produziu PNG, MP4 de 120 quadros e `visual.json` com respostas editoriais simuladas e render real. A troca de um rótulo mudou pixels apenas dentro do cartão editado. As capas estática e do vídeo tiveram pixels idênticos. A prévia reduzida e os quadros do vídeo foram conferidos a 360 px. Uma prova sintética com gateway de API também exportou PNG com um único destino e sem anotação.

Para uma pauta em que a rota explica a tese, o Dots pode selecionar este formato durante o fluxo editorial normal. Na revisão, confira a direção das conexões, os escopos citados e a leitura da capa a 360 px. Registre o que a pauta demonstrou antes de generalizar o formato.

## Pontos de extensão

O template usa símbolos e texto desenhados em Flutter. Reaproveita os [campos editoriais](../example/lib/src/editorial_fields.dart), o [relógio do Fluvie](../example/lib/src/motion_clock.dart), a [validação editorial](../example/bin/validate_editorial.dart) e o [comando de exportação](../tool/render_example.sh). Para um novo arranjo, confirme primeiro se os formatos deste mapa conseguem representar a relação. O [contrato da ilustração](../example/lib/src/illustration_document.dart) e o [renderer](../example/lib/editorial_illustration.dart) são os pontos de extensão da composição.

| Quando surgir a necessidade | O que reaproveitar ou testar |
| --- | --- |
| Arte original com recorte ou textura | Exporte o PNG do ComfyUI e aponte `asset` no cartão. Guarde o `visual.json` e `assets/` juntos, e preserve o workflow de arte para conseguir refazer a camada. O exemplo de máscara usa nós nativos do ComfyUI. [ComfyUI local e comando](integrations.md#comfyui-para-camadas-de-ilustração) |
| Cena web que precisa de uma camada animada | Reaproveite a timeline pausada do GSAP no exemplo HyperFrames. Os marcos vêm do JSON, e o render transparente entra como camada no Fluvie. [Integração local](integrations.md#hyperframes-and-fluvie) |
| Revisão de vídeo | Extrair início, transição e quadro final com FFmpeg. Conferir a leitura a 360 px e verificar se a informação continua visível durante tempo suficiente. [Verificação do projeto](verification.md) |

O ComfyUI local exportou um chip RGBA com máscara usando nós nativos. O render de prova empacotou a camada e outra exportação, feita com o JSON e o PNG entregues, reproduziu os pixels da capa e o texto alternativo. A prova editorial usou respostas dos modelos simuladas.

O exemplo GSAP manteve a sequência e o mosaico em oito quadros comparados com o render anterior. O WebM com transparência teve 168 quadros e a composição em Fluvie teve 186, incluindo a introdução.

Ao acrescentar uma possibilidade, registre o tipo de pauta, a fixture editável, o comando de reprodução e o estágio que já foi verificado. Use uma pauta sintética ou fontes públicas para exemplos compartilháveis. Mantenha pautas privadas e renders de revisão na pasta da tentativa.

## Gráficos quantitativos com incerteza ou painéis independentes

`quantitative_chart` exporta PNG 1080 × 1350 e recebe duas formas de entrada:

- `kind: intervals`: duas a quatro estimativas independentes com limites inferior e superior, eixo assinado fixo, zero rotulado, rótulos diretos e um destaque em outra unidade fora do eixo. [Entrada sintética](../example/fixtures/quantitative_chart.json).
- `kind: bar_panels`: dois painéis de duas a quatro barras categóricas, cada um com unidade e máximo próprios e base zero. A anotação pertence a uma categoria; datas irregulares não são conectadas. [Entrada sintética](../example/fixtures/quantitative_chart_panels.json).

Ambos têm título, subtítulo, destaque com legenda e fontes, contexto, nota de escopo e chave de fontes. O worker inclui os exemplos nos prompts de planejamento e redação, valida os IDs verificados e incorpora o texto alternativo no PNG. A validação Dart é compartilhada com o renderer; limites fora do eixo, intervalos invertidos, valores negativos em barras e referências ausentes são rejeitados. Texto que excede a página faz o render falhar, evitando uma entrega cortada.

```bash
dart example/bin/validate_editorial.dart quantitative_chart < example/fixtures/quantitative_chart.json
bash tool/render_example.sh quantitative_chart example/fixtures/quantitative_chart.json /tmp/dots-intervals
bash tool/render_example.sh quantitative_chart example/fixtures/quantitative_chart_panels.json /tmp/dots-panels
bash tool/render_example.sh editorial_matrix example/fixtures/editorial_matrix_rows_note.json /tmp/dots-rows-note
```

A matriz aceita `rows_note`, uma nota opcional de até 60 caracteres imediatamente acima da primeira linha. Use para indicar o período das linhas sem confundir observações históricas com um lançamento posterior. Omitir o campo preserva a composição anterior.

Verificação: exportações reais pelo comando acima, prévias conferidas a 360/390 px e testes em `example/test/quantitative_document_test.dart`, `example/test/editorial_documents_test.dart` e `tool/test_editorial_dots.py`. A geometria dos intervalos é calculada sem arredondar; apenas os rótulos são arredondados. O limite inferior positivo da segunda linha sintética fica 28,16 pixels à direita de zero no PNG. Pautas e evidências privadas permanecem nas pastas das tentativas da ponte.
