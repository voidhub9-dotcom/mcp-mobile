# Steal_An_Egg_LuminHub.lua

Lumin Hub for Steal An Egg (`PlaceId 107778070777162`), built against place
version 385.

Constants are read out of the running place at load time rather than hard
coded, so a game update that reshuffles the numbers is picked up automatically.

## Sources

| What | Where it comes from |
| --- | --- |
| Egg drop tables | `Directory.Areas.Directory[area].DropTable` |
| Bat ranking | `Directory.Gears.Directory[gear].IndexBatTier` |
| Bat reach | `Config.Range + Config.HitTolerance + gear.BatControllerData.RangeBonus`, times `GetHitboxScalar()` |
| Bat swing rate | fixed 0.6 s client debounce in `BatController.Client` |
| Bloom tree tag | `Directory.Sakura.TreeTag` (`SakuraBloomTree`) |
| Tree reach | `tree:GetAttribute("Radius") + Bloom.HitRange`, horizontal only |
| Tree sizes | `Directory.Sakura.Bloom.Sizes` — Small 1 hit / 1 crystal, Gigantic 3 hits / 6 crystals |
| Crystal tag | `Directory.Sakura.CrystalTag` (`SakuraCrystal`), 60 s lifetime |
| Bloom timings | `Directory.Sakura.Bloom` — 285 s long, every 1800 s, 10 stud hit and pickup range |
| Incubator unlock | `SakuraBloomPolicy.IsUnlocked(isLocalDataLoaded, save)` |
| Crane ownership | `Save.Inventory[uid].Category == "Crane"` |
| Crystals held | `CurrencyCmds.Get("SakuraCrystals")` |
| Own carry state | `Eggs: AreaEggCarryState` → `{ IsCarrying, Uid }` |
| Speed curve | `SpeedUpgradeUtil.GetSpeedModifierFromPower` |
| Movement margin | `Constants.CLIENT_OVERLAP_MARGIN` (0.95) |

Bat reach works out to 17 studs with a Forest Bat, 28.25 with an Abyss Ocean
Bat and 33.875 with a Katana.

## Remote signatures

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

## Features

**Egg Finder** (Intel tab) lists every egg on the field with rarity, area,
distance, mutations and the drop-table odds as a percentage and 1-in-N. It
polls on a timer, so there is no per-frame scanning.

There is no reset prediction. The Field Reset countdown, Most Overdue ranking,
Rare Reveal and Rarity Mix panels have all been removed, along with the spawn
history they were built on.

**Bat Aura** (Farm tab) equips the highest `IndexBatTier` bat you own, asking
the server for it through `Index: RequestEquipAreaBat` when it is not already
in your backpack, and swings at players carrying eggs, optionally limited to a
radius around your plot. Swings go through the tool's own `Activate`, so the
game's bat controller picks the target and sends the request itself.

The game's own eligibility check ignores whether a target is carrying an egg —
it wants a living, non-ragdolled player inside the gameplay area and in reach.
Restricting to carriers is this script's own filter, layered on top of those
four checks, which it also applies so it never swings at someone the server
would reject.

**Sakura tab** — Great Bloom tree farming, crystal collection, Cherry Blossom
egg farming, the incubator unlock, and place/hatch buttons.

- *Auto Farm Trees* does not swing. The Great Bloom client already runs a
  Heartbeat loop that hits a tree for you every 0.15 s whenever you hold a bat,
  the incubator is unlocked and a tree is in reach. So the farm equips a bat and
  parks you inside `Radius + HitRange` of the nearest tree, then sweeps the
  crystals. Sending `HitTree` directly is an opt-in toggle, off by default.
- Hitting trees at all requires the incubator to be unlocked, so the farm says
  so plainly instead of running with nothing to show for it.
- *Auto Unlock Incubator* checks that you own a Crane and that the incubator is
  still locked. With no Crane it sends nothing, and once unlocked it stops
  rather than spending a second one.

**Global Auto Farm** (Farm tab) rotates the egg farm through every area. The
order is derived from where the live eggs sit on the map, currently Forest →
Lake → Desert → Jungle → Snow → Volcano → Abyss Ocean → Prehistoric → Cosmic →
Cherry Blossom, so a new area added by an update slots itself in without a
script change.

**Calibrate Fast Travel** (Farm tab) reads the walk speed the game derives from
your Speed Power and sets the travel speed to that times the client's own 0.95
overlap margin, shaving it further if rollbacks have already been seen. At
Speed Power 243.7M (walk speed 195.5) that gives 185 instead of the stock 300,
which is what causes the rollbacks.

## Anti-cheat posture

`ReplicatedFirst.UGI.ContentCatalog.Exchange` is this game's integrity client.
It removes itself from the instance tree — `game:GetDescendants()` returns
nothing for it — while staying the only live listener on
`ClientCharacter: Update`. It is left completely alone. Three things that used
to interfere with it are gone:

- A `neutralizeFrameLoops()` pass that disabled every Heartbeat, Stepped and
  RenderStepped connection whose source matched `UGI.ContentCatalog`, re-run on
  a 5 second `ACSweep` loop.
- A `hookfunction` on `Library.Client.Network.Fire` plus a `__namecall` hook to
  swallow `RuntimeSync.REPORT`. That remote does not exist in this place, so
  the hook blocked nothing and only altered a function the game holds.
- Blanket disabling of `ScriptContext.Error` listeners, which is the channel
  the integrity client reports through.

## Logging

Console silencing is opt-in through **Silence Console** in the Menu tab,
default off. When enabled it blanks `print`, `warn` and the `rconsole*` family
and keeps clearing `LogService`, but it no longer touches `ScriptContext.Error`.
The hub prints nothing of its own, so this only hides other scripts' output,
and replacing shared globals is itself detectable.

Status surfaces through the menu labels and notifications, which are GUI.

## Movement

Travel Mode defaults to **Tween**, and the script calibrates it once at load:
travel speed becomes your live `Humanoid.WalkSpeed` times the client's own 0.95
overlap margin, instead of the stock 300. At walk speed ~201 that is ~191
studs/s, so the pace matches what the server expects even though the path is a
straight line rather than real ground.

**Walk** steers the humanoid with `MoveTo` instead. Slower, but it follows
terrain and is the least distinguishable from normal play. **Instant** snaps
the root and is the easiest to spot.

Carrying an egg no longer fights the humanoid. `Move:Halt()` clears
`WalkToPart`, pins `WalkToPoint` to the current position and zeroes
`MoveDirection`; in Walk mode the carry loop calls it instead of rewriting the
root CFrame, which is what used to make the character jitter on top of an egg
and drop the grab.

## Icons

Tab, groupbox and tabbox icons are back, along with the window icon, which
`resolveLuminIcon()` caches to `A7.png` from the branding URL. They were never
a detection vector — the live run confirmed the menu's ScreenGuis sit in
`gethui()` and CoreGui holds only Roblox's own CoreScript GUIs.

## GUI parenting

Every ScreenGui and Highlight the script creates goes into `gethui()`, resolved
once at load through a pcall and cached as `GuiHost`. `CoreGui` is kept only as
the fallback for executors that do not expose `gethui`, and for locating
Roblox's own `RobloxPromptGui` in the kick watcher, which is a CoreScript GUI
and never lives in the hidden container.

The menu window itself is parented by the external Library, not by this file.

## Auto-execute on rejoin

The rejoin and teleport handlers re-run the script from `getgenv().LuminHubSource`
if you set it before executing, or from the Rejoin Payload box in the menu.
Neither is set by default and no fallback URL is baked in, so nothing is fetched
unless you point it somewhere yourself.
