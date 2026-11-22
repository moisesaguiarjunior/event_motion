# Fluxo editorial do Dots até o X

O Dots reúne uma pauta e envia o briefing JSON para a fila privada no GitHub. A ponte local lê a fila no Mac e encaminha cada pauta editorial ao checkout do Event Motion. A ponte continua responsável por reservas, retentativas e retorno dos arquivos. No macOS, a rotina existente consulta a fila a cada 15 minutos enquanto a sessão está disponível.

## Da pauta ao rascunho

1. **Sol pesquisa e propõe a matéria.** Abre as fontes primárias e registra o que cada fonte sustenta. Propõe tese, abertura, contraponto, voz e direção da arte. Números carregam unidade, data, escopo e denominador quando aplicável.
2. **Sol e Opus discutem o plano.** O Opus recebe a pesquisa e testa a tese e a leitura da imagem. Aponta o que manter e pode propor um caminho mais forte. O Sol decide o que incorporar e torna a decisão visível. Os dois modelos recebem o briefing como material editorial.
3. **Sol escreve e especifica a arte.** Produz o texto para X, texto alternativo e JSON editável. Uma correção factual pode trazer uma fonte ou afirmação nova, com ID próprio. O Opus recebe o texto e o JSON exatos para a segunda deliberação.
4. **Opus revisa antes de renderizar.** Erro factual, arte que distorce os dados e perda do caráter editorial podem bloquear a saída. Uma preferência estilística pode ser recusada. Se houver um problema reparável, há uma rodada de correção e nova revisão. Uma pendência remanescente devolve o parecer e a pesquisa para revisão humana.
5. **Event Motion renderiza a peça revisada.** O pacote volta à fila privada para a aprovação de Moisés com pauta, texto para X e imagem. Quando a pauta pede vídeo ou os agentes escolhem animar a peça, a pasta inclui o MP4.

## Pasta de entrega

A ponte devolve uma pasta por tentativa em `results/<id>/attempt-<n>/artifacts/`.

| Arquivo | Conteúdo |
| --- | --- |
| `pauta.md` | Briefing original do Dots, links enviados com ele, tese e direção visual. |
| `post.md` | Texto revisado, pronto para colar no X. |
| `imagem.png` | Imagem final, inclusive nas entregas com vídeo. |
| `video.mp4` | Animação, quando prevista na entrega. |
| `visual.json` e `alt-text.txt` | Composição editável e descrição acessível. |
| `research-notes.md` e `editorial-review.md` | Fontes, evidências, pareceres e decisões. |
| `demandas-gerador.md` | Propostas para ampliar o gerador, quando surgirem. |

Uma pauta pendente volta com o briefing, a pesquisa, o parecer e as eventuais demandas do gerador. O post e a arte entram depois da revisão editorial.

## Demandas para o gerador

Sol e Opus podem registrar lacunas durante a pesquisa, a deliberação ou a revisão. Cada proposta informa a capacidade desejada, o formato afetado, a origem, o motivo e um critério de aceite observável. Propostas idênticas aparecem uma vez com todas as origens. A coleta fica na pasta privada da pauta para triagem humana.

Um exemplo é anotar a diferença entre duas séries com um colchete vertical. A demanda descreve a leitura que se quer facilitar e pode pedir que a linha conecte os dois valores na mesma categoria, com um rótulo que mostre a diferença e a unidade.

## Caráter editorial

Escolha um ponto de vista que faça sentido sem o gráfico. Abra com a observação, o contraste ou a imagem concreta que merece o post. Preserve as frases que têm ritmo, os exemplos que fazem o argumento andar e o humor que decorre da situação. Se uma afirmação estiver errada, corrija a afirmação e procure um detalhe igualmente vivo. O autor pode manter uma frase que funciona mesmo quando o outro modelo prefere uma versão mais uniforme.

A referência visual tem leitura em camadas. O gráfico e a anotação contam a história principal. Cards de evidência e cronologia deixam a pessoa aprofundar o assunto. A composição escolhe quais dessas camadas servem à tese. [Referência visual no X](https://x.com/SadAlbert10/status/2124233311132557475/photo/1)

## Imagem e vídeo

| Composição | Use para | Saída |
| --- | --- | --- |
| `data_story` | Até três séries comparáveis, categorias igualmente espaçadas, anotação de um ponto e até quatro cards de evidência e quatro marcos. A arte conserva unidades e notas de fonte. | PNG de 1440 × 1800. A versão MP4 dá tempo ao gráfico, evidências e cronologia em oito segundos. |
| `editorial_catalog` | Explicações em oito a doze células, cada uma com um diagrama ilustrativo, paleta e ordem de leitura. | PNG e, quando solicitado, MP4 com destaque em sequência. |

O briefing mantém a versão 1 da ponte. A imagem acompanha todo post aprovado e o campo `infographic` continua disponível para solicitá-la explicitamente. Inclua `video` quando a animação for obrigatória. O renderer usa Flutter e Fluvie. `visual.json` reproduz a peça a partir do template registrado no parecer. [Guia de customização](casos-de-uso.md) · [Fixture da peça com dados](../example/fixtures/data_story.json)

```sh
bash tool/render_example.sh data_story
bash tool/render_example.sh data_story_video
```

## Rodar a entrada do repo

O worker passa o caminho de `tool/editorial_dots.py` pela configuração local `editorial_entry`. Para verificar manualmente um briefing já salvo, use um diretório separado por tentativa.

```sh
python3 -B tool/editorial_dots.py /path/to/briefing.json /path/to/new-attempt
```

A entrada chama `codex exec` com Sol e pesquisa web, sem ferramenta de shell, e `claude -p` com Opus e saída estruturada. Ela usa os logins das duas CLIs. O processo local chama apenas os renderizadores do repo na montagem. A decisão `ready_for_review` libera o pacote para a fila. A ponte apresenta pendências como `needs_review`. Os eventos do Codex, respostas do Claude e diagnósticos do renderer ficam na pasta local da tentativa. [Claude Code em modo não interativo](https://code.claude.com/docs/en/headless)
