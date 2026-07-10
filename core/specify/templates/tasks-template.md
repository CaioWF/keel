# Tarefas — [Feature]

## Checklist de Implementação

> Cada task que entrega um critério de aceitação deve citar o `AC-N` correspondente da spec
> (ex.: `(AC-1)`). O gate `eval-spec-fidelity` falha se algum `AC-N` da spec não tiver task.
>
> Cada task pode declarar seu **scope de arquivos** com `[scope: glob, glob]` — os globs que
> ela vai tocar (deriva do `Estrutura de Arquivos` do plan). Tasks com scopes disjuntos podem
> rodar em paralelo no modo `dispatch-parallel` (ver `execution-mode-routing`). Sem `[scope: …]`,
> ou com glob amplo (`**`, `*`), a task nunca paraleliza — roda sozinha (default seguro).

- [ ] Task 1: Descrição da tarefa (AC-1) [scope: src/moduloA/**, tests/moduloA/**]
- [ ] Task 2: Descrição da tarefa (AC-2) [scope: src/moduloB/**, tests/moduloB/**]
- [ ] Task 3: Descrição da tarefa
- [ ] Task 4: Descrição da tarefa
- [ ] Task 5: Descrição da tarefa

## Subtarefas

### Task 1
- [ ] Subtarefa 1.1
- [ ] Subtarefa 1.2

### Task 2
- [ ] Subtarefa 2.1
- [ ] Subtarefa 2.2

## Bloqueadores

- [Listagem de bloqueadores conhecidos ou dependências]

## Notas

- [Anotações importantes para execução]
