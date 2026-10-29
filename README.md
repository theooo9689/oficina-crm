# Oficina CRM

CRM simples para acompanhar prospectados, orçamentos e observações dos leads.

## Ativar a sincronização sem e-mail

1. No Supabase do projeto, abra **SQL Editor → New query**.
2. Copie e execute uma vez o conteúdo de [supabase/access-code-migration.sql](supabase/access-code-migration.sql).
3. Abra o [CRM publicado](https://theooo9689.github.io/oficina-crm/), clique em **Nuvem** e informe o código compartilhado.
4. Repita no outro notebook usando o mesmo código. O navegador lembra o código depois da primeira conexão; as alterações sincronizam em até 10 segundos.

A migração cria uma tabela acessada por funções que validam o código. Ela também copia os registros da tabela antiga `public.leads`, se houver. O código em texto puro não está no repositório; mantenha-o privado. O site não inclui os nomes e telefones dos leads.
