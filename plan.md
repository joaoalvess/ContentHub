# ContentHub tvOS — Plano de Implementação

> **Status:** em progresso. Este documento é o ponto de continuidade entre
> sessões. Leia a seção **"Estado atual"** primeiro e depois o **"O que
> fazer a seguir"**.
>
> Projeto criado em Xcode 26.4 / tvOS 26.4 com
> `PBXFileSystemSynchronizedRootGroup` (arquivos `.swift` soltos na pasta
> entram no target automaticamente), Swift 5 com
> `SWIFT_APPROACHABLE_CONCURRENCY = YES` e
> `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Framework de teste: **Swift
> Testing** (`@Test`, `#expect`).

---

## 1. Contexto & escopo

Base de um app tvOS estilo Stremio/Apple TV+ que agrega filmes, séries e
animes vindos de "addons" remotos.

**Abas planejadas:** Início · Filmes · Séries · Animes.

**Shelves de cada aba** (variações por aba serão refinadas depois):

- Continuar Assistindo
- Em Alta
- Top 10
- Lançamentos
- Serviços de Streaming
- Para Você
- Popular
- Explore por Gênero
- Assistidos Recentemente

**Addon inicial:**
`https://aiometadata.viren070.me/stremio/8c777fa0-4d2e-4b2b-a8ca-54473a2daf42/manifest.json`

Expõe `catalog`, `meta`, `subtitles`; tipos `movie`, `series`,
`anime.*`; 53 catálogos, 40 com `showInHome = true`.

- `GET {base}/catalog/{type}/{id}.json` → `{ "metas": [Meta] }`.
- Campos de `Meta` usados: `id, type, name, description, poster,
  background, landscapePoster, logo, genres, year (string), releaseInfo,
  runtime (string), released (ISO date), imdbRating (string), imdb_id,
  _tmdbId, _tvdbId`.

**Princípio central:** separar o vocabulário do addon do vocabulário do
app. A UI só conhece `MediaItem`, `Shelf`, `PageBlueprint`. A troca ou
adição de addons não toca em UI.

**Decisões já tomadas com o usuário:**

- Design: inspiração Apple TV+ (link Claude Design retornou 404).
- Continue Assistindo: mock visual já, mas persistência SwiftData desde o
  início (pronto para quando houver player).
- Não exibir catálogos do addon crus; refinar e compor nossas shelves.
- Todos os catálogos serão **alimentadores** das nossas shelves — a
  escolha final de quais catálogos viram quais shelves é ajuste fino
  depois.
- Arquitetura deve permitir **mesma `PageView` reaproveitada** entre
  todas as abas (Início/Filmes/Séries/Animes).
- Loading incremental, skeletons e estados vazios.
- Ordenação, priorização e fallback quando uma shelf falhar.
- Testes de UI/foco e de agregação de dados.
- TDD estrito nas layers 1–14 com **Swift Testing**.

---

## 2. Arquitetura em camadas

```
┌─────────────── UI (SwiftUI) ───────────────┐
│ RootView (TabView) → PageView(blueprint)   │
│   ├─ HeroView                              │
│   └─ ShelfView (PosterShelf/Top10Shelf/…)  │
└────────────────────────────────────────────┘
            ▲ observa
┌──── PageViewModel (@Observable) ───────────┐
│ carrega shelves em paralelo via providers  │
│ cada shelf tem estado próprio              │
│ (loading / loaded / empty / failed)        │
└────────────────────────────────────────────┘
            ▲ consome
┌─── Shelf Providers (estratégia) ───────────┐
│ TrendingProvider, Top10Provider,           │
│ StreamingServicesProvider,                 │
│ ContinueWatchingProvider (SwiftData),      │
│ RecentlyWatchedProvider (SwiftData), …     │
└────────────────────────────────────────────┘
     ▲ via AddonClient   ▲ via WatchProgressStore
┌─ Addon / Stremio ──┐  ┌─ Persistence ─┐
│ AddonClient        │  │ SwiftData:    │
│ Manifest/Meta DTO  │  │ WatchProgress │
│ → MediaMapper → MediaItem (domínio)  │
└────────────────────┘  └───────────────┘
                 ▲
            SharedDataStore (cache/dedup por MediaItem.id)
```

### Por que essa divisão

- **Shelf como unidade de composição** (não View, não catálogo). Mesma
  shelf pode aparecer em abas diferentes com filtros diferentes.
- **ShelfProvider** é um protocolo com
  `func load() async throws -> Shelf`. Fácil de mockar, paralelizável,
  permite misturar fontes (addon + SwiftData + curadoria) sem a View
  saber.
- **PageBlueprint** declara a página: hero source + ordem de providers +
  prioridades. Trocar a composição de Início vs Filmes é editar um
  blueprint, não tocar em View.
- **SharedDataStore** deduplica `MediaItem` por id — se "Em Alta" e
  "Top 10" trazem o mesmo filme, reusamos a instância e a imagem em
  cache.

### Contratos-chave (implementados na base atual)

```swift
// Media/MediaItem.swift
struct MediaItem: Sendable, Identifiable, Hashable {
    let id: String              // id canônico (ex.: "tmdb:1613798")
    let kind: MediaKind
    let title: String
    let description: String?
    let posterURL: URL?
    let landscapeURL: URL?
    let logoURL: URL?
    let genres: [String]
    let year: Int?
    let runtime: String?
    let rating: Double?
    let releaseDate: Date?
    let rank: Int?              // só em shelves Top 10
    let progress: Double?       // 0..1, só em Continue Assistindo
}

// Shelves/ShelfProvider.swift
protocol ShelfProvider: Sendable {
    var id: String { get }
    var title: String { get }
    var layout: ShelfLayout { get }
    var kind: ShelfKind { get }
    var priority: LoadPriority { get }   // .critical / .high / .normal / .low
    func load() async throws -> Shelf
}

// Pages/PageBlueprint.swift
struct PageBlueprint: Sendable {
    let id: String
    let title: String
    let heroSource: HeroSource            // .shelf(id) ou .staticItems
    let providers: [any ShelfProvider]
}
```

### `PageViewModel` — carregamento incremental + fallback por shelf

- Estado por shelf:
  `ShelfState = .loading | .loaded(Shelf) | .empty | .failed(ShelfFailure)`.
- `TaskGroup` dispara providers por prioridade; hero espera apenas a
  shelf indicada por `heroSource`, as demais populam conforme chegam.
- Se um provider lança, UI mostra `ShelfErrorView` só naquela shelf — a
  página continua renderizando o resto. Retry isola.

### Estados visuais de shelf

| Estado   | UI                                                      |
|----------|---------------------------------------------------------|
| loading  | `ShelfSkeleton` — 5 placeholder cards com shimmer       |
| loaded   | conteúdo normal                                         |
| empty    | ícone + texto ("Nada por aqui ainda")                   |
| failed   | `ShelfErrorView` — texto + botão "Tentar novamente"     |
| partial  | items ok + nota pequena ("algumas fontes off")          |

---

## 3. Estrutura de arquivos alvo

```
ContentHub/
├── App/
│   ├── ContentHubApp.swift           ✅
│   ├── RootView.swift                ⚠️ placeholder (Layer 19)
│   └── AppEnvironment.swift          ✅ (DI + stores + addon padrão + seed DEBUG)
├── DesignSystem/
│   ├── Colors.swift                  ❌
│   ├── Typography.swift              ❌
│   └── Metrics.swift                 ❌
├── Stremio/
│   ├── Manifest.swift                ✅
│   ├── CatalogResponse.swift         ✅
│   ├── Meta.swift                    ✅
│   └── StremioError.swift            ✅
├── Addons/
│   ├── Addon.swift                   ✅
│   ├── AddonClient.swift             ✅
│   └── AddonRegistry.swift           ✅
├── Media/
│   ├── MediaItem.swift               ✅
│   ├── MediaKind.swift               ✅
│   └── MediaMapper.swift             ✅
├── Shelves/
│   ├── Shelf.swift                   ✅
│   ├── ShelfLayout.swift             ✅
│   ├── ShelfKind.swift               ✅
│   ├── ShelfProvider.swift           ✅
│   └── Providers/
│       ├── TrendingShelfProvider.swift          ✅
│       ├── TopShelfProvider.swift               ✅
│       ├── Top10ShelfProvider.swift             ✅
│       ├── StreamingServicesShelfProvider.swift ✅
│       ├── ForYouShelfProvider.swift            ✅
│       ├── GenreExplorerShelfProvider.swift     ✅
│       ├── ReleasesShelfProvider.swift          ✅
│       ├── ContinueWatchingShelfProvider.swift  ✅
│       └── RecentlyWatchedShelfProvider.swift   ✅
├── Pages/
│   ├── PageBlueprint.swift           ✅
│   ├── PageViewModel.swift           ✅
│   ├── PageView.swift                ❌
│   └── Blueprints/
│       ├── HomePageBlueprint.swift   ✅
│       ├── MoviesPageBlueprint.swift ✅
│       ├── SeriesPageBlueprint.swift ✅
│       └── AnimesPageBlueprint.swift ✅
├── Views/
│   ├── Hero/
│   │   ├── HeroView.swift            ❌
│   │   └── HeroCarousel.swift        ❌
│   ├── Shelves/
│   │   ├── ShelfView.swift           ❌
│   │   ├── PosterShelfView.swift     ❌
│   │   ├── Top10ShelfView.swift      ❌
│   │   ├── ContinueWatchingShelfView.swift ❌
│   │   ├── ShelfSkeleton.swift       ❌
│   │   └── ShelfErrorView.swift      ❌
│   └── Cards/
│       ├── PosterCard.swift          ❌
│       ├── Top10Card.swift           ❌
│       └── ContinueWatchingCard.swift ❌
├── Persistence/
│   ├── ModelContainer+App.swift      ❌ (lógica segue em AppEnvironment)
│   ├── WatchProgress.swift           ✅
│   └── WatchProgressStore.swift      ✅
├── Caching/
│   └── SharedDataStore.swift         ✅
└── Utilities/
    └── RemoteImage.swift             ❌
```

Testes atuais em `ContentHubTests/`:

```
ContentHubTests/
├── Fixtures/
│   ├── manifest.json                 ✅
│   ├── catalog_trending_movie.json   ✅
│   └── catalog_top_series.json       ✅
├── Helpers/
│   ├── Fixtures.swift                ✅
│   ├── StubURLProtocol.swift         ✅
│   ├── StubAddonClient.swift         ✅
│   └── InMemoryModelContainer.swift  ✅
├── Stremio/
│   ├── ManifestDecodingTests.swift   ✅
│   └── MetaDecodingTests.swift       ✅
├── Addons/
│   ├── CatalogURLTests.swift         ✅
│   └── HTTPAddonClientTests.swift    ✅
├── Media/
│   └── MediaMapperTests.swift        ✅
├── Shelves/
│   ├── TrendingShelfProviderTests.swift          ✅
│   ├── Top10ShelfProviderTests.swift             ✅
│   ├── StreamingServicesShelfProviderTests.swift ✅
│   ├── ContinueWatchingShelfProviderTests.swift  ✅
│   ├── RecentlyWatchedShelfProviderTests.swift   ✅
│   ├── ForYouShelfProviderTests.swift            ✅
│   ├── GenreExplorerShelfProviderTests.swift     ✅
│   └── ReleasesShelfProviderTests.swift          ✅
├── Pages/
│   ├── PageBlueprintTests.swift      ✅
│   └── PageViewModelTests.swift      ✅
├── Caching/
│   └── SharedDataStoreTests.swift    ✅
└── Persistence/
    └── WatchProgressStoreTests.swift ✅
```

`ContentHubUITests/` ainda está no template padrão do Xcode e segue
pendente de implementação real da Layer 21.

Legenda: ✅ feito · ⚠️ parcial · ❌ pendente.

---

## 4. Estado atual

### 4.1 Entregue até agora

- **Layers 1–14 concluídas**. A base de dados, domínio, providers,
  blueprints e orquestração de carregamento estão prontas; a UI ainda
  não começou.
- **Stremio DTOs e parsing tolerante**:
  `Manifest.swift`, `Meta.swift`, `CatalogResponse.swift`,
  `StremioError.swift`.
  - `Meta` faz decode tolerante de URL e parse manual de data ISO8601
    com e sem fractional seconds.
- **Addon layer pronta**:
  `Addon.swift`, `AddonRegistry.swift`, `AddonClient.swift`.
  - `Addon.aioMetadata` virou a configuração padrão do app.
  - `HTTPAddonClient` busca manifest e catálogos e monta URLs
    `catalog/{type}/{id}/...json` com extras em path (`genre=`,
    `skip=`).
- **Domínio pronto**:
  `MediaKind`, `MediaItem`, `MediaMapper`.
  - ID canônico: `tmdb:` primeiro, depois `imdb:`, fallback
    `type:id`.
  - `MediaKind` cobre `movie`, `series`, `anime`, `animeMovie`.
- **Cache e persistência prontos**:
  `SharedDataStore` (`actor`) e `WatchProgressStore` (`actor`).
  - `SharedDataStore` faz dedup por `id` e merge preservando `rank` e
    `progress` não-nulos do item mais novo.
  - `WatchProgressStore` suporta `recordProgress`, `recent(limit:)` e
    `inProgress(limit:)`.
- **Shelf layer pronta**:
  contratos (`Shelf`, `ShelfLayout`, `ShelfKind`, `ShelfProvider`,
  `LoadPriority`) e providers:
  `Trending`, `TopShelf`, `Top10`, `StreamingServices`, `ForYou`,
  `GenreExplorer`, `Releases`, `ContinueWatching`,
  `RecentlyWatched`.
  - `StreamingServices` e `GenreExplorer` suportam sucesso parcial via
    `Shelf.isPartial`.
  - `ContinueWatching` e `RecentlyWatched` fazem join com
    `SharedDataStore`; itens sem resolução no cache são omitidos por
    enquanto.
- **Pages layer pronta**:
  `HeroSource`, `PageBlueprint`, blueprints de `Home`, `Movies`,
  `Series`, `Animes`, e `PageViewModel`.
  - `PageViewModel` carrega por tiers de prioridade
    (`critical` → `high` → `normal` → `low`) em paralelo dentro de cada
    tier e isola retry por shelf.
- **Bootstrap do app parcialmente pronto**:
  `ContentHubApp.swift` e `AppEnvironment.swift` já criam
  `ModelContainer`, `AddonRegistry`, `HTTPAddonClient`,
  `SharedDataStore`, `WatchProgressStore` e seed DEBUG de
  `WatchProgress`.
  - `RootView.swift` continua placeholder; o shell visual ainda não foi
    ligado aos blueprints.
- **Test suite das layers 1–14 pronta e validada**:
  31 testes em 17 suites cobrindo DTOs, client, mapper, cache,
  persistência, providers, blueprints e `PageViewModel`.

### 4.2 Verificado nesta sessão

- `xcodebuild test` real está **verde** para o target de unidade com
  1 worker e sem paralelismo:

```fish
xcodebuild test -scheme ContentHub \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -only-testing:ContentHubTests \
  -parallel-testing-enabled NO \
  -maximum-parallel-testing-workers 1
```

- Resultado validado em `2026-04-19`: **31 testes / 17 suites
  passando**.
- Os problemas antigos de build/SourceKit ficaram para trás:
  `@main`, `import Testing`, fixtures do bundle e tipos fora de escopo
  deixaram de ser bloqueadores depois do ciclo de implementação e do
  `xcodebuild test` real.

### 4.3 Pendências reais a partir daqui

- **Layer 15 em diante ainda não começou**:
  `DesignSystem`, cards, shelf views, hero, `PageView`, `RootView`
  real e UI tests.
- **`RootView` segue placeholder**; o app ainda não navega pelas abas
  nem renderiza os blueprints criados.
- **`PageView.swift`, `RemoteImage.swift` e a camada de Views** ainda
  não existem.
- **UI tests** ainda são só template do Xcode.
- **Validação visual/end-to-end** ainda está pendente porque a UI não
  foi construída.

### 4.4 Decisões aplicadas

- Para não travar a máquina, o fluxo de teste passou a usar sempre
  **1 simulator / 1 worker** durante a fase não-visual.
- O app ficou com **DI explícita em `AppEnvironment`** em vez de
  singletons globais.
- A composição inicial dos blueprints usa IDs concretos (`tmdb.trending`,
  `tmdb.top`, `streaming.*`) só como ponto de partida; o ajuste fino dos
  catálogos continua sendo trabalho de curadoria posterior.

---

## 5. O que fazer a seguir (ordem recomendada)

### Passo 0 — preservar o fluxo de teste leve

Durante a fase de UI, continuar evitando paralelismo:

```fish
xcodebuild test -scheme ContentHub \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -only-testing:ContentHubTests \
  -parallel-testing-enabled NO \
  -maximum-parallel-testing-workers 1
```

Quando começar UI tests, manter a mesma estratégia e rodar o target de
UI isolado, também sem paralelismo.

### Passo 1 — Layer 15

Implementar `DesignSystem/Colors.swift`, `Typography.swift`,
`Metrics.swift` e os cards genéricos:

- `PosterCard`
- `Top10Card`
- `ContinueWatchingCard`

### Passo 2 — Layer 16

Implementar a família de shelves visuais:

- `ShelfView`
- `PosterShelfView`
- `Top10ShelfView`
- `ContinueWatchingShelfView`
- `ShelfSkeleton`
- `ShelfErrorView`

### Passo 3 — Layer 17

Implementar `HeroView` e `HeroCarousel`, já pensando em tvOS,
full-screen hero e futura aplicação de Liquid Glass só quando entrar na
parte visual.

### Passo 4 — Layer 18

Implementar `PageView.swift` conectando `PageViewModel` aos estados de
shelf e ao hero.

### Passo 5 — Layer 19

Trocar o placeholder de `RootView` pelo `TabView` com as 4 abas:
`Início`, `Filmes`, `Séries`, `Animes`, todas reaproveitando a mesma
`PageView`.

### Passo 6 — Layer 20

Fechar o bootstrap visual final:

- ligar `RootView` aos blueprints reais;
- confirmar o seed DEBUG de `WatchProgress` na experiência inicial;
- decidir se vale extrair a criação do `ModelContainer` para
  `ModelContainer+App.swift` ou manter em `AppEnvironment`.

### Passo 7 — Layer 21

Substituir os UI tests template por testes reais de foco, scroll,
troca de abas e reuso de `PageView`.

---

## 6. Layers (roteiro consolidado)

### Layer 1 — Stremio/Manifest DTO ✅

- `Manifest.swift` implementado.
- `ManifestDecodingTests.swift` cobrindo manifest real.

### Layer 2 — Stremio/Meta DTO ✅

- `Meta.swift` e `CatalogResponse.swift` implementados.
- `MetaDecodingTests.swift` cobrindo fixtures reais e campos opcionais.

### Layer 3 — Media/MediaItem + MediaMapper ✅

- `MediaKind.swift`, `MediaItem.swift`, `MediaMapper.swift`
  implementados.
- `MediaMapper` faz canonical ID, parse de `year`, parse de `rating`
  e mapeamento do vocabulário do addon para o vocabulário do app.
- `MediaMapperTests.swift` verde.

### Layer 4 — Addons/AddonClient ✅

- `Addon.swift`, `AddonRegistry.swift`, `AddonClient.swift`
  implementados.
- `HTTPAddonClient` usa `URLSession` injetável e cobre manifest/catalog.
- URL builder validado, inclusive extras (`genre`, `skip`).
- `CatalogURLTests.swift` e `HTTPAddonClientTests.swift` verdes.

### Layer 5 — Caching/SharedDataStore ✅

- `SharedDataStore.swift` implementado como `actor`.
- Dedup e merge por `MediaItem.id` funcionando.
- `SharedDataStoreTests.swift` verde.

### Layer 6 — Persistence/WatchProgressStore ✅

- `WatchProgress.swift` e `WatchProgressStore.swift` implementados.
- `WatchProgressStore` usa `ModelContainer` e faz upsert/queries
  ordenadas.
- `WatchProgressStoreTests.swift` verde com store in-memory.

### Layer 7 — TrendingShelfProvider ✅

- Contratos da shelf e `TrendingShelfProvider` implementados.
- `TrendingShelfProviderTests.swift` verde.

### Layer 8 — Top10ShelfProvider ✅

- `Top10ShelfProvider.swift` implementado.
- Rank `1...10` injetado em `MediaItem.rank`.
- `Top10ShelfProviderTests.swift` verde.

### Layer 9 — StreamingServicesShelfProvider ✅

- `StreamingServicesShelfProvider.swift` implementado.
- Agregação multi-catalog com sucesso parcial em `Shelf.isPartial`.
- `StreamingServicesShelfProviderTests.swift` verde.

### Layer 10 — ContinueWatchingShelfProvider ✅

- `ContinueWatchingShelfProvider.swift` implementado.
- Join atual usa `WatchProgressStore` + `SharedDataStore`.
- Fallback por fetch remoto ainda não existe; itens sem resolução no
  cache são omitidos.
- `ContinueWatchingShelfProviderTests.swift` verde.

### Layer 11 — RecentlyWatchedShelfProvider ✅

- `RecentlyWatchedShelfProvider.swift` implementado.
- Ordenação por `updatedAt desc` validada.
- `RecentlyWatchedShelfProviderTests.swift` verde.

### Layer 12 — ForYou / GenreExplorer / Releases ✅

- `ForYouShelfProvider.swift`, `GenreExplorerShelfProvider.swift`,
  `ReleasesShelfProvider.swift` implementados.
- Todos com testes próprios verdes.

### Layer 13 — Pages/PageBlueprint ✅

- `HeroSource`, `PageBlueprint` e os blueprints de
  `Home/Movies/Series/Animes` implementados.
- `PageBlueprintTests.swift` verde.

### Layer 14 — PageViewModel ✅

- `PageViewModel.swift` implementado como `@Observable @MainActor`.
- Carregamento por prioridade, estados por shelf e retry isolado
  funcionando.
- `PageViewModelTests.swift` verde.

### Layer 15–20 — UI (sem TDD rígido) ❌

Pendências:

15. `DesignSystem` + cards genéricos.  
16. Shelf views + skeleton/error states.  
17. Hero + HeroCarousel.  
18. `PageView`.  
19. `RootView` real com tabs.  
20. Fechamento do bootstrap visual.

### Layer 21 — UI focus tests ❌

Pendências:

- smoke test real;
- navegação horizontal/vertical com d-pad;
- preservação de foco;
- atualização do hero com scroll;
- troca de abas com reuso de `PageView`.

---

## 7. Verificação final

### 7.1 Já verificado

```fish
xcodebuild test -scheme ContentHub \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -only-testing:ContentHubTests \
  -parallel-testing-enabled NO \
  -maximum-parallel-testing-workers 1
```

- Status: **verde**
- Resultado: **31 testes em 17 suites**
- Motivo do comando restrito: evitar múltiplos clones de simulator e
  travamento da máquina durante a fase não-visual.

### 7.2 Ainda precisa ser verificado quando a UI existir

1. **Build e run do app no simulator**
   ```fish
   xcodebuild build -scheme ContentHub \
     -destination 'platform=tvOS Simulator,name=Apple TV'
   ```
2. **Smoke visual**
   - hero no topo;
   - shelves visíveis ao scroll;
   - `Continuar Assistindo` carregando os mocks seedados;
   - troca de abas reutilizando `PageView`.
3. **Falha de rede**
   - shelves exibindo erro parcial/isolado;
   - retry recarregando apenas a shelf afetada.
4. **UI focus tests**
   - foco horizontal e vertical;
   - preservação de foco;
   - comportamento de hero no scroll.

---

## 8. Riscos & decisões pendentes

- **Continue Watching depende de cache quente**:
  como `ContinueWatchingShelfProvider` hoje não busca fallback remoto,
  os itens seedados só aparecem completos depois que algum provider já
  popular o `SharedDataStore` com os mesmos IDs.
- **Curadoria dos catálogos ainda é provisória**:
  os IDs usados nos blueprints servem para destravar a arquitetura, mas
  ainda precisam ser afinados contra o comportamento real do addon.
- **Assinatura do addon**:
  `stremioAddonsConfig.signature` segue fora do v1.
- **UI tests podem abrir clones extras do simulator**:
  se o scheme completo for rodado com paralelismo ligado, o Xcode pode
  voltar a abrir múltiplos devices/clones. Manter `parallel-testing-enabled NO`.
- **`ModelContainer+App.swift` ainda não existe**:
  não bloqueia o projeto, mas a extração segue como limpeza opcional
  quando a fase visual começar.

---

## 9. Changelog desta sessão

- Concluídas as layers **3–14**.
- Adicionados:
  `Addon`, `AddonRegistry`, `AddonClient`, `MediaKind`, `MediaItem`,
  `MediaMapper`, `SharedDataStore`, `WatchProgressStore`, contratos de
  shelf, todos os providers, blueprints de páginas e `PageViewModel`.
- `AppEnvironment` evoluiu de bootstrap mínimo para container DI real
  com addon padrão, client HTTP, cache compartilhado e persistência.
- `Meta` ganhou parse manual de datas ISO8601 e o URL builder do
  `HTTPAddonClient` foi corrigido para evitar `//catalog/...`.
- Adicionada a suíte de testes das layers 3–14 com stubs/helpers
  dedicados.
- Validado `xcodebuild test` real com **1 worker**, sem UI tests e sem
  paralelismo: **31 testes / 17 suites passando**.
- Simulator encerrado ao final da execução para devolver a máquina
  limpa.
