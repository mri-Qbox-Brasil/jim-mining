# jim-mining — Manual

Job de mineração completo: quebrar minério com picareta, furadeira ou laser, lavar e garimpar pedras, fundir minérios em lingotes, lapidar joias e vender tudo para NPCs compradores.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Itens](#itens)
5. [Ciclo de produção](#ciclo-de-produção)
6. [Locais](#locais)
7. [Receitas de crafting](#receitas-de-crafting)
8. [Integrações](#integrações)
9. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
10. [Localização](#localização)
11. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qb-core` | Sim | `exports['qb-core']:GetCoreObject()` no cliente e no servidor. Em QBox, exige bridge de `qb-core` |
| `ox_lib` | Sim | Carregado via `@ox_lib/init.lua`. Progress bar e context menu |
| `qb-target` | Sim | Todas as zonas são criadas com `qb-target`, sem alternativa no código |
| `ox_inventory` | Sim (padrão) | Loja registrada via `RegisterShop("miningShop", ...)` quando `Config.Inv = "ox"` |
| `mri_Qbox` | Sim | `exports['mri_Qbox']:CanCarryItem` é chamado antes de cada mineração |
| `cw-rep` | Sim | `exports["cw-rep"]:updateSkill(src, 'mining', 5)` é chamado a cada recompensa |
| `rep-talkNPC` | Não | NPC tutorial "Seu Fábio". Desative com `Config.npcTalk = false` |
| `qb-menu` | Não | Só se `Config.Menu = "qb"` |
| `jim-shops` | Não | Só se `Config.JimShops = true` |

> Este é um fork com integrações MRI. As chamadas a `mri_Qbox`, `cw-rep` e `rep-talkNPC` não têm fallback: sem esses recursos, minerar e receber recompensa quebram.

---

## Instalação

1. Copie a pasta `jim-mining` para `resources/`.
2. Adicione ao `server.cfg`, depois das dependências:
   ```
   ensure qb-target
   ensure ox_lib
   ensure jim-mining
   ```
3. Copie o conteúdo de `images/` para a pasta de imagens do seu inventário (por padrão `ox_inventory/web/images/`, o mesmo caminho de `Config.img`).
4. Cadastre os itens no seu inventário. O recurso **não** traz `items.lua` nem SQL — ele apenas valida na inicialização. Se faltar item, o console imprime avisos como:
   ```
   Selling: Missing Item from QBCore.Shared.Items: 'goldore'
   Crafting recipe couldn't find item 'steel' in the shared
   ```
   Os itens necessários vêm de `Config.Items.items` (loja), `Config.CrackPool`, `Config.WashPool`, `Config.PanPool`, `Config.SellingPrices` e de todas as receitas em `Crafting`.
5. Ajuste o `config.lua` (idioma, inventário, menu, notificações) e o `shared/locations.lua` (locais habilitados).

Não há permissões ACE.

---

## Configuração

Todas as opções ficam em `config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.npcTalk` | bool | Sim | Cria o NPC tutorial "Seu Fábio" via `rep-talkNPC` na entrada da mina |
| `Config.Debug` | bool | Sim | Logs no console, `debugPoly` nas zonas, tempos reduzidos para 1-2 s e **desativa o kick por dupe** |
| `Config.img` | string | Sim | Caminho das imagens do inventário usado nos menus. Padrão `"ox_inventory/web/images/"` |
| `Config.Lan` | string | Sim | Idioma. Deve existir `locales/<Lan>.lua`. Padrão `"pt"` |
| `Config.JimShops` | bool | Sim | Abre a loja via `jim-shops:ShopOpen` em vez do inventário padrão |
| `Config.Inv` | string | Sim | `"ox"` ou `"qb"`. Define como itens são checados/removidos e se a loja é registrada no `ox_inventory` |
| `Config.Menu` | string | Sim | `"ox"` (`ox_lib` context) ou `"qb"` (`qb-menu`) |
| `Config.ProgressBar` | string | Sim | `"ox"` ou `"qb"` |
| `Config.Notify` | string | Sim | `"ox"` ou `"qb"` |
| `Config.DrillSound` | bool | Sim | Liga o som da furadeira |
| `Config.MultiCraft` | bool | Sim | Ativa o submenu de quantidade ao fabricar |
| `Config.MultiCraftAmounts` | tabela de números | Sim | Quantidades oferecidas no multicraft. Padrão `{ 1, 5, 10 }` |
| `Config.K4MB1Prop` | bool | Sim | Usa as props de minério do MLO Mining Cave da K4MB1 no lugar das props padrão do jogo |
| `Config.Timings` | tabela | Sim | Duração de cada ação, em ms. Veja abaixo |
| `Config.CrackPool` | lista de itens | Sim | Itens sorteados ao quebrar pedra: `carbon`, `copperore`, `ironore`, `metalscrap` |
| `Config.WashPool` | lista de itens | Sim | Itens sorteados ao lavar pedra. `goldore` aparece duas vezes, o que dobra sua chance |
| `Config.PanPool` | lista de itens | Sim | Itens sorteados ao garimpar. Itens repetidos têm chance proporcional |
| `Config.OreSell` | lista de itens | Sim | Itens que o comprador de minérios aceita |
| `Config.SellingPrices` | tabela `[item] = preço` | Sim | Preço unitário de cada item vendável (minérios, gemas e joias). Todos vêm com `100` |
| `Config.Items` | tabela | Sim | Loja de mineração: `label`, `slots` e a lista `items` (`name`, `price`, `amount`, `slot`) |
| `Crafting` | tabela | Sim | Receitas dos 5 menus de fabricação. Veja [Receitas de crafting](#receitas-de-crafting) |

### `Config.Timings`

| Chave | Padrão | Onde é usada |
|---|---|---|
| `Cracking` | 5000–10000 ms | Quebrar pedra na bancada |
| `Washing` | 10000–12000 ms | Lavar pedra na água |
| `Panning` | 25000–30000 ms | Garimpar com a bateia |
| `Pickaxe` | 15000–18000 ms | Minerar com picareta **e** com furadeira |
| `Mining` | 10000–15000 ms | Declarada no config |
| `Laser` | 7000–10000 ms | Minerar com laser |
| `OreRespawn` | 55000–75000 ms | Tempo até a pedra minerada reaparecer |
| `Crafting` | 5000 ms | Fabricação |

Os valores usam `math.random(min, max)` e são sorteados **uma vez** no carregamento do config — não a cada ação.

---

## Itens

A loja de mineração (`Config.Items`) vende:

| Item | Preço | Uso |
|---|---|---|
| `pickaxe` | 100 | Minerar. Tem ~10% de chance de quebrar por uso |
| `miningdrill` | 10000 | Minerar mais rápido. Consome `drillbit` |
| `drillbit` | 0 | Broca. Necessária para a furadeira; ~20% de chance de quebrar por uso |
| `mininglaser` | 60000 | Minerar com laser. Não consome nada |
| `goldpan` | 100 | Bateia, usada para garimpar |
| `weapon_flashlight` | 100 | Lanterna |
| `water_bottle`, `sandwich`, `bandage` | 10 | Consumíveis |

Minerar sempre produz `stone`. `stone` é a matéria-prima de quebrar (`Cracking`) e lavar (`Washing`).

---

## Ciclo de produção

1. **Minerar** — nas pedras dentro das minas habilitadas, com `pickaxe`, `miningdrill` (requer `drillbit`) ou `mininglaser`. Rende de 1 a 3 `stone`. A pedra some e reaparece após `Config.Timings.OreRespawn`.
2. **Quebrar pedra** (bancada `prop_vertdrill_01`) — consome 1 `stone` e devolve de 1 a 3 sorteios do `CrackPool`.
3. **Lavar pedra** (nos rios e lagos de `Locations.Washing`) — consome 1 `stone` e devolve de 1 a 2 sorteios do `WashPool` (ouro e gemas brutas).
4. **Garimpar** (`goldpan`, nas zonas de `Locations.Panning`) — não consome nada e devolve de 1 a 3 sorteios do `PanPool` (ouro, prata e lixo).
5. **Fundir** (fundição) — transforma minérios em lingotes e metais pelas receitas `SmeltMenu`.
6. **Lapidar** (bancada `gr_prop_gr_speeddrill_01c`) — corta gemas brutas e monta anéis, colares e brincos.
7. **Vender** — o comprador de minérios (`OreBuyer`) compra os itens de `Config.OreSell`; o comprador de joias (`JewelBuyer`) compra as peças acabadas. A venda é sempre do **estoque inteiro** do item, ao preço de `Config.SellingPrices`, pago em dinheiro vivo.

Cada recompensa também chama `exports["cw-rep"]:updateSkill(src, 'mining', 5)`.

### Proteção anti-dupe

Ao remover um item, o servidor confere se o jogador realmente o tem. Se não tiver, o jogador é **kickado** com "Kicked for attempting to duplicate items" e o console registra o nome do personagem. Com `Config.Debug = true`, o kick não acontece.

---

## Locais

Ficam em `shared/locations.lua`, na tabela `Config.Locations`.

| Chave | Conteúdo |
|---|---|
| `Washing` | 10 pontos de lavagem de pedra (montanhas, riacho, Gordo, Alamo Sea). `Enable` liga/desliga o grupo |
| `Panning` | 3 áreas de garimpo (`Vineyard`, `Tongva`, `Wilderness`), cada uma com `Enable`, `Blip` e uma lista `Positions` (`coords` vec4, `w` largura, `d` profundidade) |
| `JewelBuyer` | Comprador de joias na Vangelico. Vem **desabilitado** (`Enable = false`) |
| `Smelting` | Coordenada avulsa da fundição |
| `Mines` | As minas em si. Cada uma pode ter `Blip`, `Store`, `Lights`, `Smelting`, `Cracking`, `OreBuyer`, `JewelCut` e `OrePositions` |

Minas incluídas:

| Mina | Padrão | Conteúdo |
|---|---|---|
| `Fundição` | Habilitada | Loja, fundição, 2 bancadas de quebrar pedra, comprador de minérios, 2 bancadas de lapidação |
| `MineShaft` | Habilitada | Blip, loja, 30 luzes e 14 pedras de minério |
| `Quarry` | Habilitada | Blip, loja, 5 luzes e 8 pedras de minério |
| `K4MB1` | Desabilitada | Mineshaft do MLO da K4MB1, com 32 pedras. Requer o MLO instalado |

Cada mina aceita `Job = "<nome>"` para restringir os alvos a um emprego. Com `Job = nil` (padrão), qualquer jogador pode usar.

Para adicionar uma mina, copie o bloco comentado ao final de `shared/locations.lua`:

```lua
["NovaMina"] = {
    Enable = true,
    Job = nil,
    Blip = { Enable = true, name = "Mina", coords = vec4(0.0, 0.0, 0.0, 0.0), sprite = 527, col = 43 },
    Store = { },
    Cracking = { },
    OreBuyer = { },
    OrePositions = { vec4(0.0, 0.0, 0.0, 0.0) },
},
```

O recurso também esconde as portas do mineshaft com `CreateModelHide(vec3(-596.04, 2089.01, 131.41), 10.5, ...)`, fixo no `client.lua`.

---

## Receitas de crafting

A tabela `Crafting` em `config.lua` tem cinco menus. Em cada receita, a chave externa é o item produzido, as chaves internas são os ingredientes e `amount` (opcional) é quanto sai por fabricação.

| Menu | Onde é usado | Produz |
|---|---|---|
| `SmeltMenu` | Fundição | `copper` (x4), `goldingot`, `silveringot`, `iron`, `steel`, `aluminum` (x3), `glass` (x2). Lingotes também podem ser refundidos a partir de correntes e anéis |
| `GemCut` | Bancada de lapidação | `emerald`, `diamond`, `ruby`, `sapphire` a partir das versões `uncut_` |
| `RingCut` | Bancada de lapidação | Anéis de ouro e prata, lisos ou com gema |
| `NeckCut` | Bancada de lapidação | Correntes e colares de ouro e prata, lisos ou com gema |
| `EarCut` | Bancada de lapidação | Brincos de ouro e prata, lisos ou com gema |

Exemplo de leitura:

```lua
{ ["steel"] = { ["ironore"] = 1, ["carbon"] = 1 } },      -- 1 steel = 1 ironore + 1 carbon
{ ["gold_ring"] = { ["goldingot"] = 1 }, ['amount'] = 3 } -- 3 gold_ring = 1 goldingot
```

---

## Integrações

### mri_Qbox

Antes de cada mineração, o cliente chama `exports['mri_Qbox']:CanCarryItem("stone", 2)`. Se o jogador não puder carregar, a ação é bloqueada com a notificação de inventário cheio.

### cw-rep

A cada recompensa de mineração o servidor chama `exports["cw-rep"]:updateSkill(source, 'mining', 5)`, somando XP na skill `mining`.

### rep-talkNPC

Com `Config.npcTalk = true`, um NPC (`s_m_m_dockwork_01`) é criado em `vec4(-599.69, 2093.15, 130.31, 347.62)` com um diálogo tutorial em português e a opção de marcar no GPS a joalheria e a bancada de joias.

### ox_inventory

Com `Config.Inv = "ox"`, a loja é registrada no servidor com `exports.ox_inventory:RegisterShop("miningShop", ...)` e aberta no cliente com `openInventory('shop', { type = 'miningShop' })`.

### jim-shops

Com `Config.JimShops = true`, a abertura da loja dispara `jim-shops:ShopOpen` em vez do inventário padrão.

---

## Entrypoints para outros recursos

O recurso não registra exports. Os eventos abaixo são internos e usados pelo `qb-target` e pelos menus.

### Eventos de servidor

| Evento | Argumentos | Descrição |
|---|---|---|
| `jim-mining:Reward` | `data` | Entrega a recompensa. `data.mine`, `data.crack`, `data.wash` ou `data.pan` define o tipo; `data.cost` é quanta `stone` consumir |
| `jim-mining:Selling` | `data` | Vende **todo** o estoque de `data.item` ao preço de `Config.SellingPrices[data.item]` |
| `jim-mining:Crafting:GetItem` | `ItemMake`, `craftable` | Remove os ingredientes e entrega o item fabricado |
| `jim-mining:server:toggleItem` | `give`, `item`, `amount`, `newsrc` | Dá (`true`) ou remove (`false`) um item. A remoção passa pela checagem anti-dupe |

### Eventos de cliente

`jim-mining:openShop`, `jim-mining:MineOre:Pick`, `jim-mining:MineOre:Drill`, `jim-mining:MineOre:Laser`, `jim-mining:CrackStart`, `jim-mining:WashStart`, `jim-mining:PanStart`, `jim-mining:SellOre`, `jim-mining:SellAnim`, `jim-mining:JewelSell`, `jim-mining:JewelSell:Sub`, `jim-mining:JewelCut`, `jim-mining:CraftMenu`, `jim-mining:Crafting:MultiCraft`, `jim-mining:Crafting:MakeItem`.

Todos esperam a tabela `data` montada pelas opções do `qb-target` (com campos como `stone`, `name`, `ped`, `bench`, `coords`). Não foram feitos para chamada externa.

---

## Localização

Os textos ficam em `locales/`, carregados como `shared_scripts`. O idioma ativo é escolhido por `Config.Lan` — **não** pela convar `ox:locale`.

Idiomas incluídos: `cn`, `da`, `de`, `en`, `et`, `fr`, `nl`, `pt`, `tr`.

O padrão do fork é `Config.Lan = "pt"`. Para adicionar um idioma, crie `locales/<codigo>.lua` seguindo a estrutura dos existentes (tabela `Loc['<codigo>']` com as subtabelas `info` e `error`).

Alguns textos estão fora dos locales: os nomes dos locais em `shared/locations.lua` e os diálogos do NPC tutorial em `client.lua` estão hardcoded em português.

---

## Estrutura de arquivos

```
jim-mining/
├── client.lua              — targets, props, minas, animações de mineração, menus de venda e crafting, NPC tutorial
├── server.lua              — recompensas, venda, crafting, anti-dupe, registro da loja no ox_inventory
├── config.lua              — inventário/menu/notify, timings, pools de itens, preços, loja e receitas
├── shared/
│   ├── shared.lua          — QBCore, helpers de model/anim/ptfx, props, peds, blips, progressBar, notify
│   └── locations.lua       — minas, lavagem, garimpo, fundição e compradores
├── locales/                — cn, da, de, en, et, fr, nl, pt, tr
├── images/                 — imagens dos itens (copiar para a pasta do inventário)
├── README.md
└── fxmanifest.lua
```
