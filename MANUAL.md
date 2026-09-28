# jim-mining — Manual

Job de mineração completo: extrair minério com picareta, furadeira ou laser, quebrar e lavar pedras, garimpar, fundir minérios em lingotes, lapidar joias e vender tudo para NPCs compradores.

Este é o fork da MRI sobre o `jim-mining` 3.0.12 do Jimathy. O código é o do upstream. A camada nossa é pequena e está listada em [O que é da MRI](#o-que-é-da-mri).

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Itens](#itens)
5. [Ciclo de produção](#ciclo-de-produção)
6. [Locais](#locais)
7. [Receitas de crafting](#receitas-de-crafting)
8. [Preços de venda](#preços-de-venda)
9. [NPC de tutorial](#npc-de-tutorial)
10. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
11. [Localização](#localização)
12. [O que é da MRI](#o-que-é-da-mri)
13. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `jim_bridge` | Sim | Carregado via `@jim_bridge/starter.lua` (versão 2.x). Fornece framework, inventário, targets, menus, progress bar, notify, lojas, venda, `canCarry` e durabilidade |
| `oxmysql` | Sim | O manifest carrega `@oxmysql/lib/MySQL.lua` no servidor. O código não faz query, mas o recurso precisa estar ligado para o script não falhar ao carregar |
| Framework (`qbx_core`, `qb-core`, `es_extended`, `ox_core`) | Sim | Detectado automaticamente pelo `jim_bridge` |
| Inventário (`ox_inventory`, `qb-inventory`…) | Sim | Detectado pelo `jim_bridge`. As lojas e a venda são registradas nele |
| Script de target (`ox_target`, `qb-target`) | Sim | Todas as interações são por target. O `jim_bridge` escolhe o instalado |
| `ox_lib` | Sim (padrão) | `Config.System` vem com `ox` para menu, progress bar, notify e drawText |
| `cw-rep` | Não | Se estiver ligado, cada recompensa dá 5 de XP na skill `mining` |
| `rep-talkNPC` + `pickle_waypoints` | Não | NPC de tutorial. Só é criado se os dois estiverem ligados e `Config.General.npcTalk = true` |
| `gordela_props` | Não | Tem o prop `gg_batera` usado no garimpo. Sem ele o prop não aparece na mão, mas o garimpo funciona |
| MLO da K4MB1 (Mining Cave / Shaft Cave) | Não | Só se ligar `K4MB1Prop`, `K4MB1Cart`, `Mines.K4MB1Quarry` ou `Mines.K4MB1Shaft` |

---

## Instalação

1. Copie a pasta `jim-mining` para `resources/`.
2. Adicione ao `server.cfg`, depois das dependências:
   ```
   ensure oxmysql
   ensure jim_bridge
   ensure jim-mining
   ```
3. Copie o conteúdo de `images/` para a pasta de imagens do inventário (`ox_inventory/web/images/`). São 62 imagens, uma por item.
4. Cadastre os itens no inventário. O recurso **não** traz `items.lua` nem SQL. Na inicialização, o servidor confere item por item e imprime avisos do tipo:
   ```
   Selling: Missing Item from Items: 'goldore'
   CrackPool: Missing Item from Items: 'carbon'
   Shop: Missing Item from Items: 'pickaxe'
   Crafting recipe couldn't find item 'steel' in the shared
   ```
   Os itens necessários vêm de `Config.Items.items` (loja), `Config.CrackPool`, `Config.WashPool`, `Config.PanPool`, `Selling` (`shared/selling.lua`) e de todas as receitas em `Crafting` (`shared/crafting.lua`).
5. Ajuste o `config.lua` e o `shared/locations.lua`.

Não há permissões ACE nem comandos.

---

## Configuração

Todas as opções ficam em `config.lua`.

### `Config.System`

| Campo | Padrão | Descrição |
|---|---|---|
| `Lan` | `"pt"` | Idioma. Deve existir `locales/<Lan>.lua` |
| `Debug` | `false` | Sem efeito prático. Logs e `debugPoly` seguem o `debugMode` do `jim_bridge`, controlado pela convar `jim_DisableDebug` |
| `Menu` | `"ox"` | `qb`, `ox` ou `gta` |
| `ProgressBar` | `"ox"` | `qb`, `ox` ou `gta` |
| `Notify` | `"ox"` | `qb`, `ox` ou `gta` |
| `drawText` | `"ox"` | `qb`, `ox` ou `gta` |

As convars `jim_menuScript`, `jim_notifyScript`, `jim_progressBarScript` e `jim_drawTextScript` do `jim_bridge`, se definidas no `server.cfg`, sobrescrevem esses valores.

### `Config.General`

| Campo | Padrão | Descrição |
|---|---|---|
| `JimShops` | `false` | Abre a loja pelo `jim-shops` em vez do inventário |
| `DrillSound` | `true` | Som da furadeira |
| `K4MB1Prop` | `false` | Usa as props de minério do MLO Mining Cave da K4MB1 |
| `AltMining` | `false` | Cada pedra dá um minério específico, sorteado por raridade em `Config.setMiningTable`. Feito para as props da K4MB1 |
| `K4MB1Cart` | `false` | Carrinho de mina no `K4MB1Shaft`. Adiciona a opção ao NPC da loja |
| `requiredJob` | `nil` | Restringe todos os alvos a um emprego. Com `nil`, qualquer jogador usa |
| `crackingRequiresDrillbit` | `true` | Quebrar pedra exige `drillbit` no inventário |
| `npcTalk` | `true` | **MRI.** Cria o NPC de tutorial na entrada da mina |

### `Config.Crafting`

| Campo | Padrão | Descrição |
|---|---|---|
| `craftCam` | `false` | Câmera na bancada durante a fabricação |
| `MultiCraft` | `true` | Submenu de quantidade ao fabricar |

### `Config.BreakTool`

Cada ferramenta com `true` perde de 2 a 3 de durabilidade por uso, via `breakTool` do `jim_bridge`. Só funciona com inventário que tenha durabilidade, como o `ox_inventory`.

| Ferramenta | Padrão |
|---|---|
| `Pickaxe` | `true` |
| `MiningDrill` | `false` |
| `DrillBit` | `false` |
| `MiningLaser` | `false` |
| `GoldPan` | `false` |

### `Config.Timings`

| Chave | Padrão | Onde é usada |
|---|---|---|
| `Cracking` | 15 a 25 s | Quebrar pedra na bancada |
| `Washing` | 15 a 25 s | Lavar pedra na água |
| `Panning` | 45 a 50 s | Garimpar com a bateia |
| `Pickaxe` | 30 a 45 s | Minerar com picareta |
| `Mining` | 45 a 50 s | Minerar com furadeira |
| `Laser` | 7 a 10 s | Minerar com laser |
| `OreRespawn` | 55 a 75 s | Tempo até a pedra reaparecer. Sorteado uma vez no carregamento |
| `Crafting` | 5 s | Fabricação |

Os intervalos são sorteados a cada ação.

### `Config.PoolAmounts`

Quantas vezes cada ação sorteia (`Successes`) e quanto sai por sorteio (`AmountPerSuccess`). Padrão: minerar e quebrar dão de 1 a 3 do item sorteado. Lavar e garimpar fazem 1 ou 2 sorteios, cada um dando de 1 a 3.

### Pools de itens

| Tabela | Descrição |
|---|---|
| `CrackPool` | Sorteio ao quebrar pedra. Cada entrada tem `item` e `rarity` (0 a 100, chance de entrar no sorteio) |
| `WashPool` | Sorteio ao lavar pedra. Ouro e gemas brutas |
| `PanPool` | Sorteio ao garimpar. Lata, garrafa, pedra, ouro e prata |
| `setMiningTable` | Só com `AltMining`. Minério, raridade (`common`, `rare`, `ultra_rare`) e prop de cada pedra |

Itens que não existem no inventário são ignorados no sorteio.

### `Config.Items`

Loja de mineração. `label`, `slots` e a lista `items` com `name`, `price`, `amount` e `slot`. Veja [Itens](#itens).

---

## Itens

A loja de mineração vende:

| Item | Preço | Uso |
|---|---|---|
| `water_bottle`, `sandwich`, `bandage` | 10 | Consumíveis |
| `weapon_flashlight` | 100 | Lanterna |
| `goldpan` | 100 | Bateia, usada para garimpar |
| `pickaxe` | 100 | Minerar. Perde durabilidade por padrão |
| `miningdrill` | 10000 | Minerar mais rápido. Exige `drillbit` |
| `mininglaser` | 60000 | Minerar em poucos segundos |
| `drillbit` | 0 | Broca. Necessária para a furadeira e, por padrão, para quebrar pedra |

Os preços dos consumíveis, lanterna e bateia são da MRI. O upstream vem com 2, 2, 25, 75 e 25.

Minerar produz `stone`, a matéria-prima de quebrar e lavar. Com `AltMining`, produz direto o minério da pedra.

---

## Ciclo de produção

1. **Minerar** nas pedras das minas habilitadas, com `pickaxe`, `miningdrill` ou `mininglaser`. Dá de 1 a 3 `stone`. A pedra troca pelo modelo vazio e volta depois de `OreRespawn`.
2. **Quebrar pedra** na bancada `prop_vertdrill_01`. Consome 1 `stone` e sorteia do `CrackPool`. Exige `drillbit` por padrão.
3. **Lavar pedra** nos pontos de `Locations.Washing`. Consome 1 `stone` e sorteia do `WashPool`.
4. **Garimpar** com `goldpan` nas áreas de `Locations.Panning`. Não consome nada e sorteia do `PanPool`.
5. **Fundir** na fundição. Minérios viram lingotes e metais pelas receitas `SmeltMenu`.
6. **Lapidar** na bancada `gr_prop_gr_speeddrill_01c`. Gemas brutas viram gemas, e lingotes viram anéis, colares e brincos.
7. **Vender** para o comprador de minérios ou de joias, pela loja de venda do inventário registrada pelo `jim_bridge`.

Antes de entregar qualquer recompensa, o servidor confere com `canCarry` se o jogador tem espaço para tudo. Se não tiver, nada é consumido e o jogador recebe "Seu inventário está cheio!". Ao lavar, a checagem cobre todos os itens sorteados de uma vez.

Se o `cw-rep` estiver ligado, cada recompensa dá 5 de XP na skill `mining`, independente de ter espaço.

---

## Locais

Ficam em `shared/locations.lua`, na tabela global `Locations`.

| Chave | Conteúdo |
|---|---|
| `Washing` | 11 pontos de lavagem de pedra (montanhas, riacho, Gordo, Alamo Sea). `Enable` liga o grupo. Blips desligados |
| `Panning` | 3 áreas de garimpo (`Vineyard`, `Tongva`, `Wilderness`), cada uma com `Enable`, `Blip` e `Positions` (`coords` vec4, `w` largura, `d` profundidade). Blips desligados |
| `JewelBuyer` | Comprador de joias na Vangelico. **Desabilitado** (`Enable = false`), então hoje não há onde vender joias |
| `Smelting` | Coordenada avulsa da fundição, sem blip |
| `Mines` | As minas. Cada uma pode ter `Job`, `Blip`, `Store`, `Lights`, `Smelting`, `Cracking`, `OreBuyer`, `JewelCut` e `OrePositions` |

Minas incluídas:

| Chave | Padrão | Conteúdo |
|---|---|---|
| `Foundary` | Habilitada, sem blip | Loja "Loja de Fundição", fundição, 2 bancadas de quebra, comprador de minérios, 2 bancadas de lapidação |
| `MineShaft` | Habilitada, blip "Mina" | Loja, 30 luzes e 14 pedras |
| `Quarry` | Habilitada, blip "Pedreira" | Loja, 5 luzes e 8 pedras |
| `K4MB1Quarry` | Desabilitada | Mineshaft do MLO Mining Cave da K4MB1, com fundição, bancadas e 32 pedras |
| `K4MB1Shaft` | Desabilitada | Substitui o `MineShaft` pelo MLO Shaft Cave da K4MB1, com 90 pedras e carrinho de mina |

`Job = "<nome>"` numa mina restringe os alvos dela a esse emprego. `Config.General.requiredJob` faz o mesmo para o recurso inteiro.

Para adicionar uma mina, use o bloco comentado no fim de `shared/locations.lua`:

```lua
["NovaMina"] = {
    Enable = true,
    Job = nil,
    Blip = { Enable = true, name = "Mina", coords = vec4(0.0, 0.0, 0.0, 0.0), sprite = 527, col = 43 },
    Store = { },
    Smelting = { },
    Cracking = { },
    OreBuyer = { },
    JewelCut = { },
    OrePositions = { vec4(0.0, 0.0, 0.0, 0.0) },
},
```

O recurso esconde as portas do mineshaft com `CreateModelHide` quando `MineShaft` está habilitado, fixo no `client/client.lua`.

---

## Receitas de crafting

A tabela `Crafting` em `shared/crafting.lua` tem cinco menus. Em cada receita, a chave externa é o item produzido, as chaves internas são os ingredientes e `amount` é quanto sai por fabricação (padrão 1).

| Menu | Onde | Produz |
|---|---|---|
| `SmeltMenu` | Fundição | `copper` (x4), `goldingot`, `silveringot`, `iron`, `steel`, `aluminum` (x3), `glass` (x2). Lingotes também saem de correntes e anéis refundidos |
| `GemCut` | Bancada de lapidação | `emerald`, `diamond`, `ruby`, `sapphire` a partir das versões `uncut_` |
| `RingCut` | Bancada de lapidação | Anéis de ouro e prata (x3 por lingote), lisos ou com gema |
| `NeckCut` | Bancada de lapidação | Correntes (x3 por lingote) e colares de ouro e prata com gema |
| `EarCut` | Bancada de lapidação | Brincos de ouro e prata (x3 por lingote), lisos ou com gema |

Exemplo de leitura:

```lua
{ ["steel"] = { ["ironore"] = 1, ["carbon"] = 1 } },
{ ["gold_ring"] = { ["goldingot"] = 1 }, ['amount'] = 3 },
```

---

## Preços de venda

Ficam em `shared/selling.lua`, na tabela `Selling`. `OreSell` é a lista do comprador de minérios. `JewelSell` tem uma seção por tipo de joia (`Emerald`, `Ruby`, `Diamond`, `Sapphire`, `Rings`, `Necklaces`, `Earrings`). Todos os itens vêm com preço `100` do upstream e não foram ajustados.

---

## NPC de tutorial

Camada da MRI, em `client/npc.lua`. Com `Config.General.npcTalk = true` e `rep-talkNPC` mais `pickle_waypoints` ligados, um NPC (`s_m_m_dockwork_01`, "Seu Fábio") é criado em `vec4(-599.69, 2093.15, 130.31, 347.62)`, na entrada da mina.

O diálogo explica o ciclo em três passos e, em cada um, oferece marcar no GPS as minas, os pontos de lavagem, a fundição, a joalheria e as áreas de garimpo. As coordenadas ficam na tabela `Tutorial.waypoints` no topo do arquivo, e são independentes de `shared/locations.lua`. Se mudar um local lá, ajuste aqui também.

O NPC é criado no `onPlayerLoaded` e apagado no `onResourceStop`.

---

## Entrypoints para outros recursos

O recurso não registra exports. O único evento de servidor é interno:

| Evento | Argumentos | Descrição |
|---|---|---|
| `jim-mining:Reward` | `data` | Entrega a recompensa. `data.mine`, `data.crack`, `data.wash` ou `data.pan` define o tipo. `data.cost` é quanta `stone` consumir e `data.setReward` é o minério, no `AltMining` |

O nome do evento usa `getScript()`, então renomear a pasta do recurso muda o nome do evento junto.

As lojas e a venda são registradas no `onResourceStart` do servidor pelo `jim_bridge`: `registerShop("miningShop", …)` para cada loja e `registerSellShop` para cada comprador de minérios e de joias.

No cliente, as ações ficam em `Mining.Functions`, `Mining.MineOre`, `Mining.Other` e `Mining.Menus`, globais dentro do recurso mas não exportadas.

---

## Localização

Os textos ficam em `locales/`, carregados como `shared_scripts`, e são lidos com `locale("secao", "chave")`. O idioma ativo é `Config.Lan`, não a convar `ox:locale`.

Idiomas incluídos: `cn`, `da`, `de`, `en`, `et`, `fr`, `nl`, `pt`, `tr`. O `pt.lua` foi traduzido por completo pela MRI. Os outros vêm do upstream.

Fora dos locales, em português fixo: os nomes dos locais em `shared/locations.lua` e o diálogo do NPC em `client/npc.lua`.

---

## O que é da MRI

Tudo o mais é o upstream 3.0.12 sem alteração.

| Arquivo | Mudança |
|---|---|
| `config.lua` | `Lan = "pt"`, `System` em `ox`, `General.npcTalk`, preços da loja |
| `locales/pt.lua` | Tradução completa |
| `shared/locations.lua` | Nomes em português, blips de garimpo e fundição desligados, `JewelBuyer` desabilitado, `MineShaft` com blip cor 43 e luz `prop_worklight_01a`, uma posição extra de garimpo em `Wilderness` |
| `client/client.lua` | Prop do garimpo `gg_batera` no lugar de `bkr_prop_meth_tray_01b` |
| `client/npc.lua` | Arquivo novo. NPC de tutorial |
| `server/server.lua` | Uma linha no evento `Reward`: XP no `cw-rep` se ele estiver ligado |
| `MANUAL.md`, `.github/workflows/repo-dispatch.yml` | Este manual e a publicação dele na documentação |

Ao atualizar do upstream, faça merge e confira só esses arquivos. Mudança de comportamento vai em PR pro Jimathy, não aqui.

---

## Estrutura de arquivos

```
jim-mining/
├── client/
│   ├── client.lua        — targets, props, minas, mineração, quebra, lavagem, garimpo, menus de crafting e venda
│   └── npc.lua           — NPC de tutorial (MRI)
├── server/
│   └── server.lua        — recompensas com canCarry, registro de lojas e compradores, validação de itens
├── shared/
│   ├── shared.lua        — sons da furadeira, timings, carrinho de mina
│   ├── crafting.lua      — receitas dos 5 menus
│   ├── selling.lua       — preços de venda
│   └── locations.lua     — minas, lavagem, garimpo, fundição e compradores
├── locales/              — cn, da, de, en, et, fr, nl, pt, tr
├── images/               — 62 imagens dos itens (copiar para a pasta do inventário)
├── config.lua            — idioma, sistema, geral, durabilidade, timings, pools e loja
├── version.txt
├── README.md
└── fxmanifest.lua
```
