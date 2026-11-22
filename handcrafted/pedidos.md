# Necessidades para investigar no handcrafted_flutter

Registro de oportunidades surgidas ao desenvolver os briefings. São hipóteses, não defeitos confirmados; conferir a API atual e criar uma prova mínima antes de abrir pedidos.

| Origem | Necessidade | Verificação anterior a um pedido |
|---|---|---|
| Chá de estrelas | Personagens táteis articulados, com materiais que acompanhem deformação, respiração, piscada, orelhas e asas. | Investigar as peças articuladas existentes, continuidade das texturas e ergonomia ao montar personagens. |
| Chá de estrelas | Camadas de cenário artesanal com profundidade, iluminação e movimento independente de câmera. | Verificar se APIs atuais cobrem recortes, sombras e transformação das superfícies; separar responsabilidades de composição no Flutter/Fluvie. |
| Chá de estrelas | Partículas luminosas com aparência de pigmento, pó ou fio artesanal, determinísticas por quadro e integráveis à iluminação da cena. | Investigar pincéis, pigmentos e APIs já existentes; comparar com os pontos e a costura desta prova. |
| O jardim que sonha | Personagens de feltro articulados com pivôs, sombras locais, deformação e preservação de textura. | A montagem atual posiciona e gira cada `CraftSurface` manualmente; avaliar as peças articuladas existentes e fazer uma prova de continuidade antes de propor uma API. |
| O jardim que sonha | Iluminação e sombras coerentes entre superfícies artesanais em movimento e fundo. | Investigar relevo/iluminação existentes e integração com camadas Flutter; a prova usa formas e iluminação independentes. |
| Jardim, revisão 2 | Gola e tecido com dobras, nó, ponta e franja que compartilhem iluminação e textura. | A prova monta três superfícies e desenha a franja manualmente; investigar deformação das peças e sombreado antes de propor componentes de roupa. |
| Jardim, revisão 2 | Sombra de contato que acompanhe altura e pose de peças articuladas. | A prova desenha elipses suaves; verificar iluminação/relevo existentes para uma sombra derivada das silhuetas. |
