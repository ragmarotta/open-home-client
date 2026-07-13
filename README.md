# Open Home Client 🏠✨

O **Open Home Client** é um aplicativo mobile moderno, limpo e de alto desempenho construído em **Flutter**, projetado para atuar como o painel de controle central para automação residencial inteligente duplex (multinível). 

Este projeto foi estruturado seguindo rigorosamente os princípios da **Clean Architecture** (Arquitetura Limpa) e o **Repository Pattern**, integrando comunicação HTTPS REST online real com a **Tuya Cloud API** e oferecendo persistência local para credenciais e arranjo customizado de cômodos.

---

## 🚀 Tecnologias Utilizadas

O ecossistema do aplicativo foi projetado com as seguintes tecnologias e pacotes:

*   **Flutter & Dart**: Framework e linguagem de desenvolvimento multiuso e reativo.
*   **Flutter BLoC (`flutter_bloc`)**: Utilizado para gerenciar o estado da aplicação de forma previsível e isolada da lógica de negócios.
*   **Equatable (`equatable`)**: Facilita a comparação de objetos Dart, otimizando o fluxo de renderização e evitando re-renderizações desnecessárias.
*   **HTTP (`http`)**: Cliente robusto para conexões REST assíncronas com os datacenters globais da Tuya.
*   **Crypto (`crypto`)**: Geração de assinaturas criptográficas **HMAC-SHA256** requeridas pelo protocolo de assinatura v2 da Tuya Cloud.
*   **Flutter Localizations (`flutter_localizations`)**: Pacote nativo do SDK do Flutter integrado para suporte completo de i18n e formatação local.
*   **Material Design 3**: UI moderna, fluida e consistente com as diretrizes do Material 3.
*   **Tema Dark OLED-Friendly (Inspirado na Apple)**: Cores balanceadas para telas OLED (Preto absoluto `#08080C`), com contraste premium de grafites, e cores ativas em gradientes Indigo/Cyan.
*   **Acessibilidade de Clique**: Todos os componentes interativos do aplicativo seguem uma área mínima de clique de `48x48dp` para melhor usabilidade e ergonomia.

---

## 🏗️ Arquitetura do Projeto

A estrutura de código está dividida em camadas principais (Core, Domain, Data e Presentation) para maximizar o desacoplamento:

```
lib/
├── core/
│   ├── localization/        # Sistema de i18n (AppLocalizations e extensões do BuildContext)
│   ├── theme/               # Configuração do Tema Dark, fontes e cores
│   └── persistence/         # Banco de dados local JSON (LocalDatabase) e armazenamento de credenciais
├── domain/
│   ├── entities/            # Modelos de dados puros (Switch, Light, Climate, Audio, Metrics, CustomRoom)
│   └── repositories/        # Contratos/Interfaces abstratas de acesso aos dados
├── data/
│   └── repositories/        # Implementações de dados: Tuya Cloud API e Mock local fallback
└── presentation/
    ├── blocs/               # Lógica de estados (DeviceBloc, ClimateBloc, AudioBloc, MonitoringBloc, SettingsBloc, TuyaBloc, RoomBloc)
    └── screens/             # Páginas da UI (Dashboard, RoomControl, AudioCentral, Climate, Settings, TuyaIntegration, RoomAssignment)
```

---

## 💾 Camada de Persistência Local (Banco de Dados)

O aplicativo implementa o **`LocalDatabase`** (em `lib/core/persistence/local_database.dart`), um banco de dados local leve em formato JSON que oferece portabilidade absoluta em ambientes WSL2/Linux/Desktop sem problemas com dependências binárias complexas. Ele armazena persistentemente:
1.  **Credenciais da Tuya Cloud**: Access ID, Access Secret, Região de Datacenter e status de conexão.
2.  **Cômodos Customizados**: Nome de exibição, Andar correspondente (Andar 1 ou 2) e a lista de IDs de dispositivos (`deviceIds`) vinculados a cada cômodo.
3.  **Apelidos de Dispositivos**: Mapeamento de IDs para nomes customizados que o usuário atribui a seus produtos inteligentes.

---

## ☁️ Integração Online Real com Tuya Cloud

A classe **`TuyaCloudRepository`** (em `lib/data/repositories/tuya_cloud_repository.dart`) comunica-se de forma direta e real com a API da Tuya Cloud usando o **Tuya Open API Signature v2 Protocol**:
*   **Autenticação Restrita**: Obtém o Access Token dinamicamente usando assinaturas HMAC-SHA256 (`clientId + timestamp + stringToSign`) criptografadas com o `clientSecret`.
*   **Geração de Assinatura de Negócio**: Requisições de controle assinam o payload inteiro incluindo método HTTP, hash SHA256 do body da requisição, URL e cabeçalhos.
*   **Endpoints Integrados**:
    *   `fetchDevices()`: Baixa todos os dispositivos ativos da conta desenvolvedora do usuário.
    *   `toggleDevice()`: Envia comandos de ativação (`switch`) para plugues e lâmpadas.
    *   `setDeviceProperties()`: Altera temperatura de termostatos (`temp_set`) ou controle de abertura de cortinas (`percent_control`).
*   **Modo Simulação Inteligente (Hybrid Fallback)**: Caso chaves mockadas sejam fornecidas (ex: iniciando com `mock_`) ou ocorram erros de rede, o repositório entra em modo de simulação interativo para manter o funcionamento visual perfeito do app para apresentações.

---

## 🎨 Design UI/UX Premium (Apple HomeKit Style)

*   **Containers e Cards Minimalistas**: Cantos muito bem arredondados (`BorderRadius.circular(24)`) e bordas extremamente finas de sutil realce (`Colors.white10`), com elevações planas.
*   **Cromática Dinâmica de Estados**: Cartões de dispositivos mudam organicamente para gradientes vibrantes quando LIGADOS (Indigo ao Cyan com brilho difuso sutil) e retornam para o grafite profundo inativo (`#1C1C24`) quando DESLIGADOS.
*   **Micro-Interações e Suavidade**:
    *   **Transição de Andar**: Troca suave entre Andar 1 e Andar 2 utilizando `AnimatedSwitcher` (efeito conjunto de Fade e Slide).
    *   **Transição de Estado**: Alteração no status de dispositivos ligar/desligar com animações implícitas (`AnimatedContainer`) para mudança orgânica e sem saltos de cor.
    *   **Thermostat Crossfade**: Aparelhos de ar condicionado ligam/desligam utilizando `AnimatedCrossFade` para suavizar a entrada de painéis numéricos.
*   **Sliders Espessos Estilo iOS**: Controles de Brilho, Volume e Posição espessos (`trackHeight: 14`), fáceis de arrastar e contendo botões redondos brancos flutuantes.
*   **Ícones com Opacidade Dinâmica**: Na aba de Áudio, os mini-ícones de caixas de som variam a opacidade em tempo real baseados na intensidade selecionada do volume.

---

## 🌟 Fluxos de Tela Principais

### 1. Dashboard Inicial (Duplex Layout)
*   **Thermal Status**: Cabeçalho térmico dinâmico que exibe a temperatura atual em formato cápsula. Se a Tuya estiver conectada, extrai a leitura real de temperatura dos aparelhos de ar-condicionado na nuvem; caso contrário, exibe dados mockados locais.
*   **Filtro por Andares**: Alternador elegante segmentado para filtrar cômodos e dispositivos entre o "Andar 1" e "Andar 2".
*   **Organização Dinâmica**: Os cômodos listados na horizontal e os dispositivos no grid central são construídos a partir das tabelas locais de forma dinâmica.

### 2. Configurações da Tuya Cloud (Integração)
*   Acessível pelo menu de Configurações do aplicativo.
*   **Glow Status Indicator**: Painel superior indicando o estado atual ("Conectado à Nuvem" em verde neon pulsante ou "Desconectado" em cinza opaco).
*   **Campos de Formulário**: Inserção de Access ID/Client ID, Access Secret/Client Secret e escolha do datacenter regional (América, Europa, China).
*   **Salvar e Sincronizar**: Ao clicar, valida a autenticação na nuvem da Tuya, salva na persistência local em caso de sucesso, sincroniza os dispositivos e redireciona automaticamente para o Gerenciador de Espaços.

### 3. Gerenciador de Espaços (Personalização)
*   **Criação de Cômodos**: Diálogo para cadastrar novos cômodos personalizados especificando nome e andar.
*   **Dispositivos Não Atribuídos**: Exibe os novos produtos encontrados na API da Tuya que ainda não foram vinculados a nenhuma sala.
*   **Vinculação Direta**: Permite escolher a qual cômodo atribuir cada produto de forma instantânea.
*   **Renomeação Amigável**: Possibilidade de dar um apelido local e amigável para qualquer dispositivo inteligente.

### 4. Controle Detalhado (Room Control Screen)
Apresenta controles específicos dependendo da categoria do dispositivo da Tuya Cloud:
*   *Lâmpadas*: Liga/Desliga e ajuste de intensidade de brilho (0% a 100%).
*   *Clima/Termostatos*: Controle tátil de temperatura alvo (+/-) e alteração do modo do sistema (COOL, HEAT, FAN).
*   *Cortinas*: Slider de porcentagem de abertura/fechamento.
*   *Tomadas/Switches*: Toggle de energia com delays de latência de rede.

---

## 🛠️ Como Executar o Projeto Localmente

Certifique-se de ter o Flutter instalado na sua máquina.

1.  **Clone o repositório**:
    ```bash
    git clone git@github.com:ragmarotta/open-home-client.git
    cd open-home-client
    ```

2.  **Instale as dependências do projeto**:
    ```bash
    flutter pub get
    ```

3.  **Execute o aplicativo**:
    ```bash
    flutter run
    ```
