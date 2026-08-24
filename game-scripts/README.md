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
| Bat hit range | `Library.Modules.BatController.Config.Range` | 15 studs (+2 `HitTolerance`) |
| Bat cooldown | `CooldownActive` / `CooldownEndTime` tool attributes | set by the server per swing |
| Bloom tree tag | `Directory.Sakura.TreeTag` | `SakuraBloomTree` |
| Crystal tag | `Directory.Sakura.CrystalTag` | `SakuraCrystal` |
| Bloom timings | `Directory.Sakura.Bloom` | 285 s long, every 1800 s, 0.6 s hit cooldown, 10 stud hit and pickup range |
| Incubator unlock | `Library.Client.Save` → `Sakura.Unlocked`, plus `Workspace.IncubatorDead` | locked until a `Crane` is returned |
| Crane ownership | `Library.Client.Save` → `Inventory[uid].Category == "Crane"` | |
| Crystals held | `Library.Client.CurrencyCmds.Get("SakuraCrystals")` | |
| Speed curve | `Library.Util.SpeedUpgradeUtil.GetSpeedModifierFromPower` | |
| Movement margin | `Library.Globals.Constants.CLIENT_OVERLAP_MARGIN` | 0.95 |

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
your backpack — and swings at players carrying eggs inside the server's real 15
stud range, optionally limited to a radius around your plot. It respects the
bat's own cooldown attributes, and it will not swap tools while you are holding
an egg. Swings go through the tool's own `Activate`, so the game's bat
controller picks the target and sends the request exactly as a manual swing
would.

**Sakura tab** — Great Bloom tree farming, crystal collection, Cherry Blossom
egg farming, the incubator unlock, and place/hatch buttons.

- *Auto Farm Trees* only runs while a bloom is actually active (checked via the
  live tree tag and the `GreatBloomEndsAt` attribute), chops with the real 0.6 s
  hit cooldown, then sweeps the crystals it dropped.
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

- `Sakura: HitTree`, `Sakura: CollectCrystal` and `Sakura: ReturnCrane` argument
  shapes could not be observed directly, because no Great Bloom was running and
  the executor in use has no decompiler or working remote spy. The features
  therefore drive the game's own interaction paths — swinging the equipped bat
  near a tagged tree, and walking inside `CrystalPickupRange` — which need no
  argument guessing. Direct crystal collection is available as an opt-in toggle,
  and the unlock falls back from `(craneUid)` to a no-argument call.
- `ExpectedPlaceVersion` was moved from 382 to 385.
