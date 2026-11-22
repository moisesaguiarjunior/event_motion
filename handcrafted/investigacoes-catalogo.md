# Investigações para o catálogo artesanal

Vinculadas ao catálogo de 36 filmes. São requisitos criativos a confrontar com a API do `handcrafted_flutter`, não recursos declarados ausentes. Nenhuma issue foi aberta. A primeira etapa de cada item é inspecionar a versão atual do pacote e construir uma prova mínima; só depois formular o pedido com evidência.

| ID | Briefings | Necessidade observável | Prova e decisão |
|---|---|---|---|
| HC-C01 | 01, 02, 16 | Fibras e textura acompanham compressão de algodão, feltro e tricô. | Comprimir e dobrar uma peça com seed fixa; conferir borda, continuidade de fibra e estabilidade entre quadros. Verificar materiais e articulação existentes. |
| HC-C02 | 01, 04, 15, 22 | Fios e varais tensionados entre pontos móveis, com folga e peso. | Dois apoios e uma carga deslizante; comparar curvas Flutter com APIs existentes. Uma composição local pode bastar, sem ampliar o pacote. |
| HC-C03 | 03, 14, 26 | Dobras de papel articuladas com verso, vinco, espessura e oclusão. | Abrir uma página com duas dobraduras conectadas. Conferir posição do pivô e sombra durante todo o arco. |
| HC-C04 | 05, 17, 25 | Aparência translúcida artesanal com espessura e borda coerentes. | Gota sobre duas cores e papel vegetal sobre uma forma móvel. Investigar materiais existentes antes de propor efeitos de vidro. |
| HC-C05 | 06, 11, 16, 30 | Tecido que enrola, ondula e acomoda preservando sua textura. | Desenrolar um tapete com verso visível; verificar deformação e recursos existentes. A onda deve atravessar a peça, não apenas mudar sua escala. |
| HC-C06 | 02, 12, 21, 31 | Pigmento espesso, mistura e absorção com controle por tempo. | Comparar espalhamento e pigmento já disponíveis com três estados do mesmo gesto. Delimitar se a demanda é material, composição ou simulação. |
| HC-C07 | 04, 18, 32, 35 | Peças rígidas articuladas com contato e sombra coerentes. | Roda rolando sem deslizar, cadeira com pivô no chão e xícara pendurada que mantém vertical. Verificar se bastam transforms e relógio da composição. |
| HC-C08 | 12, 16, 33 | Fibras e fragmentos com trajetórias determinísticas e repouso. | Vinte fragmentos com seed fixa, amostrados fora de ordem pelo Fluvie. Separar aparência artesanal de partículas e comportamento físico. |
| HC-C09 | 22, 28, 34 | Laços e nós com frente/verso, oclusão e tensão no tecido. | Um laço apertando lentamente, sem interpenetração; comparar montagem manual com formas e articulações existentes. |
| HC-C10 | Todos os cenários compostos | Sombras de contato e luz consistentes entre peças móveis. | Peça sobe, gira e pousa sobre uma superfície; conferir sombra e relevo atuais. Documentar o que o pacote oferece e o que depende de renderização da cena. |

Pedidos anteriores continuam em `pedidos.md`. Estes IDs permitem ligar uma futura prova ou issue ao briefing que a motivou. Não há prioridade técnica atribuída sem medir o que já funciona.


## Provas separadas para a primeira leva

- **04 / roda e freada:** carroceria e duas rodas artesanais sobre um trilho. Medir giro pelo deslocamento; provar avanço, parada, ré e acomodação da caixa. Só depois acrescentar o embarque.
- **04 / berço de linha:** botão, base de balsa, guias, batente, carretel, polias, aba da soleira e empurrador; provar apoio sob o botão, recolhimento, parada e transferência contínua para o piso. Pode ser uma curva desenhada por quadro; simulação física não é requisito. Registrar se o fio é resolvido pela composição ou pede algo ao pacote.
- **03 / dobradura:** uma página e duas peças conectadas, com verso e sombra. Primeiro conferir a abertura, depois a mão e o marcador.
- **05 / gota:** testar apenas o contorno leitoso e a divisão visível da água ao tocar o dedal; a transparência do papel vegetal de 25 é outra prova. Não exigir refração física se o gesto fica claro com um material estilizado.
- **32 / cadeira:** contato do arco inferior com o piso, inclinação do assento e atraso da almofada. Não agrupar esta prova com roda de bonde ou xícara suspensa.
