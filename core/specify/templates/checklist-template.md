# Checklist Pré-Merge

## Testes

- [ ] Testes unitários implementados
- [ ] Testes de integração implementados
- [ ] Cobertura de testes > 80%
- [ ] Todos os testes passam localmente

## Quality Gates

- [ ] Linter sem erros
- [ ] Tipos TypeScript corretos
- [ ] Sem console.log ou debug statements
- [ ] Performance dentro dos limites

## Documentação

- [ ] Spec atualizada com implementação final
- [ ] Código comentado onde necessário
- [ ] README/docs atualizados
- [ ] Exemplos de uso se aplicável

## Code Review

- [ ] PR revisada por pelo menos 1 reviewer
- [ ] Feedback incorporado ou respondido
- [ ] Commits com histórico claro

## Deploy

- [ ] Migrations testadas (se aplicável)
- [ ] Variáveis de ambiente documentadas
- [ ] Rollback plan documentado
- [ ] Monitoramento e alertas configurados

## Segurança

- [ ] Sem secrets/credenciais hardcoded
- [ ] Checks de autorização em allow-list (não deny-list)
- [ ] Input validado / sem injeção (SQL/comando/path)
- [ ] Sem SSRF em requests externos
- [ ] Crypto forte / IDs imprevisíveis
- [ ] Nenhuma dependência de terceiro nova sem revisão (supply-chain)
- [ ] Secrets fora dos logs
