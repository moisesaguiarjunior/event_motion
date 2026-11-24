# Fluxo editorial do Dots até o X

O Dots reúne uma pauta e envia o briefing JSON para a fila privada no GitHub. A ponte local lê a fila no Mac e encaminha cada pauta editorial ao checkout do Event Motion. A ponte continua responsável por reservas, retentativas e retorno dos arquivos. No macOS, a rotina existente consulta a fila a cada 15 minutos enquanto a sessão está disponível.

## Da pauta ao rascunho

1. **Sol pesquisa e propõe a matéria.** Abre as fontes primárias e registra o que cada fonte sustenta. Propõe tese, abertura, contraponto, voz e direção da arte. Números carregam unidade, data, escopo e denominador quando aplicável.
2. **Sol e Opus discutem o plano.** O Opus recebe a pesquisa e testa a tese e a leitura da imagem. Aponta o que manter e pode propor um caminho mais forte. O Sol registra qual ângulo alternativo as fontes sustentam e por que o escolhido importa mais. Se o Opus bloquear o ângulo, o Sol volta às fontes e o Opus revisa o novo plano antes da redação. Se o ângulo continuar bloqueado, a pauta volta para revisão sem post. Os dois modelos recebem o briefing como material editorial.
3. **Sol escreve e especifica a arte.** Produz o texto para X e, quando há uma composição adequada, o texto alternativo e o JSON editável. Uma correção factual pode trazer uma fonte ou afirmação nova, com ID próprio. O Opus recebe o texto e o JSON exatos para a segunda deliberação.
4. **Opus revisa antes de renderizar.** Erro factual, arte que distorce os dados e perda do caráter editorial podem bloquear a saída. Uma preferência estilística pode ser recusada. Se houver um problema reparável, há uma rodada de correção e nova revisão. Uma pendência remanescente devolve o parecer e a pesquisa para revisão humana.
5. **Event Motion renderiza a peça revisada.** O pacote volta à fila privada para a aprovação de Moisés com pauta, texto para X e imagem. Quando a pauta pede vídeo ou os agentes escolhem animar a peça, a pasta inclui o MP4.

## Pasta de entrega

A ponte devolve uma pasta por tentativa em `results/<id>/attempt-<n>/artifacts/`.

| Arquivo | Conteúdo |
| --- | --- |
| `pauta.md` | Briefing original do Dots, links enviados com ele, tese e direção visual. |
| `post.md` | Texto revisado com referências numeradas e sem URLs, pronto para colar no X. |
| `sources-reply.txt` | Links correspondentes, prontos para colar em uma resposta separada. |
| `imagem.png` | Imagem final, inclusive nas entregas com vídeo. |
| `video.mp4` | Animação, quando prevista na entrega. |
| `visual.json` e `alt-text.txt` | Composição editável e descrição acessível. |
| `assets/*.png` | Camadas de arte que o `visual.json` usa, quando a pauta inclui PNGs locais aprovados. |
| `research-notes.md` e `editorial-review.md` | Fontes, evidências, pareceres e decisões. |
| `demandas-gerador.md` | Propostas para ampliar o gerador, quando surgirem. |

Se Opus aprovar o texto com o visual pendente, a saída editorial é `needs_visual` e a ponte grava `needs_review`. A tentativa devolve o post, a resposta com as fontes, a pesquisa, o parecer e o motivo da pendência. O JSON entra se tiver sido validado. Um problema factual em aberto impede a entrega do post.

## Demandas para o gerador

Sol e Opus podem registrar lacunas durante a pesquisa, a deliberação ou a revisão. Cada proposta informa a capacidade desejada, o formato afetado, a origem, o motivo e um critério de aceite observável. Propostas idênticas aparecem uma vez com todas as origens. A coleta fica na pasta privada da pauta para triagem humana.

No Mac, as propostas ficam em `runtime/jobs/<id>/attempt-<n>/artifacts/demandas-gerador.md` dentro de `~/Library/Application Support/DotEditorialBridge`. A ponte copia o arquivo para `results/<id>/attempt-<n>/artifacts/` na fila privada quando entrega o pacote. Uma tentativa que falhou antes da entrega pode ter o pedido salvo apenas no Mac. Tentativas antigas também podem ter pedidos nas respostas em `.editorial/`.

O arquivo privado `runtime/generator-requests.md` reúne a triagem por capacidade, com ID, origem, critério de aceite, estado e evidência. Ao triar uma proposta nova, acrescente a origem ao ID existente ou abra um ID. Ao concluir, registre o teste ou a exportação que verifica o critério de aceite. O estado da pauta fica em `runs/<id>.json` na fila privada. O estado do pedido é atualizado na triagem.

```sh
rg --files --hidden "$HOME/Library/Application Support/DotEditorialBridge/runtime/jobs" \
  -g demandas-gerador.md
```

Quando falta a composição ideal, Sol registra a demanda e escolhe uma composição instalada que preserve a leitura dos dados. Se nenhuma servir, usa `template: none` e `media: none` e segue com o post. Opus pode aprovar o texto com a arte pendente. Se o plano identificar que falta uma composição, ou se as tentativas de validar e renderizar o visual se esgotarem, o worker cria uma entrada com a direção visual, o motivo e um critério de aceite quando os agentes ainda não registraram uma demanda.

Para atender a uma demanda, Sol pode implementar localmente uma composição reutilizável com entrada editável, fixture sintética e validação pelo caminho normal de exportação. Astra revisa a implementação e verifica a saída antes de incluir a composição no fluxo editorial. O worker agendado registra as demandas para triagem e usa as composições já instaladas.

Um exemplo é anotar a diferença entre duas séries com um colchete vertical. A demanda descreve a leitura que se quer facilitar e pode pedir que a linha conecte os dois valores na mesma categoria, com um rótulo que mostre a diferença e a unidade.

## Caráter editorial

Escolha um ponto de vista que faça sentido sem o gráfico. Abra com a observação, o contraste ou a imagem concreta que merece o post. Preserve as frases que têm ritmo, os exemplos que fazem o argumento andar e o humor que decorre da situação. Se uma afirmação estiver errada, corrija a afirmação e procure um detalhe igualmente vivo. O autor pode manter uma frase que funciona mesmo quando o outro modelo prefere uma versão mais uniforme.

A pesquisa precisa encontrar o fato que justifica a leitura, por que ele ficou relevante agora e quem é afetado. Se as fontes primárias sustentarem uma tese diferente da sugerida no briefing, a pauta muda junto. O Opus pode bloquear um rascunho que enterre o dado decisivo ou prometa uma conclusão que as fontes ainda não sustentam.

Uma pergunta curta pode abrir o post. Se ela depende de uma notícia recente, diga logo o que mudou e quando, antes do dado que explica a relevância. Use uma medida de escala quando ela ajuda a entender o impacto, com seu recorte e período. Uma observação direta ou um número podem funcionar melhor em outra pauta. Por exemplo, a entrada do ChatGPT Enterprise no AWS Marketplace ganha relevância diante da parcela da receita da Anthropic que veio de marketplaces de nuvem. Esse dado dá dimensão ao canal. O efeito da listagem sobre o crescimento da Anthropic é uma hipótese. Histórico e exemplos entram quando explicam ou qualificam o ponto central.

A referência visual tem leitura em camadas. O gráfico e a anotação contam a história principal. Cards de evidência e cronologia deixam a pessoa aprofundar o assunto. A composição escolhe quais dessas camadas servem à tese. [Referência visual no X](https://x.com/SadAlbert10/status/2124233311132557475/photo/1)

## Imagem e vídeo

O [mapa de ilustrações possíveis](mapa-de-ilustracoes.md) reúne os formatos, os exemplos e os pontos de reuso para novas pautas.

| Composição | Use para | Saída |
| --- | --- | --- |
| `quantitative_chart` | Estimativas com intervalos de confiança em um eixo assinado ou dois painéis de barras com unidades e eixos independentes. | PNG de 1080 × 1350; JSON editável e texto alternativo embutido. |
| `data_story` | Linha, pontos pareados, rosca e barra empilhada. As composições aceitam anotação, evidências, cronologia, unidade e fontes. | PNG de 1440 × 1800 para linha e rosca. Pontos pareados e barra exportam em 1080 × 1350. A versão MP4 dura oito segundos. |
| `editorial_catalog` | Explicações em oito a doze células, cada uma com um diagrama ilustrativo, paleta e ordem de leitura. | PNG e, quando solicitado, MP4 com destaque em sequência. |
| `editorial_matrix` | Cronologia qualitativa com duas a quatro linhas. Data e mudança ficam ao lado de duas colunas de papéis. A matriz aceita um dado de destaque com a legenda logo abaixo. A nota de escopo e a chave de fontes ficam no rodapé. | PNG de 1440 × 1800. Com dado de destaque, exporta em 1080 × 1350. |
| `editorial_illustration` | Canal de distribuição, rota de API ou processamento com uma origem, um canal e até dois destinos. Cartões, anotação e fontes são editáveis. As conexões acompanham o número de destinos. | PNG de 1080 × 1350. O MP4 opcional dura cinco segundos, a 24 fps, e revela a rota em ordem. |

O briefing mantém a versão 1 da ponte. O pacote completo inclui imagem e o campo `infographic` permite solicitá-la explicitamente. Inclua `video` quando a animação for obrigatória. O renderer usa Flutter e Fluvie. `visual.json` reproduz a peça a partir do template registrado no parecer. [Guia de customização](casos-de-uso.md) · [Fixture da peça com dados](../example/fixtures/data_story.json)

```sh
bash tool/render_example.sh data_story
bash tool/render_example.sh data_story example/fixtures/data_story_composition.json
bash tool/render_example.sh data_story_video
bash tool/render_example.sh editorial_matrix
bash tool/render_example.sh editorial_illustration
```

Em `data_story`, o campo `chart_kind` seleciona a composição. O padrão é `line`.

- `paired_dot` recebe exatamente duas séries sobre o mesmo eixo horizontal. A primeira usa pontos vazados e a segunda usa pontos preenchidos. Cada ponto recebe o valor na própria linha. [Exemplo de pontos pareados](../example/fixtures/data_story_paired_dot.json)
- `line` e `paired_dot` aceitam `y_min`, `y_max`, `axis_suffix` e `reference_lines`. Os limites se aplicam ao eixo de valores, que é horizontal nos pontos pareados. Cada referência tem `value` e `label`. Sem limites, a faixa é calculada a partir dos valores. [Exemplo de linha com eixo fixo](../example/fixtures/data_story_axis.json)
- `stacked_bar` recebe uma série de duas a sete partes positivas que somam 100. O `subtotal` recebe índices inclusivos `start_index` e `end_index`, começando em zero, e um `label` com a descrição. O renderer soma as partes selecionadas e posiciona o colchete. `value_prefix` configura o símbolo usado no valor, e `approximate_indices` acrescenta a marca de aproximação. [Exemplo de barra empilhada](../example/fixtures/data_story_stacked_bar.json)
- `composition` usa a rosca do Fluvie com duas a sete partes positivas que somam 100. `slice_groups` recebe um grupo por categoria, com `null` para as fatias independentes. Cada grupo reúne duas ou três fatias e aparece na legenda com os tons correspondentes. [Exemplo de rosca agrupada](../example/fixtures/data_story_grouped_donut.json)

Em `editorial_matrix`, `hero_stat` recebe `value` e `caption`. A legenda pode incluir denominador, período, escopo e referências com os IDs do rodapé. [Exemplo de matriz com destaque](../example/fixtures/editorial_matrix_hero.json)

Em `editorial_illustration`, o Sol edita `origin`, `channel`, `destinations` e, quando útil, `annotation`. O renderer desenha as conexões. O Opus recebe o JSON completo antes do render. O worker confere os IDs do rodapé com as fontes verificadas e grava o texto alternativo na imagem e no pacote. [Exemplo editável da ilustração](../example/fixtures/editorial_illustration.json)

Quando uma pauta pedir arte externa, coloque os PNGs aprovados na pasta local `example/assets/editorial_local/` e inclua os nomes em `illustration_assets` no briefing JSON. Indique no briefing onde cada peça entra. O worker usa a lista para validar referências `asset` nos cartões e leva ao pacote só os PNGs usados. O JSON entregue pode ser renderizado novamente com a pasta `assets/` ao lado. [ComfyUI e render local](integrations.md#comfyui-para-camadas-de-ilustração)

As exportações de pontos pareados e de barra empilhada incluem no PNG o texto alternativo da pauta e mantêm `alt-text.txt` no pacote. Nos renders manuais, a descrição pode vir do campo `alt_text` do JSON.

O catálogo, a matriz e o contrato da rosca usam a mesma validação Dart na geração e no render. Um JSON fora do contrato volta ao Sol para correção antes da revisão do Opus. Se o renderer detectar um erro de contrato após a revisão, o agente pode corrigir apenas o visual uma vez na mesma etapa e submete o visual corrigido ao Opus antes de renderizar novamente. Se a imagem continuar bloqueada, a ponte encerra em `needs_review` e entrega o post, a pesquisa, o JSON quando validado e o motivo da pendência. A retentativa da fila não refaz uma pauta por erro de formato. As demandas registradas durante a pauta ficam na pasta local da tentativa mesmo se o render falhar. [Exemplo editável da matriz](../example/fixtures/editorial_matrix.json)

## Rodar a entrada do repo

O worker passa o caminho de `tool/editorial_dots.py` pela configuração local `editorial_entry`. Para verificar manualmente um briefing já salvo, use um diretório separado por tentativa.

```sh
python3 -B tool/editorial_dots.py /path/to/briefing.json /path/to/new-attempt
```

A entrada chama `codex exec` com Sol e pesquisa web, sem ferramenta de shell, e `claude -p` com Opus e saída estruturada. Ela usa os logins das duas CLIs. O processo local chama apenas os renderizadores do repo na montagem. A decisão `ready_for_review` libera o pacote para a fila. A ponte apresenta pendências como `needs_review`. Os eventos do Codex, respostas do Claude e diagnósticos do renderer ficam na pasta local da tentativa. [Claude Code em modo não interativo](https://code.claude.com/docs/en/headless)

A matriz aceita também `rows_note` (até 60 caracteres), imediatamente acima das linhas. Para intervalos e painéis independentes, use as [entradas quantitativas e comandos de reprodução](mapa-de-ilustracoes.md#gráficos-quantitativos-com-incerteza-ou-painéis-independentes).
