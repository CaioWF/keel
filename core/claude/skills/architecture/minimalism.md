# Minimalismo — a laziness ladder (agnóstico de linguagem)

Heurística geradora: pensar como dev experiente que **resiste a complexidade desnecessária**.
Agente de IA tende a over-engineer — instala dep, cria abstração, gera código verboso quando
algo mais simples resolve. Esta é a disciplina **antes de escrever**: suba a escada e pare no
primeiro degrau que resolve.

## A escada (suba antes de adicionar código)

Para qualquer pedaço de funcionalidade, na ordem:

1. **Precisa existir?** O requisito é real ou é feature inventada/antecipada (YAGNI)? Se não
   precisa, o melhor código é nenhum código.
2. **Já está no codebase?** Existe função/módulo/util que já faz isso? Reuse em vez de recriar.
3. **Está na stdlib?** A linguagem já oferece? Prefira o padrão da linguagem a escrever do zero.
4. **É feature nativa da plataforma?** Runtime/framework/SO já dá de graça? Use o nativo.
5. **Dep já instalada?** Alguma dependência do projeto já cobre? Use o que já está lá antes de
   adicionar pacote novo.
6. **Dá em one-liner?** Se sim, escreva o one-liner — não uma abstração ao redor dele.
7. **Senão: código mínimo viável.** Só agora escreva, e só o mínimo que satisfaz o requisito.

## O carve-out (não-negociável)

A escada otimiza **volume de código**, nunca **corretude de borda**. Jamais corte:

- **Validação de trust-boundary** — input externo é validado, sempre.
- **Tratamento de perda de dados** — falha não pode corromper/perder estado silenciosamente.
- **Segurança** — authz (allow-list), secrets, injection, SSRF, crypto.
- **Acessibilidade** — quando há superfície de usuário.

"Mínimo" significa sem gordura, não sem cinto de segurança. Esses quatro nunca são o degrau que
se pula.

## Minimalismo (pré) vs `simplify` (pós) — não confundir

Puxam direções opostas de propósito:

- **Esta skill decide o que NASCE.** Pré-escrita, geradora: não adicione dep/abstração/feature
  sem subir a escada.
- **`simplify` limpa o que NASCEU.** Pós-escrita, behavior-preserving: melhora leitura do diff —
  e explicitamente **não estripa** abstração que paga aluguel.

Não há contradição: minimalismo evita criar o supérfluo; `simplify` não remove o necessário.
Em dúvida sobre remover algo já escrito, é território de `simplify`, não desta skill.

## Sinais de violação (red flags)

- Dep nova para algo que stdlib/dep-existente já faz.
- Camada de abstração com uma única implementação e nenhum segundo caso à vista.
- Wrapper/helper que só repassa argumentos.
- Config/flag para um caso que ninguém pediu.
- Generalização "pro futuro" sem requisito presente.

## Enforcement

Advisory por natureza — é decisão de desenho, não regra mecânica. O reforço vem do wire-in nas
fases: `analyze` checa o degrau 1 (precisa existir?) contra a spec; `implement-feature` e o
implementer subagent sobem a escada antes de adicionar dep/abstração. A constituição carrega a
regra dura (`## Princípios de arquitetura`). O racional fica aqui.
