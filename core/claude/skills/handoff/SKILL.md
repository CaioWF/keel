---
name: handoff
description: Use ao PAUSAR/encerrar uma sessão (grava o estado atual em docs/STATE.md para retomar depois) ou ao RETOMAR (lê docs/STATE.md e a spec ativa, recompõe o contexto e propõe o próximo passo). Mantém continuidade entre sessões de humanos e agentes.
---

# handoff — continuidade de sessão (pause / resume)

Mantém a continuidade do projeto via `docs/STATE.md`, a memória de trabalho **volátil**
(diferente do ADR, que é decisão **durável** em `docs/architecture/adr/`). Detecte a intenção
pelo pedido (pausar vs. retomar); se ambíguo, pergunte.

## Modo PAUSE (pausar / encerrar)

Atualize `docs/STATE.md` com o estado real desta sessão:

1. **Em andamento / próximo passo** — a feature/spec ativa e a **próxima ação concreta** e
   específica ("implementar AC-3 no adapter X", não "continuar a feature").
2. **Decisões recentes** — o que foi decidido. Se for difícil de reverter, **crie/atualize um ADR**
   (`docs/architecture/adr/`, use `_template.md`) e linke; o STATE só resume.
3. **Bloqueios** — o que trava e quem/como destrava.
4. **Ideias adiadas / todos** — o que ficou de fora de propósito, com o gatilho para reconsiderar.
5. Marque a data e o autor. Se houver `SPEC_DEVIATION` aberto no código, registre como bloqueio.
6. Seja conciso e acionável — o STATE é para alguém (ou um agente) retomar **frio** amanhã.

Não commite por conta própria; ofereça o commit (`docs: handoff — atualiza STATE`) e aguarde
aprovação, conforme a regra de commits do projeto.

## Modo RESUME (retomar)

1. Leia `docs/STATE.md` e a `spec.md`/`tasks.md` da feature ativa citada nele.
2. **Resuma onde paramos** em poucas linhas: feature ativa, último passo, bloqueios abertos.
3. **Proponha o próximo passo** (o "Em andamento / próximo passo" do STATE) e confirme com o
   usuário antes de executar.

## Regras

- STATE.md é **volátil**; ADR é **durável**. Nunca escreva uma decisão estrutural só no STATE.
- Não invente progresso: relate fielmente o que foi feito, o que falta e o que está bloqueado.
- O STATE já é injetado no contexto no SessionStart; ao retomar, confie nele como ponto de partida.
