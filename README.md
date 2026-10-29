# Oficina CRM

CRM para acompanhar prospectados, orçamentos, observações e receitas recebidas.

## Ativar a sincronização sem e-mail

1. No Supabase do projeto, abra **SQL Editor → New query**.
2. Copie e execute uma vez o conteúdo de [supabase/access-code-migration.sql](supabase/access-code-migration.sql).
3. Abra o [CRM publicado](https://theooo9689.github.io/oficina-crm/), clique em **Nuvem** e informe o código compartilhado.
4. Repita no outro notebook usando o mesmo código. O navegador lembra o código depois da primeira conexão; as alterações sincronizam em até 10 segundos.

A migração cria uma tabela acessada por funções que validam o código. Ela também copia os registros da tabela antiga `public.leads`, se houver. O código em texto puro não está no repositório; mantenha-o privado. O site não inclui os nomes e telefones dos leads.

## Financeiro

Em cada lead marcado como Fechado, o campo Receita do processo fechado salva o valor gerado e o lança no gráfico automaticamente. Também é possível adicionar outras receitas manualmente, informar data e descrição, e relacionar cada entrada a um lead. O gráfico tem visões de 30 dias, 90 dias e 12 meses; os pontos mostram valores ao passar o cursor ou navegar pelo teclado. Receitas sincronizam com o mesmo código dos leads e entram nos backups JSON. Não é necessária uma migração SQL adicional para essa função.
