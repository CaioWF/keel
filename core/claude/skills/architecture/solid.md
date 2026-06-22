# SOLID (agnóstico de linguagem)

Cinco heurísticas para módulos que mudam sem quebrar. Use como checklist de desenho, não como
dogma — cada uma resolve uma dor específica de acoplamento/coesão.

## S — Single Responsibility

Uma unidade tem **uma razão para mudar** (um ator/stakeholder). Se duas mudanças não
relacionadas tocam o mesmo módulo, separe.
- Red flag: classe/função que faz parsing + regra de negócio + persistência.

## O — Open/Closed

Aberto para extensão, fechado para modificação. Adicione comportamento por **nova implementação
de uma abstração**, não editando o código existente que já funciona.
- Red flag: um `switch`/`if` por tipo que cresce a cada feature nova. Considere polimorfismo/estratégia.

## L — Liskov Substitution

Um subtipo deve ser usável onde o supertipo é esperado, **sem surpresa**. Não fortaleça
pré-condições nem enfraqueça pós-condições.
- Red flag: subclasse que lança em método herdado, ou checagem `instanceof` para tratar um subtipo diferente.

## I — Interface Segregation

Clientes não devem depender de métodos que não usam. Prefira **portas pequenas e focadas** a uma
interface gorda.
- Red flag: implementar uma interface com metade dos métodos jogando `notImplemented`.

## D — Dependency Inversion

Dependa de **abstrações**, não de concretos. Módulos de alto nível (use cases) definem a porta;
os de baixo nível (infra) a implementam. É o motor da dependency rule da Clean Architecture.
- Red flag: use case dando `new` num cliente HTTP/SQL concreto em vez de receber a porta.

## Como aplicar

No desenho da feature (plan-writer), passe o módulo por essas cinco perguntas. SOLID **suporta** a
dependency rule (especialmente D e I): são a forma tática de manter as fronteiras da Clean
Architecture limpas. Enforcement é por lint de linguagem (depois), não no core agnóstico.
