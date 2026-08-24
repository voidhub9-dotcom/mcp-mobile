# game-scripts

Executor scripts driven through this MCP connector.

## Steal_An_Egg_LuminHub.lua

Lumin Hub for **Steal An Egg** (`PlaceId 107778070777162`), updated against a live
server running **place version 385**.

Every constant the new features rely on is read out of the running place at load
time rather than hard coded, so an update that reshuffles the numbers is picked
up automatically. These are the sources that were checked against the live game
while the features were written:

| What | Where it comes from | Value seen live |
| --- | --- | --- |
| Egg drop tables | `Directory.Areas.Directory[area].DropTable` | 10 areas, weights summing to 100 |
| Bat ranking | `Directory.Gears.Directory[gear].IndexBatTier` | Forest Bat 1 … Katana 10 |
| Bat reach | `Config.Range + Config.HitTolerance + gear.BatControllerData.RangeBonus`, times `GetHitboxScalar()` | 17 with a Forest Bat, 28.25 with an Abyss Ocean Bat, 33.875 with a Katana |
| Bat swing rate | `_tryActivate(0.6, …)` in `BatController.Client` | fixed 0.6 s client debounce |
| Bat request | `Network.Fire(NETWORK_MAP.Bat.ACTIVATE, target, traceId)` | target from `_selectClosestTarget()` |
| Bloom tree tag | `Directory.Sakura.TreeTag` | `SakuraBloomTree`, 50 live trees under `Workspace.SakuraBloomTrees` |
| Tree reach | `tree:GetAttribute("Radius") + Bloom.HitRange`, horizontal only | 5.07 + 10 = 15.07 on a Small tree |
| Tree sizes | `Directory.Sakura.Bloom.Sizes` | Small 1 hit / 1 crystal … Gigantic 3 hits / 6 crystals |
| Crystal tag | `Directory.Sakura.CrystalTag` | `SakuraCrystal`, 60 s lifetime |
| Bloom timings | `Directory.Sakura.Bloom` | 285 s long, every 1800 s, 10 stud hit and pickup range |
| Incubator unlock | `SakuraBloomPolicy.IsUnlocked(isLocalDataLoaded, save)` | `false` — `Workspace.IncubatorDead` still present |
| Crane ownership | `Library.Client.Save` → `Inventory[uid].Category == "Crane"` | none owned |
| Crystals held | `Library.Client.CurrencyCmds.Get("SakuraCrystals")` | 0 |
| Own carry state | `Eggs: AreaEggCarryState` → `{ IsCarrying, Uid }` | local player only |
| Speed curve | `Library.Util.SpeedUpgradeUtil.GetSpeedModifierFromPower` | |
| Movement margin | `Library.Globals.Constants.CLIENT_OVERLAP_MARGIN` | 0.95 |

### Remote signatures

Read out of the decompiled client, not guessed:

| Remote | Kind | Arguments |
| --- | --- | --- |
| `Bat:Activate` | RemoteEvent | `(target, traceId)` — sent by the tool's own controller |
| `Sakura: HitTree` | RemoteEvent | `(treeInstance)` |
| `Sakura: CollectCrystal` | RemoteFunction | `(crystalModel)` |
| `Sakura: ReturnCrane` | RemoteFunction | none — the server finds your Crane itself |
| `Sakura: Deposit` | RemoteFunction | `(amount)` |
| `Sakura: Mutate` | RemoteFunction | none |
| `Sakura: InsertEgg` | RemoteFunction | `(eggUid)` |
| `Index: RequestEquipAreaBat` | RemoteFunction | `(areaId)` |

### What was added

**Egg Finder** (Intel tab) lists every egg on the field with its rarity, area,
distance, mutations and the real spawn odds as both a percentage and 1-in-N. It
polls on a timer — there is no `RenderStepped` or `Heartbeat` scan, so it costs
nothing per frame.

**Egg Predictor** (Intel tab) shows an area's drop table straight from
`DropTable`, rarest first, with percentage and 1-in-N alongside the current
server luck multiplier. It is the per-roll spawn chance, not a claim about what
the next reset will contain.

**Bat Aura** (Farm tab) equips the highest `IndexBatTier` bat you own — asking
the server for it through `Index: RequestEquipAreaBat` when it is not already in
your backpack — and swings at players carrying eggs, optionally limited to a
radius around your plot. Swings go through the tool's own `Activate`, so the
game's bat controller picks the target and sends the request exactly as a manual
swing would.

Worth knowing: the game's own `_isTargetEligible` does **not** care whether a
target is carrying an egg. It checks that they are alive, not ragdolled, inside
the gameplay area and within reach. Restricting to carriers is this script's
choice, layered on top of those four real checks, which it also applies so it
never swings at someone the server would reject.

**Sakura tab** — Great Bloom tree farming, crystal collection, Cherry Blossom
egg farming, the incubator unlock, and place/hatch buttons.

- *Auto Farm Trees* does not swing. The Great Bloom client already runs a
  Heartbeat loop calling its own `tryAutoSwing` every 0.15 s, which hits a tree
  for you whenever you hold a bat, the incubator is unlocked and a tree is in
  reach. So the farm equips a bat and parks you inside `Radius + HitRange` of the
  nearest tree, then sweeps the crystals. Sending `HitTree` yourself is an opt-in
  toggle, off by default.
- Hitting trees at all requires the incubator to be unlocked — `tryAutoSwing`
  checks `SakuraBloomPolicy.IsUnlocked` before it sends anything — so the farm
  says so plainly instead of running uselessly.
- *Auto Unlock Incubator* checks that you actually own a Crane and that the
  incubator is still locked. With no Crane it sends nothing at all, and once
  unlocked it stops rather than spending a second one.

**Global Auto Farm** (Farm tab) rotates the egg farm through every area. The
order is derived from where the live eggs sit on the map, which currently gives
Forest → Lake → Desert → Jungle → Snow → Volcano → Abyss Ocean → Prehistoric →
Cosmic → Cherry Blossom, and means a new area added by an update slots itself in
without a script change.

**Calibrate Fast Travel** (Farm tab) reads the walk speed the game derives from
your Speed Power and sets the travel speed to that times the client's own 0.95
overlap margin, shaving it further if rollbacks have already been seen. On the
test account (Speed Power 243.7M, walk speed 195.5) that gives 185 instead of
the stock 300, which is what causes the rollbacks.

### Notes

- All of the above was read from the live server: module values through the
  connector, and call sites from `decompile()` on the shipped client scripts
  (`BatController.Client`, `AdminAbuseClient.Events.GreatBloom`, the two
  `SakuraIncubator` scripts, `AreaEggs`). Cobalt's remote spy times out on this
  Delta build, so decompilation was used instead — it gives the argument lists
  directly rather than waiting to observe a call.
- `ExpectedPlaceVersion` was moved from 382 to 385.
