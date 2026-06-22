# Arquitetura da Feature — [Feature]

> Formato agnóstico de linguagem. Descreve as camadas e a direção das dependências; **cada
> linguagem realiza com seu idioma** (TS: pastas + barrels; Go: packages + `internal/`; Python:
> módulos/pacotes; Java: pacotes). Preencha no plan-writer. Guia: skill `architecture`.

## Camadas

| Camada | Responsabilidade | Pode depender de | NÃO pode depender de |
|---|---|---|---|
| `domain` | Entidades, value objects, invariantes de negócio | (nada externo) | framework, I/O, banco, HTTP |
| `application` | Use cases; define **portas** (interfaces) | `domain` | infra concreta |
| `infrastructure` | Implementa as portas: repos, clients, ORM | `application`, `domain` | `interface` |
| `interface` | Entrega: HTTP/CLI/UI; converte entrada/saída | `application` | detalhes de `infrastructure` |

Direção de dependência (só para dentro): `interface → application → domain`;
`infrastructure → application/domain` (implementando portas declaradas dentro).

## Realização nesta linguagem/stack

- Linguagem: [ex.: TypeScript]
- Mapeamento de camada → unidade: [ex.: cada camada é uma pasta; imports cruzando a fronteira são
  proibidos pelo pack de enforcement]
- Enforcement: [ex.: `ts-clean-arch` via dependency-cruiser; ou "advisory" se não houver pack]

## Componentes desta feature

- **Domínio:** [entidades / value objects / agregados + raízes]
- **Use cases:** [intenções + portas que cada um declara]
- **Adapters/infra:** [implementações das portas: repositório X, client Y]
- **Interface:** [endpoints/comandos de entrada]

## Decisões de fronteira

- [Por que tal coisa é domínio e não infra]
- [Onde fica cada porta e quem a implementa]
- [Agregados e seus limites de consistência]
