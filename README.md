# CheckFast 🚀

**Presença comprovada, pagamento garantido.**

O CheckFast é um sistema completo (Web Administrativo + App Mobile) construído em Flutter e focado na gestão de trade marketing, controle de promotores/colaboradores temporários e automação financeira rigorosa.

## 🎯 Objetivo
Garantir que a agência pague apenas pelos serviços executados corretamente através de três pilares de validação:
1. **Validação de GPS**: Bloqueio de check-in caso o promotor esteja a > 200m da loja.
2. **Anti-fraude de Imagem (Liveness Detection)**: Integração com ML Kit do Google para garantir que a foto do check-in possui um rosto real com olhos abertos, rejeitando fotos estáticas.
3. **Auditoria de Tempo**: Pagamento do lote PIX liberado única e exclusivamente se o intervalo entre Check-in e Check-out for igual ou superior a **4 horas**.

---

## 🛠 Tecnologias
- **Frontend / App**: Flutter (Dart) com design responsivo (`Material 3`)
- **Backend / Database**: Firebase (Firestore)
- **Localização**: `geolocator`
- **Reconhecimento Facial (IA)**: `google_mlkit_face_detection`
- **Geração de Lotes Financeiros**: Integração customizada para TXT Bancário (CNAB) e `excel` para extração de XLS.

---

## 📂 Arquitetura do Projeto

O código está estruturado para escalar rapidamente, seguindo o padrão MVC/MVVM simplificado:

```text
lib/
├── core/
│   ├── constants/       # Cores (Azul/Ciano/Verde), Fontes (Poppins)
│   └── services/        # Firebase, ML Kit, Exportação XLS, Lote PIX
├── models/              # Estruturas do banco (User, Store, Demand, Attendance)
├── viewmodels/          # Regras de negócio (ex: Motor de 4 Horas Mínimas)
├── views/
│   ├── mobile/          # Telas focadas no colaborador (Vagas, Cadastro, Check-in, Financeiro)
│   └── web/             # Telas focadas no gestor (Dashboard, Aprovação de Treinamento)
└── main.dart            # Ponto de entrada
```

---

## ⚙️ Regras de Negócio Chave

### 1. Motor das 4 Horas Mínimas
Localizado em `lib/viewmodels/attendance_viewmodel.dart`.
Se a diferença entre o check-in e check-out for menor que 4.0 horas, o pagamento é reprovado automaticamente e o saldo barrado.

### 2. Automação PIX em Lote
Localizado em `lib/core/services/pix_batch_service.dart`.
Gera um arquivo de remessa contendo a chave PIX, o nome e o valor de todos os aprovados do dia em formato de 15 dígitos sem pontos (padrão de bancos corporativos), permitindo o pagamento de 500+ colaboradores com apenas 1 upload.

### 3. Cão de Guarda (Prevenção de Faltas)
Localizado em `lib/core/services/notification_service.dart`.
Notifica o aparelho do colaborador e levanta um alerta silencioso no painel Web se ele estiver fora do raio do GPS 30 minutos antes da vaga começar.

---

## 🚀 Como Rodar o Projeto

1. Faça o clone do repositório.
2. No VS Code, abra um novo Terminal.
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Conecte com o seu Firebase (é necessário fazer login na sua conta Google):
   ```bash
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --project=checkfast-9ce1f
   ```
5. Rode a versão Web (Admin):
   ```bash
   flutter run -d chrome
   ```
6. Rode a versão Mobile:
   ```bash
   flutter run
   ```

---

## 🔒 Governança e Ciclo de Deploy (Regra de Ouro)

Para garantir a estabilidade do sistema e a confiança na auditoria de pagamentos, a seguinte regra de CI/CD é **obrigatória** para todos os desenvolvedores e agentes trabalhando no CheckFast:

> **Regra de Ouro de Lançamento:**  
> A partir de hoje, **toda criação de telas novas, fluxos novos ou qualquer alteração no sistema** deve seguir rigorosamente o fluxo de dois estágios:
> 
> 1. **Ambiente de Homologação (Staging/Testes):** A funcionalidade deve ser lançada em ambiente isolado (utilizando o *DevTools* ou apontando para um banco/projeto Firebase de testes). Toda a mecânica de aprovação e erros deve ser simulada aqui primeiro.
> 2. **Ambiente Real (Produção):** Apenas após **tudo ser exaustivamente aprovado** em homologação, a alteração poderá ser promovida para o ambiente de Produção, que é vinculado ao domínio oficial e utilizado ativamente pelos promotores reais e gestores da agência.
>
> *Não são permitidos deploys diretos em produção sem validação prévia.*
