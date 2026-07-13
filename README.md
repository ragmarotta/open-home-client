# Open Home Client 🏠✨

O **Open Home Client** é um aplicativo mobile moderno, limpo e de alto desempenho construído em **Flutter**, projetado para atuar como o painel de controle central para automação residencial inteligente. 

Este projeto foi estruturado seguindo rigorosamente os princípios da **Clean Architecture** (Arquitetura Limpa) e o **Repository Pattern**, permitindo que ele seja facilmente integrável com plataformas reais no futuro (como Tuya Cloud, Tasmota HTTP local, LG ThinQ e Home Assistant), enquanto atualmente opera com dados simulados locais robustos com latência simulada de rede.

---

## 🚀 Tecnologias Utilizadas

O ecossistema do aplicativo foi projetado com as seguintes tecnologias e pacotes:

*   **Flutter & Dart**: Framework e linguagem de desenvolvimento multiuso e reativo.
*   **Flutter BLoC (`flutter_bloc`)**: Utilizado para gerenciar o estado da aplicação de forma previsível e isolada da lógica de negócios.
*   **Equatable (`equatable`)**: Facilita a comparação de objetos Dart, otimizando o fluxo de renderização e evitando re-renderizações desnecessárias.
*   **Flutter Localizations (`flutter_localizations`)**: Pacote nativo do SDK do Flutter integrado para suporte completo de i18n e formatação local.
*   **Material Design 3**: UI moderna, fluida e consistente com as diretrizes do Material 3.
*   **Tema Dark Nativo (OLED-friendly)**: Cores balanceadas para telas OLED, com contraste premium de Charcoal e Slate, e cores ativas em Indigo/Cyan.
*   **Tamanho de Toques Mínimo (48dp)**: Todos os componentes interativos do aplicativo foram desenhados com área mínima de clique para melhor usabilidade e acessibilidade.

---

## 🏗️ Arquitetura do Projeto

A estrutura de código está dividida em camadas principais (Core, Domain, Data e Presentation) para maximizar o desacoplamento:

```
lib/
├── core/
│   ├── localization/        # Sistema de i18n (AppLocalizations e extensões do BuildContext)
│   └── theme/               # Configuração do Tema Dark, fontes e cores
├── domain/
│   ├── entities/            # Modelos de dados puros (Switch, Light, Climate, Audio, Metrics)
│   └── repositories/        # Contratos/Interfaces abstratas de acesso aos dados
├── data/
│   └── repositories/        # Implementações Mock de repositórios (Simulações Tuya, Tasmota, Nest, etc.)
└── presentation/
    ├── blocs/               # Logica de estados (DeviceBloc, ClimateBloc, AudioBloc, MonitoringBloc, SettingsBloc)
    └── screens/             # Páginas da UI (Dashboard, RoomControl, AudioCentral, Climate, EnergyPresence, SettingsScreen)
```

---

## 🌟 Funcionalidades Implementadas

O aplicativo conta com cinco seções centrais e telas de detalhe totalmente integradas via BLoCs reativos:

### 1. Painel de Controle Duplex (Dashboard Tab)
*   **Home Thermal Status**: Exibe a temperatura em tempo real de cada andar.
    *   *Andar 1*: 22°C (Confortável - Badge Verde)
    *   *Andar 2*: 27°C (Quente ⚠️ - Badge de Alerta Amber)
*   **Alternador de Andar**: Um botão segmentado reativo de usabilidade rápida para filtrar os dados entre "Floor 1 (Ground)" e "Floor 2 (Upper)".
*   **Visualização de Dispositivos**: Uma lista e grid interativos exibindo os dispositivos inteligentes correspondentes ao andar selecionado. Cada cartão possui switches diretos para ações rápidas de On/Off e indicação de status.

### 2. Controle Detalhado por Quarto (Room/Device Control Screen)
Acessado ao clicar em qualquer quarto (ex: "Living Room") ou segurando em um dispositivo. Esta tela unifica diferentes marcas e ecossistemas sob a mesma interface gráfica elegante:
*   **Tasmota Smart Switch**: Controle liga/desliga de interruptores locais com latência de resposta simulada.
*   **Custom NodeMCU LED Strip**: Um painel avançado com slider para controle de **Brilho** (0% a 100%) e um seletor visual e inline de **Paleta de Cores** pré-definidas (Indigo, Cyan, Amber, Sunset, Emerald, etc.) usando círculos de toque acessível.
*   **Tuya Zigbee Smart Plug**: Controle direto para ligar ou desligar tomadas inteligentes de eletrodomésticos.
*   **Ações Rápidas de Cenas (Preset Scenes)**:
    *   *Modo Filme (Movie Mode)*: Desliga a luz de teto Tasmota, liga a tomada Tuya (Media Center) e ajusta a fita LED NodeMCU para um azul suave com 20% de brilho.
    *   *Modo Leitura (Reading)*: Liga a luz Tasmota principal e ajusta a fita LED para cor quente (Amber) com 90% de brilho.

### 3. Central de Áudio Multiroom (Audio Central Tab)
*   **Estado de Reprodução**: Exibe o player de música atual ("Now Playing: Spotify - Relax Mix") com barras de progresso do player de mídia e botões reativos de Play/Pause.
*   **Zonas de Transmissão (Cast)**: Lista de caixas de som selecionáveis por andar (ex: *Chromecast Audio - Floor 1* e *Google Nest Mini - Floor 2*).
*   **Volume Master e Individual**: Cada zona de som possui controles deslizantes individuais. Há também um controle deslizante de **Volume Master** no topo.
*   **Sincronização de Áudio Multiroom**: Botão em destaque "Synchronize Audio Across Floors". Ao ser ativado, unifica todas as zonas, alinha os volumes e sincroniza o comportamento do player em toda a casa.

### 4. Monitoramento de Energia & Presença (Security & Energy Tab)
*   **Consumo Elétrico Trifásico**: Monitoramento em tempo real das cargas elétricas de entrada (Fase A - Residencial, Fase B - Climatização, Fase C - Cozinha/Lavanderia).
*   **Carga Ativa Contínua**: O aplicativo escuta um `Stream` reativo que envia atualizações contínuas de consumo elétrico (em kW/h) com animações suaves de barras de progresso horizontais e exibição do valor total.
*   **Sensores de Ocupação**: Uma lista de presença indicando se há movimento detectado nos cômodos da residência, exibindo quando ocorreu o último movimento (ex: "Active now", "2m ago") e badges verdes brilhantes para áreas ocupadas.

### 5. Configurações & Internacionalização (Settings Screen)
Acessível a partir do botão de engrenagem localizado no topo direito do Dashboard.
*   **Internacionalização (i18n)**: Suporte de tradução dinâmica em tempo real para múltiplos idiomas. Os arquivos de tradução estão preparados para:
    *   **Português (pt)**: Definido como o idioma padrão inicial do aplicativo.
    *   **Inglês (en)**: Totalmente integrado e selecionável a qualquer momento.
*   **Fuso Horário Padrão**: Fuso horário de Brasília (GMT-3 São Paulo) configurado como padrão inicial, com suporte a outros fusos através de uma lista dropdown reativa.
*   **Documentação Interna de Métodos**: Todos os métodos, atributos e classes contam com documentação completa em formato *Dart Docstrings* no padrão oficial da linguagem.

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
