# Estratégia de testes (agnóstico de linguagem)

Onde investir esforço de teste e por quê. O **como** (ciclo red-green-refactor, comportamento >
implementação) está na skill `test-driven-development` — esta nota não reescreve, só posiciona.

## A pirâmide

- **Unidade (base, maioria):** domínio e use cases testados em isolamento, sem framework/rede/banco.
  Rápidos, determinísticos. A Clean Architecture torna isso barato — o domínio é puro.
- **Integração (meio):** adapters reais contra suas dependências (banco em container, HTTP fake).
  Verifica que as portas casam com as implementações.
- **End-to-end (topo, poucos):** fluxo do usuário pela aplicação montada. Caros e mais frágeis —
  cubra os caminhos críticos, não tudo.

Anti-pirâmide (muito E2E, pouca unidade) = suíte lenta e instável. Se testar o domínio exige
subir o mundo, a fronteira está errada (volte à dependency rule).

## Princípios (reforçam `test-driven-development`)

- **Teste comportamento, não implementação:** asserte entradas/saídas/efeitos observáveis. Um
  teste que quebra num refactor que preserva comportamento está testando implementação — reescreva.
- **Não asserte sobre mocks:** mock é para isolar uma dependência de borda, não para ser o objeto
  do teste. Prefira fakes a mocks que verificam chamadas internas.
- **Nomeie pelo comportamento:** o nome do teste descreve a regra de negócio, não o método.
- **Domínio puro = teste sem mock:** se o domínio segue a dependency rule, a maioria dos testes de
  unidade não precisa de mock nenhum.

## Como aplicar

No plan-writer, decida o nível de teste por componente (domínio → unidade; adapter → integração;
fluxo → 1-2 E2E). O gate de teste (`run-gates.sh`) roda a suíte; esta estratégia decide o que
escrever. O enforcement do ciclo TDD é disciplina da skill `test-driven-development` (REQUIRED).
