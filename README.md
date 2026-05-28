# FPGA_Basys3_VHDL_Projects


# Real-Hardware Conversion Scaffold

**Reference only — this is NOT built.** `drones.c` is a **register-based simulation
of a multi-drone communication driver**. User Space speaks a per-drone register
API (one `/dev/skyport_droneX` per drone); each drone's register block is a
`kzalloc`'d `u32` array. In production this driver runs on a **ground / fleet
controller**, and below its accessors a **transport layer** (LTE/5G modem, radio
link, etc.) carries each register read/write to and from a remote drone — which
is what enables **BVLOS** (Beyond Visual Line of Sight) operation.

> The register offsets, command codes, modem `compatible` string, and any
> addressing scheme below are **placeholders**. On real silicon they come from
> the modem's datasheet and the fleet protocol spec.

---

## Deployment

```
 User Space (drone_controller / dashboard, on the ground controller)
         │  echo "START_MISSION 101 ..." > /dev/skyport_drone0
         │  cat /dev/skyport_drone0   →   JSON telemetry
         ▼
 ┌──────────────────────────────────────────────────────────────────┐
 │ drones.ko — multi-drone communication driver (this project)      │
 │ • One cdev per drone (/dev/skyport_drone0/1/2)                   │
 │ • Per-drone register block: STATUS, GPS, BATTERY, WEIGHT,        │
 │   ALTITUDE, SPEED, COMMAND, NAV, PROPELLER, PITCH                │
 │ • skyport_reg_read / skyport_reg_write — the API seam            │
 │ • SIM: registers are RAM; simulate_flight + SET_TELEMETRY        │
 │   stand in for the radio link                                    │
 │ • REAL HW: every reg op becomes a transport op                   │
 └──────────────────────────────────────────────────────────────────┘
         │
         │  Transport layer (modem / radio) — NOT IMPLEMENTED HERE
         ▼
   Drone 0       Drone 1       Drone 2     (BVLOS — miles away)
   (real flight controllers, GPS, motors, gripper, battery)
```

The driver's job is to provide a **uniform per-drone API** so any controller
(daemon, dashboard, scripted tool) speaks the same protocol to every drone.
Whether the actual transport underneath is LTE/5G, dedicated radio, or a
ruggedised mesh network is the production team's choice; the kernel API stays
the same.

---

## 1. What changes between the simulation and a real fleet controller

| Simulation (`drones.c` today) | Real (fleet controller + transport) |
|---|---|
| `drone->regs` is a `kzalloc`'d `u32` array per drone | `drone->regs_base` is `void __iomem *` mapped from a modem device, OR a cached register shadow per drone fed by the transport's incoming-telemetry handler |
| `skyport_reg_read/_write` does plain array access | the accessors read/write the modem's per-drone window with `ioread32`/`iowrite32`, OR the transport library marshals the read/write into a packet to the addressed drone |
| `skyport_init()` manually allocates dev numbers + RAM register blocks | a **`platform_driver`** whose `probe()` binds the modem device and creates the per-drone cdevs |
| `skyport_simulate_flight()` invents altitude/speed from propeller/pitch | deleted — real drones produce real telemetry; the modem receives it asynchronously and updates each drone's cached register block |
| `skyport_hw_command()` rolls/zeros `WEIGHT_REG` on grip/release | deleted — the real drone's gripper changes the real weight sensor on the drone; the modem ships the new reading back |
| `SET_TELEMETRY` (User Space feeds GPS/battery) | deleted — telemetry is *received* from each drone via the transport; User Space never writes sensors |
| Sensors polled on `read()` | telemetry arrives **asynchronously** over the radio link; the ISR updates the cache, `read()` reports the latest cached values |

---

## 2. Register map and command codes (unchanged from the simulation)

This is the **protocol every drone speaks**. The names and offsets stay; on real
hardware the datasheet pins down the exact values.

```c
/* Read-only sensor registers (updated by incoming telemetry frames) */
#define DRONE_STATUS_REG     0x00   /* flight status = drone_state value     */
#define DRONE_GPS_X_REG      0x04   /* current position X                    */
#define DRONE_GPS_Y_REG      0x08   /* current position Y                    */
#define DRONE_ALTITUDE_REG   0x0C   /* altimeter, metres                     */
#define DRONE_SPEED_REG      0x10   /* speedometer, km/h                     */
#define DRONE_BATTERY_REG    0x14   /* battery, percent                      */
#define DRONE_WEIGHT_REG     0x18   /* package weight sensor, grams          */

/* Write registers (sent as commands to the drone) */
#define DRONE_COMMAND_REG    0x1C   /* write a CMD_* code below              */
#define DRONE_NAV_X_REG      0x20   /* target X for navigation               */
#define DRONE_NAV_Y_REG      0x24   /* target Y for navigation               */

/* Actuator setpoints (driver commands, drone obeys) */
#define DRONE_PROPELLER_REG  0x28   /* throttle %, 0–100                     */
#define DRONE_PITCH_REG      0x2C   /* pitch degrees                         */

#define DRONE_REG_COUNT      12     /* 12 * sizeof(u32) = 0x30 bytes / drone */

#define CMD_EMERGENCY_LAND   0x01
#define CMD_HOVER            0x02
#define CMD_GOTO_CHARGER     0x03
#define CMD_ABORT_MISSION    0x04
#define CMD_START_MISSION    0x05
#define CMD_GRIP_PACKAGE     0x06
#define CMD_RELEASE_PACKAGE  0x07
#define CMD_FLY_TO_PICKUP    0x08
#define CMD_FLY_TO_DROPOFF   0x09
```

---

## 3. The seam — the only place "simulation" lives

Every register operation funnels through two accessors, and the
simulation/real-hardware difference lives entirely in their bodies:

```c
static inline u32 skyport_reg_read(struct skyport_drone *d, u32 off)
{
    return d->regs[off >> 2];              /* SIM: plain RAM            */
    /* REAL: read the latest cached value the transport layer received  *
     *       from drone d->drone_id:                                    *
     *   return ioread32(d->regs_base + off);                           */
}

static inline void skyport_reg_write(struct skyport_drone *d, u32 off, u32 val)
{
    d->regs[off >> 2] = val;               /* SIM: plain RAM            */
    /* REAL: write into the modem's outgoing command window for drone   *
     *       d->drone_id; the transport will frame & send it over air.  *
     *   iowrite32(val, d->regs_base + off);                            */
}
```

The storage type changes with them: `u32 *regs` becomes
`void __iomem *regs_base`, mapped per-drone in `probe()`.

---

## 4. Per-drone addressing

Three cdevs, three drones, one modem. Each `struct skyport_drone` is a **logical
channel** for one remote drone. The modem needs to know which drone an op
targets. Two reasonable options:

- **Separate register windows per drone.** The modem exposes an N-window MMIO
  area; `drone->regs_base` points at window `drone_id`. Accessor bodies stay
  the simplest possible `ioread32`/`iowrite32`.
- **Shared command FIFO + drone ID.** The driver tags each operation with
  `drone->drone_id` and sends through a shared channel. Accessor bodies do
  that framing.

Either matches the simulation's per-drone struct cleanly; the choice belongs to
the modem.

---

## 5. probe() / remove() — bind the modem, not a flight controller

```c
#include <linux/platform_device.h>
#include <linux/io.h>                  /* ioremap, ioread32, iowrite32 */
#include <linux/interrupt.h>           /* request_irq                  */
#include <linux/mod_devicetable.h>     /* of_device_id                 */

static int skyport_probe(struct platform_device *pdev)
{
    struct skyport_drone *drone;
    struct resource *res;
    int irq;

    drone = devm_kzalloc(&pdev->dev, sizeof(*drone), GFP_KERNEL);
    if (!drone)
        return -ENOMEM;

    /* Map this drone's window on the modem. (For the shared-FIFO model, map
     * the modem's command/event area instead.) Replaces the kzalloc of
     * drone->regs in the simulation. */
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    drone->regs_base = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(drone->regs_base))
        return PTR_ERR(drone->regs_base);

    mutex_init(&drone->lock);
    platform_set_drvdata(pdev, drone);

    /* Crucial for story B: telemetry from drones arrives ASYNCHRONOUSLY over
     * the radio link. The modem raises an IRQ when a new telemetry frame is
     * decoded; the ISR/bottom-half updates the cached registers for that
     * drone so the next read() returns fresh data. */
    irq = platform_get_irq(pdev, 0);
    devm_request_irq(&pdev->dev, irq, skyport_isr, 0, "skyport_modem", drone);

    /* Then create the cdev / "/dev/skyport_droneX" node, as skyport_init() does.
     * No fake startup register writes — real registers reflect the real drone. */
    return 0;
}

static int skyport_remove(struct platform_device *pdev)
{
    /* devm_* allocations and the ioremap are released automatically; the
     * kzalloc/kfree of drone->regs disappears entirely. */
    return 0;
}
```

---

## 6. Device-tree binding

`compatible` describes the **modem device** the driver binds to (not a drone):

```c
static const struct of_device_id skyport_of_match[] = {
    { .compatible = "skyport,fleet-modem" },
    { }
};
MODULE_DEVICE_TABLE(of, skyport_of_match);

static struct platform_driver skyport_driver = {
    .probe  = skyport_probe,
    .remove = skyport_remove,
    .driver = {
        .name           = "skyport_fleet",
        .of_match_table = skyport_of_match,
    },
};
module_platform_driver(skyport_driver);   /* replaces module_init/module_exit */
```

The kernel calls `probe()` once the modem device appears in the device tree.

---

## 7. What does NOT change in the handlers

Because every command/telemetry path already goes through the register accessors,
the entire upper layer of `drones.c` stays:

```c
/* HOVER (already in the simulation; in production, this sends CMD_HOVER
 * over the radio link to the addressed drone) */
skyport_hw_command(drone, CMD_HOVER);

/* GO_TO_CHARGER */
skyport_reg_write(drone, DRONE_NAV_X_REG, charger_x);
skyport_reg_write(drone, DRONE_NAV_Y_REG, charger_y);
skyport_hw_command(drone, CMD_GOTO_CHARGER);

/* read() telemetry — same code, sources are now real drones */
... skyport_reg_read(drone, DRONE_GPS_X_REG) ...
... skyport_reg_read(drone, DRONE_ALTITUDE_REG) ...
```

The simulation-only pieces are **removed** (not adapted):

- **`skyport_simulate_flight()`** — gone, and its call in `read()` goes with it.
  A real fleet of drones produces real altitude/speed; the modem ships those
  values back and the ISR caches them.
- **`SET_TELEMETRY`** — gone. Position and battery are *received*, not written
  by User Space.
- **`skyport_hw_command` gripper side-effects** — gone. The real gripper on the
  drone changes the real weight sensor; only the `iowrite32(cmd, COMMAND_REG)`
  remains.
- **Fake startup register writes** in `skyport_init` — gone. Real registers
  reflect the real drone.

---

## 8. Still not free — the real engineering left to do

This kernel driver is the **API every higher layer will speak to.** Around it,
a production deployment still needs:

- **Transport protocol** — framing, sequence numbers, ACKs, retries, link-loss
  handling, message integrity (CRC/HMAC).
- **Security over the air** — `expected_delivery_code` is a local-RAM secret
  today; over a radio link you also need confidentiality (TLS / link
  encryption) and authentication so the wrong-code dmesg log doesn't escape
  the device.
- **IRQ + bottom-half handling** — incoming telemetry frames arrive
  asynchronously per drone; the ISR/workqueue updates the cached register
  block for that drone.
- **Drone addressing / pairing / onboarding** — each drone needs a stable ID
  and a cryptographic identity.
- **Latency & reliability** — over-the-air round-trips are slow and lossy;
  `read()` returns the *latest known* values, not a fresh probe.
- **Modem-specific work** — datasheet register values, the chosen chipset's
  init sequence, power management.
- **Regulatory** — BVLOS operation requires regulatory approval, telemetry
  retention, and emergency-land authority chains.

So the kernel-side communication driver and its register API are built; the
transport, security, link-management, and regulatory layers are the major
engineering blocks for an actual fleet deployment.
