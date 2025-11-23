# 🔧 Corrigir Deletar Secretaria Permanentemente

## ✅ Problema Resolvido

A validação de unicidade de secretarias foi melhorada para:
- Verificar apenas secretarias **ATIVAS** (não impede criar nova se a anterior estiver inativa)
- Normalizar nome (trim) antes de verificar e criar
- Melhorar mensagens de erro

## 🚀 Como Aplicar no Servidor

### Passo 1: Atualizar código
```bash
cd ~/debrief
git pull
```

### Passo 2: Reiniciar backend
```bash
docker-compose restart backend
```

### Passo 3: Testar
1. Acesse `http://82.25.92.217:2022/configuracoes`
2. Tente deletar uma secretaria usando o **botão de lixeira** (ícone Trash2) - isso faz **deletar permanente**
3. Tente criar uma nova secretaria com o mesmo nome - deve funcionar agora

## 📝 Importante

### Dois tipos de "deletar":

1. **Desativar (Soft Delete)** - Botão "Desativar":
   - Apenas marca como inativa (`ativo = false`)
   - Secretaria permanece no banco
   - Não aparece em formulários
   - Pode ser reativada depois
   - **NÃO remove do banco**

2. **Deletar Permanente (Hard Delete)** - Botão de lixeira (Trash2):
   - Remove completamente do banco
   - **Ação irreversível**
   - Só funciona se não houver demandas vinculadas
   - **Remove do banco**

### Para deletar e poder inserir novamente:

Use o **botão de lixeira** (ícone Trash2) para deletar permanentemente, não o botão "Desativar".

## 🔍 Verificação

Se ainda receber erro ao tentar criar secretaria com mesmo nome após deletar:

1. Verifique se usou o botão de lixeira (hard delete) e não o botão "Desativar"
2. Verifique se a secretaria foi realmente removida do banco:
   ```bash
   docker-compose exec backend python -c "
   from app.core.database import SessionLocal
   from app.models import Secretaria
   db = SessionLocal()
   secretarias = db.query(Secretaria).filter(Secretaria.nome.ilike('NOME_DA_SECRETARIA')).all()
   for s in secretarias:
       print(f'ID: {s.id}, Nome: {s.nome}, Ativo: {s.ativo}')
   "
   ```

Se aparecer apenas secretarias com `ativo = False`, a validação deve permitir criar uma nova.

